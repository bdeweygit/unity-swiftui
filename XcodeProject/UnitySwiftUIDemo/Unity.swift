//
//  Unity.swift
//  UnitySwiftUIDemo
//
//  Created by Benjamin Dewey on 12/24/23.
//

import MetalKit
import UnityFramework

class Unity: SetsNativeState, ObservableObject  {
    /* UnityFramework's principal class is implemented as a singleton
       so we will do the same. Singleton init is lazy and thread safe. */
    static let shared = Unity()

    // MARK: Lifecycle

    private var loaded = false
    private let framework: UnityFramework

    private init() {
        // Load framework and get the singleton instance
        let bundle = Bundle(path: "\(Bundle.main.bundlePath)/Frameworks/UnityFramework.framework")!
        bundle.load()
        framework = bundle.principalClass!.getInstance()!

        // Set header for framework's CrashReporter; is this needed?
        let machineHeader = UnsafeMutablePointer<MachHeader>.allocate(capacity: 1)
        machineHeader.pointee = _mh_execute_header
        framework.setExecuteHeader(machineHeader)

        // Set bundle containing framework's data folder
        framework.setDataBundleId("com.unity3d.framework")

        /* Register as the native state setter. Note we have disabled the
           Thread Performance Checker in the UnitySwiftUIDemo scheme or else the mere
           presence of this line will instigate a crash before our code executes when
           running from Xcode. The Unity-iPhone scheme also has the Thread Performance
           Checker disabled by default, perhaps for the same reason. See forum discussion:
           forum.unity.com/threads/unity-2021-3-6f1-xcode-14-ios-16-problem-unityframework-crash-before-main.1338284/ */
        RegisterNativeStateSetter(self)
    }

    func start() {
        // Load native state textures concurrently
        let loadingGroup = DispatchGroup()
        DispatchQueue.global().async(group: loadingGroup, execute: { [self] in
            let url = Bundle.main.url(forResource: "marble", withExtension: "jpg")
            marbleTexture = marbleTexture ?? url?.loadTexture()
        })
        DispatchQueue.global().async(group: loadingGroup, execute: { [self] in
            let url = Bundle.main.url(forResource: "checkerboard", withExtension: "png")
            checkerboardTexture = checkerboardTexture ?? url?.loadTexture()
        })
        loadingGroup.wait()

        // Start the player
        framework.runEmbedded(withArgc: CommandLine.argc, argv: CommandLine.unsafeArgv, appLaunchOpts: nil)

        // Hide Unity's UIWindow so it won't display UIView or intercept touches
        framework.appController().window.isHidden = true

        loaded = true
    }

    func stop() {
        // docs.unity3d.com/ScriptReference/Application.Unload.html
        framework.unloadApplication()
        loaded = false
    }

    // Expose Unity's UIView while loaded
    var view: UIView? { loaded ? framework.appController().rootView : nil }

    // MARK: Native State

    enum Texture {
        case none
        case marble
        case checkerboard
    }
    enum LightTemperature: String {
        case neutral = "#ffffff"
        case warm = "#ff9100"
        case cool = "#7dcfff"
    }

    private var marbleTexture: MTLTexture?
    private var checkerboardTexture: MTLTexture?
    @Published var visible = true { didSet { stateDidSet() } }
    @Published var scale: Float = 1 { didSet { stateDidSet() } }
    @Published var texture = Texture.none { didSet { stateDidSet() } }
    @Published var spotlight = LightTemperature.neutral { didSet { stateDidSet() } }

    private func stateDidSet() {
        let textureInstance: MTLTexture? = switch texture {
        case .none: nil
        case .marble: marbleTexture
        case .checkerboard: checkerboardTexture
        }
        let textureWidth_C = CInt(textureInstance?.width ?? 0)
        let textureHeight_C = CInt(textureInstance?.height ?? 0)
        let texture_C = textureInstance.flatMap({ Unmanaged.passUnretained($0) })
        spotlight.rawValue.withCString({ spotlight_C in
            let nativeState = NativeState(scale: scale, visible: visible, spotlight: spotlight_C, textureWidth: textureWidth_C, textureHeight: textureHeight_C, texture: texture_C)
            setNativeState?(nativeState)
        })
    }

    /* When a Unity script calls the NativeState plugin's OnSetNativeState function this
       closure will be set to a C function pointer that was marshaled from a corresponding
       C# delegate. See section on using delegates: docs.unity3d.com/Manual/PluginsForIOS.html */
    var setNativeState: SetNativeStateCallback? {
        didSet {
            if setNativeState != nil {
                /* We can now send state to Unity. We should assume
                   Unity needs it immediately, so set the current state now. */
                stateDidSet()
            }
        }
    }
}

// MARK: Extensions

extension URL {
    func loadTexture() -> MTLTexture? {
        let device = MTLCreateSystemDefaultDevice()!
        let loader = MTKTextureLoader(device: device)
        return try? loader.newTexture(URL: self)
    }
}
