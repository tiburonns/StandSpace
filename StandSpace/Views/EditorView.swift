import SwiftUI

struct EditorView: View {
    @EnvironmentObject private var store: DashboardStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Space") {
                    Picker("Space activo", selection: activeSpaceBinding) {
                        ForEach(store.spaces) { space in
                            Label(
                                space.kind.title,
                                systemImage: space.kind.icon
                            )
                            .tag(space.id)
                        }
                    }
                }

                Section("Experiencia") {
                    Toggle(
                        "Mantener pantalla encendida",
                        isOn: $store.keepScreenAwake
                    )

                    Toggle(
                        "Auto-dim",
                        isOn: $store.autoDimEnabled
                    )

                    Toggle(
                        "Protección OLED",
                        isOn: $store.oledProtectionEnabled
                    )

                    Picker(
                        "Fondo",
                        selection: $store.backgroundStyle
                    ) {
                        ForEach(BoardBackgroundStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }

                    Text("Auto-dim atenúa la interfaz después de un periodo sin interacción. Protección OLED desplaza el contenido unos píxeles periódicamente para reducir elementos estáticos.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Módulos") {
                    ForEach($store.items) { $item in
                        NavigationLink {
                            ModuleEditorView(item: $item)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.kind.icon)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.kind.title)
                                    Text("\(item.size.title) · \(item.style.title)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: store.delete)
                    .onMove(perform: store.move)
                }

                Section("StandSpace") {
                    LabeledContent("Versión", value: "0.4.0")
                    Text("StandSpace es gratuito. La meta del proyecto es ofrecer toda la experiencia principal sin paywalls ni módulos Pro.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Restablecer todos los Spaces", role: .destructive) {
                        store.reset()
                    }
                }
            }
            .navigationTitle("Ajustes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }

    private var activeSpaceBinding: Binding<UUID> {
        return Binding(
            get: {
                store.selectedSpaceID
            },
            set: { newValue in
                store.selectSpace(newValue)
            }
        )
    }
}

struct ModuleEditorView: View {
    @Binding var item: DashboardItem

    var body: some View {
        Form {
            Section("Diseño") {
                Picker("Tamaño vertical", selection: $item.size) {
                    ForEach(item.kind.supportedSizes) { size in
                        Text(size.title).tag(size)
                    }
                }

                Picker(
                    "Tamaño horizontal",
                    selection: landscapeSizeBinding
                ) {
                    ForEach(item.kind.supportedSizes) { size in
                        Text(size.title).tag(size)
                    }
                }

                Picker("Estilo", selection: $item.style) {
                    ForEach(ModuleStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
            }

            if item.kind == .text {
                Section("Contenido") {
                    TextField("Título", text: $item.title)
                    TextField("Texto", text: $item.text, axis: .vertical)
                        .lineLimit(3...8)
                }
            }

            Section("Vista previa") {
                ModuleCardView(item: item)
                    .frame(height: previewHeight)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(item.kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var landscapeSizeBinding: Binding<ModuleSize> {
        return Binding(
            get: {
                item.landscapeSize ?? item.size
            },
            set: { newValue in
                item.landscapeSize = newValue
            }
        )
    }

    private var previewHeight: CGFloat {
        item.size.span.rows == 1 ? 170 : 300
    }
}

struct ModuleGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedKind: ModuleKind?
    @State private var selectedSize: ModuleSize?
    @State private var selectedStyle: ModuleStyle = .glass

    let onAdd: (ModuleKind, ModuleSize?, ModuleStyle) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(ModuleCategory.allCases) { category in
                        let modules = filteredModules(in: category)
                        if !modules.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(category.title)
                                    .font(.title3.bold())

                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 155), spacing: 12)],
                                    spacing: 12
                                ) {
                                    ForEach(modules) { kind in
                                        moduleTile(kind)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Agregar módulo")
            .searchable(text: $searchText, prompt: "Buscar módulos")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .sheet(item: kindBinding) { kind in
            ModuleAddConfigurator(
                kind: kind,
                selectedSize: selectedSize ?? kind.defaultSize,
                selectedStyle: selectedStyle
            ) { size, style in
                onAdd(kind, size, style)
                selectedKind = nil
                selectedSize = nil
                selectedStyle = .glass
                dismiss()
            }
        }
    }

    private func moduleTile(_ kind: ModuleKind) -> some View {
        Button {
            selectedKind = kind
            selectedSize = kind.defaultSize
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: kind.icon)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 10)

                Text(kind.title)
                    .font(.headline)
                Text(kind.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func filteredModules(in category: ModuleCategory) -> [ModuleKind] {
        ModuleKind.allCases.filter { kind in
            guard kind.category == category else { return false }
            guard !searchText.isEmpty else { return true }
            return kind.title.localizedCaseInsensitiveContains(searchText)
                || kind.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var kindBinding: Binding<ModuleKind?> {
        Binding(get: { selectedKind }, set: { selectedKind = $0 })
    }
}

private struct ModuleAddConfigurator: View {
    let kind: ModuleKind
    @State var selectedSize: ModuleSize
    @State var selectedStyle: ModuleStyle
    let onAdd: (ModuleSize, ModuleStyle) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ModuleCardView(
                        item: DashboardItem(
                            kind: kind,
                            size: selectedSize,
                            style: selectedStyle,
                            title: kind == .text ? "Nota" : "",
                            text: kind == .text ? "Tu texto aquí" : ""
                        )
                    )
                    .frame(height: selectedSize.span.rows == 1 ? 180 : 280)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tamaño")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(kind.supportedSizes) { size in
                                    Button(size.title) {
                                        withAnimation(.snappy) { selectedSize = size }
                                    }
                                    .buttonStyle(ChoiceButtonStyle(selected: selectedSize == size))
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Estilo")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(ModuleStyle.allCases) { style in
                                    Button(style.title) {
                                        withAnimation(.snappy) { selectedStyle = style }
                                    }
                                    .buttonStyle(ChoiceButtonStyle(selected: selectedStyle == style))
                                }
                            }
                        }
                    }

                    Button {
                        onAdd(selectedSize, selectedStyle)
                    } label: {
                        Label("Agregar a StandSpace", systemImage: "plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}

private struct ChoiceButtonStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(selected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(selected ? Color.white : Color.primary)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
