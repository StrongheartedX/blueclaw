import SwiftUI

struct UsageSectionView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Section("Usage") {
            if let usage = appState.usageData {
                VStack(alignment: .leading, spacing: 12) {
                    // Today
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today")
                                .font(.caption)
                                .foregroundStyle(AppColors.textMuted)
                            Text(String(format: "$%.4f", usage.todayCost))
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        Spacer()
                        if appState.isLoadingUsage {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }

                    HStack(spacing: 24) {
                        UsageStatLabel(label: "Tokens In", value: UsageData.formatTokens(usage.todayInputTokens))
                        UsageStatLabel(label: "Tokens Out", value: UsageData.formatTokens(usage.todayOutputTokens))
                    }

                    Divider()

                    // All time
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("All Time")
                                .font(.caption)
                                .foregroundStyle(AppColors.textMuted)
                            Text(String(format: "$%.2f", usage.allTimeCost))
                                .font(.headline)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        Spacer()
                        Text("\(UsageData.formatTokens(usage.allTimeInputTokens)) in / \(UsageData.formatTokens(usage.allTimeOutputTokens)) out")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .padding(.vertical, 4)
            } else if appState.isLoadingUsage {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                Text("Usage data unavailable")
                    .font(.callout)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }
}

private struct UsageStatLabel: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.textMuted)
        }
    }
}
