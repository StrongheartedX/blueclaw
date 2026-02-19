import SwiftUI

struct SecurityScoreCardView: View {
    let report: AuditReport
    var latestVersion: String?

    private var score: Int { report.overallScore(latestVersion: latestVersion) }

    var body: some View {
        VStack(spacing: 12) {
            // Circular score
            ZStack {
                Circle()
                    .stroke(AppColors.surfaceBorder, lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(report.scoreColor(latestVersion: latestVersion), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("/ 100")
                        .font(.caption2)
                        .foregroundStyle(AppColors.textMuted)
                }
            }

            Text(report.scoreLabel(latestVersion: latestVersion))
                .font(.headline)
                .foregroundStyle(report.scoreColor(latestVersion: latestVersion))

            let passCount = report.count(for: .pass)
            let issueCount = report.findings.count - passCount - report.count(for: .info)
            if issueCount > 0 {
                Text("\(passCount) passed, \(issueCount) \(issueCount == 1 ? "issue" : "issues")")
                    .font(.caption)
                    .foregroundStyle(AppColors.textMuted)
            } else {
                Text("\(passCount) checks passed")
                    .font(.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}
