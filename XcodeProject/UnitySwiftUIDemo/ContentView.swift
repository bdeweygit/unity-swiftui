//
//  ContentView.swift
//  UnitySwiftUIDemo
//
//  Created by Benjamin Dewey on 12/24/23.
//

import SwiftUI

struct ContentView: View {
    @State private var fullscreen = true
    @State private var ignoreSafeArea = true
    @State private var miniplayerSquare = true
    @State private var miniplayerAlignment = Alignment.top

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack(alignment: miniplayerAlignment) {
                    Color.clear
                    UnityView().if(fullscreen && ignoreSafeArea, transform: { view in
                        view.ignoresSafeArea()
                    }).if(!fullscreen && miniplayerSquare, transform: { view in
                        view.frame(width: 200, height: 200)
                    }).if(!fullscreen && !miniplayerSquare, transform: { view in
                        view.frame(width: geometry.size.width * 0.5, height: geometry.size.height * 0.5)
                    })
                }
                VStack {
                    Picker("Player size", selection: $fullscreen) {
                        Text("Fullscreen").tag(true)
                        Text("Miniplayer").tag(false)
                    }.pickerStyle(.segmented)
                    if fullscreen {
                        Picker("Fullscreen fill", selection: $ignoreSafeArea) {
                            Text("Full area").tag(true)
                            Text("Safe area").tag(false)
                        }.pickerStyle(.segmented)
                    } else {
                        Picker("Miniplayer alignment", selection: $miniplayerAlignment) {
                            Text("Top").tag(Alignment.top)
                            Text("Center").tag(Alignment.center)
                            Text("Bottom").tag(Alignment.bottom)
                        }.pickerStyle(.segmented)
                        Picker("Miniplayer shape", selection: $miniplayerSquare) {
                            Text("Square").tag(true)
                            Text("Aspect").tag(false)
                        }.pickerStyle(.segmented)
                    }
                }.padding()
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

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    ContentView()
}
