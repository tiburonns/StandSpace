import SwiftUI

struct ModuleCardView: View {
    let item: DashboardItem

    var body: some View {
        moduleContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(padding)
            .foregroundStyle(foregroundStyle)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(cardBorder)
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    @ViewBuilder
    private var moduleContent: some View {
        switch item.kind {
        case .clock:
            ClockModuleView(size: item.size)
        case .date:
            DateModuleView(size: item.size)
        case .battery:
            BatteryModuleView(size: item.size)
        case .text:
            TextModuleView(item: item)
        }
    }

    private var padding: CGFloat {
        item.size == .small ? 16 : 22
    }

    private var foregroundStyle: Color {
        .white
    }

    @ViewBuilder
    private var cardBackground: some View {
        switch item.style {
        case .glass:
            Rectangle().fill(.ultraThinMaterial)
        case .minimal:
            Color.clear
        case .solid:
            Color.white.opacity(0.10)
        case .outline:
            Color.black.opacity(0.15)
        case .gradient:
            LinearGradient(
                colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private var cardBorder: some View {
        if item.style == .outline || item.style == .glass {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(item.style == .outline ? 0.35 : 0.12), lineWidth: 1)
        }
    }
}
