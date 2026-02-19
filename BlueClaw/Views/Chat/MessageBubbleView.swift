import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    var isStreaming = false
    var agentEmoji: String?
    var agentName: String?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Role label
                if message.role == .assistant {
                    HStack(spacing: 4) {
                        if let emoji = agentEmoji {
                            Text(emoji)
                                .font(.system(size: 10))
                        } else {
                            Image(systemName: "cpu")
                                .font(.system(size: 10))
                        }
                        Text(agentName ?? "Assistant")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.leading, 4)
                }

                // Image thumbnail
                if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Message content
                if isStreaming {
                    Text(message.content + "▊")
                        .font(.body)
                        .foregroundStyle(message.role == .user ? .white : AppColors.textPrimary)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(bubbleColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else if message.imageData != nil && message.content == "\u{1F4F7} Image" {
                    // Image-only message, skip the text bubble
                    EmptyView()
                } else {
                    MarkdownTextView(content: message.content, isUser: message.role == .user)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(bubbleColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }

    private var bubbleColor: Color {
        switch message.role {
        case .user:
            AppColors.userBubble
        case .assistant:
            AppColors.assistantBubble
        case .system:
            AppColors.surface
        }
    }
}
