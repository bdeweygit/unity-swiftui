using System.Runtime.InteropServices;

// Should match NativeState struct in Assets/Plugins/iOS/NativeState.h
public readonly struct NativeState
{
    public readonly float scale;
    [MarshalAs(UnmanagedType.U1)] // 1-byte native C bool
    public readonly bool visible;
    public readonly string spotlight;
    public readonly int textureWidth;
    public readonly int textureHeight;
    public readonly System.IntPtr texture;
}

public static class NativeStateManager
{
    public static NativeState State { get; private set; }

    // Should match SetNativeStateCallback typedef in Assets/Plugins/iOS/NativeState.h
    private delegate void SetNativeStateCallback(NativeState nextState);

    /* Imported from Plugins/iOS/NativeState.m to pass instance of
       SetNativeStateCallback to C. See section on using delegates: docs.unity3d.com/Manual/PluginsForIOS.html */
    [DllImport("__Internal")]
    private static extern void OnSetNativeState(SetNativeStateCallback callback);

    /* Reverse P/Invoke wrapped method to set state value. iOS is an AOT platform hence the decorator.
       See section on calling managed methods from native code: docs.unity3d.com/Manual/ScriptingRestrictions.html */
    [AOT.MonoPInvokeCallback(typeof(SetNativeStateCallback))]
    private static void SetState(NativeState nextState) { State = nextState; }

    static NativeStateManager()
    {
        #if !UNITY_EDITOR
            OnSetNativeState(SetState);
        #endif
    }
}
