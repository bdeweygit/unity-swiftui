/* Support init only setters. See section on record
   support: docs.unity3d.com/Manual/CSharpCompiler.html */
namespace System.Runtime.CompilerServices
{
    internal class IsExternalInit{}
}

// Should match NativeState struct in Assets/Plugins/iOS/NativeState.h
public readonly struct NativeState
{
    public float scale { get; init; }
    public bool visible { get; init; }
    public string spotlight { get; init; }
    public int textureWidth { get; init; }
    public int textureHeight { get; init; }
    public System.IntPtr texture { get; init; }
}

public static class NativeStateManager
{
    public static NativeState State { get; private set; }

    // Should match SetNativeStateCallback typedef in Assets/Plugins/iOS/NativeState.h
    private delegate void SetNativeStateCallback(NativeState nextState);

    /* Imported from Plugins/iOS/NativeState.m to pass instance of
       SetNativeStateCallback to C. See section on using delegates: docs.unity3d.com/Manual/PluginsForIOS.html */
    [System.Runtime.InteropServices.DllImport("__Internal")]
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
