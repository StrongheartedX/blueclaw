import Foundation
import SwiftUI

enum AuditSeverity: String, Codable, CaseIterable, Sendable {
    case critical
    case high
    case medium
    case low
    case info
    case pass

    var displayName: String {
        switch self {
        case .pass: "Pass"
        default: rawValue.capitalized
        }
    }

    var color: Color {
        switch self {
        case .critical: .red
        case .high: .orange
        case .medium: .yellow
        case .low: .blue
        case .info: .gray
        case .pass: .green
        }
    }

    var icon: String {
        switch self {
        case .critical: "C"
        case .high: "H"
        case .medium: "M"
        case .low: "L"
        case .info: "i"
        case .pass: "\u{2713}"
        }
    }
}

struct AuditFinding: Identifiable, Codable, Sendable {
    let id: UUID
    let category: String
    let title: String
    let description: String
    let severity: AuditSeverity
    let recommendation: String

    init(category: String, title: String, description: String, severity: AuditSeverity, recommendation: String) {
        self.id = UUID()
        self.category = category
        self.title = title
        self.description = description
        self.severity = severity
        self.recommendation = recommendation
    }
}

struct AuditReport: Identifiable, Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let findings: [AuditFinding]
    let gatewayVersion: String

    init(findings: [AuditFinding], gatewayVersion: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.findings = findings
        self.gatewayVersion = gatewayVersion
    }

    /// Computes the overall security score.
    /// - `latestVersion`: the latest stable gateway release tag (e.g. "v2026.2.19"),
    ///   fetched async from GitHub. When provided, gateway version is scored as a category.
    func overallScore(latestVersion: String? = nil) -> Int {
        guard !findings.isEmpty else { return 100 }

        // Score each category equally. Data Protection is handled as a
        // flat deduction rather than diluted by category averaging.
        let grouped = Dictionary(grouping: findings, by: \.category)
        let scored = grouped.filter { $0.key != "Data Protection" }

        var categoryScores = scored.values.map { categoryScore(for: $0) }

        // Gateway version: scored as its own category when we know the latest release.
        if let latest = latestVersion, gatewayVersion != "Unknown" {
            let ver = gatewayVersion.lowercased()
            if ver == "dev" || ver.hasPrefix("dev") {
                categoryScores.append(100)
            } else if SecurityAuditor.isVersionCurrent(gatewayVersion, latest: latest) {
                categoryScores.append(100)
            } else {
                categoryScores.append(40)
            }
        }

        // Unencrypted transport = automatic 0. Nothing else matters if
        // traffic is sent in plaintext.
        let transportCritical = findings.contains {
            $0.category == "Transport" && $0.severity == .critical
        }
        if transportCritical { return 0 }

        var score = categoryScores.isEmpty ? 100 : categoryScores.reduce(0, +) / categoryScores.count

        // Content scanning disabled = flat 20-point deduction.
        let scanningDisabled = findings.contains {
            $0.category == "Data Protection" && $0.severity != .pass
        }
        if scanningDisabled {
            score = max(0, score - 20)
        }

        return score
    }

    private func categoryScore(for categoryFindings: [AuditFinding]) -> Int {
        let worstPenalty = categoryFindings.map { f -> Int in
            switch f.severity {
            case .critical: 100
            case .high: 60
            case .medium: 30
            case .low: 10
            case .info: 0
            case .pass: 0
            }
        }.max() ?? 0
        return max(0, 100 - worstPenalty)
    }

    /// Convenience for contexts without latest version info.
    var overallScore: Int { overallScore() }

    func scoreLabel(latestVersion: String? = nil) -> String {
        switch overallScore(latestVersion: latestVersion) {
        case 80...100: "Good"
        case 60..<80: "Fair"
        case 40..<60: "Needs Attention"
        default: "Critical"
        }
    }

    func scoreColor(latestVersion: String? = nil) -> Color {
        switch overallScore(latestVersion: latestVersion) {
        case 80...100: .green
        case 60..<80: .yellow
        case 40..<60: .orange
        default: .red
        }
    }

    func count(for severity: AuditSeverity) -> Int {
        findings.filter { $0.severity == severity }.count
    }

    var groupedByCategory: [(String, [AuditFinding])] {
        let order: [String: Int] = ["Gateway": 0, "Transport": 1, "Data Protection": 2, "Credentials": 3]
        let categories = Dictionary(grouping: findings, by: \.category)
        return categories.sorted { (order[$0.key] ?? 99) < (order[$1.key] ?? 99) }
    }
}
