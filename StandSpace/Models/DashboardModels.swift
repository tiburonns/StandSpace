import Foundation
import SwiftUI

enum ModuleKind: String, Codable, CaseIterable, Identifiable {
    case clock
    case date
    case battery
    case text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clock: "Reloj"
        case .date: "Fecha"
        case .battery: "Batería"
        case .text: "Texto"
        }
    }

    var icon: String {
        switch self {
        case .clock: "clock"
        case .date: "calendar"
        case .battery: "battery.75percent"
        case .text: "text.quote"
        }
    }
}

enum ModuleSize: String, Codable, CaseIterable, Identifiable {
    case small
    case wide
    case tall
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: "1 × 1"
        case .wide: "2 × 1"
        case .tall: "1 × 2"
        case .large: "2 × 2"
        }
    }

    var span: ModuleSpan {
        switch self {
        case .small: ModuleSpan(columns: 1, rows: 1)
        case .wide: ModuleSpan(columns: 2, rows: 1)
        case .tall: ModuleSpan(columns: 1, rows: 2)
        case .large: ModuleSpan(columns: 2, rows: 2)
        }
    }
}

enum ModuleStyle: String, Codable, CaseIterable, Identifiable {
    case glass
    case minimal
    case solid
    case outline
    case gradient

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glass: "Cristal"
        case .minimal: "Minimalista"
        case .solid: "Sólido"
        case .outline: "Contorno"
        case .gradient: "Gradiente"
        }
    }
}

enum BoardBackgroundStyle: String, Codable, CaseIterable, Identifiable {
    case black
    case midnight
    case standbyRed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .black: "Negro"
        case .midnight: "Medianoche"
        case .standbyRed: "Rojo nocturno"
        }
    }

    @ViewBuilder
    var background: some View {
        switch self {
        case .black:
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
        size: ModuleSize = .small,
        style: ModuleStyle = .glass,
        title: String = "",
        text: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.size = size
        self.style = style
        self.title = title
        self.text = text
    }
}

struct ModuleSpan: Equatable {
    let columns: Int
    let rows: Int
}
