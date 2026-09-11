import SwiftUI

struct DashboardView: View {
    let items: [DashboardItem]

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                DashboardGridLayout(columns: geometry.size.width > 700 ? 6 : 4, spacing: 12) {
                    ForEach(items) { item in
                        ModuleCardView(item: item)
                            .moduleSpan(item.size.span)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
