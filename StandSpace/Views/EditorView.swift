import SwiftUI

struct EditorView: View {
    @EnvironmentObject private var store: DashboardStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Tablero") {
                    Toggle("Mantener pantalla encendida", isOn: $store.keepScreenAwake)

                    Picker("Fondo", selection: $store.backgroundStyle) {
                        ForEach(BoardBackgroundStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
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

                Section {
                    Menu {
                        ForEach(ModuleKind.allCases) { kind in
                            Button {
                                store.add(kind)
                            } label: {
                                Label(kind.title, systemImage: kind.icon)
                            }
                        }
                    } label: {
                        Label("Agregar módulo", systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    Button("Restablecer tablero", role: .destructive) {
                        store.reset()
                    }
                }
            }
            .navigationTitle("Personalizar")
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
}

struct ModuleEditorView: View {
    @Binding var item: DashboardItem

    var body: some View {
        Form {
            Section("Diseño") {
                Picker("Tamaño", selection: $item.size) {
                    ForEach(ModuleSize.allCases) { size in
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

    private var previewHeight: CGFloat {
        switch item.size {
        case .small, .wide: 170
        case .tall, .large: 300
        }
    }
}
