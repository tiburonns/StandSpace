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
    let positions: [UUID: GridPosition]
    let height: CGFloat
    let unit: CGFloat
    let columns: Int
}

enum DashboardPackingEngine {
    static func pack(items: [DashboardItem], width: CGFloat, columns: Int, spacing: CGFloat) -> PackedDashboardLayout {
        let safeColumns = max(columns, 1)
        let unit = max((width - CGFloat(safeColumns - 1) * spacing) / CGFloat(safeColumns), 1)

        var occupied = Array(repeating: Array(repeating: false, count: safeColumns), count: 1)
        var frames: [UUID: CGRect] = [:]
        var positions: [UUID: GridPosition] = [:]
        var maxRow = 0

        for item in items {
            let requested = item.size.span
            let span = ModuleSpan(
                columns: min(max(requested.columns, 1), safeColumns),
                rows: max(requested.rows, 1)
            )

            var cell: GridPosition?

            if let preferred = item.position,
               canPlace(preferred, span: span, occupied: &occupied, columns: safeColumns) {
                cell = preferred
            }

            if cell == nil {
                cell = firstAvailableCell(span: span, occupied: &occupied, columns: safeColumns)
            }

            guard let resolved = cell else { continue }
            markOccupied(resolved, span: span, occupied: &occupied)

            let frame = frameFor(position: resolved, span: span, unit: unit, spacing: spacing)
            frames[item.id] = frame
            positions[item.id] = resolved
            maxRow = max(maxRow, resolved.row + span.rows)
        }

        let height = maxRow == 0 ? 0 : CGFloat(maxRow) * unit + CGFloat(maxRow - 1) * spacing
        return PackedDashboardLayout(frames: frames, positions: positions, height: height, unit: unit, columns: safeColumns)
    }

    static func snappedPosition(
        for point: CGPoint,
        itemSize: ModuleSize,
        unit: CGFloat,
        spacing: CGFloat,
        columns: Int
    ) -> GridPosition {
        let step = max(unit + spacing, 1)
        let span = itemSize.span

        let rawColumn = Int((point.x / step).rounded())
        let rawRow = Int((point.y / step).rounded())

        let maxColumn = max(0, columns - span.columns)
        return GridPosition(
            column: min(max(rawColumn, 0), maxColumn),
            row: max(rawRow, 0)
        )
    }

    private static func frameFor(position: GridPosition, span: ModuleSpan, unit: CGFloat, spacing: CGFloat) -> CGRect {
        let x = CGFloat(position.column) * (unit + spacing)
        let y = CGFloat(position.row) * (unit + spacing)
        let width = CGFloat(span.columns) * unit + CGFloat(span.columns - 1) * spacing
        let height = CGFloat(span.rows) * unit + CGFloat(span.rows - 1) * spacing
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func canPlace(
        _ position: GridPosition,
        span: ModuleSpan,
        occupied: inout [[Bool]],
        columns: Int
    ) -> Bool {
        guard position.column >= 0,
              position.row >= 0,
              position.column + span.columns <= columns else { return false }

        ensureRows(position.row + span.rows, occupied: &occupied, columns: columns)

        for row in position.row..<(position.row + span.rows) {
            for column in position.column..<(position.column + span.columns) {
                if occupied[row][column] { return false }
            }
        }
        return true
    }

    private static func firstAvailableCell(
        span: ModuleSpan,
        occupied: inout [[Bool]],
        columns: Int
    ) -> GridPosition {
        var row = 0

        while true {
            ensureRows(row + span.rows, occupied: &occupied, columns: columns)

            if span.columns <= columns {
                for column in 0...(columns - span.columns) {
                    let candidate = GridPosition(column: column, row: row)
                    if canPlace(candidate, span: span, occupied: &occupied, columns: columns) {
                        return candidate
                    }
                }
            }

            row += 1
        }
    }

    private static func ensureRows(_ count: Int, occupied: inout [[Bool]], columns: Int) {
        while occupied.count < count {
            occupied.append(Array(repeating: false, count: columns))
        }
    }

    private static func markOccupied(_ position: GridPosition, span: ModuleSpan, occupied: inout [[Bool]]) {
        for row in position.row..<(position.row + span.rows) {
            for column in position.column..<(position.column + span.columns) {
                occupied[row][column] = true
            }
        }
    }
}

// Retained for isolated previews and future module surfaces.
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

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let width = proposal.width ?? 800
        let result = calculateFrames(width: width, subviews: subviews)
        cache.frames = result.frames
        cache.size = result.size
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
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
        var frames: [CGRect] = []
        var y: CGFloat = 0

        for subview in subviews {
            let span = subview[ModuleSpanLayoutKey.self]
            let width = CGFloat(min(span.columns, safeColumns)) * unit + CGFloat(max(0, min(span.columns, safeColumns) - 1)) * spacing
            let height = CGFloat(max(span.rows, 1)) * unit + CGFloat(max(span.rows - 1, 0)) * spacing
            frames.append(CGRect(x: 0, y: y, width: width, height: height))
            y += height + spacing
        }

        return (frames, CGSize(width: width, height: max(0, y - spacing)))
    }
}
