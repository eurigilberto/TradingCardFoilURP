using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Mathematics;

public class RotateCard : MonoBehaviour
{
    public Vector2 minMaxBack = new Vector2(150, 210);
    public Vector2 minMaxFront = new Vector2(-30, 30);
    public AnimationCurve transitionCurve;
    private float currentRotation = 0;

    public float transitionStartTime;
    public float loopStartTime;

    public float loopDuration = 4;
    public float transitionDuration = 1;

    public float rotationFrequency = 0.5f;

    public enum AnimState
    {
        FrontLoop,
        TransitionToBack,
        BackLoop,
        TransitionToFront
    }

    public AnimState currentState;

    // Start is called before the first frame update
    void Start()
    {
        currentState = AnimState.FrontLoop;
    }

    private void TransitionAnim(AnimState nextState, Vector2 fromToAngles)
    {
        float animT = (Time.time - transitionStartTime) / transitionDuration;
        if (animT <= 1)
        {
            float curveT = transitionCurve.Evaluate(animT);
            gameObject.transform.rotation = Quaternion.Euler(new Vector3(0, math.lerp(fromToAngles.x, fromToAngles.y, curveT), 0));
        }
        else
        {
            gameObject.transform.rotation = Quaternion.Euler(new Vector3(0, math.lerp(fromToAngles.x, fromToAngles.y, 1), 0));
            loopStartTime = Time.time;
            currentState = nextState;
        }
    }

    private void TransitionToBack()
    {
        TransitionAnim(AnimState.BackLoop, new Vector2(currentRotation, 180));
    }

    private void TransitionToFront()
    {
        TransitionAnim(AnimState.FrontLoop, new Vector2(currentRotation, 0));
    }

    public void LoopAnim(Vector2 interpAngles, AnimState nextState)
    {
        float currentTime = Time.time - loopStartTime;
        float animT = math.remap(-1, 1, 0, 1, math.sin(currentTime * rotationFrequency));
        if (currentTime < loopDuration)
        {
            gameObject.transform.rotation = Quaternion.Euler(0, math.lerp(interpAngles.x, interpAngles.y, animT), 0);
        }
        else
        {
            currentRotation = math.lerp(interpAngles.x, interpAngles.y, animT);
            transitionStartTime = Time.time;
            currentState = nextState;
        }
    }

    public void FrontLoopState()
    {
        LoopAnim(minMaxFront, AnimState.TransitionToBack);
    }
    public void BackLoopState()
    {
        LoopAnim(minMaxBack, AnimState.TransitionToFront);
    }

    // Update is called once per frame
    void Update()
    {
        switch (currentState)
        {
            case AnimState.FrontLoop:
                FrontLoopState();
                break;
            case AnimState.TransitionToBack:
                TransitionToBack();
                break;
            case AnimState.BackLoop:
                BackLoopState();
                break;
            case AnimState.TransitionToFront:
                TransitionToFront();
                break;
            default:
                break;
        }
    }
}
