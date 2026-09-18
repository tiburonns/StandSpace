import SwiftUI

struct ModuleCardView: View {
    let item: DashboardItem

    var body: some View {
        moduleContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(padding)
            .foregroundStyle(Color.white)
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
        case .timer:
            TimerModuleView(size: item.size, storageID: item.id)
        case .calendar:
            CalendarModuleView(size: item.size)
        case .storage:
            StorageModuleView(size: item.size)
        case .device:
            DeviceInfoModuleView(size: item.size)
        case .dayProgress:
            DayProgressModuleView(size: item.size)
        case .text:
            TextModuleView(item: item)
        }
    }

    private var padding: CGFloat {
        return item.size == .small ? 16 : 22
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
        case .tinted:
            LinearGradient(
                colors: [Color.accentColor.opacity(0.30), Color.accentColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private var cardBorder: some View {
        if item.style == .outline || item.style == .glass || item.style == .tinted {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    item.style == .tinted
                        ? Color.accentColor.opacity(0.35)
                        : Color.white.opacity(item.style == .outline ? 0.35 : 0.12),
                    lineWidth: 1
                )
        }
    }
}
