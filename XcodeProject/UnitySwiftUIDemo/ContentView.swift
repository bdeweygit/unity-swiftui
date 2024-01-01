//
//  ContentView.swift
//  UnitySwiftUIDemo
//
//  Created by Benjamin Dewey on 12/24/23.
//

import SwiftUI

struct ContentView: View {
    @State private var loading = false
    @State private var playerDisplay = 0 // TODO: replace with an enum
    @State private var miniplayerDisplay = 0 // TODO: replace with an enum
    @State private var UnityContainer: UIViewContainer?
    @State private var miniplayerAlignment = Alignment.top

    var body: some View {
        if let UnityContainer = UnityContainer {
            GeometryReader(content: { geometry in
                ZStack(content: {
                    ZStack(alignment: miniplayerAlignment, content: {
                        Color.clear
                        if playerDisplay == 0 { // Fullscreen
                            UnityContainer.ignoresSafeArea()
                        } else if playerDisplay == 1 { // Safe area
                            UnityContainer
                        } else { // Miniplayer
                            let scale = 0.5
                            let width = geometry.size.width * scale
                            let height = geometry.size.height * scale
                            if miniplayerDisplay == 0 { // Square
                                let length = min(width, height)
                                UnityContainer.frame(width: length, height: length)
                            } else { // Aspect
                                UnityContainer.frame(width: width, height: height)
                            }
                        }
                    })
                    VStack(content: {
                        Picker("Player display", selection: $playerDisplay, content: {
                            Text("Fullscreen").tag(0)
                            Text("Safe area").tag(1)
                            Text("Miniplayer").tag(2)
                        }).pickerStyle(.segmented)
                        if playerDisplay == 2 { // Miniplayer
                            Picker("Miniplayer alignment", selection: $miniplayerAlignment, content: {
                                Text("Top").tag(Alignment.top)
                                Text("Center").tag(Alignment.center)
                                Text("Bottom").tag(Alignment.bottom)
                            }).pickerStyle(.segmented)
                            Picker("Miniplayer display", selection: $miniplayerDisplay, content: {
                                Text("Square").tag(0)
                                Text("Aspect").tag(1)
                            }).pickerStyle(.segmented)
                        }
                    }).padding()
                })
            })
        } else {
            if loading {
                ProgressView("Loading...")
            } else {
                Button("Start Unity", action: {
                    /* Create a container view for Unity. This must be done on
                     the main thread which will be blocked while Unity starts. Use
                     async so we can render a ProgressView before the thread blocks. */
                    loading = true
                    DispatchQueue.main.async(execute: {
                        UnityContainer = UIViewContainer(containee: Unity.shared.view)
                        loading = false
                    })
                }).buttonStyle(.borderedProminent)
            }
        }
    }
}

extension Alignment: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .top: hasher.combine(0)
        case .center: hasher.combine(1)
        case .bottom: hasher.combine(2)
        default: hasher.combine(3) // Handle custom alignments if needed
        }
    }
}

#Preview {
    ContentView()
}
