using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Mathematics;

public class RotateCamera : MonoBehaviour
{
    public Vector2 startEndAngleZ;
    public Vector2 startEndAngleY;
    public float frequency;
    private Transform _transform;

    // Start is called before the first frame update
    void Start()
    {
        _transform = gameObject.transform;
    }

    // Update is called once per frame
    void Update()
    {
        float interpZ = math.sin(Time.time * frequency) * 0.5f + 0.5f;
        float interpY = math.cos(Time.time * frequency) * 0.5f + 0.5f;
        _transform.rotation = Quaternion.Euler(0, math.lerp(startEndAngleY.x, startEndAngleY.y, interpY), math.lerp(startEndAngleZ.x, startEndAngleZ.y, interpZ));
    }
}
