//通过Compute Shader计算的粒子系统的输入文件
#ifndef CS_PARTICLE_INPUT
#define CS_PARTICLE_INPUT

#include "../../../ShaderLibrary/Common.hlsl"

TEXTURE2D(_MainTex);
TEXTURE2D(_DistortionTex);
SAMPLER(sampler_MainTex);
float4 _MainTex_ST;
float4 _MainTex_TexelSize;

//由于本身是使用DrawProcedural，没有必要GPU实例化
CBUFFER_START(UnityPerMaterial)
    float4 _ParticleColor;
    //偏移主纹理
    #ifdef _DISTORTION
        float _DistortionSize;
        float _DistortionBlend;
    #endif

    //软粒子
    #ifdef _SOFT_PARTICLE
        float _SoftParticlesDistance;
        float _SoftParticlesRange;
    #endif

    //近平面透明
    #ifdef _NEAR_ALPHA
        float _NearFadeDistance;
        float _NearFadeRange;
    #endif


CBUFFER_END
int _RowCount;
int _ColCount;
float _ParticleSize;

struct NoiseParticleData {
    float4 random;          //xyz是随机数，w是目前存活时间
    int2 index;             //状态标记，x是当前编号，y是是否存活
    float3 worldPos;        //当前位置
    float4 uvTransData;     //uv动画需要的数据
    float interpolation;    //插值需要的数据
    float4 color;           //颜色值，包含透明度
    float size;             //粒子大小
    float3 nowSpeed;        //xyz是当前速度，w是存活时间
};

StructuredBuffer<NoiseParticleData> _ParticleNoiseBuffer;         //输入的buffer


struct FragInput
{
    float4 color : VAR_COLOR;
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
    float interpolation : UV_INTERPELATION;
    float3 positionWS : VAR_POSITION;
};


//计算uv，包含uv动画
float4 GetUV(float2 uv, float4 uvTransData) {
    uv = uv * _MainTex_ST.xy + _MainTex_ST.zw;  //缩放uv
    float4 reUV;
    reUV.xy = uv + uvTransData.xy;
    reUV.zw = uv + uvTransData.zw;

    reUV.xz /= _RowCount;
    reUV.yw /= _ColCount;
    return reUV;
}

//封装点生成面
void outOnePoint(inout TriangleStream<FragInput> tristream, NoiseParticleData particle, float texAspectRatio)
{
    FragInput o[4] = (FragInput[4])0;

    float3 worldVer = particle.worldPos;
    float paritcleLen = particle.size;

    float3 worldPos = worldVer + -unity_MatrixV[0].xyz * paritcleLen + -unity_MatrixV[1].xyz * paritcleLen * texAspectRatio;
    o[0].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[0].color = particle.color;
    o[0].uv = GetUV(float2(0, 0), particle.uvTransData);
    o[0].interpolation = particle.interpolation;

    worldPos = worldVer + UNITY_MATRIX_V[0].xyz * -paritcleLen
        + UNITY_MATRIX_V[1].xyz * paritcleLen * texAspectRatio;
    o[1].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[1].color = particle.color;
    o[1].uv = GetUV(float2(1, 0), particle.uvTransData);
    o[1].interpolation = particle.interpolation;

    worldPos = worldVer + UNITY_MATRIX_V[0].xyz * paritcleLen
        + UNITY_MATRIX_V[1].xyz * -paritcleLen * texAspectRatio;
    o[2].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[2].color = particle.color;
    o[2].uv = GetUV(float2(0, 1), particle.uvTransData);
    o[2].interpolation = particle.interpolation;

    worldPos = worldVer + UNITY_MATRIX_V[0].xyz * paritcleLen
        + UNITY_MATRIX_V[1].xyz * paritcleLen * texAspectRatio;
    o[3].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
    o[3].color = particle.color;
    o[3].uv = GetUV(float2(1, 1), particle.uvTransData);
    o[3].interpolation = particle.interpolation;

    tristream.Append(o[1]);
    tristream.Append(o[2]);
    tristream.Append(o[0]);
    tristream.RestartStrip();

    tristream.Append(o[1]);
    tristream.Append(o[3]);
    tristream.Append(o[2]);
    tristream.RestartStrip();
}

float4 GetBaseColor(FragInput i){
    float4 color1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
    float4 color2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.zw);
    return lerp(color1, color2, i.interpolation) * i.color;
}

#ifdef _DISTORTION
    float2 GetDistortion(FragInput i, float baseAlpha){
        float2 color1 = SAMPLE_TEXTURE2D(_DistortionTex, sampler_MainTex, i.uv.xy).xy;
        float2 color2 = SAMPLE_TEXTURE2D(_DistortionTex, sampler_MainTex, i.uv.zw).xy;
        float2 color = lerp(color1, color2, i.interpolation) * i.color.xy;
        return color.xy * baseAlpha * _DistortionSize;
    }

    float GetDistortionBlend(){
        return _DistortionBlend;
    }
#endif

float ChangeAlpha(Fragment fragment){
    float reAlpha = 1;

    #ifdef _NEAR_ALPHA
        reAlpha = saturate( (fragment.depth - _NearFadeDistance) / _NearFadeRange );
    #endif

    #ifdef _SOFT_PARTICLE
        float depthDelta = fragment.bufferDepth - fragment.depth;	//获得深度差
        reAlpha *= (depthDelta - _SoftParticlesDistance) / _SoftParticlesRange;	//进行透明控制
    #endif
    return saturate( reAlpha );
}

#endif