#import "NativeState.h"

id<SetsNativeState> nativeStateSetter = NULL;

void RegisterNativeStateSetter(id<SetsNativeState> someNativeStateSetter) {
    nativeStateSetter = someNativeStateSetter;
}

void _OnSetNativeState(SetNativeStateCallback callback) {
    nativeStateSetter.setNativeState = callback;
}
