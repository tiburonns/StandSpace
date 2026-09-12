import SwiftUI

struct ClockModuleView: View {
    let size: ModuleSize

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            VStack(alignment: .leading, spacing: 4) {
                Text(context.date, format: Date.FormatStyle.dateTime.hour().minute())
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)

                if showsSeconds {
                    Text(context.date, format: Date.FormatStyle.dateTime.second())
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .leading
            )
        }
    }

    private var showsSeconds: Bool {
        let span = size.span
        return span.columns > 1 || span.rows > 1
    }

    private var fontSize: CGFloat {
        let span = size.span

        switch (span.columns, span.rows) {
        case (1, 1):
            return 42
        case (1, 2):
            return 56
        case (2, 1):
            return 66
        case (2, 2):
            return 92
        case (3, 1):
            return 82
        case (4, 1):
            return 96
        case (3, 2):
            return 108
        case (4, 2):
            return 122
        default:
            return 66
        }
    }
}
