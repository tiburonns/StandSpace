import Foundation
import SwiftUI

enum StandSpaceTestFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

@main
struct StandSpaceLayoutIntegration {
    static func main() throws {
        try testPackingAvoidsOverlap()
        try testPreferredCollisionFallsBack()
        try testLandscapeOverrides()
        try testSnappingClampsToGrid()
        try testOversizedModuleClampsToColumnCount()
        try testLanguageResolutionAndModelTitles()
        print("PASS: StandSpace packing, orientation, snapping, grid bounds, and localization")
    }

    private static func require(
        _ condition: @autoclosure () -> Bool,
        _ message: String
    ) throws {
        guard condition() else {
            throw StandSpaceTestFailure.failed(message)
        }
    }

    private static func testPackingAvoidsOverlap() throws {
        let first = DashboardItem(kind: .clock, size: .large)
        let second = DashboardItem(kind: .calendar, size: .wide)

        let layout = DashboardPackingEngine.pack(
            items: [first, second],
            width: 400,
            columns: 4,
            spacing: 12
        )

        guard let firstFrame = layout.frames[first.id],
              let secondFrame = layout.frames[second.id] else {
            throw StandSpaceTestFailure.failed("Packing dropped a module")
        }

        try require(!firstFrame.intersects(secondFrame), "Packed modules overlap")
        try require(layout.frames.count == 2, "Packed frame count is incorrect")
        try require(layout.height > 0, "Packed layout height is invalid")
    }

    private static func testPreferredCollisionFallsBack() throws {
        let preferred = GridPosition(column: 0, row: 0)
        let first = DashboardItem(
            kind: .clock,
            size: .large,
            position: preferred
        )
        let second = DashboardItem(
            kind: .battery,
            size: .small,
            position: preferred
        )

        let layout = DashboardPackingEngine.pack(
            items: [first, second],
            width: 400,
            columns: 4,
            spacing: 12
        )

        try require(layout.positions[first.id] == preferred, "First preferred position was not respected")
        try require(layout.positions[second.id] != preferred, "Collision did not fall back to a free cell")

        if let firstFrame = layout.frames[first.id],
           let secondFrame = layout.frames[second.id] {
            try require(!firstFrame.intersects(secondFrame), "Fallback placement still overlaps")
        } else {
            throw StandSpaceTestFailure.failed("Collision fallback dropped a module")
        }
    }

    private static func testLandscapeOverrides() throws {
        let item = DashboardItem(
            kind: .text,
            size: .small,
            position: GridPosition(column: 0, row: 0),
            landscapePosition: GridPosition(column: 2, row: 1),
            landscapeSize: .tripleWide
        )

        let layout = DashboardPackingEngine.pack(
            items: [item],
            width: 600,
            columns: 6,
            spacing: 12,
            orientation: .landscape
        )

        try require(
            layout.positions[item.id] == GridPosition(column: 2, row: 1),
            "Landscape position override was ignored"
        )

        guard let frame = layout.frames[item.id] else {
            throw StandSpaceTestFailure.failed("Landscape item was not packed")
        }

        let expectedWidth = layout.unit * 3 + 24
        try require(abs(frame.width - expectedWidth) < 0.001, "Landscape size override was ignored")
    }

    private static func testSnappingClampsToGrid() throws {
        let negative = DashboardPackingEngine.snappedPosition(
            for: CGPoint(x: -500, y: -500),
            itemSize: .wide,
            unit: 80,
            spacing: 12,
            columns: 4
        )
        try require(negative == GridPosition(column: 0, row: 0), "Negative snapping escaped the grid")

        let farRight = DashboardPackingEngine.snappedPosition(
            for: CGPoint(x: 10_000, y: 100),
            itemSize: .wide,
            unit: 80,
            spacing: 12,
            columns: 4
        )
        try require(farRight.column == 2, "Snapping did not clamp the module to the right edge")
        try require(farRight.row >= 0, "Snapping produced a negative row")
    }

    private static func testLanguageResolutionAndModelTitles() throws {
        try require(
            StandSpaceAppLanguage.system.resolvedCode(
                preferredLanguages: ["es-MX", "en-US"]
            ) == "es",
            "System language did not resolve Spanish regional locales"
        )
        try require(
            StandSpaceAppLanguage.system.resolvedCode(
                preferredLanguages: ["fr-FR", "en-US"]
            ) == "en",
            "Unsupported system language did not fall back to English"
        )
        try require(
            ModuleKind.calendar.title(language: .english) == "Next Event",
            "English module title regressed"
        )
        try require(
            ModuleKind.calendar.title(language: .spanish) == "Próximo evento",
            "Spanish module title regressed"
        )
        try require(
            StandSpaceKind.desk.title(language: .english) == "Desk",
            "English Space title regressed"
        )
        try require(
            StandSpaceKind.desk.title(language: .spanish) == "Escritorio",
            "Spanish Space title regressed"
        )
        try require(
            ModuleStyle.glass.title(language: .english) == "Glass"
                && ModuleStyle.glass.title(language: .spanish) == "Cristal",
            "Module style localization regressed"
        )
        try require(
            BoardBackgroundStyle.standbyRed.title(language: .english) == "Night Red"
                && BoardBackgroundStyle.standbyRed.title(language: .spanish) == "Rojo nocturno",
            "Background localization regressed"
        )
    }

    private static func testOversizedModuleClampsToColumnCount() throws {
        let item = DashboardItem(kind: .text, size: .hero)
        let layout = DashboardPackingEngine.pack(
            items: [item],
            width: 300,
            columns: 3,
            spacing: 10
        )

        guard let frame = layout.frames[item.id] else {
            throw StandSpaceTestFailure.failed("Oversized item was dropped")
        }

        try require(abs(frame.width - 300) < 0.001, "Oversized item did not clamp to available columns")
    }
}
