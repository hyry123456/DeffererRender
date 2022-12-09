#ifndef PARTICLE_FACTORY_PASS
#define PARTICLE_FACTORY_PASS

#include "CS_ParticleInput.hlsl"
#include "../../../ShaderLibrary/Fragment.hlsl"

struct ToGeom {
    float3 worldPos : VAR_POSITION;
    bool isUse : CHECK;
    float4 transferData : UV_TRANSFER;
    float interplation : UV_INTERPELATION;
    float4 color : COLOR;
    float size : SIZE;
    uint texIndex : TEXTURE_INDEX;
    float3 speed : SPEED;
    int groupId : GROUP_ID;
};

struct FragInput_Array
{
    float4 color : VAR_COLOR;
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
    float interpolation : UV_INTERPELATION;
    uint texIndex : TEXTURE_INDEX;
    float3 positionWS : VAR_POSITION;
};

struct ParticleNodeData
{
    float3 beginPos;        //该组粒子运行初始位置
    float3 endPos;          //方形物体的确认范围用到位置
    float3 beginSpeed;      //初始速度
    int3 initEnum;          //x:初始化的形状,y:是否使用重力，z:图片编号
    float2 sphereData;      //初始化球坐标需要的数据, x=角度, y=半径
    float3 cubeRange;       //初始化矩形坐标的范围, 分别表示xyz的偏移范围
    float3 lifeTimeRange;   //生存周期的范围,x:随机释放时间,Y:存活时间,Z:最大生存到的时间
    float3 noiseData;       //噪声调整速度时需要的数据, x:噪声采样次数, y:噪声采样频率, z:强度
    int3 outEnum;           //确定输出时算法的枚举，x:followSpeed? y:初始化速度方式
    float2 smoothRange;     //粒子的大小范围，用来对应size曲线的大小
    int2 uvCount;        //x:row，y:column,
    int2 drawData;     //x:颜色条编号,y是大小的编号
};

StructuredBuffer<NoiseParticleData> _ParticlesBuffer;     //所有粒子的buffer
StructuredBuffer<ParticleNodeData> _GroupNodeBuffer;      //组数据
TEXTURE2D_ARRAY(_Textures);         //所有的纹理
SAMPLER(sampler_Textures);


ToGeom vert(uint id : SV_InstanceID, uint idVert : SV_VertexId)
{
    ToGeom o = (ToGeom)0;
    uint allIndex = idVert + id * 64;
    uint groupId = id;

    if (_ParticlesBuffer[allIndex].index.y == 0)
        o.isUse = false;
    else o.isUse = true;
    o.worldPos = _ParticlesBuffer[allIndex].worldPos;
    o.interplation = _ParticlesBuffer[allIndex].interpolation;
    o.transferData = _ParticlesBuffer[allIndex].uvTransData;
    o.color = _ParticlesBuffer[allIndex].color;
    o.size = _ParticlesBuffer[allIndex].size;
    o.texIndex = _ParticlesBuffer[allIndex].index.x;
    o.speed = _ParticlesBuffer[allIndex].nowSpeed;

    o.groupId = groupId;
    
    
    return o;
}

//计算uv，包含uv动画
float4 GetUV(float2 uv, float4 uvTransData, int2 uvCount) {

    float4 reUV;
    reUV.xy = uv + uvTransData.xy;
    reUV.zw = uv + uvTransData.zw;

    reUV.xz /= uvCount.x;
    reUV.yw /= uvCount.y;
    return reUV;
}

void OutPutParticle(ToGeom IN, inout TriangleStream<FragInput_Array> tristream){
    FragInput_Array o[4] = (FragInput_Array[4])0;

    float3 worldVer = IN.worldPos;
    float paritcleLen = IN.size;
    int2 uvCount = _GroupNodeBuffer[IN.groupId].uvCount;

    float3 worldPos = worldVer + -unity_MatrixV[0].xyz * paritcleLen + -unity_MatrixV[1].xyz * paritcleLen;
    o[0].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[0].color = IN.color;
    o[0].uv = GetUV(float2(0, 0), IN.transferData, uvCount);
    o[0].interpolation = IN.interplation;
    o[0].texIndex = IN.texIndex;

    worldPos = worldVer + UNITY_MATRIX_V[0].xyz * -paritcleLen
        + UNITY_MATRIX_V[1].xyz * paritcleLen;
    o[1].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[1].color = IN.color;
    o[1].uv = GetUV(float2(1, 0), IN.transferData, uvCount);
    o[1].interpolation = IN.interplation;
    o[1].texIndex = IN.texIndex;

    worldPos = worldVer + UNITY_MATRIX_V[0].xyz * paritcleLen
        + UNITY_MATRIX_V[1].xyz * -paritcleLen;
    o[2].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[2].color = IN.color;
    o[2].uv = GetUV(float2(0, 1), IN.transferData, uvCount);
    o[2].interpolation = IN.interplation;
    o[2].texIndex = IN.texIndex;

    worldPos = worldVer + UNITY_MATRIX_V[0].xyz * paritcleLen
        + UNITY_MATRIX_V[1].xyz * paritcleLen;
    o[3].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[3].color = IN.color;
    o[3].uv = GetUV(float2(1, 1), IN.transferData, uvCount);
    o[3].interpolation = IN.interplation;
    o[3].texIndex = IN.texIndex;

    tristream.Append(o[1]);
    tristream.Append(o[2]);
    tristream.Append(o[0]);
    tristream.RestartStrip();

    tristream.Append(o[1]);
    tristream.Append(o[3]);
    tristream.Append(o[2]);
    tristream.RestartStrip();
}

void OutPutParticle_FollowSpeed(ToGeom IN, inout TriangleStream<FragInput_Array> tristream){
    FragInput_Array o[4] = (FragInput_Array[4])0;

    float3 worldVer = IN.worldPos;
    float paritcleLen = IN.size * 0.1;
    int2 uvCount = _GroupNodeBuffer[IN.groupId].uvCount;

    float3 viewDir = normalize( _WorldSpaceCameraPos - worldVer );
    float3 particleNormal = cross(viewDir, IN.speed);

    //左下
    float3 worldPos = worldVer + -IN.speed * paritcleLen + -particleNormal * paritcleLen;
    o[0].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[0].color = IN.color;
    o[0].uv = GetUV(float2(0, 0), IN.transferData, uvCount);
    o[0].interpolation = IN.interplation;
    o[0].positionWS = worldPos;

    worldPos = worldVer + -IN.speed * paritcleLen + particleNormal * paritcleLen;
    o[1].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[1].color = IN.color;
    o[1].uv = GetUV(float2(1, 0), IN.transferData, uvCount);
    o[1].interpolation = IN.interplation;
    o[1].positionWS = worldPos;

    worldPos = worldVer + IN.speed * paritcleLen + -particleNormal * paritcleLen;
    o[2].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[2].color = IN.color;
    o[2].uv = GetUV(float2(0, 1), IN.transferData, uvCount);
    o[2].interpolation = IN.interplation;
    o[2].positionWS = worldPos;

    worldPos = worldVer + IN.speed * paritcleLen + particleNormal * paritcleLen;
    o[3].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[3].color = IN.color;
    o[3].uv = GetUV(float2(1, 1), IN.transferData, uvCount);
    o[3].interpolation = IN.interplation;
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

void LoadOnePoint(ToGeom IN, inout TriangleStream<FragInput_Array> tristream) {
    int3 outEnum = _GroupNodeBuffer[IN.groupId].outEnum;
    switch(outEnum.x){
        case 1:
            OutPutParticle_FollowSpeed(IN, tristream);
            break;
        default :
            OutPutParticle(IN, tristream);
            break;
    }

}


[maxvertexcount(6)]
void geom(point ToGeom IN[1], inout TriangleStream<FragInput_Array> tristream)
{
    if (!IN[0].isUse) return;
    LoadOnePoint(IN[0], tristream);
}

float4 GetBaseColor_Array(FragInput_Array i){
    float4 color1 = SAMPLE_TEXTURE2D_ARRAY(_Textures, sampler_Textures, i.uv.xy, i.texIndex);
    float4 color2 = SAMPLE_TEXTURE2D_ARRAY(_Textures, sampler_Textures, i.uv.zw, i.texIndex);
    return lerp(color1, color2, i.interpolation) * i.color;
}


float4 frag(FragInput_Array i) : SV_Target
{
    Fragment fragment = GetFragment(i.pos);
    float4 color = GetBaseColor_Array(i);
    color.a *= ChangeAlpha(fragment);

    // return float4(i.pos.xy / _CameraBufferSize.zw, 0, 1);

    // float depth = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_point_clamp, fragment.screenUV, 0);

    // return SAMPLE_TEXTURE2D_ARRAY(_Textures, sampler_Textures, i.uv.xy, i.texIndex) * i.color;
    // return Linear01Depth(depth, _ZBufferParams);
    #ifdef _DEFFER_FOG
		color.xyz = GetDefferFog(i.pos, i.positionWS, color.xyz);
	#endif


    return color;
    return i.color;
    return 1;
}

#endif
