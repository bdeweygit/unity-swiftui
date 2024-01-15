struct NativeState {
    float cubeScale;
};

typedef void (*SetNativeStateCallback)(const struct NativeState* nextState);

@protocol SetsNativeState
    /* This is the critical method that will be used to send state from Swift to Unity.
       Encapsulation within a protocol lets us take advantage of Swift's didSet property observer. */
    @required @property SetNativeStateCallback setNativeState;
@end

__attribute__ ((visibility("default")))
void RegisterNativeStateSetter(id<SetsNativeState> setter);
