#ifndef CUSTOM_TERRAIN_INCLUDED
#define CUSTOM_TERRAIN_INCLUDED

struct Attributes_full {             //设置一个通用输入结构体，方便一些顶点操作
    float4 positionOS : POSITION;
    float4 tangentOS : TANGENT;
    float3 normalOS : NORMAL;
    float4 texcoord0 : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

inline void ExpandBillboard (in float4x4 mat, inout float4 pos, inout float3 normal, inout float4 tangent)
{
    // tangent.w = 0 if this is a billboard
    float isBillboard = 1.0f - abs(tangent.w);

    // billboard normal
    float3 norb = normalize(mul(float4(normal, 0), mat)).xyz;

    // billboard tangent
    float3 tanb = normalize(mul(float4(tangent.xyz, 0.0f), mat)).xyz;

    pos += mul(float4(normal.xy, 0, 0), mat) * isBillboard;
    normal = lerp(normal, norb, isBillboard);
    tangent = lerp(tangent, float4(tanb, -1.0f), isBillboard);
}

float4 SmoothCurve( float4 x ) {
    return x * x *( 3.0 - 2.0 * x );
}
float4 TriangleWave( float4 x ) {
    return abs( frac( x + 0.5 ) * 2.0 - 1.0 );
}
float4 SmoothTriangleWave( float4 x ) {
    return SmoothCurve( TriangleWave( x ) );
}

//进行顶点移动
inline float4 AnimateVertex(float4 pos, float3 normal, float4 animParams)
{
    // animParams stored in color
    // animParams.x = branch phase
    // animParams.y = edge flutter factor
    // animParams.z = primary factor
    // animParams.w = secondary factor

    float fDetailAmp = 0.1f;
    float fBranchAmp = 0.3f;

    // Phases (object, vertex, branch)
    float fObjPhase = dot(unity_ObjectToWorld._14_24_34, 1);
    float fBranchPhase = fObjPhase + animParams.x;

    float fVtxPhase = dot(pos.xyz, animParams.y + fBranchPhase);

    // x is used for edges; y is used for branches
    float2 vWavesIn = _Time.yy + float2(fVtxPhase, fBranchPhase );

    // 1.975, 0.793, 0.375, 0.193 are good frequencies
    float4 vWaves = (frac( vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);

    vWaves = SmoothTriangleWave( vWaves );
    float2 vWavesSum = vWaves.xz + vWaves.yw;

    float4 wind = UNITY_ACCESS_INSTANCED_PROP(UnityPerTree, _Wind);

    // Edge (xz) and branch bending (y)
    float3 bend = animParams.y * fDetailAmp * normal.xyz;
    bend.y = animParams.w * fBranchAmp;
    pos.xyz += ((vWavesSum.xyx * bend) + (wind.xyz * vWavesSum.y * animParams.w)) * wind.w;

    // Primary bending
    // Displace position
    pos.xyz += animParams.z * wind.xyz;

    return pos;
}

void TreeVertLeaf (inout Attributes_full input)
{
    ExpandBillboard (unity_IT_MatrixMV, input.positionOS, input.normalOS, input.tangentOS);
    input.positionOS = AnimateVertex (input.positionOS,
        input.normalOS, float4(input.color.xy, input.texcoord1.xy));

    input.normalOS = normalize(input.normalOS);
    input.tangentOS.xyz = normalize(input.tangentOS.xyz);
}

#endif
