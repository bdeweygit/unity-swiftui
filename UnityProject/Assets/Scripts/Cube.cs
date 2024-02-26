using UnityEngine;
using UnityEngine.UI;

public class Cube : MonoBehaviour
{
    public Canvas canvas;
    public Sprite sprite;
    private GameObject touchIndicator;

    void Update()
    {
        NativeState state = NativeStateManager.State;

        // Compute next state
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
        GetComponent<Renderer>().enabled = state.visible;
        transform.localScale = nextLocalScale;
        GameObject.Find("Spotlight").GetComponent<Light>().color = nextColor;
        GetComponent<Renderer>().material.mainTexture = nextMainTexture;

        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0);

            if (state.visible)
            {
                Vector2 delta = touch.deltaPosition * 0.1f;
                transform.Rotate(delta.y, -delta.x, 0, Space.World);
            }

            if (touchIndicator == null)
            {
                touchIndicator = new GameObject("TouchIndicator");
                touchIndicator.AddComponent<Image>().sprite = sprite;
                touchIndicator.transform.SetParent(canvas.transform);
            }

            touchIndicator.transform.position = touch.position;

            if (touch.phase == TouchPhase.Ended || touch.phase == TouchPhase.Canceled)
            {
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
