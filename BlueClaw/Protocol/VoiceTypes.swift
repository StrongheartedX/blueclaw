import Foundation

nonisolated struct VoiceExchange: Identifiable, Sendable {
    let id: String
    let userText: String
    var assistantText: String
    let timestamp: Date

    init(id: String = UUID().uuidString, userText: String, assistantText: String = "", timestamp: Date = Date()) {
        self.id = id
        self.userText = userText
        self.assistantText = assistantText
        self.timestamp = timestamp
    }
}
