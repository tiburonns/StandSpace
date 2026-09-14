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
            let orientation = canvasOrientation(for: geometry.size)
            let isLandscape = orientation == .landscape
            let horizontalPadding = canvasHorizontalPadding(
                for: geometry.size,
                orientation: orientation
            )
            let canvasWidth = max(
                geometry.size.width - horizontalPadding * 2,
                1
            )
            let columns = columnCount(
                for: geometry.size,
                orientation: orientation
            )
            let topInset = canvasTopInset(
                orientation: orientation,
                showsControls: controlsVisible || isEditing
            )
            let layout = DashboardPackingEngine.pack(
                items: store.items,
                width: canvasWidth,
                columns: columns,
                spacing: spacing,
                orientation: orientation
            )

            ZStack(alignment: .topLeading) {
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        if isEditing {
                            gridBackdrop(
                                width: canvasWidth,
                                height: max(
                                    layout.height + layout.unit * 2,
                                    geometry.size.height - topInset - 20
                                ),
                                unit: layout.unit,
                                columns: columns
                            )
                            .transition(.opacity)
                        }

                        ForEach(store.items) { item in
                            if let frame = layout.frames[item.id] {
                                module(
                                    item,
                                    frame: frame,
                                    layout: layout,
                                    columns: columns,
                                    orientation: orientation
                                )
                            }
                        }
                    }
                    .frame(
                        width: canvasWidth,
                        height: max(
                            layout.height + layout.unit,
                            geometry.size.height - topInset
                        ),
                        alignment: .topLeading
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, topInset)
                    .padding(.bottom, isLandscape ? 12 : 28)
                }
                .scrollDisabled(draggingID != nil)

                if controlsVisible || isEditing {
                    topToolbar(
                        orientation: orientation,
                        columns: columns
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isLandscape ? 6 : 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isEditing {
                    selectedID = nil
                } else {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        controlsVisible.toggle()
                    }
                }
            }
            .onChange(of: isLandscape) { _, landscape in
                selectedID = nil
                draggingID = nil
                dragOffset = .zero

                if landscape && !isEditing {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        controlsVisible = false
                    }
                } else {
                    controlsVisible = true
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
                                Button("Listo") {
                                    inspectorID = nil
                                }
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
        columns: Int,
        orientation: CanvasOrientation
    ) -> some View {
        let renderedItem = item.rendered(for: orientation)
        let isSelected = selectedID == item.id
        let isDragging = draggingID == item.id

        return ModuleCardView(item: renderedItem)
            .frame(width: frame.width, height: frame.height)
            .overlay {
                if isEditing {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            isSelected ? Color.white : Color.white.opacity(0.18),
                            style: StrokeStyle(
                                lineWidth: isSelected ? 2 : 1,
                                dash: isSelected ? [] : [5, 5]
                            )
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
                    LiveResizeHandle(
                        item: renderedItem,
                        unit: layout.unit,
                        spacing: spacing,
                        maxColumns: columns
                    ) { size in
                        store.resize(
                            id: item.id,
                            to: size,
                            orientation: orientation
                        )
                        feedbackTick += 1
                    }
                    .offset(x: 10, y: 10)
                }
            }
            .scaleEffect(isDragging ? 1.035 : 1)
            .shadow(
                color: .black.opacity(isDragging ? 0.38 : 0),
                radius: isDragging ? 22 : 0,
                y: 10
            )
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
            .onLongPressGesture(minimumDuration: 0.30) {
                guard !isEditing else { return }

                withAnimation(.snappy) {
                    isEditing = true
                    controlsVisible = true
                    selectedID = item.id
                }
                feedbackTick += 1
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: isEditing ? 4 : 12)
                    .onChanged { value in
                        guard isEditing else { return }
                        selectedID = item.id
                        draggingID = item.id
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        guard isEditing else { return }

                        let proposedOrigin = CGPoint(
                            x: frame.minX + value.translation.width,
                            y: frame.minY + value.translation.height
                        )

                        let snapped = DashboardPackingEngine.snappedPosition(
                            for: proposedOrigin,
                            itemSize: renderedItem.size,
                            unit: layout.unit,
                            spacing: spacing,
                            columns: columns
                        )

                        store.setPosition(
                            id: item.id,
                            position: snapped,
                            orientation: orientation
                        )

                        withAnimation(.snappy) {
                            draggingID = nil
                            dragOffset = .zero
                        }

                        feedbackTick += 1
                    }
            )
            .animation(.snappy, value: frame)
    }

    @ViewBuilder
    private func topToolbar(
        orientation: CanvasOrientation,
        columns: Int
    ) -> some View {
        let isLandscape = orientation == .landscape

        HStack(spacing: isLandscape ? 7 : 10) {
            if isEditing {
                Button {
                    showingGallery = true
                } label: {
                    if isLandscape {
                        Image(systemName: "plus")
                    } else {
                        Label("Agregar", systemImage: "plus")
                    }
                }
                .buttonStyle(
                    StandSpaceToolbarButtonStyle(
                        compact: isLandscape
                    )
                )

                if isLandscape {
                    Menu {
                        ForEach(LandscapePreset.allCases) { preset in
                            Button {
                                store.applyLandscapePreset(
                                    preset,
                                    columns: columns
                                )
                                feedbackTick += 1
                            } label: {
                                Label(
                                    preset.title,
                                    systemImage: preset.icon
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "rectangle.3.group")
                    }
                    .buttonStyle(
                        StandSpaceToolbarButtonStyle(compact: true)
                    )
                    .accessibilityLabel("Diseño horizontal")
                }

                Menu {
                    Picker(
                        "Fondo",
                        selection: $store.backgroundStyle
                    ) {
                        ForEach(BoardBackgroundStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }

                    Divider()

                    Button {
                        store.backgroundStyle = .standbyRed
                    } label: {
                        Label(
                            "Modo noche",
                            systemImage: "moon.stars"
                        )
                    }

                    Button {
                        store.backgroundStyle = .oled
                    } label: {
                        Label(
                            "OLED negro",
                            systemImage: "circle.fill"
                        )
                    }
                } label: {
                    if isLandscape {
                        Image(systemName: "paintpalette")
                    } else {
                        Label("Tema", systemImage: "paintpalette")
                    }
                }
                .buttonStyle(
                    StandSpaceToolbarButtonStyle(
                        compact: isLandscape
                    )
                )

                Spacer()

                if !isLandscape {
                    Text("Editar StandSpace")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()
                }

                Button {
                    withAnimation(.snappy) {
                        isEditing = false
                        selectedID = nil
                        if isLandscape {
                            controlsVisible = false
                        }
                    }
                    feedbackTick += 1
                } label: {
                    if isLandscape {
                        Image(systemName: "checkmark")
                    } else {
                        Text("Listo")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(
                    StandSpaceToolbarButtonStyle(
                        prominent: true,
                        compact: isLandscape
                    )
                )
            } else {
                Spacer()

                if isLandscape {
                    Button {
                        store.backgroundStyle = store.backgroundStyle == .standbyRed
                            ? .oled
                            : .standbyRed
                    } label: {
                        Image(
                            systemName: store.backgroundStyle == .standbyRed
                                ? "circle.lefthalf.filled"
                                : "moon.stars"
                        )
                    }
                    .buttonStyle(
                        StandSpaceToolbarButtonStyle(compact: true)
                    )
                    .accessibilityLabel("Alternar modo noche")
                }

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(
                    StandSpaceToolbarButtonStyle(
                        compact: isLandscape
                    )
                )

                Button {
                    withAnimation(.snappy) {
                        isEditing = true
                        controlsVisible = true
                    }
                    feedbackTick += 1
                } label: {
                    if isLandscape {
                        Image(systemName: "square.grid.2x2")
                    } else {
                        Label("Editar", systemImage: "square.grid.2x2")
                    }
                }
                .buttonStyle(
                    StandSpaceToolbarButtonStyle(
                        prominent: true,
                        compact: isLandscape
                    )
                )
            }
        }
        .font(.subheadline.weight(.semibold))
    }

    private func gridBackdrop(
        width: CGFloat,
        height: CGFloat,
        unit: CGFloat,
        columns: Int
    ) -> some View {
        Canvas { context, size in
            let step = unit + spacing
            let rows = Int(ceil(size.height / max(step, 1)))

            for row in 0...rows {
                for column in 0..<columns {
                    let rect = CGRect(
                        x: CGFloat(column) * step,
                        y: CGFloat(row) * step,
                        width: unit,
                        height: unit
                    )

                    let path = Path(
                        roundedRect: rect.insetBy(dx: 2, dy: 2),
                        cornerRadius: 18
                    )

                    context.stroke(
                        path,
                        with: .color(.white.opacity(0.07)),
                        lineWidth: 1
                    )
                }
            }
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
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func canvasOrientation(
        for size: CGSize
    ) -> CanvasOrientation {
        return size.width > size.height
            ? .landscape
            : .portrait
    }

    private func columnCount(
        for size: CGSize,
        orientation: CanvasOrientation
    ) -> Int {
        switch orientation {
        case .portrait:
            switch size.width {
            case 1100...:
                return 8
            case 760...:
                return 6
            default:
                return 4
            }

        case .landscape:
            switch size.width {
            case 1180...:
                return 10
            case 760...:
                return 8
            default:
                return 6
            }
        }
    }

    private func canvasHorizontalPadding(
        for size: CGSize,
        orientation: CanvasOrientation
    ) -> CGFloat {
        switch orientation {
        case .portrait:
            return size.width > 900 ? 28 : 18
        case .landscape:
            return size.width > 1000 ? 20 : 10
        }
    }

    private func canvasTopInset(
        orientation: CanvasOrientation,
        showsControls: Bool
    ) -> CGFloat {
        switch orientation {
        case .portrait:
            return showsControls ? 70 : 18
        case .landscape:
            return showsControls ? 52 : 8
        }
    }

    private var inspectorBinding: Binding<IdentifiableUUID?> {
        return Binding(
            get: {
                inspectorID.map(IdentifiableUUID.init)
            },
            set: {
                inspectorID = $0?.id
            }
        )
    }
}

private struct IdentifiableUUID: Identifiable {
    let id: UUID
}

private struct StandSpaceToolbarButtonStyle: ButtonStyle {
    var prominent = false
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(
                minWidth: compact ? 34 : nil,
                minHeight: compact ? 34 : nil
            )
            .padding(.horizontal, compact ? 7 : 13)
            .padding(.vertical, compact ? 6 : 9)
            .background(
                prominent
                    ? AnyShapeStyle(Color.white.opacity(0.18))
                    : AnyShapeStyle(.ultraThinMaterial),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(
                        .white.opacity(prominent ? 0.20 : 0.10),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private struct LiveResizeHandle: View {
    let item: DashboardItem
    let unit: CGFloat
    let spacing: CGFloat
    let maxColumns: Int
    let onResize: (ModuleSize) -> Void

    @State private var startSize: ModuleSize?
    @State private var previewSize: ModuleSize?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let previewSize = previewSize {
                Text(previewSize.title)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.regularMaterial, in: Capsule())
                    .offset(x: -32, y: -32)
            }

            Image(
                systemName: "arrow.up.left.and.arrow.down.right"
            )
            .font(.caption.bold())
            .frame(width: 34, height: 34)
            .background(.regularMaterial, in: Circle())
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.28), lineWidth: 1)
            )
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if startSize == nil {
                            startSize = item.size
                            previewSize = item.size
                        }

                        guard let baseSize = startSize else {
                            return
                        }

                        let step = max(unit + spacing, 1)
                        let base = baseSize.span
                        let columns = min(
                            maxColumns,
                            max(
                                1,
                                base.columns
                                    + Int(
                                        (
                                            value.translation.width
                                            / step
                                        ).rounded()
                                    )
                            )
                        )
                        let rows = max(
                            1,
                            base.rows
                                + Int(
                                    (
                                        value.translation.height
                                        / step
                                    ).rounded()
                                )
                        )

                        let newSize = ModuleSize.closestSupported(
                            columns: columns,
                            rows: rows,
                            supported: item.kind.supportedSizes
                        )

                        if previewSize != newSize {
                            previewSize = newSize
                            onResize(newSize)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.15)) {
                            startSize = nil
                            previewSize = nil
                        }
                    }
            )
        }
    }
}
