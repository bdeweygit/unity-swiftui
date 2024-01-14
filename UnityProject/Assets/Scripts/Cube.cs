using UnityEngine;

public class Cube : MonoBehaviour
{
    void Update()
    {
        var state = NativeStateManager.State;
        var scale = (state.cubeScale + 2f);
        gameObject.transform.localScale = new Vector3(scale, scale, scale);
    }
}
