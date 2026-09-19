import SwiftUI

struct EditorView: View {
    @EnvironmentObject private var store: DashboardStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StandSpaceAppLanguage.storageKey)
    private var languageRawValue = StandSpaceAppLanguage.system.rawValue

    var body: some View {
        NavigationStack {
            List {
                Section(t("Language", "Idioma")) {
                    Picker(
                        t("App language", "Idioma de la app"),
                        selection: $languageRawValue
                    ) {
                        ForEach(StandSpaceAppLanguage.allCases) { language in
                            Text(language.optionTitle)
                                .tag(language.rawValue)
                        }
                    }
                }

                if let warning =
                    store.persistenceWarning {
                    Section {
                        Label(
                            warning,
                            systemImage:
                                "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                    }
                }

                Section(t("Space", "Espacio")) {
                    Picker(t("Active space", "Space activo"), selection: activeSpaceBinding) {
                        ForEach(store.spaces) { space in
                            Label(
                                space.kind.title,
                                systemImage: space.kind.icon
                            )
                            .tag(space.id)
                        }
                    }
                }

                Section(t("Experience", "Experiencia")) {
                    Toggle(
                        t("Keep screen awake", "Mantener pantalla encendida"),
                        isOn: $store.keepScreenAwake
                    )

                    Toggle(
                        t("Auto-dim", "Atenuación automática"),
                        isOn: $store.autoDimEnabled
                    )

                    Toggle(
                        t("OLED protection", "Protección OLED"),
                        isOn: $store.oledProtectionEnabled
                    )

                    Picker(
                        t("Background", "Fondo"),
                        selection: $store.backgroundStyle
                    ) {
                        ForEach(BoardBackgroundStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }

                    Text(t("Auto-dim dims the interface after a period without interaction. OLED protection shifts content by a few pixels periodically to reduce static elements.", "Auto-dim atenúa la interfaz después de un periodo sin interacción. Protección OLED desplaza el contenido unos píxeles periódicamente para reducir elementos estáticos."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(t("Modules", "Módulos")) {
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
                    LabeledContent(
                        t("Version", "Versión"),
                        value: appVersion
                    )
                    Text(t("StandSpace is free. The project goal is to provide the complete core experience without paywalls or Pro-only modules.", "StandSpace es gratuito. La meta del proyecto es ofrecer toda la experiencia principal sin paywalls ni módulos Pro."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button(t("Reset all Spaces", "Restablecer todos los Spaces"), role: .destructive) {
                        store.reset()
                    }
                }
            }
            .navigationTitle(t("Settings", "Ajustes"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("Done", "Listo")) { dismiss() }
                }
            }
        }
    }


    private var appLanguage: StandSpaceAppLanguage {
        StandSpaceAppLanguage(rawValue: languageRawValue) ?? .system
    }

    private func t(_ english: String, _ spanish: String) -> String {
        appLanguage.text(english: english, spanish: spanish)
    }

    private var appVersion: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey:
                "CFBundleShortVersionString"
        ) as? String ?? "—"
        let build = Bundle.main.object(
            forInfoDictionaryKey:
                "CFBundleVersion"
        ) as? String ?? "—"
        return "\(version) (\(build))"
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

    private var language: StandSpaceAppLanguage { .current }
    private func t(_ english: String, _ spanish: String) -> String {
        language.text(english: english, spanish: spanish)
    }

    var body: some View {
        Form {
            Section(t("Layout", "Diseño")) {
                Picker(t("Portrait size", "Tamaño vertical"), selection: $item.size) {
                    ForEach(item.kind.supportedSizes) { size in
                        Text(size.title).tag(size)
                    }
                }

                Picker(
                    t("Landscape size", "Tamaño horizontal"),
                    selection: landscapeSizeBinding
                ) {
                    ForEach(item.kind.supportedSizes) { size in
                        Text(size.title).tag(size)
                    }
                }

                Picker(t("Style", "Estilo"), selection: $item.style) {
                    ForEach(ModuleStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
            }

            if item.kind == .text {
                Section(t("Content", "Contenido")) {
                    TextField(t("Title", "Título"), text: $item.title)
                    TextField(t("Text", "Texto"), text: $item.text, axis: .vertical)
                        .lineLimit(3...8)
                }
            }

            Section(t("Preview", "Vista previa")) {
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

    private var language: StandSpaceAppLanguage { .current }
    private func t(_ english: String, _ spanish: String) -> String {
        language.text(english: english, spanish: spanish)
    }
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
            .navigationTitle(t("Add Module", "Agregar módulo"))
            .searchable(text: $searchText, prompt: t("Search modules", "Buscar módulos"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("Close", "Cerrar")) { dismiss() }
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

    private var language: StandSpaceAppLanguage { .current }
    private func t(_ english: String, _ spanish: String) -> String {
        language.text(english: english, spanish: spanish)
    }
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
                            title: kind == .text ? t("Note", "Nota") : "",
                            text: kind == .text ? t("Your text here", "Tu texto aquí") : ""
                        )
                    )
                    .frame(height: selectedSize.span.rows == 1 ? 180 : 280)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(t("Size", "Tamaño"))
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
                        Text(t("Style", "Estilo"))
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
                        Label(t("Add to StandSpace", "Agregar a StandSpace"), systemImage: "plus")
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
