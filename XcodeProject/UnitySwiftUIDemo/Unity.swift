//
//  Unity.swift
//  UnitySwiftUIDemo
//
//  Created by Benjamin Dewey on 12/24/23.
//

import UnityFramework

class Unity: SetsNativeState {
    /* UnityFramework is implemented as a singleton class so
     we will do the same. Singleton init is lazy and thread safe. */
    static let shared = Unity()
    private let framework: UnityFramework

    private init() {
        // Load framework and get the singleton instance
        let bundle = Bundle(path: "\(Bundle.main.bundlePath)/Frameworks/UnityFramework.framework")!
        bundle.load()
        self.framework = bundle.principalClass!.getInstance()!

        // Set header for framework's CrashReporter; is this needed?
        let machineHeader = UnsafeMutablePointer<MachHeader>.allocate(capacity: 1)
        machineHeader.pointee = _mh_execute_header
        self.framework.setExecuteHeader(machineHeader)

        // Set bundle containing framework's data folder
        self.framework.setDataBundleId("com.unity3d.framework")

        // Register as the native state setter
        /* Note that we have disabled the Thread Performance Checker in the UnitySwiftUIDemo
         scheme or else the mere presence of this line will instigate a crash before our code
         even executes when running via Xcode. The Unity-iPhone scheme also has the Thread
         Performance Checker disabled by default, perhaps for the same reason. See forum discussion:
         forum.unity.com/threads/unity-2021-3-6f1-xcode-14-ios-16-problem-unityframework-crash-before-main.1338284/ */
        RegisterNativeStateSetter(self)

        // Start the player
        self.framework.runEmbedded(withArgc: CommandLine.argc, argv: CommandLine.unsafeArgv, appLaunchOpts: nil)

        // Unity claims the key window so let user interactions passthrough to our window
        self.framework.appController().window.isUserInteractionEnabled = false
    }

    var view: UIView { self.framework.appController().rootView }

    /* This will point to a C# function in Unity once a script
     calls the NativeState plugin's _OnSetNativeState function */
    var setNativeState: SetNativeStateCallback?
}
