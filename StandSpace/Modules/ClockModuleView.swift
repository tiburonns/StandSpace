import SwiftUI

struct ClockModuleView: View {
    let size: ModuleSize

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 4) {
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)

                if showsSeconds {
                    Text(context.date, format: .dateTime.second())
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private var showsSeconds: Bool {
        size.span.columns > 1 || size.span.rows > 1
    }

    private var fontSize: CGFloat {
        let span = size.span

        switch (span.columns, span.rows) {
        case (1, 1):
            42
        case (1, 2):
            56
        case (2, 1):
            66
        case (2, 2):
            92
        case (3, 1):
            82
        case (4, 1):
            96
        case (3, 2):
            108
        case (4, 2):
            122
        default:
            66
        }
    }
}
