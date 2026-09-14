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
        copy.landscapePosition = nil

        withAnimation(.snappy) {
            items.insert(copy, at: min(index + 1, items.count))
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    func setPosition(
        id: UUID,
        position: GridPosition?,
        orientation: CanvasOrientation = .portrait
    ) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }

        withAnimation(.snappy) {
            switch orientation {
            case .portrait:
                items[index].position = position
            case .landscape:
                items[index].landscapePosition = position
            }
        }
    }

    func resize(
        id: UUID,
        to size: ModuleSize,
        orientation: CanvasOrientation = .portrait
    ) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              items[index].kind.supportedSizes.contains(size) else { return }

        let current = items[index].size(for: orientation)
        guard current != size else { return }

        withAnimation(.snappy(duration: 0.18)) {
            switch orientation {
            case .portrait:
                items[index].size = size
            case .landscape:
                items[index].landscapeSize = size
            }
        }
    }

    func applyLandscapePreset(_ preset: LandscapePreset, columns: Int) {
        guard !items.isEmpty else { return }

        withAnimation(.snappy) {
            for index in items.indices {
                items[index].landscapePosition = nil
                items[index].landscapeSize = nil
            }

            switch preset {
            case .adaptive:
                break

            case .duo:
                let slotWidth = max(2, columns / 2)
                for index in items.indices.prefix(2) {
                    let column = index == 0 ? 0 : slotWidth
                    items[index].landscapePosition = GridPosition(column: column, row: 0)
                    items[index].landscapeSize = Self.bestSize(
                        for: items[index].kind,
                        maxColumns: slotWidth,
                        maxRows: 2
                    )
                }

            case .quad:
                let slotWidth = max(2, columns / 2)
                let positions = [
                    GridPosition(column: 0, row: 0),
                    GridPosition(column: slotWidth, row: 0),
                    GridPosition(column: 0, row: 2),
                    GridPosition(column: slotWidth, row: 2)
                ]

                for index in items.indices.prefix(4) {
                    items[index].landscapePosition = positions[index]
                    items[index].landscapeSize = Self.bestSize(
                        for: items[index].kind,
                        maxColumns: slotWidth,
                        maxRows: 2
                    )
                }

            case .focus:
                let focusIndex = items.firstIndex(where: { $0.kind == .clock }) ?? items.startIndex
                items[focusIndex].landscapePosition = GridPosition(column: 0, row: 0)
                items[focusIndex].landscapeSize = Self.bestSize(
                    for: items[focusIndex].kind,
                    maxColumns: min(columns, 4),
                    maxRows: 2
                )

                var row = 2
                for index in items.indices where index != focusIndex {
                    items[index].landscapePosition = GridPosition(column: 0, row: row)
                    let size = Self.bestSize(
                        for: items[index].kind,
                        maxColumns: min(columns, 4),
                        maxRows: 1
                    )
                    items[index].landscapeSize = size
                    row += max(size.span.rows, 1)
                }
            }
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
        var repaired = item

        if !item.kind.supportedSizes.contains(item.size) {
            repaired.size = item.kind.defaultSize
        }

        if let landscapeSize = item.landscapeSize,
           !item.kind.supportedSizes.contains(landscapeSize) {
            repaired.landscapeSize = nil
        }

        return repaired
    }

    private static func bestSize(
        for kind: ModuleKind,
        maxColumns: Int,
        maxRows: Int
    ) -> ModuleSize {
        let fitting = kind.supportedSizes.filter {
            $0.span.columns <= maxColumns && $0.span.rows <= maxRows
        }

        return fitting.max { lhs, rhs in
            let leftArea = lhs.span.columns * lhs.span.rows
            let rightArea = rhs.span.columns * rhs.span.rows

            if leftArea == rightArea {
                return lhs.span.columns < rhs.span.columns
            }

            return leftArea < rightArea
        } ?? kind.defaultSize
    }

    static let defaultItems: [DashboardItem] = [
        DashboardItem(
            kind: .clock,
            size: .large,
            style: .glass,
            position: GridPosition(column: 0, row: 0),
            landscapePosition: GridPosition(column: 0, row: 0),
            landscapeSize: .hero
        ),
        DashboardItem(
            kind: .battery,
            size: .small,
            style: .solid,
            position: GridPosition(column: 2, row: 0),
            landscapePosition: GridPosition(column: 4, row: 0),
            landscapeSize: .large
        ),
        DashboardItem(
            kind: .date,
            size: .wide,
            style: .minimal,
            position: GridPosition(column: 2, row: 1),
            landscapePosition: GridPosition(column: 6, row: 0),
            landscapeSize: .wide
        ),
        DashboardItem(
            kind: .dayProgress,
            size: .wide,
            style: .tinted,
            landscapePosition: GridPosition(column: 4, row: 2),
            landscapeSize: .wide
        ),
        DashboardItem(
            kind: .timer,
            size: .wide,
            style: .glass,
            landscapePosition: GridPosition(column: 6, row: 2),
            landscapeSize: .wide
        )
    ]
}
