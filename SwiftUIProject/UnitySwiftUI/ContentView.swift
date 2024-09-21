//
//  ContentView.swift
//  UnitySwiftUI
//
//  Created by Benjamin Dewey on 12/24/23.
//

import SwiftUI

struct ContentView: View {
    @State private var loading = false
    @State private var showState = false
    @State private var showLayout = false
    @State private var display = Display.square
    @State private var alignment = Alignment.top

    @ObservedObject private var unity = Unity.shared

    var body: some View {
        ZStack(alignment: .bottomLeading, content: {
            if loading {
                // Unity is starting up or shutting down
                ProgressView("Loading...").tint(.white).foregroundStyle(.white)
            } else if let UnityContainer = unity.view.flatMap({ UIViewContainer(containee: $0) }) {
                // Unity is running
                switch display {
                case .fullscreen:
                    UnityContainer.ignoresSafeArea()
                case .safearea:
                    UnityContainer
                case .aspect, .square:
                    let isAspect = display == .aspect
                    GeometryReader(content: { geometry in
                        let aspect = geometry.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5))
                        let square = min(aspect.width, aspect.height)
                        let width = isAspect ? aspect.width : square
                        let height = isAspect ? aspect.height : square
                        UnityContainer.frame(width: width, height: height).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                    })
                }
                VStack(alignment: .leading, content: {
                    if showState || showLayout {
                        VStack(content: {
                            if showState {
                                HStack(content: {
                                    Text(String(format: "Scale %.2f", unity.scale))
                                    Slider(value: $unity.scale, in: 1...3)
                                })
                                Picker("Texture", selection: $unity.texture, content: {
                                    Text("Default").tag(Unity.Texture.none)
                                    Text("Marble").tag(Unity.Texture.marble)
                                    Text("Checkerboard").tag(Unity.Texture.checkerboard)
                                })
                                Picker("Spotlight", selection: $unity.spotlight, content: {
                                    Text("Neutral").tag(Unity.LightTemperature.neutral)
                                    Text("Warm").tag(Unity.LightTemperature.warm)
                                    Text("Cool").tag(Unity.LightTemperature.cool)
                                })
                                Picker("Visible", selection: $unity.visible, content: {
                                    Text("Show").tag(true)
                                    Text("Hide").tag(false)
                                })
                            }
                            if showLayout {
                                Picker("Display", selection: $display, content: {
                                    Text("Square").tag(Display.square)
                                    Text("Aspect").tag(Display.aspect)
                                    Text("Safe area").tag(Display.safearea)
                                    Text("Fullscreen").tag(Display.fullscreen)
                                })
                                if display == .aspect || display == .square {
                                    Picker("Alignment", selection: $alignment, content: {
                                        Text("Top").tag(Alignment.top)
                                        Text("Center").tag(Alignment.center)
                                        Text("Bottom").tag(Alignment.bottom)
                                    })
                                }
                            }
                        }).padding().background(CustomButtonStyle.color).clipShape(CustomButtonStyle.shape)
                    }
                    HStack(content: {
                        let stateImage = "cube" + (showState ? ".fill" : "")
                        let layoutImage = "aspectratio" + (showLayout ? ".fill" : "")
                        Button("State", systemImage: stateImage, action: {
                            showState.toggle()
                            showLayout = false
                        })
                        Button("Layout", systemImage: layoutImage, action: {
                            showLayout.toggle()
                            showState = false
                        })
                        Button("Stop Unity", systemImage: "stop", action: {
                            showLayout = false
                            showState = false
                            loading = true
                            DispatchQueue.main.async(execute: {
                                unity.stop()
                                loading = false
                            })
                        })
                    })
                })
            } else {
                // Unity is not running
                Button("Start Unity", systemImage: "play", action: {
                    /* Unity startup is slow and must must occur on the
                       main thread. Use async dispatch so we can re-render
                       with a ProgressView before the UI becomes unresponsive. */
                    loading = true
                    DispatchQueue.main.async(execute: {
                        unity.start()
                        loading = false
                    })
                })
            }
        }).safeAreaPadding().pickerStyle(.segmented).buttonStyle(CustomButtonStyle())
    }
}

fileprivate enum Display {
    case square
    case aspect
    case safearea
    case fullscreen
}

fileprivate struct CustomButtonStyle: PrimitiveButtonStyle {
    static let color = Color(.darkGray)
    static let shape = RoundedRectangle(cornerRadius: 6)
    func makeBody(configuration: Configuration) -> some View {
        BorderedProminentButtonStyle().makeBody(configuration: configuration).tint(CustomButtonStyle.color).clipShape(CustomButtonStyle.shape)
    }
}

/* Make alignment hashable so it can be used as a
   picker selection. We only care about top, center,
   and bottom. Retroactive conformance is a bad practice
   but is much more laconic than writing out a wrapper type. */
extension Alignment: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .top: hasher.combine(0)
        case .center: hasher.combine(1)
        case .bottom: hasher.combine(2)
        default: hasher.combine(3)
        }
    }
}
