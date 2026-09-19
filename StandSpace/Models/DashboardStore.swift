import Foundation
import SwiftUI

private struct DashboardStoreEnvelope: Codable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int = currentSchemaVersion
    var spaces: [StandSpaceProfile]
}

@MainActor
final class DashboardStore: ObservableObject {
    @Published var items: [DashboardItem] {
        didSet {
            guard !isApplyingSpace else { return }
            syncActiveSpace()
            saveSpaces()
        }
    }

    @Published var keepScreenAwake: Bool {
        didSet {
            UserDefaults.standard.set(
                keepScreenAwake,
                forKey: Keys.keepAwake
            )
        }
    }

    @Published var backgroundStyle: BoardBackgroundStyle {
        didSet {
            guard !isApplyingSpace else { return }
            syncActiveSpace()
            saveSpaces()
        }
    }

    @Published private(set) var spaces: [StandSpaceProfile]
    @Published private(set) var selectedSpaceID: UUID

    @Published var autoDimEnabled: Bool {
        didSet {
            UserDefaults.standard.set(
                autoDimEnabled,
                forKey: Keys.autoDim
            )
        }
    }

    @Published var oledProtectionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(
                oledProtectionEnabled,
                forKey: Keys.oledProtection
            )
        }
    }

    @Published private(set) var persistenceWarning: String? = nil

    private var isApplyingSpace = false
    private var blocksSpacePersistence = false

    private enum Keys {
        static let legacyItems = "dashboard.items.v1"
        static let legacyBackground = "dashboard.background"
        static let keepAwake = "dashboard.keepAwake"
        static let legacySpaces = "dashboard.spaces.v1"
        static let spaces = "dashboard.spaces.v2"
        static let selectedSpace = "dashboard.selectedSpace.v1"
        static let autoDim = "dashboard.autoDim"
        static let oledProtection = "dashboard.oledProtection"
    }

    init() {
        let defaults = UserDefaults.standard

        let legacyItems: [DashboardItem]
        if let data = defaults.data(forKey: Keys.legacyItems),
           let decoded = try? JSONDecoder().decode(
               [DashboardItem].self,
               from: data
           ),
           !decoded.isEmpty {
            legacyItems = decoded.map(Self.repairIfNeeded)
        } else {
            legacyItems = Self.deskItems
        }

        let legacyBackground = defaults
            .string(forKey: Keys.legacyBackground)
            .flatMap(BoardBackgroundStyle.init(rawValue:))
            ?? .midnight

        let loadedSpaces: [StandSpaceProfile]
        var detectedNewerSchema = false

        if let data = defaults.data(
            forKey: Keys.spaces
        ) {
            let rawSchemaVersion: Int? = {
                guard
                    let object = try? JSONSerialization
                        .jsonObject(with: data)
                        as? [String: Any]
                else {
                    return nil
                }
                return object["schemaVersion"]
                    as? Int
            }()

            if let rawSchemaVersion,
               rawSchemaVersion
                > DashboardStoreEnvelope
                    .currentSchemaVersion {
                // Detect this before Codable. A future schema might no longer
                // decode with this older model, but its data still must not be
                // overwritten.
                detectedNewerSchema = true
                loadedSpaces = Self.makeDefaultSpaces(
                    deskItems: legacyItems,
                    deskBackground: legacyBackground
                )
            } else if
                let envelope = try? JSONDecoder()
                    .decode(
                        DashboardStoreEnvelope.self,
                        from: data
                    ),
                envelope.schemaVersion
                    <= DashboardStoreEnvelope
                        .currentSchemaVersion,
                !envelope.spaces.isEmpty
            {
                loadedSpaces = envelope.spaces.map(
                    Self.repairProfile
                )
            } else {
                loadedSpaces = Self.makeDefaultSpaces(
                    deskItems: legacyItems,
                    deskBackground: legacyBackground
                )
            }
        } else if let data = defaults.data(forKey: Keys.legacySpaces),
                  let decoded = try? JSONDecoder().decode(
                      [StandSpaceProfile].self,
                      from: data
                  ),
                  !decoded.isEmpty {
            loadedSpaces = decoded.map(Self.repairProfile)
        } else {
            loadedSpaces = Self.makeDefaultSpaces(
                deskItems: legacyItems,
                deskBackground: legacyBackground
            )
        }

        self.spaces = loadedSpaces

        let savedID = defaults
            .string(forKey: Keys.selectedSpace)
            .flatMap(UUID.init(uuidString:))

        let resolvedID = loadedSpaces
            .first(where: { $0.id == savedID })?
            .id
            ?? loadedSpaces[0].id

        self.selectedSpaceID = resolvedID

        let active = loadedSpaces.first(
            where: { $0.id == resolvedID }
        ) ?? loadedSpaces[0]

        self.items = active.items.map(Self.repairIfNeeded)
        self.backgroundStyle = active.backgroundStyle

        self.keepScreenAwake =
            defaults.object(forKey: Keys.keepAwake) == nil
            ? true
            : defaults.bool(forKey: Keys.keepAwake)

        self.autoDimEnabled =
            defaults.object(forKey: Keys.autoDim) == nil
            ? true
            : defaults.bool(forKey: Keys.autoDim)

        self.oledProtectionEnabled =
            defaults.object(forKey: Keys.oledProtection) == nil
            ? true
            : defaults.bool(forKey: Keys.oledProtection)

        self.blocksSpacePersistence =
            detectedNewerSchema
        self.persistenceWarning =
            detectedNewerSchema
            ? "Se detectó una configuración creada por una versión más nueva. Esta versión no la sobrescribirá; actualiza StandSpace o restablece los Spaces explícitamente."
            : nil
    }

    var activeSpace: StandSpaceProfile {
        return spaces.first(
            where: { $0.id == selectedSpaceID }
        ) ?? spaces[0]
    }

    func selectSpace(_ id: UUID) {
        guard id != selectedSpaceID,
              let next = spaces.first(
                  where: { $0.id == id }
              ) else {
            return
        }

        syncActiveSpace()

        isApplyingSpace = true
        selectedSpaceID = id
        items = next.items.map(Self.repairIfNeeded)
        backgroundStyle = next.backgroundStyle
        isApplyingSpace = false

        if !blocksSpacePersistence {
            UserDefaults.standard.set(
                id.uuidString,
                forKey: Keys.selectedSpace
            )
        }

        saveSpaces()
    }

    func selectSpace(_ kind: StandSpaceKind) {
        guard let space = spaces.first(
            where: { $0.kind == kind }
        ) else {
            return
        }

        selectSpace(space.id)
    }

    func add(
        _ kind: ModuleKind,
        size: ModuleSize? = nil,
        style: ModuleStyle = .glass
    ) {
        let chosenSize = size.flatMap {
            kind.supportedSizes.contains($0) ? $0 : nil
        } ?? kind.defaultSize

        var item = DashboardItem(
            kind: kind,
            size: chosenSize,
            style: style
        )

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
        guard let index = items.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        withAnimation(.snappy) {
            items.remove(at: index)
        }
    }

    func duplicate(id: UUID) {
        guard let index = items.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        var copy = items[index]
        copy.id = UUID()
        copy.position = nil
        copy.landscapePosition = nil

        withAnimation(.snappy) {
            items.insert(
                copy,
                at: min(index + 1, items.count)
            )
        }
    }

    func move(
        from source: IndexSet,
        to destination: Int
    ) {
        items.move(
            fromOffsets: source,
            toOffset: destination
        )
    }

    func setPosition(
        id: UUID,
        position: GridPosition?,
        orientation: CanvasOrientation = .portrait
    ) {
        guard let index = items.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

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
        guard let index = items.firstIndex(
            where: { $0.id == id }
        ),
        items[index].kind.supportedSizes.contains(size) else {
            return
        }

        let current = items[index].size(
            for: orientation
        )
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

    func applyLandscapePreset(
        _ preset: LandscapePreset,
        columns: Int
    ) {
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
                    let column = index == 0
                        ? 0
                        : slotWidth

                    items[index].landscapePosition =
                        GridPosition(
                            column: column,
                            row: 0
                        )

                    items[index].landscapeSize =
                        Self.bestSize(
                            for: items[index].kind,
                            maxColumns: slotWidth,
                            maxRows: 2
                        )
                }

            case .quad:
                let slotWidth = max(2, columns / 2)
                let positions = [
                    GridPosition(column: 0, row: 0),
                    GridPosition(
                        column: slotWidth,
                        row: 0
                    ),
                    GridPosition(column: 0, row: 2),
                    GridPosition(
                        column: slotWidth,
                        row: 2
                    )
                ]

                for index in items.indices.prefix(4) {
                    items[index].landscapePosition =
                        positions[index]

                    items[index].landscapeSize =
                        Self.bestSize(
                            for: items[index].kind,
                            maxColumns: slotWidth,
                            maxRows: 2
                        )
                }

            case .focus:
                let focusIndex = items.firstIndex(
                    where: { $0.kind == .clock }
                ) ?? items.startIndex

                items[focusIndex].landscapePosition =
                    GridPosition(column: 0, row: 0)

                items[focusIndex].landscapeSize =
                    Self.bestSize(
                        for: items[focusIndex].kind,
                        maxColumns: min(columns, 4),
                        maxRows: 2
                    )

                var row = 2

                for index in items.indices
                where index != focusIndex {
                    items[index].landscapePosition =
                        GridPosition(
                            column: 0,
                            row: row
                        )

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

    func binding(
        for id: UUID
    ) -> Binding<DashboardItem>? {
        guard items.contains(
            where: { $0.id == id }
        ) else {
            return nil
        }

        return Binding(
            get: { [weak self] in
                self?.items.first(
                    where: { $0.id == id }
                ) ?? DashboardItem(kind: .text)
            },
            set: { [weak self] newValue in
                guard let self = self,
                      let index = self.items.firstIndex(
                          where: { $0.id == id }
                      ) else {
                    return
                }

                self.items[index] =
                    Self.repairIfNeeded(newValue)
            }
        )
    }

    func reset() {
        // Reset is an explicit destructive action, so it is the one operation
        // allowed to replace data from a newer unsupported schema.
        blocksSpacePersistence = false
        persistenceWarning = nil

        let fresh = Self.makeDefaultSpaces(
            deskItems: Self.deskItems,
            deskBackground: .midnight
        )

        isApplyingSpace = true
        spaces = fresh
        selectedSpaceID = fresh[0].id
        items = fresh[0].items
        backgroundStyle = fresh[0].backgroundStyle
        isApplyingSpace = false

        keepScreenAwake = true
        autoDimEnabled = true
        oledProtectionEnabled = true

        UserDefaults.standard.set(
            selectedSpaceID.uuidString,
            forKey: Keys.selectedSpace
        )

        saveSpaces()
    }

    private func syncActiveSpace() {
        guard let index = spaces.firstIndex(
            where: { $0.id == selectedSpaceID }
        ) else {
            return
        }

        spaces[index].items = items
        spaces[index].backgroundStyle =
            backgroundStyle
    }

    private func saveSpaces() {
        guard !blocksSpacePersistence else {
            return
        }

        let envelope = DashboardStoreEnvelope(
            spaces: spaces.map(Self.repairProfile)
        )

        guard let data = try? JSONEncoder().encode(
            envelope
        ) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: Keys.spaces
        )
    }

    private static func repairProfile(
        _ profile: StandSpaceProfile
    ) -> StandSpaceProfile {
        var repaired = profile
        repaired.items = profile.items.map(repairIfNeeded)
        return repaired
    }

    private static func repairIfNeeded(
        _ item: DashboardItem
    ) -> DashboardItem {
        var repaired = item

        if !item.kind.supportedSizes.contains(
            item.size
        ) {
            repaired.size = item.kind.defaultSize
        }

        if let landscapeSize =
            item.landscapeSize,
           !item.kind.supportedSizes.contains(
               landscapeSize
           ) {
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
            $0.span.columns <= maxColumns
                && $0.span.rows <= maxRows
        }

        return fitting.max { lhs, rhs in
            let leftArea =
                lhs.span.columns * lhs.span.rows
            let rightArea =
                rhs.span.columns * rhs.span.rows

            if leftArea == rightArea {
                return lhs.span.columns
                    < rhs.span.columns
            }

            return leftArea < rightArea
        } ?? kind.defaultSize
    }

    private static func makeDefaultSpaces(
        deskItems: [DashboardItem],
        deskBackground: BoardBackgroundStyle
    ) -> [StandSpaceProfile] {
        return [
            StandSpaceProfile(
                kind: .desk,
                items: deskItems,
                backgroundStyle: deskBackground
            ),
            StandSpaceProfile(
                kind: .night,
                items: nightItems,
                backgroundStyle: .standbyRed
            ),
            StandSpaceProfile(
                kind: .work,
                items: workItems,
                backgroundStyle: .midnight
            ),
            StandSpaceProfile(
                kind: .kitchen,
                items: kitchenItems,
                backgroundStyle: .warm
            )
        ]
    }

    static let deskItems: [DashboardItem] = [
        DashboardItem(
            kind: .clock,
            size: .large,
            style: .glass,
            position: GridPosition(
                column: 0,
                row: 0
            ),
            landscapePosition: GridPosition(
                column: 0,
                row: 0
            ),
            landscapeSize: .hero
        ),
        DashboardItem(
            kind: .battery,
            size: .small,
            style: .solid,
            position: GridPosition(
                column: 2,
                row: 0
            ),
            landscapePosition: GridPosition(
                column: 4,
                row: 0
            ),
            landscapeSize: .large
        ),
        DashboardItem(
            kind: .date,
            size: .wide,
            style: .minimal,
            position: GridPosition(
                column: 2,
                row: 1
            ),
            landscapePosition: GridPosition(
                column: 6,
                row: 0
            ),
            landscapeSize: .wide
        ),
        DashboardItem(
            kind: .dayProgress,
            size: .wide,
            style: .tinted,
            landscapePosition: GridPosition(
                column: 4,
                row: 2
            ),
            landscapeSize: .wide
        ),
        DashboardItem(
            kind: .timer,
            size: .wide,
            style: .glass,
            landscapePosition: GridPosition(
                column: 6,
                row: 2
            ),
            landscapeSize: .wide
        )
    ]

    static let nightItems: [DashboardItem] = [
        DashboardItem(
            kind: .clock,
            size: .hero,
            style: .minimal,
            position: GridPosition(
                column: 0,
                row: 0
            ),
            landscapePosition: GridPosition(
                column: 0,
                row: 0
            ),
            landscapeSize: .hero
        ),
        DashboardItem(
            kind: .date,
            size: .wide,
            style: .minimal,
            landscapePosition: GridPosition(
                column: 4,
                row: 0
            ),
            landscapeSize: .tripleWide
        ),
        DashboardItem(
            kind: .battery,
            size: .small,
            style: .minimal,
            landscapePosition: GridPosition(
                column: 4,
                row: 1
            ),
            landscapeSize: .wide
        )
    ]

    static let workItems: [DashboardItem] = [
        DashboardItem(
            kind: .calendar,
            size: .large,
            style: .glass,
            landscapePosition: GridPosition(
                column: 0,
                row: 0
            ),
            landscapeSize: .tripleWide
        ),
        DashboardItem(
            kind: .timer,
            size: .wide,
            style: .tinted,
            landscapePosition: GridPosition(
                column: 3,
                row: 0
            ),
            landscapeSize: .tripleWide
        ),
        DashboardItem(
            kind: .dayProgress,
            size: .wide,
            style: .minimal,
            landscapePosition: GridPosition(
                column: 6,
                row: 0
            ),
            landscapeSize: .wide
        ),
        DashboardItem(
            kind: .battery,
            size: .small,
            style: .solid,
            landscapePosition: GridPosition(
                column: 6,
                row: 1
            ),
            landscapeSize: .wide
        )
    ]

    static let kitchenItems: [DashboardItem] = [
        DashboardItem(
            kind: .timer,
            size: .large,
            style: .glass,
            landscapePosition: GridPosition(
                column: 0,
                row: 0
            ),
            landscapeSize: .hero
        ),
        DashboardItem(
            kind: .clock,
            size: .wide,
            style: .minimal,
            landscapePosition: GridPosition(
                column: 4,
                row: 0
            ),
            landscapeSize: .tripleWide
        ),
        DashboardItem(
            kind: .date,
            size: .wide,
            style: .minimal,
            landscapePosition: GridPosition(
                column: 4,
                row: 1
            ),
            landscapeSize: .tripleWide
        )
    ]
}
