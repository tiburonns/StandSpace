import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: DashboardStore

    let onInteraction: () -> Void

    @State private var isEditing = false
    @State private var controlsVisible = true
    @State private var selectedID: UUID?
    @State private var draggingID: UUID?
    @State private var dragOffset: CGSize = .zero
    @State private var showingGallery = false
    @State private var showingSettings = false
    @State private var inspectorID: UUID?
    @State private var feedbackTick = 0
    @State private var landscapePage: LandscapePage = .dashboard

    private let spacing: CGFloat = 12

    init(
        onInteraction: @escaping () -> Void = {}
    ) {
        self.onInteraction = onInteraction
    }

    var body: some View {
        GeometryReader { geometry in
            let orientation = canvasOrientation(
                for: geometry.size
            )
            let isLandscape =
                orientation == .landscape
            let horizontalPadding =
                canvasHorizontalPadding(
                    for: geometry.size,
                    orientation: orientation
                )
            let canvasWidth = max(
                geometry.size.width
                    - horizontalPadding * 2,
                1
            )
            let columns = columnCount(
                for: geometry.size,
                orientation: orientation
            )
            let topInset = canvasTopInset(
                orientation: orientation,
                showsControls:
                    controlsVisible || isEditing
            )
            let layout =
                DashboardPackingEngine.pack(
                    items: store.items,
                    width: canvasWidth,
                    columns: columns,
                    spacing: spacing,
                    orientation: orientation
                )

            ZStack(alignment: .topLeading) {
                if isLandscape && !isEditing {
                    landscapePager(
                        geometry: geometry,
                        layout: layout,
                        columns: columns,
                        horizontalPadding:
                            horizontalPadding,
                        topInset: topInset
                    )
                } else {
                    dashboardCanvas(
                        geometry: geometry,
                        layout: layout,
                        columns: columns,
                        horizontalPadding:
                            horizontalPadding,
                        topInset: topInset,
                        orientation: orientation
                    )
                }

                if controlsVisible || isEditing {
                    topToolbar(
                        orientation: orientation,
                        columns: columns
                    )
                    .padding(
                        .horizontal,
                        horizontalPadding
                    )
                    .padding(
                        .top,
                        isLandscape ? 6 : 12
                    )
                    .transition(
                        .move(edge: .top)
                            .combined(with: .opacity)
                    )
                    .zIndex(50)
                }

                if isLandscape && !isEditing {
                    landscapeBottomChrome
                        .padding(
                            .horizontal,
                            horizontalPadding
                        )
                        .padding(.bottom, 8)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottom
                        )
                        .zIndex(40)
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        onInteraction()
                    }
            )
            .onTapGesture {
                guard !isEditing else {
                    selectedID = nil
                    return
                }

                withAnimation(
                    .easeInOut(duration: 0.18)
                ) {
                    controlsVisible.toggle()
                }
            }
            .onChange(of: isLandscape) {
                _, landscape in

                selectedID = nil
                draggingID = nil
                dragOffset = .zero
                landscapePage = .dashboard
                onInteraction()

                if landscape && !isEditing {
                    withAnimation(
                        .easeInOut(duration: 0.2)
                    ) {
                        controlsVisible = false
                    }
                } else {
                    controlsVisible = true
                }
            }
            .onChange(of: landscapePage) {
                _, _ in
                onInteraction()
            }
            .onChange(
                of: store.selectedSpaceID
            ) { _, _ in
                selectedID = nil
                draggingID = nil
                dragOffset = .zero
                landscapePage = .dashboard
                onInteraction()
            }
        }
        .sensoryFeedback(
            .selection,
            trigger: feedbackTick
        )
        .sheet(isPresented: $showingGallery) {
            ModuleGalleryView {
                kind,
                size,
                style in

                store.add(
                    kind,
                    size: size,
                    style: style
                )
                feedbackTick += 1
                onInteraction()
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showingSettings) {
            EditorView()
                .environmentObject(store)
        }
        .sheet(item: inspectorBinding) {
            itemID in

            if let binding = store.binding(
                for: itemID.id
            ) {
                NavigationStack {
                    ModuleEditorView(
                        item: binding
                    )
                    .toolbar {
                        ToolbarItem(
                            placement:
                                .confirmationAction
                        ) {
                            Button("Listo") {
                                inspectorID = nil
                                onInteraction()
                            }
                        }
                    }
                }
            }
        }
    }

    private func dashboardCanvas(
        geometry: GeometryProxy,
        layout: PackedDashboardLayout,
        columns: Int,
        horizontalPadding: CGFloat,
        topInset: CGFloat,
        orientation: CanvasOrientation
    ) -> some View {
        let isLandscape =
            orientation == .landscape
        let canvasWidth = max(
            geometry.size.width
                - horizontalPadding * 2,
            1
        )

        return ScrollView(
            .vertical,
            showsIndicators: false
        ) {
            ZStack(alignment: .topLeading) {
                if isEditing {
                    gridBackdrop(
                        width: canvasWidth,
                        height: max(
                            layout.height
                                + layout.unit * 2,
                            geometry.size.height
                                - topInset
                                - 20
                        ),
                        unit: layout.unit,
                        columns: columns
                    )
                    .transition(.opacity)
                }

                ForEach(store.items) {
                    item in

                    if let frame =
                        layout.frames[item.id] {
                        module(
                            item,
                            frame: frame,
                            layout: layout,
                            columns: columns,
                            orientation:
                                orientation
                        )
                    }
                }
            }
            .frame(
                width: canvasWidth,
                height: max(
                    layout.height
                        + layout.unit,
                    geometry.size.height
                        - topInset
                ),
                alignment: .topLeading
            )
            .padding(
                .horizontal,
                horizontalPadding
            )
            .padding(.top, topInset)
            .padding(
                .bottom,
                isLandscape ? 44 : 28
            )
        }
        .scrollDisabled(
            draggingID != nil
        )
    }

    private func landscapePager(
        geometry: GeometryProxy,
        layout: PackedDashboardLayout,
        columns: Int,
        horizontalPadding: CGFloat,
        topInset: CGFloat
    ) -> some View {
        TabView(selection: $landscapePage) {
            dashboardCanvas(
                geometry: geometry,
                layout: layout,
                columns: columns,
                horizontalPadding:
                    horizontalPadding,
                topInset: topInset,
                orientation: .landscape
            )
            .tag(LandscapePage.dashboard)

            landscapeClockPage(
                geometry: geometry
            )
            .tag(LandscapePage.clock)

            StandbyPhotoPage(
                controlsVisible: controlsVisible
            )
            .tag(LandscapePage.photos)

            StandbyMusicPage(
                controlsVisible: controlsVisible
            )
            .tag(LandscapePage.music)

            landscapeFocusPage(
                geometry: geometry
            )
            .tag(LandscapePage.focus)
        }
        .tabViewStyle(
            .page(indexDisplayMode: .never)
        )
    }

    private func landscapeClockPage(
        geometry: GeometryProxy
    ) -> some View {
        TimelineView(
            .periodic(
                from: Date(),
                by: 1
            )
        ) { context in
            VStack(spacing: 4) {
                Spacer()

                Text(
                    context.date,
                    format:
                        Date.FormatStyle
                            .dateTime
                            .hour()
                            .minute()
                )
                .font(
                    .system(
                        size: min(
                            max(
                                geometry.size.height
                                    * 0.31,
                                82
                            ),
                            158
                        ),
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .minimumScaleFactor(0.55)
                .lineLimit(1)
                .monospacedDigit()

                Text(
                    context.date,
                    format:
                        Date.FormatStyle
                            .dateTime
                            .weekday(.wide)
                            .day()
                            .month(.wide)
                )
                .font(
                    .title2.weight(.medium)
                )
                .foregroundStyle(.secondary)

                Text(
                    store.activeSpace.kind.title
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 6)

                Spacer()
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .padding(.horizontal, 30)
            .padding(.bottom, 34)
        }
    }

    private func landscapeFocusPage(
        geometry: GeometryProxy
    ) -> some View {
        HStack(spacing: 14) {
            ModuleCardView(
                item: DashboardItem(
                    kind: .timer,
                    size: .large,
                    style: .glass
                )
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

            ModuleCardView(
                item: DashboardItem(
                    kind: .calendar,
                    size: .large,
                    style: .tinted
                )
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, controlsVisible ? 54 : 16)
        .padding(.bottom, 44)
        .frame(
            width: geometry.size.width,
            height: geometry.size.height
        )
    }

    private var landscapeBottomChrome:
        some View {
        HStack(spacing: 10) {
            pageIndicator

            Spacer(minLength: 8)

            if controlsVisible {
                spaceStrip
                    .transition(.opacity)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(
                LandscapePage.allCases
            ) { page in
                Button {
                    withAnimation(.snappy) {
                        landscapePage = page
                    }
                    onInteraction()
                } label: {
                    Image(
                        systemName: page.icon
                    )
                    .font(.caption2.weight(.bold))
                    .frame(width: 26, height: 26)
                    .background(
                        landscapePage == page
                            ? Color.white.opacity(0.20)
                            : Color.white.opacity(0.06),
                        in: Circle()
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(page.title)
            }
        }
        .padding(5)
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
    }

    private var spaceStrip: some View {
        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(spacing: 6) {
                ForEach(store.spaces) {
                    space in

                    Button {
                        store.selectSpace(
                            space.id
                        )
                        onInteraction()
                        feedbackTick += 1
                    } label: {
                        HStack(spacing: 5) {
                            Image(
                                systemName:
                                    space.kind.icon
                            )
                            .font(.caption)

                            Text(
                                space.kind.title
                            )
                            .font(
                                .caption
                                    .weight(.semibold)
                            )
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .background(
                            store.selectedSpaceID
                                == space.id
                                ? Color.white
                                    .opacity(0.18)
                                : Color.white
                                    .opacity(0.05),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: 390)
        .padding(4)
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
    }

    private func module(
        _ item: DashboardItem,
        frame: CGRect,
        layout: PackedDashboardLayout,
        columns: Int,
        orientation: CanvasOrientation
    ) -> some View {
        let renderedItem = item.rendered(
            for: orientation
        )
        let isSelected =
            selectedID == item.id
        let isDragging =
            draggingID == item.id

        return ModuleCardView(
            item: renderedItem
        )
        .frame(
            width: frame.width,
            height: frame.height
        )
        .overlay {
            if isEditing {
                RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
                .stroke(
                    isSelected
                        ? Color.white
                        : Color.white
                            .opacity(0.18),
                    style: StrokeStyle(
                        lineWidth:
                            isSelected ? 2 : 1,
                        dash:
                            isSelected
                            ? []
                            : [5, 5]
                    )
                )
            }
        }
        .overlay(alignment: .topLeading) {
            if isEditing && isSelected {
                editButton(
                    systemName: "minus",
                    role: .destructive
                ) {
                    store.delete(id: item.id)
                    selectedID = nil
                    feedbackTick += 1
                    onInteraction()
                }
                .offset(x: -8, y: -8)
            }
        }
        .overlay(alignment: .topTrailing) {
            if isEditing && isSelected {
                editButton(
                    systemName:
                        "plus.square.on.square"
                ) {
                    store.duplicate(id: item.id)
                    feedbackTick += 1
                    onInteraction()
                }
                .offset(x: 8, y: -8)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if isEditing && isSelected {
                editButton(
                    systemName:
                        "slider.horizontal.3"
                ) {
                    inspectorID = item.id
                    onInteraction()
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
                        orientation:
                            orientation
                    )
                    feedbackTick += 1
                    onInteraction()
                }
                .offset(x: 10, y: 10)
            }
        }
        .scaleEffect(
            isDragging ? 1.035 : 1
        )
        .shadow(
            color: .black.opacity(
                isDragging ? 0.38 : 0
            ),
            radius:
                isDragging ? 22 : 0,
            y: 10
        )
        .offset(
            x: frame.minX
                + (
                    isDragging
                    ? dragOffset.width
                    : 0
                ),
            y: frame.minY
                + (
                    isDragging
                    ? dragOffset.height
                    : 0
                )
        )
        .zIndex(
            isDragging || isSelected
                ? 10
                : 0
        )
        .onTapGesture {
            guard isEditing else {
                return
            }

            if selectedID == item.id {
                inspectorID = item.id
            } else {
                selectedID = item.id
                feedbackTick += 1
            }

            onInteraction()
        }
        .onLongPressGesture(
            minimumDuration: 0.30
        ) {
            guard !isEditing else {
                return
            }

            withAnimation(.snappy) {
                isEditing = true
                controlsVisible = true
                selectedID = item.id
            }

            feedbackTick += 1
            onInteraction()
        }
        .simultaneousGesture(
            DragGesture(
                minimumDistance:
                    isEditing ? 4 : 12
            )
            .onChanged { value in
                guard isEditing else {
                    return
                }

                selectedID = item.id
                draggingID = item.id
                dragOffset = value.translation
                onInteraction()
            }
            .onEnded { value in
                guard isEditing else {
                    return
                }

                let proposedOrigin = CGPoint(
                    x: frame.minX
                        + value.translation.width,
                    y: frame.minY
                        + value.translation.height
                )

                let snapped =
                    DashboardPackingEngine
                    .snappedPosition(
                        for: proposedOrigin,
                        itemSize:
                            renderedItem.size,
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
                onInteraction()
            }
        )
        .animation(
            .snappy,
            value: frame
        )
    }

    @ViewBuilder
    private func topToolbar(
        orientation: CanvasOrientation,
        columns: Int
    ) -> some View {
        let isLandscape =
            orientation == .landscape

        HStack(
            spacing: isLandscape ? 7 : 10
        ) {
            spaceMenu(
                compact: isLandscape
            )

            if isEditing {
                Button {
                    showingGallery = true
                    onInteraction()
                } label: {
                    if isLandscape {
                        Image(systemName: "plus")
                    } else {
                        Label(
                            "Agregar",
                            systemImage: "plus"
                        )
                    }
                }
                .buttonStyle(
                    StandSpaceToolbarButtonStyle(
                        compact: isLandscape
                    )
                )

                if isLandscape {
                    Menu {
                        ForEach(
                            LandscapePreset
                                .allCases
                        ) { preset in
                            Button {
                                store
                                    .applyLandscapePreset(
                                        preset,
                                        columns: columns
                                    )
                                feedbackTick += 1
                                onInteraction()
                            } label: {
                                Label(
                                    preset.title,
                                    systemImage:
                                        preset.icon
                                )
                            }
                        }
                    } label: {
                        Image(
                            systemName:
                                "rectangle.3.group"
                        )
                    }
                    .buttonStyle(
                        StandSpaceToolbarButtonStyle(
                            compact: true
                        )
                    )
                    .accessibilityLabel(
                        "Diseño horizontal"
                    )
                }

                backgroundMenu(
                    compact: isLandscape
                )

                Spacer()

                if !isLandscape {
                    Text("Editar StandSpace")
                        .font(.headline)
                        .foregroundStyle(
                            .secondary
                        )
                        .lineLimit(1)

                    Spacer()
                }

                Button {
                    withAnimation(.snappy) {
                        isEditing = false
                        selectedID = nil

                        if isLandscape {
                            controlsVisible =
                                false
                        }
                    }

                    feedbackTick += 1
                    onInteraction()
                } label: {
                    if isLandscape {
                        Image(
                            systemName:
                                "checkmark"
                        )
                    } else {
                        Text("Listo")
                            .fontWeight(
                                .semibold
                            )
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
                        store.backgroundStyle =
                            store.backgroundStyle
                                == .standbyRed
                            ? .oled
                            : .standbyRed

                        onInteraction()
                    } label: {
                        Image(
                            systemName:
                                store
                                    .backgroundStyle
                                    == .standbyRed
                                ? "circle.lefthalf.filled"
                                : "moon.stars"
                        )
                    }
                    .buttonStyle(
                        StandSpaceToolbarButtonStyle(
                            compact: true
                        )
                    )
                    .accessibilityLabel(
                        "Alternar modo noche"
                    )
                }

                Button {
                    showingSettings = true
                    onInteraction()
                } label: {
                    Image(
                        systemName: "gearshape"
                    )
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
                        landscapePage =
                            .dashboard
                    }

                    feedbackTick += 1
                    onInteraction()
                } label: {
                    if isLandscape {
                        Image(
                            systemName:
                                "square.grid.2x2"
                        )
                    } else {
                        Label(
                            "Editar",
                            systemImage:
                                "square.grid.2x2"
                        )
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
        .font(
            .subheadline.weight(.semibold)
        )
    }

    private func spaceMenu(
        compact: Bool
    ) -> some View {
        Menu {
            ForEach(store.spaces) {
                space in

                Button {
                    store.selectSpace(
                        space.id
                    )
                    onInteraction()
                    feedbackTick += 1
                } label: {
                    Label(
                        space.kind.title,
                        systemImage:
                            space.kind.icon
                    )
                }
            }
        } label: {
            if compact {
                Image(
                    systemName:
                        store.activeSpace
                            .kind.icon
                )
            } else {
                Label(
                    store.activeSpace
                        .kind.title,
                    systemImage:
                        store.activeSpace
                            .kind.icon
                )
            }
        }
        .buttonStyle(
            StandSpaceToolbarButtonStyle(
                compact: compact
            )
        )
    }

    private func backgroundMenu(
        compact: Bool
    ) -> some View {
        Menu {
            Picker(
                "Fondo",
                selection:
                    $store.backgroundStyle
            ) {
                ForEach(
                    BoardBackgroundStyle
                        .allCases
                ) { style in
                    Text(style.title)
                        .tag(style)
                }
            }

            Divider()

            Button {
                store.backgroundStyle =
                    .standbyRed
                onInteraction()
            } label: {
                Label(
                    "Modo noche",
                    systemImage:
                        "moon.stars"
                )
            }

            Button {
                store.backgroundStyle = .oled
                onInteraction()
            } label: {
                Label(
                    "OLED negro",
                    systemImage:
                        "circle.fill"
                )
            }
        } label: {
            if compact {
                Image(
                    systemName:
                        "paintpalette"
                )
            } else {
                Label(
                    "Tema",
                    systemImage:
                        "paintpalette"
                )
            }
        }
        .buttonStyle(
            StandSpaceToolbarButtonStyle(
                compact: compact
            )
        )
    }

    private func gridBackdrop(
        width: CGFloat,
        height: CGFloat,
        unit: CGFloat,
        columns: Int
    ) -> some View {
        Canvas { context, size in
            let step = unit + spacing
            let rows = Int(
                ceil(
                    size.height
                        / max(step, 1)
                )
            )

            for row in 0...rows {
                for column in 0..<columns {
                    let rect = CGRect(
                        x: CGFloat(column)
                            * step,
                        y: CGFloat(row)
                            * step,
                        width: unit,
                        height: unit
                    )

                    let path = Path(
                        roundedRect:
                            rect.insetBy(
                                dx: 2,
                                dy: 2
                            ),
                        cornerRadius: 18
                    )

                    context.stroke(
                        path,
                        with: .color(
                            .white.opacity(
                                0.07
                            )
                        ),
                        lineWidth: 1
                    )
                }
            }
        }
        .frame(
            width: width,
            height: height
        )
        .allowsHitTesting(false)
    }

    private func editButton(
        systemName: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            role: role,
            action: action
        ) {
            Image(systemName: systemName)
                .font(.caption.bold())
                .frame(
                    width: 30,
                    height: 30
                )
                .background(
                    .regularMaterial,
                    in: Circle()
                )
                .overlay(
                    Circle()
                        .stroke(
                            .white
                                .opacity(
                                    0.22
                                ),
                            lineWidth: 1
                        )
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
            return size.width > 900
                ? 28
                : 18
        case .landscape:
            return size.width > 1000
                ? 20
                : 10
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

    private var inspectorBinding:
        Binding<IdentifiableUUID?> {
        return Binding(
            get: {
                inspectorID.map(
                    IdentifiableUUID.init
                )
            },
            set: {
                inspectorID = $0?.id
            }
        )
    }
}

private struct IdentifiableUUID:
    Identifiable {
    let id: UUID
}

private struct StandSpaceToolbarButtonStyle:
    ButtonStyle {
    var prominent = false
    var compact = false

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .frame(
                minWidth:
                    compact ? 34 : nil,
                minHeight:
                    compact ? 34 : nil
            )
            .padding(
                .horizontal,
                compact ? 7 : 13
            )
            .padding(
                .vertical,
                compact ? 6 : 9
            )
            .background(
                prominent
                    ? AnyShapeStyle(
                        Color.white
                            .opacity(0.18)
                    )
                    : AnyShapeStyle(
                        .ultraThinMaterial
                    ),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(
                        .white.opacity(
                            prominent
                                ? 0.20
                                : 0.10
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(
                configuration.isPressed
                    ? 0.96
                    : 1
            )
            .opacity(
                configuration.isPressed
                    ? 0.82
                    : 1
            )
    }
}

private struct LiveResizeHandle: View {
    let item: DashboardItem
    let unit: CGFloat
    let spacing: CGFloat
    let maxColumns: Int
    let onResize:
        (ModuleSize) -> Void

    @State private var startSize:
        ModuleSize?
    @State private var previewSize:
        ModuleSize?

    var body: some View {
        ZStack(
            alignment: .bottomTrailing
        ) {
            if let previewSize =
                previewSize {
                Text(previewSize.title)
                    .font(
                        .caption2.bold()
                    )
                    .padding(
                        .horizontal,
                        8
                    )
                    .padding(
                        .vertical,
                        5
                    )
                    .background(
                        .regularMaterial,
                        in: Capsule()
                    )
                    .offset(
                        x: -32,
                        y: -32
                    )
            }

            Image(
                systemName:
                    "arrow.up.left.and.arrow.down.right"
            )
            .font(.caption.bold())
            .frame(
                width: 34,
                height: 34
            )
            .background(
                .regularMaterial,
                in: Circle()
            )
            .overlay(
                Circle()
                    .stroke(
                        .white.opacity(
                            0.28
                        ),
                        lineWidth: 1
                    )
            )
            .contentShape(Circle())
            .gesture(
                DragGesture(
                    minimumDistance: 0
                )
                .onChanged { value in
                    if startSize == nil {
                        startSize =
                            item.size
                        previewSize =
                            item.size
                    }

                    guard let baseSize =
                        startSize else {
                        return
                    }

                    let step = max(
                        unit + spacing,
                        1
                    )
                    let base =
                        baseSize.span
                    let columns = min(
                        maxColumns,
                        max(
                            1,
                            base.columns
                                + Int(
                                    (
                                        value
                                            .translation
                                            .width
                                        / step
                                    )
                                    .rounded()
                                )
                        )
                    )
                    let rows = max(
                        1,
                        base.rows
                            + Int(
                                (
                                    value
                                        .translation
                                        .height
                                    / step
                                )
                                .rounded()
                            )
                    )

                    let newSize =
                        ModuleSize
                        .closestSupported(
                            columns:
                                columns,
                            rows: rows,
                            supported:
                                item.kind
                                .supportedSizes
                        )

                    if previewSize
                        != newSize {
                        previewSize =
                            newSize
                        onResize(newSize)
                    }
                }
                .onEnded { _ in
                    withAnimation(
                        .easeOut(
                            duration: 0.15
                        )
                    ) {
                        startSize = nil
                        previewSize = nil
                    }
                }
            )
        }
    }
}
