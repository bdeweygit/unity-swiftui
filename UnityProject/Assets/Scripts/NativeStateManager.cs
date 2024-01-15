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
    public float cubeScale { get; init; }
}

public static class NativeStateManager
{
    public static NativeState State { get; private set; }

    // Should match the SetNativeStateCallback typedef in Plugins/iOS/NativeState.h
    private delegate void SetNativeStateCallback(in NativeState nextState);

    // Import C function from plugin
    [System.Runtime.InteropServices.DllImport("__Internal")]
    private static extern void OnSetNativeState(SetNativeStateCallback callback);

    /* Static method that Swift can call by pointer. See section on calling managed
       methods from native code: docs.unity3d.com/Manual/ScriptingRestrictions.html */
    [AOT.MonoPInvokeCallback(typeof(SetNativeStateCallback))]
    private static void SetState(in NativeState nextState) { State = nextState; }

    static NativeStateManager()
    {
        #if !UNITY_EDITOR
            OnSetNativeState(SetState);
        #endif
    }
}
