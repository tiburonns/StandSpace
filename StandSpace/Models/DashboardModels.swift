import Foundation
import SwiftUI

enum ModuleCategory: String, CaseIterable, Identifiable {
    case essentials
    case information
    case personal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .essentials: return "Esenciales"
        case .information: return "Información"
        case .personal: return "Personal"
        }
    }
}

enum ModuleKind: String, Codable, CaseIterable, Identifiable {
    case clock
    case date
    case battery
    case text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clock: return "Reloj"
        case .date: return "Fecha"
        case .battery: return "Batería"
        case .text: return "Texto"
        }
    }

    var subtitle: String {
        switch self {
        case .clock: return "Hora actual con diferentes proporciones"
        case .date: return "Día, fecha y año de un vistazo"
        case .battery: return "Nivel y estado de carga del dispositivo"
        case .text: return "Notas, frases o información personalizada"
        }
    }

    var icon: String {
        switch self {
        case .clock: return "clock"
        case .date: return "calendar"
        case .battery: return "battery.75percent"
        case .text: return "text.quote"
        }
    }

    var category: ModuleCategory {
        switch self {
        case .clock, .battery: return .essentials
        case .date: return .information
        case .text: return .personal
        }
    }

    var defaultSize: ModuleSize {
        switch self {
        case .clock: return .large
        case .date: return .wide
        case .battery: return .small
        case .text: return .wide
        }
    }

    var supportedSizes: [ModuleSize] {
        switch self {
        case .clock:
            [.small, .wide, .large, .tripleWide, .banner, .hero]
        case .date:
            [.small, .wide, .tall, .large, .tripleWide]
        case .battery:
            [.small, .wide, .tall, .large]
        case .text:
            ModuleSize.allCases
        }
    }
}

enum ModuleSize: String, Codable, CaseIterable, Identifiable {
    // Keep the original raw values so v0.1 dashboards decode without migration.
    case small
    case wide
    case tall
    case large
    case tripleWide
    case banner
    case triple
    case hero

    var id: String { rawValue }

    var title: String { "\(span.columns) × \(span.rows)" }

    var span: ModuleSpan {
        switch self {
        case .small: return ModuleSpan(columns: 1, rows: 1)
        case .wide: return ModuleSpan(columns: 2, rows: 1)
        case .tall: return ModuleSpan(columns: 1, rows: 2)
        case .large: return ModuleSpan(columns: 2, rows: 2)
        case .tripleWide: return ModuleSpan(columns: 3, rows: 1)
        case .banner: return ModuleSpan(columns: 4, rows: 1)
        case .triple: return ModuleSpan(columns: 3, rows: 2)
        case .hero: return ModuleSpan(columns: 4, rows: 2)
        }
    }

    static func closestSupported(
        columns: Int,
        rows: Int,
        supported: [ModuleSize]
    ) -> ModuleSize {
        supported.min { lhs, rhs in
            let left = abs(lhs.span.columns - columns) + abs(lhs.span.rows - rows)
            let right = abs(rhs.span.columns - columns) + abs(rhs.span.rows - rows)
            if left == right {
                return lhs.span.columns * lhs.span.rows < rhs.span.columns * rhs.span.rows
            }
            return left < right
        } ?? .small
    }
}

enum ModuleStyle: String, Codable, CaseIterable, Identifiable {
    case glass
    case minimal
    case solid
    case outline
    case gradient
    case tinted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glass: return "Cristal"
        case .minimal: return "Minimalista"
        case .solid: return "Sólido"
        case .outline: return "Contorno"
        case .gradient: return "Gradiente"
        case .tinted: return "Tinte"
        }
    }
}

enum BoardBackgroundStyle: String, Codable, CaseIterable, Identifiable {
    // Original cases preserved for v0.1 UserDefaults compatibility.
    case black
    case midnight
    case standbyRed
    case oled
    case aurora
    case warm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .black: return "Negro"
        case .midnight: return "Medianoche"
        case .standbyRed: return "Rojo nocturno"
        case .oled: return "OLED"
        case .aurora: return "Aurora"
        case .warm: return "Cálido"
        }
    }

    @ViewBuilder
    var background: some View {
        switch self {
        case .black, .oled:
            Color.black
        case .midnight:
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.07, blue: 0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .standbyRed:
            LinearGradient(
                colors: [Color.black, Color(red: 0.22, green: 0.01, blue: 0.01)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .aurora:
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.02, blue: 0.08),
                    Color(red: 0.03, green: 0.16, blue: 0.16),
                    Color(red: 0.08, green: 0.04, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .warm:
            LinearGradient(
                colors: [Color.black, Color(red: 0.20, green: 0.09, blue: 0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct DashboardItem: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: ModuleKind
    var size: ModuleSize
    var style: ModuleStyle
    var title: String
    var text: String

    init(
        id: UUID = UUID(),
        kind: ModuleKind,
        size: ModuleSize? = nil,
        style: ModuleStyle = .glass,
        title: String = "",
        text: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.size = size ?? kind.defaultSize
        self.style = style
        self.title = title
        self.text = text
    }
}

struct ModuleSpan: Equatable, Sendable {
    let columns: Int
    let rows: Int
}
