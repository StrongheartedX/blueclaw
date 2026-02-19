import Foundation
import AVFoundation
import Speech
import UIKit

@Observable
@MainActor
final class VoiceInputService {
    var isRecording = false
    var isSpeaking = false
    var transcription = ""
    var audioLevel: Float = 0
    var error: String?

    var onFinalTranscription: ((String) -> Void)?

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let synthesizer = AVSpeechSynthesizer()
    private var silenceTask: Task<Void, Never>?
    private var ttsDelegate: TTSDelegate?

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        let micStatus: Bool
        if #available(iOS 17.0, *) {
            micStatus = await AVAudioApplication.requestRecordPermission()
        } else {
            micStatus = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        return speechStatus && micStatus
    }

    // MARK: - Recording

    func startRecording() {
        guard !isRecording else { return }
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            error = "Speech recognition unavailable"
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let engine = AVAudioEngine()
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true

            let inputNode = engine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                request.append(buffer)
                // Calculate audio level
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)
                var sum: Float = 0
                for i in 0..<frameLength {
                    sum += abs(channelData[i])
                }
                let avg = frameLength > 0 ? sum / Float(frameLength) : 0
                Task { @MainActor [weak self] in
                    self?.audioLevel = min(avg * 10, 1.0)
                }
            }

            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let result {
                        self.transcription = result.bestTranscription.formattedString
                        self.resetSilenceTimer()
                    }
                    if let error {
                        let code = (error as NSError).code
                        // Ignore common non-fatal speech recognition errors
                        if ![216, 209, 203, 1110, 301].contains(code) {
                            self.error = error.localizedDescription
                        }
                    }
                }
            }

            engine.prepare()
            try engine.start()

            self.audioEngine = engine
            self.recognitionRequest = request
            self.isRecording = true
            self.transcription = ""
            self.error = nil

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            self.error = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        stopRecordingInternal()
        let text = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            onFinalTranscription?(text)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func stopRecordingInternal() {
        silenceTask?.cancel()
        silenceTask = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        audioLevel = 0

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func resetSilenceTimer() {
        silenceTask?.cancel()
        silenceTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(1.5))
            } catch {
                return // Cancelled
            }
            guard let self, self.isRecording else { return }
            let text = self.transcription.trimmingCharacters(in: .whitespacesAndNewlines)
            self.stopRecordingInternal()
            if !text.isEmpty {
                self.onFinalTranscription?(text)
            }
        }
    }

    // MARK: - Text-to-Speech

    func speak(_ text: String, completion: (() -> Void)? = nil) {
        synthesizer.stopSpeaking(at: .immediate)

        let cleaned = stripMarkdown(text)
        guard !cleaned.isEmpty else {
            completion?()
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // Continue anyway
        }

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.05
        utterance.preUtteranceDelay = 0.15
        utterance.postUtteranceDelay = 0.1
        utterance.volume = 0.9

        // Try premium/enhanced voices first — these sound significantly more natural
        let preferredVoiceIDs = [
            "com.apple.voice.premium.en-US.Zoe",
            "com.apple.voice.premium.en-US.Ava",
            "com.apple.voice.premium.en-US.Evan",
            "com.apple.voice.premium.en-US.Tom",
            "com.apple.voice.enhanced.en-US.Zoe",
            "com.apple.voice.enhanced.en-US.Ava",
            "com.apple.voice.enhanced.en-US.Evan",
            "com.apple.voice.enhanced.en-US.Tom",
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.compact.en-US.Samantha",
        ]
        for voiceID in preferredVoiceIDs {
            if let voice = AVSpeechSynthesisVoice(identifier: voiceID) {
                utterance.voice = voice
                break
            }
        }
        if utterance.voice == nil {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        let delegate = TTSDelegate { [weak self] in
            Task { @MainActor [weak self] in
                self?.isSpeaking = false
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                completion?()
            }
        }
        self.ttsDelegate = delegate
        synthesizer.delegate = delegate

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Markdown Stripping

    private func stripMarkdown(_ text: String) -> String {
        var result = text
        // Code blocks
        result = result.replacingOccurrences(of: "```[\\s\\S]*?```", with: " code block ", options: .regularExpression)
        // Inline code
        result = result.replacingOccurrences(of: "`[^`]+`", with: "", options: .regularExpression)
        // Bold
        result = result.replacingOccurrences(of: "\\*\\*([^*]+)\\*\\*", with: "$1", options: .regularExpression)
        // Italic
        result = result.replacingOccurrences(of: "\\*([^*]+)\\*", with: "$1", options: .regularExpression)
        // Headers
        result = result.replacingOccurrences(of: "^#{1,6}\\s+", with: "", options: .regularExpression)
        // Links
        result = result.replacingOccurrences(of: "\\[([^\\]]+)\\]\\([^)]+\\)", with: "$1", options: .regularExpression)
        // Collapse whitespace
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - TTS Delegate

private final class TTSDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish()
    }
}
