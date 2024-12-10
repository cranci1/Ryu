//
//  RyuApp.swift
//  Ryu
//
//  Created by Francesco on 10/12/24.
//

import SwiftUI

@main
struct RyuApp: App {
    @StateObject private var settings = Settings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .accentColor(settings.accentColor)
                .onAppear {
                    settings.updateAppearance()
                }
        }
    }
}