using UnityEngine;
using UnityEngine.UI;

public class RootBehavior : MonoBehaviour
{
    public Canvas canvas;
    public Sprite sprite;
    public Light spotlight;
    public GameObject cube;
    private GameObject touchIndicator;

    void Update()
    {
        // Create next state
        NativeState state = NativeStateManager.State;
        Vector3 nextLocalScale = new Vector3(state.scale, state.scale, state.scale);
        Color nextColor;
        ColorUtility.TryParseHtmlString(state.spotlight, out nextColor);
        Texture2D nextMainTexture = null;
        if (state.texture != System.IntPtr.Zero)
        {
            /* In practice it looks like our values for width and height are ignored.
               It probably determines correct values from native MTLTexture's own properties.
               Documentation still insists that we pass correct width and height values, so we will. */
            nextMainTexture = Texture2D.CreateExternalTexture(state.textureWidth, state.textureHeight, TextureFormat.BGRA32, false, false, state.texture);
        }

        // Apply next state
        cube.GetComponent<Renderer>().enabled = state.visible;
        cube.transform.localScale = nextLocalScale;
        spotlight.color = nextColor;
        cube.GetComponent<Renderer>().material.mainTexture = nextMainTexture;

        // Update cube rotation and touch indicator
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0);

            if (state.visible)
            {
                // Rotate in same direction as touch delta
                Vector2 delta = touch.deltaPosition * 0.1f;
                cube.transform.Rotate(delta.y, -delta.x, 0, Space.World);
            }

            if (touchIndicator is null)
            {
                // Create touch indicator
                touchIndicator = new GameObject("Touch Indicator");
                touchIndicator.AddComponent<Image>().sprite = sprite;
                touchIndicator.transform.SetParent(canvas.transform);
            }

            // Update touch indicator position
            touchIndicator.transform.position = touch.position;

            if (touch.phase == TouchPhase.Ended || touch.phase == TouchPhase.Canceled)
            {
                // Fade out touch indicator
                Image image = touchIndicator.GetComponent<Image>();
                StartCoroutine(FadeDestroy(image));
                touchIndicator = null;
            }
        }
    }

    private System.Collections.IEnumerator FadeDestroy(Image image)
    {
        while (image.color.a > 0)
        {
            image.color -= new Color(0, 0, 0, Time.deltaTime);
            yield return null;
        }

        Destroy(image.gameObject);
    }
}
