import SwiftUI

// MARK: - Popover content shown when clicking the menu bar icon

struct UsageMenuView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            mainUsageSection
            if viewModel.hasModelBreakdown {
                Divider()
                modelBreakdownSection
            }
            if let extra = viewModel.usage?.extraUsage, extra.isEnabled {
                Divider()
                extraUsageSection(extra)
            }
            Divider()
            footer
        }
        .frame(width: 280)
        .padding(.vertical, 8)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Claude Meter")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - 5-Hour & 7-Day bars

    private var mainUsageSection: some View {
        VStack(spacing: 10) {
            usageRow(
                label: "5-Hour",
                utilization: viewModel.usage?.fiveHour?.utilization,
                resetsAt: viewModel.usage?.fiveHour?.resetsAt
            )
            usageRow(
                label: "7-Day",
                utilization: viewModel.usage?.sevenDay?.utilization,
                resetsAt: viewModel.usage?.sevenDay?.resetsAt
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Per-model breakdown

    private var modelBreakdownSection: some View {
        VStack(spacing: 8) {
            Text("Model Breakdown")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            usageRow(
                label: "Opus",
                utilization: viewModel.usage?.sevenDayOpus?.utilization,
                resetsAt: nil,
                compact: true
            )
            usageRow(
                label: "Sonnet",
                utilization: viewModel.usage?.sevenDaySonnet?.utilization,
                resetsAt: nil,
                compact: true
            )
            usageRow(
                label: "Cowork",
                utilization: viewModel.usage?.sevenDayCowork?.utilization,
                resetsAt: nil,
                compact: true
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Extra usage

    private func extraUsageSection(_ extra: ExtraUsage) -> some View {
        HStack {
            Text("Extra Usage")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            let used = extra.usedCredits ?? 0
            let limit = extra.monthlyLimit ?? 0
            Text("$\(used, specifier: "%.2f") / $\(limit, specifier: "%.2f")")
                .font(.system(size: 11, design: .monospaced))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if let error = viewModel.error {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 10))
                Text(error)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text("Updated \(viewModel.updatedAgoString)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Refresh") {
                Task { await viewModel.fetchUsage() }
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Reusable progress row

    private func usageRow(
        label: String,
        utilization: Double?,
        resetsAt: String?,
        compact: Bool = false
    ) -> some View {
        let pct = utilization ?? 0

        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: compact ? 11 : 12, weight: .medium))
                Spacer()
                Text("\(Int(pct))%")
                    .font(.system(size: compact ? 11 : 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(ColorThresholds.color(for: pct))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: compact ? 4 : 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(ColorThresholds.color(for: pct))
                        .frame(width: geo.size.width * min(pct / 100, 1.0), height: compact ? 4 : 6)
                }
            }
            .frame(height: compact ? 4 : 6)

            if let resetsAt {
                Text("Resets in \(viewModel.resetTimeString(for: resetsAt))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
