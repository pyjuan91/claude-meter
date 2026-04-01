import Foundation

/// Root response from GET /api/organizations/{orgId}/usage
struct UsageData: Codable {
    let fiveHour: UsagePeriod?
    let sevenDay: UsagePeriod?
    let sevenDayOpus: UsagePeriod?
    let sevenDaySonnet: UsagePeriod?
    let sevenDayCowork: UsagePeriod?
    let extraUsage: ExtraUsage?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOpus = "seven_day_opus"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayCowork = "seven_day_cowork"
        case extraUsage = "extra_usage"
    }
}

/// A single usage window (5-hour rolling or 7-day)
struct UsagePeriod: Codable {
    let utilization: Double   // 0-100+
    let resetsAt: String      // ISO 8601

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

/// Extra (paid) usage bucket
struct ExtraUsage: Codable {
    let isEnabled: Bool
    let usedCredits: Double?
    let monthlyLimit: Double?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case usedCredits = "used_credits"
        case monthlyLimit = "monthly_limit"
    }
}
