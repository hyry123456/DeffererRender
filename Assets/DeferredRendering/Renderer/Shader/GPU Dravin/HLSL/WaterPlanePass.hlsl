#ifndef WATER_PLANE
#define WATER_PLANE

#include "../../../ShaderLibrary/Common.hlsl"
#include "../../ShaderLibrary/GI.hlsl"

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"

CBUFFER_START(UnityPerMaterial)
    StructuredBuffer<float3> _PointsBuffer;
    int _PointsSizeX, _PointsSizeY;
    float4x4 _PointsM_Martrix;

    float _Steepness;
    float _WaveLength;
    float _Speed;
    float4 _WaveDir0;
    float4 _WaveDir1;

    float _WaveScale;
    float _RefrDistort;
    float3 _RefrColor;  //水透视时看到的颜色
    float4 _WaterColor;
    float _Gloss;

    float3 _SpecularColor;
    float3 _NearColor;
    float _NearDistance;
    float _NearRange;
CBUFFER_END

TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);
TEXTURE2D(_ReflectiveColor);
SAMPLER(sampler_ReflectiveColor);


struct ToGeom{
    uint index : VAR_INDEX;
};

struct FragInput{
    float4 positionCS : SV_POSITION;
    float3 normal : VAR_NORMAL;
    float3 worldPos : VAR_WORLDPOS;
    float2 uv : VAR_UV;
    float2 bumpUV0 : VAR_BUMP_UV0;
    float2 bumpUV1 : VAR_BUMP_UV1;
};

ToGeom vert(uint id : SV_InstanceID)
{
    ToGeom o = (ToGeom)0;
    o.index = id;
    return o;
}

struct GersnerResult{
    float3 offsetPos;
    float3 normal;
};

float3 GerstnerWave (float4 wave, float3 p, inout float3 normal, float amplitude) {
    float waveLen = wave.w;
    float steepness = wave.z;

    float frequency = 2 * 3.14 / waveLen;
    float a = steepness / frequency;
    float f = frequency * (p.x * wave.x + p.z * wave.y - _Speed * _Time.y);
    float s = a * frequency;

    float3 tangent = float3(
        1 - wave.x * wave.x * s * sin(f),
        wave.x * s * cos(f),
        -wave.x * wave.y * s * sin(f)
    ) ;
    float3 binormal = float3(
        -wave.x * wave.y * s * sin(f),
        wave.y * s * cos(f),
        1 - wave.y * wave.y * s * sin(f)
    ) ;
    normal += -normalize( cross(tangent, binormal) ) * amplitude;
    return float3(      // 输出顶点偏移量
        wave.x * a * cos(f),
        a * sin(f),
        wave.y * a * cos(f)
    ) * amplitude;
}

[maxvertexcount(6)]
void geom(point ToGeom IN[1], inout TriangleStream<FragInput> tristream)
{
    uint x = IN[0].index / (_PointsSizeX - 1);
    uint y = IN[0].index - x * (_PointsSizeY - 1);
    float3 point0 = _PointsBuffer[x * _PointsSizeX + y];
    float3 point1 = _PointsBuffer[x * _PointsSizeX + y + 1];
    float3 point2 = _PointsBuffer[ (x + 1) * _PointsSizeX + y ];
    float3 point3 = _PointsBuffer[ (x + 1) * _PointsSizeX + y + 1 ];

    float3 normal0 =0, normal1 = 0, normal2 = 0, normal3 = 0;
    float3 addPos0 = 0, addPos1 = 0, addPos2 = 0, addPos3 = 0;

    float2 dirs[4] = {normalize(_WaveDir0.xy), normalize(_WaveDir0.zw), normalize(_WaveDir1.xy), normalize(_WaveDir1.zw)};
    float frequency = 1.0;
    float amplitude = 1.0;

    for(int i=0; i< 4; i++){
        addPos0 += GerstnerWave(float4(dirs[i], _Steepness * frequency, _WaveLength * frequency),
            point0, normal0, amplitude);
        addPos1 += GerstnerWave(float4(dirs[i], _Steepness * frequency, _WaveLength * frequency),
            point1, normal1, amplitude);
        addPos2 += GerstnerWave(float4(dirs[i], _Steepness * frequency, _WaveLength * frequency),
            point2, normal2, amplitude);
        addPos3 += GerstnerWave(float4(dirs[i], _Steepness * frequency, _WaveLength * frequency),
            point3, normal3, amplitude) ;

        frequency *= 2.0;
        amplitude *= 0.5;
    }

    point0.xz += addPos0.xz; point0.y = addPos0.y;
    point1.xz += addPos1.xz; point1.y = addPos1.y;
    point2.xz += addPos2.xz; point2.y = addPos2.y;
    point3.xz += addPos3.xz; point3.y = addPos3.y;

    point0 = mul(_PointsM_Martrix, float4(point0, 1)).xyz;
    point1 = mul(_PointsM_Martrix, float4(point1, 1)).xyz;
    point2 = mul(_PointsM_Martrix, float4(point2, 1)).xyz;
    point3 = mul(_PointsM_Martrix, float4(point3, 1)).xyz;

    FragInput frags[4] = (FragInput[4])0;
    frags[0].positionCS = mul(UNITY_MATRIX_VP, float4(point0, 1));
    frags[0].worldPos = point0;
    frags[1].positionCS = mul(UNITY_MATRIX_VP, float4(point1, 1));
    frags[1].worldPos = point1;
    frags[2].positionCS = mul(UNITY_MATRIX_VP, float4(point2, 1));
    frags[2].worldPos = point2;
    frags[3].positionCS = mul(UNITY_MATRIX_VP, float4(point3, 1));
    frags[3].worldPos = point3;

    frags[0].normal = TransformObjectToWorldNormal( normal0 );
    frags[1].normal = TransformObjectToWorldNormal( normal1 );
    frags[2].normal = TransformObjectToWorldNormal( normal2 );
    frags[3].normal = TransformObjectToWorldNormal( normal3 );

    frags[0].uv = float2( (float)x / _PointsSizeY, (float)y / _PointsSizeX);
    frags[1].uv = float2( (float)x / _PointsSizeY, (float)(y + 1.0) / _PointsSizeX);
    frags[2].uv = float2( (float)(x + 1.0) / _PointsSizeY, (float)y / _PointsSizeX);
    frags[3].uv = float2( (float)(x + 1.0) / _PointsSizeY, (float)(y + 1.0) / _PointsSizeX);

    float4 temp; float4 moveDir; moveDir.xy = _WaveDir0.xy + _WaveDir1.xy * 0.25; 
    moveDir.zw = -(_WaveDir0.zw * 0.5 + _WaveDir1.zw * 0.125);
    moveDir *= _Time.x * _Speed * 0.05;
    temp.xyzw = frags[0].worldPos.xzxz * float4(_WaveScale, _WaveScale, _WaveScale * 0.4, _WaveScale * 0.45) + moveDir;
    frags[0].bumpUV0 = temp.xy; frags[0].bumpUV1 = temp.wz;
    temp.xyzw = frags[1].worldPos.xzxz * float4(_WaveScale, _WaveScale, _WaveScale * 0.4, _WaveScale * 0.45) + moveDir;
    frags[1].bumpUV0 = temp.xy; frags[1].bumpUV1 = temp.wz;
    temp.xyzw = frags[2].worldPos.xzxz * float4(_WaveScale, _WaveScale, _WaveScale * 0.4, _WaveScale * 0.45) + moveDir;
    frags[2].bumpUV0 = temp.xy; frags[2].bumpUV1 = temp.wz;
    temp.xyzw = frags[3].worldPos.xzxz * float4(_WaveScale, _WaveScale, _WaveScale * 0.4, _WaveScale * 0.45) + moveDir;
    frags[3].bumpUV0 = temp.xy; frags[3].bumpUV1 = temp.wz;

    tristream.Append(frags[0]);
    tristream.Append(frags[1]);
    tristream.Append(frags[2]);
    tristream.RestartStrip();

    tristream.Append(frags[1]);
    tristream.Append(frags[3]);
    tristream.Append(frags[2]);
    tristream.RestartStrip();
}

void frag(FragInput i,
    out float4 _GBufferColorTex : SV_Target0,
    out float4 _GBufferNormalTex : SV_Target1)
{
    float4 map0 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.bumpUV0); float3 bump0 = DecodeNormal(map0, 1);
    float4 map1 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.bumpUV1); float3 bump1 = DecodeNormal(map1, 1);
    float3 bump = (bump0 + bump1) * 0.5;
    float3 normal = normalize( BlendNormalRNM(i.normal, bump) ) * 0.5 + 0.5;

    _GBufferColorTex = _WaterColor;

    _GBufferNormalTex = float4(normal, 1);
}

float4 TransferFrag(FragInput i) : SV_Target0
{
    Fragment fragment = GetFragment(i.positionCS);

    float4 map0 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.bumpUV0); float3 bump0 = DecodeNormal(map0, 1);
    float4 map1 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.bumpUV1); float3 bump1 = DecodeNormal(map1, 1);
    float3 bump = (bump0 + bump1) * 0.5;
    float3 normal = normalize( BlendNormalRNM(i.normal, bump) );

    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    float fresnelFac = dot( viewDir, normal );

    float3 reflect = ReflectLod(fragment.screenUV, 0);

    float2 offset = normal.xz * _RefrDistort;
    float3 refrColor_offset = GetBufferColor(fragment, offset).rgb;
    float3 refrColor = GetBufferColor(fragment).rgb;
    float3 finalRefrCol;
    if(GetBufferDepth(fragment, offset) <= fragment.bufferDepth)
        finalRefrCol = refrColor;
    else finalRefrCol = refrColor_offset;
    finalRefrCol *= _RefrColor;

    Surface surface = (Surface)0;
    surface.position = i.worldPos;
    surface.normal = normal;
    surface.viewDirection = normalize(_WorldSpaceCameraPos - surface.position);
    surface.smoothness = _Gloss;

    DiffuseData diffuse = GetLightingDiffuse(surface, i.positionCS);

    float3 color = diffuse.specularCol * _SpecularColor;
    // #ifdef _IS_REFR
        color += lerp(finalRefrCol, reflect, fresnelFac);
    // #else
        // float4 water = SAMPLE_TEXTURE2D(_ReflectiveColor, sampler_ReflectiveColor, float2(fresnelFac, fresnelFac)) * _HorizonColor;
        // color.rgb += lerp(water.rgb, reflect.rgb, water.a);
    // #endif

    // float depthDelta = fragment.bufferDepth - fragment.depth;
    // color = lerp(_NearColor * color, color, saturate( (depthDelta - _NearDistance) / _NearRange ) );

    return float4(color.rgb, 1);
}

#endif
