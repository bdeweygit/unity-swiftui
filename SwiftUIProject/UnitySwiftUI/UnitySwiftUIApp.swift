//
//  UnitySwiftUIApp.swift
//  UnitySwiftUI
//
//  Created by Benjamin Dewey on 12/24/23.
//

import SwiftUI

@main
struct UnitySwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack(content: {
                Color.gray.ignoresSafeArea()
                ContentView()
            })
        }
    }
}
