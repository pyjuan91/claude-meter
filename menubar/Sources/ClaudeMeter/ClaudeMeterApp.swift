import SwiftUI

// MARK: - App entry point
//
// Uses SwiftUI MenuBarExtra (macOS 13+) for a native menu bar experience.
// LSUIElement = true in Info.plist hides the Dock icon.

@main
struct ClaudeMeterApp: App {
    @StateObject private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            UsageMenuView(viewModel: viewModel)
        } label: {
            MenuBarLabel(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu bar icon + percentage label

private struct MenuBarLabel: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(nsImage: DonutIcon.render(
                percentage: viewModel.fiveHourUtilization,
                size: 18
            ))
            Text("\(Int(viewModel.fiveHourUtilization))%")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
    }
}
