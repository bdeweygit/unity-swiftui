//
//  ContentView.swift
//  UnitySwiftUIDemo
//
//  Created by Benjamin Dewey on 12/24/23.
//

import SwiftUI

struct ContentView: View {
    @State private var playerSize = 0
    @State private var loading = false
    @State private var miniplayerSquare = true
    @State private var UnityContainer: UIViewContainer?
    @State private var miniplayerAlignment = Alignment.top

    var body: some View {
        if let UnityContainer = UnityContainer {
            GeometryReader(content: { geometry in
                ZStack(content: {
                    ZStack(alignment: miniplayerAlignment, content: {
                        Color.clear
                        if playerSize == 0 {
                            UnityContainer.ignoresSafeArea()
                        } else if playerSize == 1 {
                            UnityContainer
                        } else {
                            let halfWidth = geometry.size.width * 0.5
                            let halfHeight = geometry.size.height * 0.5
                            if miniplayerSquare {
                                let minAxis = min(halfWidth, halfHeight)
                                UnityContainer.frame(width: minAxis, height: minAxis)
                            } else {
                                UnityContainer.frame(width: halfWidth, height: halfHeight)
                            }
                        }
                    })
                    VStack(content: {
                        Picker("Player size", selection: $playerSize, content: {
                            Text("Fullscreen").tag(0)
                            Text("Safe area").tag(1)
                            Text("Miniplayer").tag(2)
                        }).pickerStyle(.segmented)
                        if playerSize == 2 {
                            Picker("Miniplayer alignment", selection: $miniplayerAlignment, content: {
                                Text("Top").tag(Alignment.top)
                                Text("Center").tag(Alignment.center)
                                Text("Bottom").tag(Alignment.bottom)
                            }).pickerStyle(.segmented)
                            Picker("Miniplayer shape", selection: $miniplayerSquare, content: {
                                Text("Square").tag(true)
                                Text("Aspect").tag(false)
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
