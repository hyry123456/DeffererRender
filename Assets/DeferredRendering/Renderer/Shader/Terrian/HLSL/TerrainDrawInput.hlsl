#ifndef DEFFER_TERRAIN_INPUT
#define DEFFER_TERRAIN_INPUT

TEXTURE2D_ARRAY(_VTexture_Diffuse);       //所有的根据纹理
SAMPLER(sampler_VTexture_Diffuse);

TEXTURE2D_ARRAY(_VTexture_Normal);         //所有的法线纹理
SAMPLER(sampler_VTexture_Normal);

TEXTURE2D_ARRAY(_VTexture_Mask);         //所有的法线纹理
SAMPLER(sampler_VTexture_Mask);

TEXTURE2D_ARRAY(_VTexture_Spilt);         //所有的比例纹理
SAMPLER(sampler_VTexture_Spilt);

TEXTURE2D(_NormalTex);         //法线纹理
SAMPLER(sampler_NormalTex);

TEXTURE2D(_HeightTex);         //高度纹理
SAMPLER(sampler_HeightTex);

TEXTURE2D(_DetailTex);         //高度纹理
SAMPLER(sampler_DetailTex);

CBUFFER_START(UnityPerMaterial)
    float _TessDegree;       //细分程度参数
    float _TessDistanceMin; //最小距离
    float _TessDistanceMax; //最大距离
    float _Height;                  //纹理对应高度
    float4 _ClipPlane[6];               //判断的6个面
CBUFFER_END


StructuredBuffer<float4> _SpecularBuffer;   //地形设置的Specular颜色，这里直接当作对应纹理的主颜色
StructuredBuffer<float3> _TerrainDataBuffer;     //地形值数据，x=normalScale, y=metallic, z=smoothness
StructuredBuffer<float2> _TilieBuffer;
uint _TextureCount;      //贴图的数量

struct TessVertex{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct TessOutPut{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct OutputPatchConstant{
    float edge[3]        : SV_TessFactor;
    float inside         : SV_InsideTessFactor;
    float3 vTangent[4]   : TANGENT;
    float2 vUV[4]        : TEXCOORD;
    float3 vTanUCorner[4]: TANUCORNER;
    float3 vTanVCorner[4]: TANVCORNER;
    float4 vCWts         : TANWEIGHTS;
};

struct TerrainInputData{
    float4 color;
    float3 terrainData;
    float4 texture_ST;
};


struct TerrainTextureData{
    float3 baseCol;
    float4 normal;
    float normalScale;
    float2 pbrData;     //metallic, smoothness
    float4 maskValue;
};

struct TriplanarUV{
    float2 x, y, z;
};

TriplanarUV GetTriplanarUV(float3 worldPos){
    TriplanarUV triUV;
    triUV.x = worldPos.zy;
    triUV.y = worldPos.xz;
    triUV.z = worldPos.xy;
    return triUV;
}

void GetTerrainData(float4 spiltCol, uint index, float2 trueUV, float3 worldPos, inout TerrainTextureData texData,
    float3 radio){
    TriplanarUV triUvs = GetTriplanarUV(worldPos);
    for(uint i = 0; (index * 4 + i) <= _TextureCount; i++){
        float2 size = _TilieBuffer[index * 4 + i];
        float3 avgBaseCol = 
            SAMPLE_TEXTURE2D_ARRAY(_VTexture_Diffuse, sampler_VTexture_Diffuse, triUvs.x * size, index * 4 + i).rgb * radio.x + 
            SAMPLE_TEXTURE2D_ARRAY(_VTexture_Diffuse, sampler_VTexture_Diffuse, triUvs.y * size, index * 4 + i).rgb * radio.y +
            SAMPLE_TEXTURE2D_ARRAY(_VTexture_Diffuse, sampler_VTexture_Diffuse, triUvs.z * size, index * 4 + i).rgb * radio.z;
        // float3 avgBaseCol = SAMPLE_TEXTURE2D_ARRAY(_VTexture_Diffuse, sampler_VTexture_Diffuse, worldUV, index * 4 + i).rgb;
        texData.baseCol += avgBaseCol * _SpecularBuffer[index * 4 + i].rgb * spiltCol[i];

        float4 avgNormal = 
            SAMPLE_TEXTURE2D_ARRAY(_VTexture_Normal, sampler_VTexture_Normal, triUvs.x * size, index * 4 + i) * radio.x + 
            SAMPLE_TEXTURE2D_ARRAY(_VTexture_Normal, sampler_VTexture_Normal, triUvs.y * size, index * 4 + i) * radio.y +
            SAMPLE_TEXTURE2D_ARRAY(_VTexture_Normal, sampler_VTexture_Normal, triUvs.z * size, index * 4 + i)  * radio.z;
        // float4 avgNormal = SAMPLE_TEXTURE2D_ARRAY(_VTexture_Normal, sampler_VTexture_Normal, worldUV, index * 4 + i);
        texData.normal += avgNormal * spiltCol[i];

        texData.normalScale += _TerrainDataBuffer[index * 4 + i].x * spiltCol[i];
        texData.pbrData += _TerrainDataBuffer[index * 4 + i].yz * spiltCol[i];

        float4 avgMask = 
            SAMPLE_TEXTURE2D_ARRAY(_VTexture_Mask, sampler_VTexture_Mask, triUvs.x * size, index * 4 + i) * radio.x +
            SAMPLE_TEXTURE2D_ARRAY(_VTexture_Mask, sampler_VTexture_Mask, triUvs.y * size, index * 4 + i) * radio.y +
            SAMPLE_TEXTURE2D_ARRAY(_VTexture_Mask, sampler_VTexture_Mask, triUvs.z * size, index * 4 + i) * radio.z ;
        // float4 avgMask = SAMPLE_TEXTURE2D_ARRAY(_VTexture_Mask, sampler_VTexture_Mask, worldUV, index * 4 + i);
        texData.maskValue += avgMask * spiltCol[i];
    }
}

TerrainTextureData GetBase(float2 trueUV, float3 worldPos, float3 normal){
    uint yCount = _TextureCount / 4 + 1;

    TerrainTextureData texData = (TerrainTextureData)0;
    normal = abs(normal);
    float3 radio = normal / (normal.x + normal.y + normal.z);
    // GetTerrainData(float4(1, 0, 0, 0), 0, trueUV, worldPos, texData);
    // texData.pbrData = float2(0, 1);
    // texData.maskValue = 1;
    for(uint i=0; i <= yCount; i++){
        float4 spiltCol = SAMPLE_TEXTURE2D_ARRAY(_VTexture_Spilt, sampler_VTexture_Spilt, trueUV, i);
        GetTerrainData(spiltCol, i, trueUV, worldPos, texData, radio);
    }
    return texData;
}


float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess)
{
    float3 wpos = mul(unity_ObjectToWorld,vertex).xyz;
    float dist = distance (wpos, _WorldSpaceCameraPos);
    float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
    return f;
}

float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
{
    float4 tess;
    tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
    tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
    tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
    tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
    return tess;
}

float4 DistanceBasedTess (float4 v0, float4 v1, float4 v2, float minDist, float maxDist, float tess)
{
    float3 f;
    f.x = CalcDistanceTessFactor (v0, minDist, maxDist, tess);
    f.y = CalcDistanceTessFactor (v1, minDist, maxDist, tess);
    f.z = CalcDistanceTessFactor (v2, minDist, maxDist, tess);

    return CalcTriEdgeTessFactors (f);
}

void tessVert (inout TessVertex v){}

//细分参数控制着色器，细分的前置准备
OutputPatchConstant hullconst(InputPatch<TessVertex, 3>v){
    OutputPatchConstant o = (OutputPatchConstant)0;
    float4 ts = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, _TessDistanceMin, _TessDistanceMax, _TessDegree);
    o.edge[0] = ts.x;
    o.edge[1] = ts.y;
    o.edge[2] = ts.z;
    o.inside = ts.w;
    return o;
}

[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[patchconstantfunc("hullconst")]
[outputcontrolpoints(3)]
TessVertex hull (InputPatch<TessVertex, 3> v, uint id : SV_OutputControlPointID){
    return v[id];
}

[domain("tri")]
TessOutPut domain (OutputPatchConstant tessFactors, const OutputPatch<TessOutPut, 3> vi, float3 bary : SV_DomainLocation){
    TessOutPut v = (TessOutPut)0;
    v.vertex = vi[0].vertex * bary.x + vi[1].vertex*bary.y + vi[2].vertex * bary.z;
    v.uv = vi[0].uv * bary.x + vi[1].uv*bary.y + vi[2].uv * bary.z;
    return v;
}


#endif