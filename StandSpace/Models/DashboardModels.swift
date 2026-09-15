import Foundation
import SwiftUI

enum StandSpaceKind: String, Codable, CaseIterable, Identifiable {
    case desk
    case night
    case work
    case kitchen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .desk: return "Escritorio"
        case .night: return "Noche"
        case .work: return "Trabajo"
        case .kitchen: return "Cocina"
        }
    }

    var icon: String {
        switch self {
        case .desk: return "desktopcomputer"
        case .night: return "moon.stars"
        case .work: return "briefcase"
        case .kitchen: return "fork.knife"
        }
    }
}

struct StandSpaceProfile: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: StandSpaceKind
    var items: [DashboardItem]
    var backgroundStyle: BoardBackgroundStyle

    init(
        id: UUID = UUID(),
        kind: StandSpaceKind,
        items: [DashboardItem],
        backgroundStyle: BoardBackgroundStyle
    ) {
        self.id = id
        self.kind = kind
        self.items = items
        self.backgroundStyle = backgroundStyle
    }
}

enum LandscapePage: String, CaseIterable, Identifiable {
    case dashboard
    case clock
    case focus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Panel"
        case .clock: return "Reloj"
        case .focus: return "Focus"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .clock: return "clock"
        case .focus: return "timer"
        }
    }
}

enum CanvasOrientation: String {
    case portrait
    case landscape
}

enum LandscapePreset: String, CaseIterable, Identifiable {
    case adaptive
    case duo
    case quad
    case focus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .adaptive: return "Adaptativo"
        case .duo: return "Duo"
        case .quad: return "Quad"
        case .focus: return "Focus"
        }
    }

    var icon: String {
        switch self {
        case .adaptive: return "rectangle.grid.1x2"
        case .duo: return "rectangle.split.2x1"
        case .quad: return "square.grid.2x2"
        case .focus: return "rectangle.inset.filled"
        }
    }
}

enum ModuleCategory: String, CaseIterable, Identifiable {
    case essentials
    case productivity
    case information
    case system
    case personal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .essentials: return "Esenciales"
        case .productivity: return "Productividad"
        case .information: return "Información"
        case .system: return "Sistema"
        case .personal: return "Personal"
        }
    }
}

enum ModuleKind: String, Codable, CaseIterable, Identifiable {
    case clock
    case date
    case battery
    case timer
    case calendar
    case storage
    case device
    case dayProgress
    case text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clock: return "Reloj"
        case .date: return "Fecha"
        case .battery: return "Batería"
        case .timer: return "Temporizador"
        case .calendar: return "Próximo evento"
        case .storage: return "Almacenamiento"
        case .device: return "Dispositivo"
        case .dayProgress: return "Progreso del día"
        case .text: return "Texto"
        }
    }

    var subtitle: String {
        switch self {
        case .clock: return "Hora actual con distintos tamaños"
        case .date: return "Día, fecha y año de un vistazo"
        case .battery: return "Nivel y estado de carga"
        case .timer: return "Cuenta regresiva rápida"
        case .calendar: return "El siguiente evento de tu calendario"
        case .storage: return "Espacio usado y disponible"
        case .device: return "Nombre, modelo y sistema"
        case .dayProgress: return "Qué porcentaje del día ya pasó"
        case .text: return "Notas o información personalizada"
        }
    }

    var icon: String {
        switch self {
        case .clock: return "clock"
        case .date: return "calendar"
        case .battery: return "battery.75percent"
        case .timer: return "timer"
        case .calendar: return "calendar.badge.clock"
        case .storage: return "internaldrive"
        case .device: return "iphone"
        case .dayProgress: return "circle.lefthalf.filled"
        case .text: return "text.quote"
        }
    }

    var category: ModuleCategory {
        switch self {
        case .clock, .battery: return .essentials
        case .timer, .calendar: return .productivity
        case .date, .dayProgress: return .information
        case .storage, .device: return .system
        case .text: return .personal
        }
    }

    var defaultSize: ModuleSize {
        switch self {
        case .clock: return .large
        case .date: return .wide
        case .battery: return .small
        case .timer: return .wide
        case .calendar: return .wide
        case .storage: return .wide
        case .device: return .wide
        case .dayProgress: return .wide
        case .text: return .wide
        }
    }

    var supportedSizes: [ModuleSize] {
        switch self {
        case .clock:
            return [.small, .wide, .large, .tripleWide, .banner, .hero]
        case .date:
            return [.small, .wide, .tall, .large, .tripleWide]
        case .battery:
            return [.small, .wide, .tall, .large]
        case .timer:
            return [.small, .wide, .large, .tripleWide]
        case .calendar:
            return [.wide, .large, .tripleWide, .banner]
        case .storage:
            return [.small, .wide, .large, .tripleWide]
        case .device:
            return [.wide, .large, .tripleWide]
        case .dayProgress:
            return [.small, .wide, .large, .tripleWide]
        case .text:
            return ModuleSize.allCases
        }
    }
}

enum ModuleSize: String, Codable, CaseIterable, Identifiable {
    case small
    case wide
    case tall
    case large
    case tripleWide
    case banner
    case triple
    case hero

    var id: String { rawValue }
    var title: String { return "\(span.columns) × \(span.rows)" }

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

    static func closestSupported(columns: Int, rows: Int, supported: [ModuleSize]) -> ModuleSize {
        return supported.min { lhs, rhs in
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
            LinearGradient(colors: [Color.black, Color(red: 0.05, green: 0.07, blue: 0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .standbyRed:
            LinearGradient(colors: [Color.black, Color(red: 0.22, green: 0.01, blue: 0.01)], startPoint: .top, endPoint: .bottom)
        case .aurora:
            LinearGradient(colors: [Color(red: 0.01, green: 0.02, blue: 0.08), Color(red: 0.03, green: 0.16, blue: 0.16), Color(red: 0.08, green: 0.04, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .warm:
            LinearGradient(colors: [Color.black, Color(red: 0.20, green: 0.09, blue: 0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct GridPosition: Codable, Equatable {
    var column: Int
    var row: Int
}

struct DashboardItem: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: ModuleKind
    var size: ModuleSize
    var style: ModuleStyle
    var title: String
    var text: String
    var position: GridPosition?
    var landscapePosition: GridPosition?
    var landscapeSize: ModuleSize?

    init(
        id: UUID = UUID(),
        kind: ModuleKind,
        size: ModuleSize? = nil,
        style: ModuleStyle = .glass,
        title: String = "",
        text: String = "",
        position: GridPosition? = nil,
        landscapePosition: GridPosition? = nil,
        landscapeSize: ModuleSize? = nil
    ) {
        self.id = id
        self.kind = kind
        self.size = size ?? kind.defaultSize
        self.style = style
        self.title = title
        self.text = text
        self.position = position
        self.landscapePosition = landscapePosition
        self.landscapeSize = landscapeSize
    }

    func size(for orientation: CanvasOrientation) -> ModuleSize {
        switch orientation {
        case .portrait:
            return size
        case .landscape:
            return landscapeSize ?? size
        }
    }

    func position(for orientation: CanvasOrientation) -> GridPosition? {
        switch orientation {
        case .portrait:
            return position
        case .landscape:
            return landscapePosition
        }
    }

    func rendered(for orientation: CanvasOrientation) -> DashboardItem {
        var copy = self
        copy.size = size(for: orientation)
        copy.position = position(for: orientation)
        return copy
    }
}

struct ModuleSpan: Equatable, Sendable {
    let columns: Int
    let rows: Int
}
