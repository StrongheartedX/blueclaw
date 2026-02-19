import Foundation

nonisolated struct UsageData: Sendable {
    let todayCost: Double
    let todayInputTokens: Int
    let todayOutputTokens: Int
    let allTimeCost: Double
    let allTimeInputTokens: Int
    let allTimeOutputTokens: Int

    init(from dict: [String: Any]) {
        // Support both flat and nested response formats
        let totals = dict["totals"] as? [String: Any] ?? dict
        let daily = dict["daily"] as? [[String: Any]]
        let today = daily?.last ?? dict

        todayCost = today["totalCost"] as? Double
            ?? today["todayCost"] as? Double ?? 0
        todayInputTokens = today["input"] as? Int
            ?? today["todayInputTokens"] as? Int ?? 0
        todayOutputTokens = today["output"] as? Int
            ?? today["todayOutputTokens"] as? Int ?? 0

        allTimeCost = totals["totalCost"] as? Double
            ?? totals["allTimeCost"] as? Double ?? 0
        allTimeInputTokens = totals["input"] as? Int
            ?? totals["allTimeInputTokens"] as? Int ?? 0
        allTimeOutputTokens = totals["output"] as? Int
            ?? totals["allTimeOutputTokens"] as? Int ?? 0
    }

    static func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            return String(format: "%.1fK", Double(tokens) / 1_000)
        }
        return "\(tokens)"
    }
}
