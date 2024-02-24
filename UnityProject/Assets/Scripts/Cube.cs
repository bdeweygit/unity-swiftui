using UnityEngine;

public class Cube : MonoBehaviour
{
    void Update()
    {
        NativeState state = NativeStateManager.State;

        // Compute next state
        bool nextEnabled = state.visible;
        Vector3 nextLocalScale = new Vector3(state.scale, state.scale, state.scale);
        Color nextColor;
        ColorUtility.TryParseHtmlString(state.spotlight, out nextColor);
        Texture2D nextMainTexture = null;
        if (state.texture != System.IntPtr.Zero) {
            /* In practice it looks like our values for width and height are ignored.
               It probably determines correct values from the native MTLTexture's own properties.
               Documentation still insists that we pass the correct width and height values, so we will.*/
            nextMainTexture = Texture2D.CreateExternalTexture(state.textureWidth, state.textureHeight, TextureFormat.BGRA32, false, false, state.texture);
        }

        // Update state
        GetComponent<Renderer>().enabled = nextEnabled;
        transform.localScale = nextLocalScale;
        GameObject.Find("Spotlight").GetComponent<Light>().color = nextColor;
        GetComponent<Renderer>().material.mainTexture = nextMainTexture;

        // Respond to single touches only
        if (Input.touchCount == 1)
        {
            // Rotate in the same direction as the touch delta
            Vector2 delta = Input.GetTouch(0).deltaPosition * 0.1f;
            transform.Rotate(delta.y, -delta.x, 0, Space.World);
        }
    }
}
