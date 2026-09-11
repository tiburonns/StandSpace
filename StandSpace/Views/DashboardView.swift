import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: DashboardStore

    @State private var isEditing = false
    @State private var controlsVisible = true
    @State private var selectedID: UUID?
    @State private var draggingID: UUID?
    @State private var dragOffset: CGSize = .zero
    @State private var showingGallery = false
    @State private var showingSettings = false
    @State private var inspectorID: UUID?
    @State private var feedbackTick = 0

    private let spacing: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = geometry.size.width > 900 ? 28 : 18
            let canvasWidth = max(geometry.size.width - horizontalPadding * 2, 1)
            let columns = columnCount(for: geometry.size.width)
            let layout = DashboardPackingEngine.pack(
                items: store.items,
                width: canvasWidth,
                columns: columns,
                spacing: spacing
            )

            ZStack(alignment: .topLeading) {
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        if isEditing {
                            gridBackdrop(
                                width: canvasWidth,
                                height: max(layout.height, geometry.size.height - 120),
                                unit: layout.unit,
                                columns: columns
                            )
                            .transition(.opacity)
                        }

                        ForEach(store.items) { item in
                            if let frame = layout.frames[item.id] {
                                module(item, frame: frame, layout: layout, columns: columns)
                            }
                        }
                    }
                    .frame(width: canvasWidth, height: max(layout.height, geometry.size.height - 72), alignment: .topLeading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isEditing || controlsVisible ? 70 : 18)
                    .padding(.bottom, 28)
                }
                .scrollDisabled(draggingID != nil)

                if controlsVisible || isEditing {
                    topToolbar
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isEditing else {
                    selectedID = nil
                    return
                }
                withAnimation(.easeInOut(duration: 0.18)) {
                    controlsVisible.toggle()
                }
            }
        }
        .sensoryFeedback(.selection, trigger: feedbackTick)
        .sheet(isPresented: $showingGallery) {
            ModuleGalleryView { kind, size, style in
                store.add(kind, size: size, style: style)
                feedbackTick += 1
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showingSettings) {
            EditorView()
                .environmentObject(store)
        }
        .sheet(item: inspectorBinding) { itemID in
            if let binding = store.binding(for: itemID.id) {
                NavigationStack {
                    ModuleEditorView(item: binding)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Listo") { inspectorID = nil }
                            }
                        }
                }
            }
        }
    }

    private func module(
        _ item: DashboardItem,
        frame: CGRect,
        layout: PackedDashboardLayout,
        columns: Int
    ) -> some View {
        let isSelected = selectedID == item.id
        let isDragging = draggingID == item.id

        return ModuleCardView(item: item)
            .frame(width: frame.width, height: frame.height)
            .overlay {
                if isEditing {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            isSelected ? Color.white : Color.white.opacity(0.22),
                            style: StrokeStyle(lineWidth: isSelected ? 2 : 1, dash: isSelected ? [] : [5, 5])
                        )
                }
            }
            .overlay(alignment: .topLeading) {
                if isEditing && isSelected {
                    editButton(systemName: "minus", role: .destructive) {
                        store.delete(id: item.id)
                        selectedID = nil
                        feedbackTick += 1
                    }
                    .offset(x: -8, y: -8)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isEditing && isSelected {
                    editButton(systemName: "plus.square.on.square") {
                        store.duplicate(id: item.id)
                        feedbackTick += 1
                    }
                    .offset(x: 8, y: -8)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if isEditing && isSelected {
                    editButton(systemName: "slider.horizontal.3") {
                        inspectorID = item.id
                    }
                    .offset(x: -8, y: 8)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isEditing && isSelected {
                    ResizeHandle(
                        item: item,
                        unit: layout.unit,
                        spacing: spacing,
                        maxColumns: columns
                    ) { size in
                        store.resize(id: item.id, to: size)
                        feedbackTick += 1
                    }
                    .offset(x: 9, y: 9)
                }
            }
            .scaleEffect(isDragging ? 1.025 : 1)
            .shadow(color: .black.opacity(isDragging ? 0.38 : 0), radius: isDragging ? 22 : 0, y: 10)
            .offset(
                x: frame.minX + (isDragging ? dragOffset.width : 0),
                y: frame.minY + (isDragging ? dragOffset.height : 0)
            )
            .zIndex(isDragging || isSelected ? 10 : 0)
            .onTapGesture {
                guard isEditing else { return }
                if selectedID == item.id {
                    inspectorID = item.id
                } else {
                    selectedID = item.id
                    feedbackTick += 1
                }
            }
            .onLongPressGesture(minimumDuration: 0.32) {
                guard !isEditing else { return }
                withAnimation(.snappy) {
                    isEditing = true
                    controlsVisible = true
                    selectedID = item.id
                }
                feedbackTick += 1
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: isEditing ? 4 : 10)
                    .onChanged { value in
                        guard isEditing else { return }
                        selectedID = item.id
                        draggingID = item.id
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        guard isEditing else { return }

                        let center = CGPoint(
                            x: frame.midX + value.translation.width,
                            y: frame.midY + value.translation.height
                        )

                        if let destination = DashboardPackingEngine.nearestIndex(
                            to: center,
                            movingID: item.id,
                            layout: layout
                        ) {
                            store.move(id: item.id, to: destination)
                        }

                        withAnimation(.snappy) {
                            draggingID = nil
                            dragOffset = .zero
                        }
                        feedbackTick += 1
                    }
            )
            .animation(.snappy, value: frame)
    }

    private var topToolbar: some View {
        HStack(spacing: 10) {
            if isEditing {
                Button {
                    showingGallery = true
                } label: {
                    Label("Agregar", systemImage: "plus")
                }
                .buttonStyle(StandSpaceToolbarButtonStyle())

                Menu {
                    Picker("Fondo", selection: $store.backgroundStyle) {
                        ForEach(BoardBackgroundStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                } label: {
                    Label("Tema", systemImage: "paintpalette")
                }
                .buttonStyle(StandSpaceToolbarButtonStyle())

                Spacer()

                Text("Editar StandSpace")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Button {
                    withAnimation(.snappy) {
                        isEditing = false
                        selectedID = nil
                    }
                    feedbackTick += 1
                } label: {
                    Text("Listo")
                        .fontWeight(.semibold)
                }
                .buttonStyle(StandSpaceToolbarButtonStyle(prominent: true))
            } else {
                Spacer()

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(StandSpaceToolbarButtonStyle())

                Button {
                    withAnimation(.snappy) {
                        isEditing = true
                        controlsVisible = true
                    }
                    feedbackTick += 1
                } label: {
                    Label("Editar", systemImage: "square.grid.2x2")
                }
                .buttonStyle(StandSpaceToolbarButtonStyle(prominent: true))
            }
        }
        .font(.subheadline.weight(.semibold))
    }

    private func gridBackdrop(width: CGFloat, height: CGFloat, unit: CGFloat, columns: Int) -> some View {
        Canvas { context, size in
            let step = unit + spacing
            var path = Path()

            for column in 0...columns {
                let x = min(CGFloat(column) * step, size.width)
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }

            let rows = Int(ceil(size.height / max(step, 1)))
            for row in 0...rows {
                let y = CGFloat(row) * step
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }

            context.stroke(path, with: .color(.white.opacity(0.055)), lineWidth: 1)
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }

    private func editButton(
        systemName: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            Image(systemName: systemName)
                .font(.caption.bold())
                .frame(width: 30, height: 30)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.22), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func columnCount(for width: CGFloat) -> Int {
        switch width {
        case 1100...: 8
        case 760...: 6
        default: 4
        }
    }

    private var inspectorBinding: Binding<IdentifiableUUID?> {
        Binding(
            get: { inspectorID.map(IdentifiableUUID.init) },
            set: { inspectorID = $0?.id }
        )
    }
}

private struct IdentifiableUUID: Identifiable {
    let id: UUID
}

private struct StandSpaceToolbarButtonStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(
                prominent ? AnyShapeStyle(Color.white.opacity(0.18)) : AnyShapeStyle(.ultraThinMaterial),
                in: Capsule()
            )
            .overlay(Capsule().stroke(.white.opacity(prominent ? 0.20 : 0.10), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private struct ResizeHandle: View {
    let item: DashboardItem
    let unit: CGFloat
    let spacing: CGFloat
    let maxColumns: Int
    let onResize: (ModuleSize) -> Void

    @State private var translation: CGSize = .zero

    var body: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.caption.bold())
            .frame(width: 32, height: 32)
            .background(.regularMaterial, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
            .scaleEffect(translation == .zero ? 1 : 1.08)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        translation = value.translation
                    }
                    .onEnded { value in
                        let step = max(unit + spacing, 1)
                        let current = item.size.span
                        let columns = min(
                            maxColumns,
                            max(1, current.columns + Int((value.translation.width / step).rounded()))
                        )
                        let rows = max(1, current.rows + Int((value.translation.height / step).rounded()))
                        let size = ModuleSize.closestSupported(
                            columns: columns,
                            rows: rows,
                            supported: item.kind.supportedSizes
                        )
                        onResize(size)
                        withAnimation(.snappy) { translation = .zero }
                    }
            )
    }
}
