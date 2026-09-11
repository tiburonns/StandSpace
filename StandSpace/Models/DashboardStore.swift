import SwiftUI

@MainActor
final class DashboardStore: ObservableObject {
    @Published var items: [DashboardItem] {
        didSet { save() }
    }

    @Published var keepScreenAwake: Bool {
        didSet { UserDefaults.standard.set(keepScreenAwake, forKey: Keys.keepAwake) }
    }

    @Published var backgroundStyle: BoardBackgroundStyle {
        didSet { UserDefaults.standard.set(backgroundStyle.rawValue, forKey: Keys.background) }
    }

    private enum Keys {
        static let items = "dashboard.items.v1"
        static let keepAwake = "dashboard.keepAwake"
        static let background = "dashboard.background"
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Keys.items),
           let decoded = try? JSONDecoder().decode([DashboardItem].self, from: data),
           !decoded.isEmpty {
            self.items = decoded
        } else {
            self.items = Self.defaultItems
        }

        if UserDefaults.standard.object(forKey: Keys.keepAwake) == nil {
            self.keepScreenAwake = true
        } else {
            self.keepScreenAwake = UserDefaults.standard.bool(forKey: Keys.keepAwake)
        }

        let rawBackground = UserDefaults.standard.string(forKey: Keys.background)
        self.backgroundStyle = rawBackground.flatMap(BoardBackgroundStyle.init(rawValue:)) ?? .midnight
    }

    func add(_ kind: ModuleKind) {
        let item: DashboardItem
        switch kind {
        case .clock:
            item = DashboardItem(kind: .clock, size: .wide, style: .glass)
        case .date:
            item = DashboardItem(kind: .date, size: .small, style: .minimal)
        case .battery:
            item = DashboardItem(kind: .battery, size: .small, style: .solid)
        case .text:
            item = DashboardItem(kind: .text, size: .wide, style: .outline, title: "Nota", text: "Tu texto aquí")
        }
        items.append(item)
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    func reset() {
        items = Self.defaultItems
        keepScreenAwake = true
        backgroundStyle = .midnight
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: Keys.items)
    }

    static let defaultItems: [DashboardItem] = [
        DashboardItem(kind: .clock, size: .large, style: .glass),
        DashboardItem(kind: .date, size: .wide, style: .minimal),
        DashboardItem(kind: .battery, size: .small, style: .solid),
        DashboardItem(kind: .text, size: .small, style: .outline, title: "Hola", text: "StandSpace")
    ]
}
