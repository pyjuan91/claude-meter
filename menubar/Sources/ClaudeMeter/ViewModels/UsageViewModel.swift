import Foundation
import SwiftUI
import Combine

// MARK: - Central state & polling orchestration

@MainActor
final class UsageViewModel: ObservableObject {

    // MARK: Published state

    @Published var usage: UsageData?
    @Published var lastUpdated: Date?
    @Published var error: String?
    @Published var isLoading = false

    // MARK: Convenience accessors

    var fiveHourUtilization: Double  { usage?.fiveHour?.utilization ?? 0 }
    var sevenDayUtilization: Double  { usage?.sevenDay?.utilization ?? 0 }

    /// Only show Model Breakdown when the API actually returns per-model data.
    var hasModelBreakdown: Bool {
        usage?.sevenDayOpus != nil || usage?.sevenDaySonnet != nil || usage?.sevenDayCowork != nil
    }

    // MARK: Polling

    private var timer: Timer?
    private let pollInterval: TimeInterval = 60  // same as browser extension

    init() {
        startPolling()
    }

    deinit {
        timer?.invalidate()
    }

    func startPolling() {
        Task { await fetchUsage() }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in await self.fetchUsage() }
        }
    }

    func fetchUsage() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let sessionKey = try CookieService.getCookie(name: "sessionKey")
            let orgId      = try CookieService.getCookie(name: "lastActiveOrg")

            let data = try await UsageService.fetchUsage(orgId: orgId, sessionKey: sessionKey)
            self.usage = data
            self.lastUpdated = Date()
            self.error = nil
        } catch {
            self.error = error.localizedDescription
            print("[ClaudeMeter] fetch error: \(error)")
        }
    }

    // MARK: - Time formatting helpers

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterBasic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// "3h 12m" style countdown until the reset timestamp.
    func resetTimeString(for isoDate: String?) -> String {
        guard let isoDate else { return "--" }

        let date = Self.isoFormatter.date(from: isoDate)
                ?? Self.isoFormatterBasic.date(from: isoDate)

        guard let date else { return "--" }

        let seconds = Int(date.timeIntervalSinceNow)
        guard seconds > 0 else { return "Resetting…" }

        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    /// "12s ago", "3m ago"
    var updatedAgoString: String {
        guard let lastUpdated else { return "Never" }
        let seconds = Int(Date().timeIntervalSince(lastUpdated))
        if seconds < 5  { return "Just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        return "\(seconds / 60)m ago"
    }
}
