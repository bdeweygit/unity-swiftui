using System.ComponentModel;

/* Support init only setters. See section on record
   support: docs.unity3d.com/Manual/CSharpCompiler.html */
namespace System.Runtime.CompilerServices
{
    [EditorBrowsable(EditorBrowsableState.Never)]
    internal class IsExternalInit{}
}

// Should match the NativeState struct in Plugins/iOS/NativeState.h
public readonly struct NativeState
{
    public float scale { get; init; }
    public int textureWidth { get; init; }
    public int textureHeight { get; init; }
    public System.IntPtr texture { get; init; }
}

public static class NativeStateManager
{
    public static NativeState State { get; private set; }

    // Should match the SetNativeStateCallback typedef in Plugins/iOS/NativeState.h
    private delegate void SetNativeStateCallback(in NativeState nextState);

    /* Imported from Plugins/iOS/NativeState.m to pass an instance of
       SetNativeStateCallback to C. See section on using delegates: docs.unity3d.com/Manual/PluginsForIOS.html */
    [System.Runtime.InteropServices.DllImport("__Internal")]
    private static extern void OnSetNativeState(SetNativeStateCallback callback);

    /* Reverse P/Invoke wrapped method to set the state value. iOS is an AOT platform hence the decorator.
       See section on calling managed methods from native code: docs.unity3d.com/Manual/ScriptingRestrictions.html */
    [AOT.MonoPInvokeCallback(typeof(SetNativeStateCallback))]
    private static void SetState(in NativeState nextState) { State = nextState; }

    static NativeStateManager()
    {
        #if !UNITY_EDITOR
            OnSetNativeState(SetState);
        #endif
    }
}
