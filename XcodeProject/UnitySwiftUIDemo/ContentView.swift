//
//  ContentView.swift
//  UnitySwiftUIDemo
//
//  Created by Benjamin Dewey on 12/24/23.
//

import SwiftUI
import MetalKit
import UnityFramework

fileprivate var marbleTexture: MTLTexture!
fileprivate var checkerboardTexture: MTLTexture!
fileprivate var UnityContainer: UIViewContainer!

fileprivate enum LoadingState {
    case unloaded
    case loading
    case loaded
}
fileprivate enum Display {
    case fullscreen
    case safearea
    case aspect
    case square
}
fileprivate enum Texture {
    case none
    case marble
    case checkerboard

    var instance: MTLTexture? {
        return switch self {
        case .none: nil
        case .marble: marbleTexture!
        case .checkerboard: checkerboardTexture!
        }
    }
}
fileprivate enum LightTemperature: String {
    case neutral = "#ffffff"
    case warm = "#ff9100"
    case cool = "#7dcfff"
}

struct CustomButtonStyle: PrimitiveButtonStyle {
    static let color = Color(.darkGray)
    static let shape = RoundedRectangle(cornerRadius: 6)
    func makeBody(configuration: Configuration) -> some View {
        BorderedProminentButtonStyle().makeBody(configuration: configuration).tint(CustomButtonStyle.color).clipShape(CustomButtonStyle.shape)
    }
}

struct ContentView: View {
    @State private var showState = false
    @State private var showLayout = false
    @State private var progress = LoadingState.unloaded
    @State private var playerDisplay = Display.fullscreen
    @State private var miniplayerAlignment = Alignment.top

    // State that is sent to Unity
    @State private var visible = true
    @State private var scale: Float = 1
    @State private var texture = Texture.none
    @State private var spotlight = LightTemperature.neutral

    private func sendStateToUnity() {
        let texture = self.texture.instance
        let textureWidth = CInt(texture?.width ?? 0)
        let textureHeight = CInt(texture?.height ?? 0)
        let unmanagedTexture = texture.flatMap({ Unmanaged.passUnretained($0) })
        self.spotlight.rawValue.withCString({ spotlight in
            let nativeState = NativeState(scale: scale, visible: visible, spotlight: spotlight, textureWidth: textureWidth, textureHeight: textureHeight, texture: unmanagedTexture)
            Unity.shared.setNativeState?(nativeState)
        })
    }

    var body: some View {
        ZStack(alignment: .bottomLeading, content: {
            switch progress {
            case .unloaded:
                Button("Start Unity", systemImage: "play", action: {
                    // We have multiple things to load.
                    progress = .loading
                    let loadingGroup = DispatchGroup()

                    /* Create a container view for Unity's UIView. This will cause
                       Unity to load which must occur on the main thread. Use async so we
                       can re-render with updated progress before the UI becomes unresponsive. */
                    DispatchQueue.main.async(group: loadingGroup, execute: {
                        UnityContainer = UIViewContainer(containee: Unity.shared.view)
                    })

                    // Load textures concurrently.
                    let concurrentQueue = DispatchQueue.global(qos: .userInitiated)
                    concurrentQueue.async(group: loadingGroup, execute: {
                        marbleTexture = Bundle.main.url(forResource: "marble", withExtension: "jpg")!.loadTexture()
                    })
                    concurrentQueue.async(group: loadingGroup, execute: {
                        checkerboardTexture = Bundle.main.url(forResource: "checkerboard", withExtension: "png")!.loadTexture()
                    })

                    loadingGroup.notify(queue: .main, execute: { progress = .loaded })
                })
            case .loading:
                ProgressView("Loading...").tint(.white).foregroundStyle(.white)
            case .loaded:
                switch playerDisplay {
                case .fullscreen:
                    UnityContainer.ignoresSafeArea()
                case .safearea:
                    UnityContainer
                case .aspect, .square:
                    let isAspect = playerDisplay == .aspect
                    GeometryReader(content: { geometry in
                        let aspect = geometry.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5))
                        let square = min(aspect.width, aspect.height)
                        let width = isAspect ? aspect.width : square
                        let height = isAspect ? aspect.height : square
                        UnityContainer.frame(width: width, height: height).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: miniplayerAlignment)
                    })
                }
                VStack(alignment: .leading, content: {
                    if showState || showLayout {
                        VStack(content: {
                            if showState {
                                    HStack(content: {
                                        Text(String(format: "Scale %.2f", scale))
                                        Slider(value: $scale, in: 1...3)
                                    })
                                    Picker("Texture", selection: $texture, content: {
                                        Text("Default").tag(Texture.none)
                                        Text("Marble").tag(Texture.marble)
                                        Text("Checkerboard").tag(Texture.checkerboard)
                                    })
                                    Picker("Spotlight", selection: $spotlight, content: {
                                        Text("Neutral").tag(LightTemperature.neutral)
                                        Text("Warm").tag(LightTemperature.warm)
                                        Text("Cool").tag(LightTemperature.cool)
                                    })
                                    Picker("Visible", selection: $visible, content: {
                                        Text("Show").tag(true)
                                        Text("Hide").tag(false)
                                    })
                            }
                            if showLayout {
                                Picker("Player display", selection: $playerDisplay, content: {
                                    Text("Fullscreen").tag(Display.fullscreen)
                                    Text("Safe area").tag(Display.safearea)
                                    Text("Aspect").tag(Display.aspect)
                                    Text("Square").tag(Display.square)
                                })
                                if playerDisplay == .aspect || playerDisplay == .square {
                                    Picker("Miniplayer alignment", selection: $miniplayerAlignment, content: {
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
                    })
                })
            }
        }).safeAreaPadding().pickerStyle(.segmented).buttonStyle(CustomButtonStyle())
        .onChange(of: scale, sendStateToUnity)
        .onChange(of: texture, sendStateToUnity)
        .onChange(of: visible, sendStateToUnity)
        .onChange(of: spotlight, sendStateToUnity)
        // TODO: Find DRYer way to receive state updates
    }
}

/* Make alignment hashable so it can be used as a
   picker selection. We only care about top, center, and bottom. */
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

extension URL {
    func loadTexture() -> MTLTexture {
        let device = MTLCreateSystemDefaultDevice()!
        let loader = MTKTextureLoader(device: device)
        return try! loader.newTexture(URL: self)
    }
}
