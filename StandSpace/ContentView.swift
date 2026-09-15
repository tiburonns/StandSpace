import Combine
import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: DashboardStore

    @State private var lastInteraction = Date()
    @State private var isDimmed = false
    @State private var pixelShift: CGSize = .zero

    private let inactivityTimer = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        ZStack {
            store.backgroundStyle.background
                .ignoresSafeArea()

            DashboardView(
                onInteraction: registerInteraction
            )
            .offset(
                x: store.oledProtectionEnabled
                    ? pixelShift.width
                    : 0,
                y: store.oledProtectionEnabled
                    ? pixelShift.height
                    : 0
            )

            Color.black
                .opacity(
                    isDimmed
                        ? dimOpacity
                        : 0
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .animation(
                    .easeInOut(duration: 0.8),
                    value: isDimmed
                )
        }
        .onReceive(inactivityTimer) { now in
            if store.oledProtectionEnabled {
                pixelShift = oledShift(
                    for: now
                )
            } else if pixelShift != .zero {
                pixelShift = .zero
            }

            guard store.autoDimEnabled else {
                if isDimmed {
                    isDimmed = false
                }
                return
            }

            if now.timeIntervalSince(
                lastInteraction
            ) >= autoDimDelay {
                isDimmed = true
            }
        }
        .onAppear {
            UIApplication.shared
                .isIdleTimerDisabled =
                store.keepScreenAwake

            pixelShift = oledShift(
                for: Date()
            )
            registerInteraction()
        }
        .onChange(
            of: store.keepScreenAwake
        ) { _, value in
            UIApplication.shared
                .isIdleTimerDisabled = value
        }
        .onChange(
            of: store.autoDimEnabled
        ) { _, enabled in
            if !enabled {
                isDimmed = false
            } else {
                registerInteraction()
            }
        }
        .onChange(
            of: store.oledProtectionEnabled
        ) { _, enabled in
            pixelShift = enabled
                ? oledShift(for: Date())
                : .zero
        }
        .onChange(
            of: store.selectedSpaceID
        ) { _, _ in
            registerInteraction()
        }
        .onDisappear {
            UIApplication.shared
                .isIdleTimerDisabled = false
        }
    }

    private var autoDimDelay: TimeInterval {
        switch store.activeSpace.kind {
        case .night:
            return 15
        case .desk, .work, .kitchen:
            return 45
        }
    }

    private var dimOpacity: Double {
        switch store.activeSpace.kind {
        case .night:
            return 0.62
        case .desk, .work, .kitchen:
            return 0.38
        }
    }

    private func registerInteraction() {
        lastInteraction = Date()

        if isDimmed {
            isDimmed = false
        }
    }

    private func oledShift(
        for date: Date
    ) -> CGSize {
        guard store.oledProtectionEnabled
        else {
            return .zero
        }

        let minute = Calendar.current
            .component(.minute, from: date)

        let pattern: [CGSize] = [
            .zero,
            CGSize(width: 1.5, height: 0),
            CGSize(width: 1.5, height: 1.5),
            CGSize(width: 0, height: 1.5),
            CGSize(width: -1.5, height: 1.5),
            CGSize(width: -1.5, height: 0),
            CGSize(width: -1.5, height: -1.5),
            CGSize(width: 0, height: -1.5),
            CGSize(width: 1.5, height: -1.5)
        ]

        let step =
            (minute / 2) % pattern.count

        return pattern[step]
    }
}
