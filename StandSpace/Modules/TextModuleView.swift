import SwiftUI

struct TextModuleView: View {
    let item: DashboardItem

    private var language: StandSpaceAppLanguage { .current }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !item.title.isEmpty {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text(
                item.text.isEmpty
                    ? StandSpaceLocalizedCopy.textModulePlaceholder(
                        language: language
                    )
                    : item.text
            )
                .font(item.size == .small ? .title3.weight(.semibold) : .title.weight(.semibold))
                .minimumScaleFactor(0.65)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
