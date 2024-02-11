#import <Metal/MTLTexture.h>

struct NativeState {
    float scale;
    bool visible;
    int textureWidth;
    int textureHeight;
    __unsafe_unretained id<MTLTexture> _Nullable texture;
};

typedef void (*SetNativeStateCallback)(const struct NativeState nextState);

@protocol SetsNativeState
/* This is the critical function pointer that will be used to send state from Swift to Unity.
   Encapsulation within a protocol will let us take advantage of Swift's didSet property observer. */
@property (nullable) SetNativeStateCallback setNativeState;
@end

__attribute__ ((visibility("default")))
void RegisterNativeStateSetter(id<SetsNativeState> _Nonnull setter);
