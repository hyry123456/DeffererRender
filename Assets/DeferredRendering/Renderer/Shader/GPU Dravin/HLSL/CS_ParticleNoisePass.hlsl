#ifndef CS_PARTICLE_NOISE_PASS
#define CS_PARTICLE_NOISE_PASS

// struct NoiseParticleData {
//     float4 random;          //xyz是随机数，w是目前存活时间
//     int2 index;             //状态标记，x是当前编号，y是是否存活
//     float3 worldPos;        //当前位置
//     float4 uvTransData;     //uv动画需要的数据
//     float interpolation;    //插值需要的数据
//     float4 color;           //颜色值，包含透明度
//     float size;             //粒子大小
//     float3 nowSpeed;        //xyz是当前速度，w是存活时间
// };


#include "CS_ParticleInput.hlsl"
#include "../../../ShaderLibrary/Fragment.hlsl"

struct ParticleIndex{
    uint index : INDEX;
};


CBUFFER_START(NoiseMaterial)
    float _TexAspectRatio;      //主纹理的宽高比
CBUFFER_END

ParticleIndex vert(uint id : SV_InstanceID)
{
    ParticleIndex output;
    output.index = id;
    return output;
}

//噪声的点到面，也就是大小跟随速度
void NoiseOutOnePoint(inout TriangleStream<FragInput> tristream, NoiseParticleData particle) 
{
    FragInput o[4] = (FragInput[4])0;

    float3 worldVer = particle.worldPos;
    float paritcleLen = particle.size;

    float3 viewDir = normalize( _WorldSpaceCameraPos - worldVer );
    float3 upDir = normalize(particle.nowSpeed), particleNormal = cross(viewDir, upDir);
    //左下
    float3 worldPos = worldVer + -upDir * paritcleLen + -particleNormal * paritcleLen * _TexAspectRatio;
    o[0].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[0].color = particle.color;
    o[0].uv = GetUV(float2(0, 0), particle.uvTransData);
    o[0].interpolation = particle.interpolation;
    o[0].positionWS = worldPos;

    worldPos = worldVer + -upDir * paritcleLen + particleNormal * paritcleLen * _TexAspectRatio;
    o[1].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[1].color = particle.color;
    o[1].uv = GetUV(float2(1, 0), particle.uvTransData);
    o[1].interpolation = particle.interpolation;
    o[1].positionWS = worldPos;

    worldPos = worldVer + upDir * paritcleLen + -particleNormal * paritcleLen * _TexAspectRatio;
    o[2].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[2].color = particle.color;
    o[2].uv = GetUV(float2(0, 1), particle.uvTransData);
    o[2].interpolation = particle.interpolation;
    o[2].positionWS = worldPos;

    worldPos = worldVer + upDir * paritcleLen + particleNormal * paritcleLen * _TexAspectRatio;
    o[3].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[3].color = particle.color;
    o[3].uv = GetUV(float2(1, 1), particle.uvTransData);
    o[3].interpolation = particle.interpolation;
    o[3].positionWS = worldPos;

    tristream.Append(o[1]);
    tristream.Append(o[2]);
    tristream.Append(o[0]);
    tristream.RestartStrip();

    tristream.Append(o[1]);
    tristream.Append(o[3]);
    tristream.Append(o[2]);
    tristream.RestartStrip();
}



[maxvertexcount(6)]
void geom(point ParticleIndex IN[1], inout TriangleStream<FragInput> tristream)
{
    NoiseParticleData particle = _ParticleNoiseBuffer[IN[0].index];
    //粒子属于死亡状态
    if(particle.index.y == 0)
        return;
    #ifdef _FELLOW_SPEED
        NoiseOutOnePoint(tristream, particle);
    #else
        outOnePoint(tristream, particle, _TexAspectRatio);
    #endif
    // NoiseOutOnePoint(tristream, particle);
    // particle.worldPos = IN[0].index;
}

float4 frag(FragInput i) : SV_Target
{

    Fragment fragment = GetFragment(i.pos);
    float4 color = GetBaseColor(i);
    // return i.color * i.color.w;

    color.a *= ChangeAlpha(fragment);

    #ifdef _DISTORTION
        float4 bufferColor = GetBufferColor(fragment, GetDistortion(i, color.a));
        color.rgb = lerp( bufferColor.rgb, 
            color.rgb, saturate(color.a - GetDistortionBlend()));
    #endif


    return color;
}

#endif