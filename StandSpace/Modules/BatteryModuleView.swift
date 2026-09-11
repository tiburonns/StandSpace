import SwiftUI
import UIKit

struct BatteryModuleView: View {
    let size: ModuleSize
    @State private var level: Float = UIDevice.current.batteryLevel
    @State private var state: UIDevice.BatteryState = UIDevice.current.batteryState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: batterySymbol)
                    .font(.system(size: size == .small ? 28 : 36, weight: .semibold))
                Spacer()
                if state == .charging {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                }
            }

            Spacer(minLength: 4)

            Text(levelText)
                .font(.system(size: size == .small ? 34 : 50, weight: .bold, design: .rounded))

            Text(stateText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in
            refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in
            refresh()
        }
    }

    private func refresh() {
        level = UIDevice.current.batteryLevel
        state = UIDevice.current.batteryState
    }

    private var levelText: String {
        guard level >= 0 else { return "—" }
        return "\(Int(level * 100))%"
    }

    private var batterySymbol: String {
        guard level >= 0 else { return "battery.0percent" }
        switch level {
        case ..<0.125: "battery.0percent"
        case ..<0.375: "battery.25percent"
        case ..<0.625: "battery.50percent"
        case ..<0.875: "battery.75percent"
        default: "battery.100percent"
        }
    }

    private var stateText: String {
        switch state {
        case .charging: "Cargando"
        case .full: "Carga completa"
        case .unplugged: "Usando batería"
        case .unknown: "Estado desconocido"
        @unknown default: "Estado desconocido"
        }
    }
}
