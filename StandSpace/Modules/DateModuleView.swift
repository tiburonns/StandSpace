import SwiftUI

struct DateModuleView: View {
    let size: ModuleSize

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(alignment: .leading, spacing: 5) {
                Text(context.date, format: .dateTime.weekday(.wide))
                    .font(size == .small ? .headline : .title2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(context.date, format: .dateTime.day().month(.wide))
                    .font(size == .small ? .title2.bold() : .largeTitle.bold())
                    .minimumScaleFactor(0.55)
                    .lineLimit(2)

                if size == .large || size == .tall {
                    Text(context.date, format: .dateTime.year())
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}
