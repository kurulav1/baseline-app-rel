//
//  simpl3App.swift
//  simpl3
//
//  Created by Väinö Kurula on 7.5.2023.
//

import SwiftUI

@main
struct simpl3App: App {
    @State var isLoggedIn = false
    @StateObject var appViewModel = AppViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
            .environmentObject(appViewModel)
        }
    }
}
