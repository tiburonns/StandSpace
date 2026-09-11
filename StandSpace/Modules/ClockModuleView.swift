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

                if size != .small {
                    Text(context.date, format: .dateTime.second())
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private var fontSize: CGFloat {
        switch size {
        case .small: 42
        case .wide: 66
        case .tall: 56
        case .large: 92
        }
    }
}
