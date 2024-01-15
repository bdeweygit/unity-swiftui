#import "NativeState.h"

id<SetsNativeState> nativeStateSetter;

// Called from Swift. Can we hide this from the C# dll import?
void RegisterNativeStateSetter(id<SetsNativeState> setter) {
    nativeStateSetter = setter;
}

/* Called from Unity. Interop marshals the argument from a C# delegate to a C function pointer.
   See section on marshalling delegates:
   learn.microsoft.com/en-us/dotnet/framework/interop/default-marshalling-behavior */
void OnSetNativeState(SetNativeStateCallback callback) {
    nativeStateSetter.setNativeState = callback;
}
