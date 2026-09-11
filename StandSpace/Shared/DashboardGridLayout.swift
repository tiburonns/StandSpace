import SwiftUI

private struct ModuleSpanLayoutKey: LayoutValueKey {
    static let defaultValue = ModuleSpan(columns: 1, rows: 1)
}

extension View {
    func moduleSpan(_ span: ModuleSpan) -> some View {
        layoutValue(key: ModuleSpanLayoutKey.self, value: span)
    }
}

struct PackedDashboardLayout {
    let frames: [UUID: CGRect]
    let orderedFrames: [(id: UUID, frame: CGRect)]
    let height: CGFloat
    let unit: CGFloat
}

enum DashboardPackingEngine {
    static func pack(
        items: [DashboardItem],
        width: CGFloat,
        columns: Int,
        spacing: CGFloat
    ) -> PackedDashboardLayout {
        let safeColumns = max(columns, 1)
        let unit = max((width - CGFloat(safeColumns - 1) * spacing) / CGFloat(safeColumns), 1)
        var occupied = Array(repeating: Array(repeating: false, count: safeColumns), count: 1)
        var frames: [UUID: CGRect] = [:]
        var orderedFrames: [(id: UUID, frame: CGRect)] = []
        var maxRow = 0

        for item in items {
            let requested = item.size.span
            let span = ModuleSpan(
                columns: min(max(requested.columns, 1), safeColumns),
                rows: max(requested.rows, 1)
            )

            let cell = firstAvailableCell(span: span, occupied: &occupied, columns: safeColumns)
            markOccupied(cell: cell, span: span, occupied: &occupied)

            let x = CGFloat(cell.column) * (unit + spacing)
            let y = CGFloat(cell.row) * (unit + spacing)
            let itemWidth = CGFloat(span.columns) * unit + CGFloat(span.columns - 1) * spacing
            let itemHeight = CGFloat(span.rows) * unit + CGFloat(span.rows - 1) * spacing
            let frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)

            frames[item.id] = frame
            orderedFrames.append((item.id, frame))
            maxRow = max(maxRow, cell.row + span.rows)
        }

        let height = maxRow == 0 ? 0 : CGFloat(maxRow) * unit + CGFloat(maxRow - 1) * spacing
        return PackedDashboardLayout(frames: frames, orderedFrames: orderedFrames, height: height, unit: unit)
    }

    static func nearestIndex(
        to point: CGPoint,
        movingID: UUID,
        layout: PackedDashboardLayout
    ) -> Int? {
        let candidates = layout.orderedFrames.enumerated().filter { $0.element.id != movingID }
        guard !candidates.isEmpty else { return 0 }

        return candidates.min { lhs, rhs in
            distance(point, lhs.element.frame.center) < distance(point, rhs.element.frame.center)
        }?.offset
    }

    private static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    private static func firstAvailableCell(
        span: ModuleSpan,
        occupied: inout [[Bool]],
        columns: Int
    ) -> (row: Int, column: Int) {
        var row = 0

        while true {
            ensureRows(row + span.rows, occupied: &occupied, columns: columns)

            for column in 0...(columns - span.columns) {
                var fits = true
                for r in row..<(row + span.rows) {
                    for c in column..<(column + span.columns) where occupied[r][c] {
                        fits = false
                    }
                }
                if fits { return (row, column) }
            }
            row += 1
        }
    }

    private static func ensureRows(_ count: Int, occupied: inout [[Bool]], columns: Int) {
        while occupied.count < count {
            occupied.append(Array(repeating: false, count: columns))
        }
    }

    private static func markOccupied(
        cell: (row: Int, column: Int),
        span: ModuleSpan,
        occupied: inout [[Bool]]
    ) {
        for row in cell.row..<(cell.row + span.rows) {
            for column in cell.column..<(cell.column + span.columns) {
                occupied[row][column] = true
            }
        }
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}

// Kept as a reusable Layout container for previews and future module surfaces.
struct DashboardGridLayout: Layout {
    var columns: Int = 4
    var spacing: CGFloat = 12

    struct Cache {
        var frames: [CGRect] = []
        var size: CGSize = .zero
    }

    func makeCache(subviews: Subviews) -> Cache { Cache() }

    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache = Cache()
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let width = proposal.width ?? 800
        let result = calculateFrames(width: width, subviews: subviews)
        cache.frames = result.frames
        cache.size = result.size
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        if cache.frames.count != subviews.count {
            let result = calculateFrames(width: bounds.width, subviews: subviews)
            cache.frames = result.frames
            cache.size = result.size
        }

        for (index, subview) in subviews.enumerated() where index < cache.frames.count {
            let frame = cache.frames[index]
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private func calculateFrames(width: CGFloat, subviews: Subviews) -> (frames: [CGRect], size: CGSize) {
        let safeColumns = max(columns, 1)
        let unit = max((width - CGFloat(safeColumns - 1) * spacing) / CGFloat(safeColumns), 1)
        var occupied = Array(repeating: Array(repeating: false, count: safeColumns), count: 1)
        var frames: [CGRect] = []
        var maxRow = 0

        for subview in subviews {
            let requested = subview[ModuleSpanLayoutKey.self]
            let span = ModuleSpan(
                columns: min(max(requested.columns, 1), safeColumns),
                rows: max(requested.rows, 1)
            )

            let cell = firstAvailableCell(span: span, occupied: &occupied, columns: safeColumns)
            markOccupied(cell: cell, span: span, occupied: &occupied)

            let x = CGFloat(cell.column) * (unit + spacing)
            let y = CGFloat(cell.row) * (unit + spacing)
            let itemWidth = CGFloat(span.columns) * unit + CGFloat(span.columns - 1) * spacing
            let itemHeight = CGFloat(span.rows) * unit + CGFloat(span.rows - 1) * spacing

            frames.append(CGRect(x: x, y: y, width: itemWidth, height: itemHeight))
            maxRow = max(maxRow, cell.row + span.rows)
        }

        let height = maxRow == 0 ? 0 : CGFloat(maxRow) * unit + CGFloat(maxRow - 1) * spacing
        return (frames, CGSize(width: width, height: height))
    }

    private func firstAvailableCell(
        span: ModuleSpan,
        occupied: inout [[Bool]],
        columns: Int
    ) -> (row: Int, column: Int) {
        var row = 0
        while true {
            ensureRows(row + span.rows, occupied: &occupied, columns: columns)
            for column in 0...(columns - span.columns) {
                var fits = true
                for r in row..<(row + span.rows) {
                    for c in column..<(column + span.columns) where occupied[r][c] {
                        fits = false
                    }
                }
                if fits { return (row, column) }
            }
            row += 1
        }
    }

    private func ensureRows(_ count: Int, occupied: inout [[Bool]], columns: Int) {
        while occupied.count < count {
            occupied.append(Array(repeating: false, count: columns))
        }
    }

    private func markOccupied(
        cell: (row: Int, column: Int),
        span: ModuleSpan,
        occupied: inout [[Bool]]
    ) {
        for row in cell.row..<(cell.row + span.rows) {
            for column in cell.column..<(cell.column + span.columns) {
                occupied[row][column] = true
            }
        }
    }
}
