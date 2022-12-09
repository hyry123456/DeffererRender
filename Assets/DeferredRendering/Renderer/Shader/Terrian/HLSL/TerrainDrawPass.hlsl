#ifndef DEFFER_TERRAIN_PASS
#define DEFFER_TERRAIN_PASS

#include "../../ShaderLibrary/GI.hlsl"


struct FragInput{
    float4 positionCS : SV_POSITION;
    float3 TtoW0 : TEXCOORD1;
    float3 TtoW1 : TEXCOORD2;
    float3 TtoW2 : TEXCOORD3;
    float3 worldPos : VAR_POSITION;
    float2 uv : VAR_UV;
};



[maxvertexcount(3)]
void TerrainGeom(triangle TessOutPut IN[3], inout TriangleStream<FragInput> tristream)
{
    FragInput output[3] = (FragInput[3])0;

    IN[0].vertex.y += SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_HeightTex, IN[0].uv, 0).r * _Height;
    IN[1].vertex.y += SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_HeightTex, IN[1].uv, 0).r * _Height;
    IN[2].vertex.y += SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_HeightTex, IN[2].uv, 0).r * _Height;


    output[0].positionCS = TransformWorldToHClip(IN[0].vertex.xyz);
    output[1].positionCS = TransformWorldToHClip(IN[1].vertex.xyz);
    output[2].positionCS = TransformWorldToHClip(IN[2].vertex.xyz);

    output[0].uv = IN[0].uv;
    output[1].uv = IN[1].uv;
    output[2].uv = IN[2].uv;

    output[0].worldPos = IN[0].vertex.xyz;
    output[1].worldPos = IN[1].vertex.xyz;
    output[2].worldPos = IN[2].vertex.xyz;

    float3 po0To1 = normalize( IN[1].vertex.xyz - IN[0].vertex.xyz );
    float3 po1To2 = normalize( IN[2].vertex.xyz - IN[1].vertex.xyz );
    float3 po2To0 = normalize( IN[0].vertex.xyz - IN[2].vertex.xyz );

    float3 normal0 = SAMPLE_TEXTURE2D_LOD(_NormalTex, sampler_NormalTex, IN[0].uv, 0).xyz;
    float3 normal1 = SAMPLE_TEXTURE2D_LOD(_NormalTex, sampler_NormalTex, IN[0].uv, 0).xyz;
    float3 normal2 = SAMPLE_TEXTURE2D_LOD(_NormalTex, sampler_NormalTex, IN[0].uv, 0).xyz;

    float3 tangent = float3(1,1,1);
    float3 worldBinormal0 = cross(normal0, tangent);
    float3 worldBinormal1 = cross(normal1, tangent);
    float3 worldBinormal2 = cross(normal2, tangent);

    output[0].TtoW0 = float3(1, worldBinormal0.x, normal0.x);  
    output[0].TtoW1 = float3(1, worldBinormal0.y, normal0.y);  
    output[0].TtoW2 = float3(1, worldBinormal0.z, normal0.z);

    output[1].TtoW0 = float3(1, worldBinormal1.x, normal1.x);  
    output[1].TtoW1 = float3(1, worldBinormal1.y, normal1.y);
    output[1].TtoW2 = float3(1, worldBinormal1.z, normal1.z);

    output[2].TtoW0 = float3(1, worldBinormal2.x, normal2.x);  
    output[2].TtoW1 = float3(1, worldBinormal2.y, normal2.y);
    output[2].TtoW2 = float3(1, worldBinormal2.z, normal2.z);

    tristream.Append(output[0]);
    tristream.Append(output[1]);
    tristream.Append(output[2]);
    tristream.RestartStrip();

}

void TerrainFragment(FragInput input,
    out float4 _GBufferColorTex : SV_Target0,
    out float4 _GBufferNormalTex : SV_Target1,
    out float4 _GBufferSpecularTex : SV_Target2,
    out float4 _GBufferBakeTex : SV_Target3)
{
    TerrainTextureData texData;
    float3 worldPos = input.worldPos;
    float4 normal = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, input.uv);
    normal = normal * 2.0 - 1.0;
    normal = normalize(normal);

    texData = GetBase(input.uv, worldPos, normal);

    float3 bump = DecodeNormal(texData.normal, texData.normalScale);
    input.TtoW0.z = normal.x; input.TtoW1.z = normal.y; input.TtoW2.z = normal.z;
    bump = normalize(float3(dot(input.TtoW0.xyz, bump), dot(input.TtoW1.xyz, bump), dot(input.TtoW2.xyz, bump)));

    _GBufferColorTex = float4(texData.baseCol, 1);
    _GBufferNormalTex = float4(bump * 0.5 + 0.5, 1);
    _GBufferSpecularTex = float4(texData.pbrData, 0.2, 1);
    _GBufferBakeTex = 0;
}


#endif