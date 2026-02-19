import SwiftUI

struct VoiceButton: View {
    @State private var voiceService = VoiceInputService()
    @State private var permissionsGranted = false
    let onTranscription: (String) -> Void

    var body: some View {
        Button {
            if voiceService.isRecording {
                voiceService.stopRecording()
            } else {
                Task {
                    if !permissionsGranted {
                        permissionsGranted = await voiceService.requestPermissions()
                    }
                    if permissionsGranted {
                        voiceService.startRecording()
                    }
                }
            }
        } label: {
            Image(systemName: voiceService.isRecording ? "mic.fill" : "mic")
                .font(.system(size: 18))
                .foregroundStyle(voiceService.isRecording ? AppColors.accent : AppColors.textMuted)
                .symbolEffect(.pulse, isActive: voiceService.isRecording)
        }
        .onAppear {
            voiceService.onFinalTranscription = { text in
                onTranscription(text)
            }
        }
    }
}
