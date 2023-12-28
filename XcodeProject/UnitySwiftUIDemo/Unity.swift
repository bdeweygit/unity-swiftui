//
//  Unity.swift
//  UnitySwiftUIDemo
//
//  Created by Benjamin Dewey on 12/24/23.
//

import UnityFramework

class Unity: SetsNativeState {
    static let shared = Unity() // Singleton init is lazy and thread safe
    private let framework: UnityFramework
    private var observation: NSKeyValueObservation?

    private init() {
        // Load unity framework
        let bundle = Bundle(path: "\(Bundle.main.bundlePath)/Frameworks/UnityFramework.framework")!
        bundle.load()
        self.framework = bundle.principalClass!.getInstance()!

        // Set header for unity CrashReporter; is this needed?
        let machineHeader = UnsafeMutablePointer<MachHeader>.allocate(capacity: 1)
        machineHeader.pointee = _mh_execute_header
        self.framework.setExecuteHeader(machineHeader)

        // Set bundle containing unity's data folder
        self.framework.setDataBundleId("com.unity3d.framework")

        // Register as the native state setter
        /* Note that we have disabled the Thread Performance Checker in the UnitySwiftUIDemo scheme
         or else the mere presence of this line will instigate a crash before our code even executes
         when running via Xcode. The Unity-iPhone scheme also has the Thread Performance Checker
         disabled by default, perhaps for the same reason. See forum discussion: forum.unity.com/threads/unity-2021-3-6f1-xcode-14-ios-16-problem-unityframework-crash-before-main.1338284/ */
        RegisterNativeStateSetter(self)

        // Start the player; runEmbedded also calls framework.showUnityWindow internally
        self.framework.runEmbedded(withArgc: CommandLine.argc, argv: CommandLine.unsafeArgv, appLaunchOpts: nil)

        // Unity claims the key window so let user interactions passthrough to our window
        self.framework.appController().window.isUserInteractionEnabled = false
    }

    var superview: UIView? {
        didSet {
            // Remove old observation
            observation?.invalidate()

            if superview == nil {
                self.framework.appController().window.rootViewController?.view.removeFromSuperview()
            } else {
                // Register new observation; it fires on register and on new value at .rootViewController
                observation = self.framework.appController().window.observe(\.rootViewController, options: [.initial], changeHandler: { [weak self] (window, _) in
                    /* The rootViewController of Unity's window has just been assigned
                     so now is the proper moment to apply our superview if we have one */
                    if let superview = self?.superview, let view = window.rootViewController?.view {
                        superview.addSubview(view)
                        view.frame = superview.frame
                    }
                })
            }
        }
    }

    /* This will point to a C# function in unity once a script calls
     the NativeState plugin's _OnSetNativeState function */
    var setNativeState: SetNativeStateCallback?
}
