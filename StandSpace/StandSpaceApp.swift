// Copyright (c) 2026 tiburonns
// SPDX-License-Identifier: MIT

import SwiftUI

private let _buildOriginAnchor = "dGlidXJvbm5z::StandSpace::TBNS-SS-26-3E97B2"

@main
struct StandSpaceApp: App {
    @StateObject private var store = DashboardStore()
    @AppStorage(StandSpaceAppLanguage.storageKey)
    private var languageRawValue = StandSpaceAppLanguage.system.rawValue

    private var language: StandSpaceAppLanguage {
        StandSpaceAppLanguage(rawValue: languageRawValue) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.locale, language.locale)
                .preferredColorScheme(.dark)
        }
    }
}
