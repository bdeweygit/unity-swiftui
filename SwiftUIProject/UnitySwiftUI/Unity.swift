//
//  Unity.swift
//  UnitySwiftUI
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

        /* Send our executable's header data to Unity's CrashReporter.
           Using _mh_execute_header might be more correct, but this is broken on
           Xcode 16. See forum discussion: forums.developer.apple.com/forums/thread/760543 */
        let executeHeader = #dsohandle.assumingMemoryBound(to: MachHeader.self)
        framework.setExecuteHeader(executeHeader)

        // Set bundle containing Unity's data folder
        framework.setDataBundleId("com.unity3d.framework")

        /* Register as the native state setter. We have disabled the
           Thread Performance Checker in the UnitySwiftUI scheme or else the mere
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

        /* Unity finishes starting - runEmbedded() returns - before completing
           its first render. If the view is displayed immediately it often shows the
           content leftover from the previous run until Unity renders again and overwrites it.
           Clearing Unity's layer with transparent color before restart hides this brief artifact. */
        if let layer = framework.appController()?.rootView?.layer as? CAMetalLayer, let drawable = layer.nextDrawable(), let buffer = MTLCreateSystemDefaultDevice()?.makeCommandQueue()?.makeCommandBuffer() {
            let descriptor = MTLRenderPassDescriptor()
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].storeAction = .store
            descriptor.colorAttachments[0].texture = drawable.texture
            descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
            /* Unity does not render an alpha value by default; transparent is written
               as opaque. To fix this we have enabled "Render Over Native UI" in the Unity
               project player settings. This is an alias for the preserveFramebufferAlpha scripting
               property: docs.unity3d.com/ScriptReference/PlayerSettings-preserveFramebufferAlpha.html */

            if let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) {
                encoder.label = "Unity Prestart Clear"
                encoder.endEncoding()
                buffer.present(drawable)
                buffer.commit()
                buffer.waitUntilCompleted()
            }
        }

        // Start Unity
        framework.runEmbedded(withArgc: CommandLine.argc, argv: CommandLine.unsafeArgv, appLaunchOpts: nil)

        // Hide Unity's UIWindow so it won't display UIView or intercept touches
        framework.appController().window.isHidden = true

        loaded = true
    }

    func stop() {
        // docs.unity3d.com/ScriptReference/Application.Unload.html
        framework.unloadApplication()

        /* We could unload native state textures here too, but on restart
           we will have to ensure Unity does not have any texture reference else reading
           will result in a null pointer exception. For now we will leave the memory as allocated. */

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
