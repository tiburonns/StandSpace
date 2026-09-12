import SwiftUI

@MainActor
final class DashboardStore: ObservableObject {
    @Published var items: [DashboardItem] { didSet { save() } }
    @Published var keepScreenAwake: Bool { didSet { UserDefaults.standard.set(keepScreenAwake, forKey: Keys.keepAwake) } }
    @Published var backgroundStyle: BoardBackgroundStyle { didSet { UserDefaults.standard.set(backgroundStyle.rawValue, forKey: Keys.background) } }

    private enum Keys {
        static let items = "dashboard.items.v1"
        static let keepAwake = "dashboard.keepAwake"
        static let background = "dashboard.background"
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Keys.items),
           let decoded = try? JSONDecoder().decode([DashboardItem].self, from: data),
           !decoded.isEmpty {
            self.items = decoded.map(Self.repairIfNeeded)
        } else {
            self.items = Self.defaultItems
        }

        self.keepScreenAwake = UserDefaults.standard.object(forKey: Keys.keepAwake) == nil
            ? true
            : UserDefaults.standard.bool(forKey: Keys.keepAwake)

        let rawBackground = UserDefaults.standard.string(forKey: Keys.background)
        self.backgroundStyle = rawBackground.flatMap(BoardBackgroundStyle.init(rawValue:)) ?? .midnight
    }

    func add(_ kind: ModuleKind, size: ModuleSize? = nil, style: ModuleStyle = .glass) {
        let chosenSize = size.flatMap { kind.supportedSizes.contains($0) ? $0 : nil } ?? kind.defaultSize
        var item = DashboardItem(kind: kind, size: chosenSize, style: style)

        if kind == .text {
            item.title = "Nota"
            item.text = "Tu texto aquí"
        }

        withAnimation(.snappy) {
            items.append(item)
        }
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func delete(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.snappy) {
            items.remove(at: index)
        }
    }

    func duplicate(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        var copy = items[index]
        copy.id = UUID()
        copy.position = nil
        withAnimation(.snappy) {
            items.insert(copy, at: min(index + 1, items.count))
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    func setPosition(id: UUID, position: GridPosition?) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.snappy) {
            items[index].position = position
        }
    }

    func resize(id: UUID, to size: ModuleSize) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              items[index].kind.supportedSizes.contains(size) else { return }

        guard items[index].size != size else { return }

        withAnimation(.snappy(duration: 0.18)) {
            items[index].size = size
        }
    }

    func binding(for id: UUID) -> Binding<DashboardItem>? {
        guard items.contains(where: { $0.id == id }) else { return nil }

        return Binding(
            get: { [weak self] in
                self?.items.first(where: { $0.id == id }) ?? DashboardItem(kind: .text)
            },
            set: { [weak self] newValue in
                guard let self = self,
                      let index = self.items.firstIndex(where: { $0.id == id }) else { return }
                self.items[index] = Self.repairIfNeeded(newValue)
            }
        )
    }

    func reset() {
        withAnimation(.snappy) {
            items = Self.defaultItems
            keepScreenAwake = true
            backgroundStyle = .midnight
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: Keys.items)
    }

    private static func repairIfNeeded(_ item: DashboardItem) -> DashboardItem {
        guard !item.kind.supportedSizes.contains(item.size) else { return item }
        var repaired = item
        repaired.size = item.kind.defaultSize
        return repaired
    }

    static let defaultItems: [DashboardItem] = [
        DashboardItem(kind: .clock, size: .large, style: .glass, position: GridPosition(column: 0, row: 0)),
        DashboardItem(kind: .battery, size: .small, style: .solid, position: GridPosition(column: 2, row: 0)),
        DashboardItem(kind: .date, size: .wide, style: .minimal, position: GridPosition(column: 2, row: 1)),
        DashboardItem(kind: .dayProgress, size: .wide, style: .tinted),
        DashboardItem(kind: .timer, size: .wide, style: .glass)
    ]
}
