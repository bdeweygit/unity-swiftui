//
//  ContentView.swift
//  UnitySwiftUIDemo
//
//  Created by Benjamin Dewey on 12/24/23.
//

import SwiftUI
import MetalKit
import UnityFramework

fileprivate var marble: MTLTexture!
fileprivate var checkerboard: MTLTexture!
fileprivate var UnityContainer: UIViewContainer!

fileprivate enum Texture {
    case none
    case marble
    case checkerboard
}
fileprivate enum LoadingState {
    case unloaded
    case loading
    case loaded
}

struct ContentView: View {
    @State private var scale: Float = 1
    @State private var playerDisplay = 0 // TODO: replace with an enum
    @State private var miniplayerDisplay = 0 // TODO: replace with an enum
    @State private var texture = Texture.none
    @State private var progress = LoadingState.unloaded
    @State private var miniplayerAlignment = Alignment.top

    private func sendStateToUnity() {
        let texture: MTLTexture? = switch self.texture {
        case .none: nil
        case .marble: marble
        case .checkerboard: checkerboard
        }

        let textureWidth = Int32(texture?.width ?? 0)
        let textureHeight = Int32(texture?.height ?? 0)
        let unmanagedTexture = texture.flatMap({ Unmanaged.passUnretained($0) })

        var nativeState = NativeState(scale: scale, textureWidth: textureWidth, textureHeight: textureHeight, texture: unmanagedTexture)
        Unity.shared.setNativeState?(&nativeState)
    }

    var body: some View {
        switch progress {
        case .unloaded:
            Button("Start Unity", action: {
                // We have multiple things to load.
                let loadingGroup = DispatchGroup()

                /* Create a container view for Unity's UIView. This will cause
                   Unity to load which must occur on the main thread. Use async so
                   we can update progress and re-render before the UI becomes unresponsive. */
                DispatchQueue.main.async(group: loadingGroup, execute: {
                    UnityContainer = UIViewContainer(containee: Unity.shared.view)
                })

                // Load textures concurrently.
                let concurrentQueue = DispatchQueue.global(qos: .userInitiated)
                concurrentQueue.async(group: loadingGroup, execute: {
                    marble = Bundle.main.url(forResource: "marble", withExtension: "jpg")!.loadTexture()
                })
                concurrentQueue.async(group: loadingGroup, execute: {
                    checkerboard = Bundle.main.url(forResource: "checkerboard", withExtension: "png")!.loadTexture()
                })

                progress = .loading
                loadingGroup.notify(queue: .main, execute: { progress = .loaded })
            }).buttonStyle(.borderedProminent)
        case .loading:
            ProgressView("Loading...")
        case .loaded:
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
                        Spacer()
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
                        HStack(content: {
                            Text(String(format: "Scale %.2f", scale))
                            Slider(value: $scale, in: 1...3)
                        })
                        Picker("Texture", selection: $texture, content: {
                            Text("None").tag(Texture.none)
                            Text("Marble").tag(Texture.marble)
                            Text("Checkerboard").tag(Texture.checkerboard)
                        }).pickerStyle(.segmented)
                    }).padding()
                })
            })
            .onChange(of: scale, sendStateToUnity)
            .onChange(of: texture, sendStateToUnity)
        }
    }
}

extension URL {
    func loadTexture() -> MTLTexture {
        let device = MTLCreateSystemDefaultDevice()!
        let loader = MTKTextureLoader(device: device)
        return try! loader.newTexture(URL: self)
    }
}

/* Make alignment hashable so it can be used as a
   Picker selection. We only care about top, center, and bottom. */
extension Alignment: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .top: hasher.combine(0)
        case .center: hasher.combine(1)
        case .bottom: hasher.combine(2)
        default: hasher.combine(3)
        }
    }
}

#Preview {
    ContentView()
}
