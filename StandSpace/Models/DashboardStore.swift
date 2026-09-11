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
            self.items = decoded.map(Self.repairIfNeeded)
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

    func add(_ kind: ModuleKind, size: ModuleSize? = nil, style: ModuleStyle = .glass) {
        let chosenSize = size.flatMap { kind.supportedSizes.contains($0) ? $0 : nil } ?? kind.defaultSize
        let item: DashboardItem

        switch kind {
        case .clock:
            item = DashboardItem(kind: .clock, size: chosenSize, style: style)
        case .date:
            item = DashboardItem(kind: .date, size: chosenSize, style: style)
        case .battery:
            item = DashboardItem(kind: .battery, size: chosenSize, style: style)
        case .text:
            item = DashboardItem(
                kind: .text,
                size: chosenSize,
                style: style,
                title: "Nota",
                text: "Tu texto aquí"
            )
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
        withAnimation(.snappy) {
            items.insert(copy, at: min(index + 1, items.count))
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    func move(id: UUID, to destination: Int) {
        guard let source = items.firstIndex(where: { $0.id == id }) else { return }
        let clamped = max(0, min(destination, items.count - 1))
        guard source != clamped else { return }

        withAnimation(.snappy) {
            let item = items.remove(at: source)
            items.insert(item, at: min(clamped, items.count))
        }
    }

    func resize(id: UUID, to size: ModuleSize) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              items[index].kind.supportedSizes.contains(size) else { return }
        withAnimation(.snappy) {
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
                guard let self,
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
        DashboardItem(kind: .clock, size: .large, style: .glass),
        DashboardItem(kind: .date, size: .wide, style: .minimal),
        DashboardItem(kind: .battery, size: .small, style: .solid),
        DashboardItem(kind: .text, size: .small, style: .outline, title: "Hola", text: "StandSpace")
    ]
}
