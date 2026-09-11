import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: DashboardStore
    @State private var showingEditor = false
    @State private var controlsVisible = true

    var body: some View {
        ZStack {
            store.backgroundStyle.background
                .ignoresSafeArea()

            DashboardView(items: store.items)
                .padding(18)

            if controlsVisible {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showingEditor = true
                        } label: {
                            Label("Editar", systemImage: "slider.horizontal.3")
                                .font(.headline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(18)
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                controlsVisible.toggle()
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = store.keepScreenAwake
        }
        .onChange(of: store.keepScreenAwake) { _, value in
            UIApplication.shared.isIdleTimerDisabled = value
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .sheet(isPresented: $showingEditor) {
            EditorView()
                .environmentObject(store)
        }
    }
}
