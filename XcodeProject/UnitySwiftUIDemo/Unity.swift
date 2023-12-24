//
//  Unity.swift
//  UnitySwiftUIDemo
//
//  Created by Benjamin Dewey on 12/24/23.
//

import UnityFramework

class Unity: SetsNativeState {
    static let shared = Unity() // singleton init is lazy and thread safe
    private let framework: UnityFramework
    private var observation: NSKeyValueObservation?

    private init() {
        // load unity framework
        let bundle = Bundle(path: "\(Bundle.main.bundlePath)/Frameworks/UnityFramework.framework")!
        bundle.load()
        self.framework = bundle.principalClass!.getInstance()!

        // set header for unity CrashReporter - is this needed?
        let machineHeader = UnsafeMutablePointer<MachHeader>.allocate(capacity: 1)
        machineHeader.pointee = _mh_execute_header
        self.framework.setExecuteHeader(machineHeader)

        // set bundle containing unity's data folder
        self.framework.setDataBundleId("com.unity3d.framework")

        // register as the native state setter
        // note that Thread Performance Checker has been disabled in the UnitySwiftUIDemo scheme or else the mere presence, not the execution, of this line will cause a crash when running via Xcode
        // see forum.unity.com/threads/unity-2021-3-6f1-xcode-14-ios-16-problem-unityframework-crash-before-main.1338284/
        RegisterNativeStateSetter(self)

        // start the player; runEmbedded also calls framework.showUnityWindow internally
        self.framework.runEmbedded(withArgc: CommandLine.argc, argv: CommandLine.unsafeArgv, appLaunchOpts: nil)

        // unity claims the key window, so let user interactions passthrough to our window
        self.framework.appController().window.isUserInteractionEnabled = false
    }

    var superview: UIView? {
        didSet {
            // remove old observation
            observation?.invalidate()

            if superview == nil {
                self.framework.appController().window.rootViewController?.view.removeFromSuperview()
            } else {
                // register new observation; it fires on register and on new value at .rootViewController
                observation = self.framework.appController().window.observe(\.rootViewController, options: [.initial], changeHandler: { [weak self] (window, _) in
                    if let superview = self?.superview, let view = window.rootViewController?.view {
                        // the rootViewController of Unity's window has been assigned
                        // now is the proper moment to apply our superview if we have one
                        superview.addSubview(view)
                        view.frame = superview.frame
                    }
                })
            }
        }
    }

    // will point to a C# function in unity once a script calls
    // the NativeState plugin's _OnSetNativeState function
    var setNativeState: SetNativeStateCallback?
}
