import SwiftUI

struct VoiceExchangeRow: View {
    let exchange: VoiceExchange

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // User message
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 20)
                Text(exchange.userText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textPrimary)
            }

            // Assistant response
            if !exchange.assistantText.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "cpu")
                        .font(.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .frame(width: 20)
                    Text(exchange.assistantText)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
