typedef void (*SetNativeStateCallback)(const char* nativeStateJSON);

@protocol SetsNativeState
    @required @property SetNativeStateCallback setNativeState;
@end

__attribute__ ((visibility("default")))
void RegisterNativeStateSetter(id<SetsNativeState> someNativeStateSetter);
