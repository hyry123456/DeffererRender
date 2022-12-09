using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DefferedRender;
public class Temp : MonoBehaviour
{
    ParticleDrawData drawData = new ParticleDrawData
    {
        //beginPos = Vector3.zero,
        beginSpeed = Vector3.down,
        speedMode = SpeedMode.PositionOutside,
        cubeOffset = Vector3.one * 50,
        useGravity = true,
        followSpeed = true,
        radius = 10,
        radian = 6.28f,
        lifeTime = 5,
        showTime = 5,
        frequency = 1,
        octave = 4,
        intensity = 30,
        sizeRange =  Vector2.up,
        colorIndex = ColorIndexMode.HighlightToAlpha,
        textureIndex = 0,
        groupCount = 1
    };

    public int indexX, indexY;

    void Update()
    {
        //drawData.beginPos = transform.position;
        //drawData.endPos = transform.position + Vector3.up * 10;
        //ParticleNoiseFactory.Instance.DrawCube(drawData);

    }
}
