#ifndef DEFFER_NOISE_WATER
#define DEFFER_NOISE_WATER

#include "CS_ParticleInput.hlsl"
#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Fragment.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"


//液体粒子需要的数据
struct FluidParticle{
    float3 worldPos;
    float3 nowSpeed;
    float3 random;
    float size;
    //0为使用，1:组阶段，2：自由粒子
    int mode;
    float4 uvTransData;     //uv动画需要的数据
    float interpolation;    //插值需要的数据
};

float _TexAspectRatio;

StructuredBuffer<FluidParticle> _FluidParticle;
TEXTURE2D(_NormalMap);
TEXTURE2D(_CameraDepth);

struct ParticleIndex{
    uint index : INDEX;
};

struct FluidFragInput
{
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
    float interpolation : INTERPOLATION;
	float3 TtoW0 : VAR_TT0;
	float3 TtoW1 : VAR_TT1;
	float3 TtoW2 : VAR_TT2;
};


ParticleIndex vert(uint id : SV_InstanceID)
{
    ParticleIndex output;
    output.index = id;
    return output;
}

void SetParticleNormal(inout FluidFragInput outputs[4], 
    float3 begin, float3 viewDir, float paritcleLen){

    float3 beginPos = begin - viewDir * paritcleLen * _TexAspectRatio;
    // float3 beginPos = begin;
    float3 normal = normalize(outputs[0].pos.xyz - beginPos);
    float3 tangent = normalize(outputs[0].pos.xyz - outputs[1].pos.xyz);
    float3 birnormal = cross(normal, tangent);

    outputs[0].TtoW0 = float3(tangent.x, birnormal.x, normal.x);
    outputs[0].TtoW1 = float3(tangent.y, birnormal.y, normal.y);
    outputs[0].TtoW2 = float3(tangent.z, birnormal.z, normal.z);

    normal = normalize(outputs[1].pos.xyz - beginPos);
    birnormal = cross(normal, tangent);
    outputs[1].TtoW0 = float3(tangent.x, birnormal.x, normal.x);
    outputs[1].TtoW1 = float3(tangent.y, birnormal.y, normal.y);
    outputs[1].TtoW2 = float3(tangent.z, birnormal.z, normal.z);

    normal = normalize(outputs[2].pos.xyz - beginPos);
    birnormal = cross(normal, tangent);
    outputs[2].TtoW0 = float3(tangent.x, birnormal.x, normal.x);
    outputs[2].TtoW1 = float3(tangent.y, birnormal.y, normal.y);
    outputs[2].TtoW2 = float3(tangent.z, birnormal.z, normal.z);

    normal = normalize(outputs[3].pos.xyz - beginPos);
    birnormal = cross(normal, tangent);
    outputs[3].TtoW0 = float3(tangent.x, birnormal.x, normal.x);
    outputs[3].TtoW1 = float3(tangent.y, birnormal.y, normal.y);
    outputs[3].TtoW2 = float3(tangent.z, birnormal.z, normal.z);
}

void SetDefaultNormal(inout FluidFragInput outputs[4], 
    float3 begin, float3 viewDir, float paritcleLen){

    float3 beginPos = begin - viewDir * paritcleLen * _TexAspectRatio;
    float3 normal = viewDir;
    float3 tangent = normalize(outputs[0].pos.xyz - outputs[1].pos.xyz);
    float3 birnormal = cross(normal, tangent);

    outputs[0].TtoW0 = float3(tangent.x, birnormal.x, normal.x);
    outputs[0].TtoW1 = float3(tangent.y, birnormal.y, normal.y);
    outputs[0].TtoW2 = float3(tangent.z, birnormal.z, normal.z);

    outputs[1].TtoW0 = float3(tangent.x, birnormal.x, normal.x);
    outputs[1].TtoW1 = float3(tangent.y, birnormal.y, normal.y);
    outputs[1].TtoW2 = float3(tangent.z, birnormal.z, normal.z);

    outputs[2].TtoW0 = float3(tangent.x, birnormal.x, normal.x);
    outputs[2].TtoW1 = float3(tangent.y, birnormal.y, normal.y);
    outputs[2].TtoW2 = float3(tangent.z, birnormal.z, normal.z);

    outputs[3].TtoW0 = float3(tangent.x, birnormal.x, normal.x);
    outputs[3].TtoW1 = float3(tangent.y, birnormal.y, normal.y);
    outputs[3].TtoW2 = float3(tangent.z, birnormal.z, normal.z);
}

//封装点生成面
void outOnePoint(inout TriangleStream<FluidFragInput> tristream, 
    FluidParticle particle)
{
    FluidFragInput o[4] = (FluidFragInput[4])0;

    float3 worldVer = particle.worldPos;
    float paritcleLen = particle.size;

    float3 worldPos = worldVer + -unity_MatrixV[0].xyz * paritcleLen + 
        -unity_MatrixV[1].xyz * paritcleLen * _TexAspectRatio;
    o[0].uv = GetUV(float2(0, 0), particle.uvTransData);
    o[0].interpolation = particle.interpolation;
    o[0].pos.xyz = worldPos;

    worldPos = worldVer + UNITY_MATRIX_V[0].xyz * -paritcleLen
        + UNITY_MATRIX_V[1].xyz * paritcleLen * _TexAspectRatio;
    o[1].uv = GetUV(float2(1, 0), particle.uvTransData);
    o[1].interpolation = particle.interpolation;
    o[1].pos.xyz = worldPos;

    worldPos = worldVer + UNITY_MATRIX_V[0].xyz * paritcleLen
        + UNITY_MATRIX_V[1].xyz * -paritcleLen * _TexAspectRatio;
    o[2].uv = GetUV(float2(0, 1), particle.uvTransData);
    o[2].interpolation = particle.interpolation;
    o[2].pos.xyz = worldPos;

    worldPos = worldVer + UNITY_MATRIX_V[0].xyz * paritcleLen
        + UNITY_MATRIX_V[1].xyz * paritcleLen * _TexAspectRatio;
    o[3].uv = GetUV(float2(1, 1), particle.uvTransData);
    o[3].interpolation = particle.interpolation;
    o[3].pos.xyz = worldPos;

    float3 viewDir = normalize( _WorldSpaceCameraPos - worldVer );
    #ifdef _PARTICLE_NORMAL
        SetParticleNormal(o, worldVer, viewDir, paritcleLen);
    #else
        SetDefaultNormal(o, worldVer, viewDir, paritcleLen);
    #endif

    o[0].pos = mul(UNITY_MATRIX_VP, float4(o[0].pos.xyz, 1));
    o[1].pos = mul(UNITY_MATRIX_VP, float4(o[1].pos.xyz, 1));
    o[2].pos = mul(UNITY_MATRIX_VP, float4(o[2].pos.xyz, 1));
    o[3].pos = mul(UNITY_MATRIX_VP, float4(o[3].pos.xyz, 1));

    tristream.Append(o[1]);
    tristream.Append(o[2]);
    tristream.Append(o[0]);
    tristream.RestartStrip();

    tristream.Append(o[1]);
    tristream.Append(o[3]);
    tristream.Append(o[2]);
    tristream.RestartStrip();
}

//噪声的点到面，也就是大小跟随速度
void speedOutOnePoint(inout TriangleStream<FluidFragInput> tristream, 
    FluidParticle particle) 
{
    FluidFragInput o[4] = (FluidFragInput[4])0;

    float3 worldVer = particle.worldPos;
    float paritcleLen = particle.size;

    float3 viewDir = normalize( _WorldSpaceCameraPos - worldVer );
    float3 upDir = normalize(particle.nowSpeed), 
        particleNormal = cross(viewDir, upDir);
    //左下
    float3 worldPos = worldVer + -upDir * paritcleLen + -particleNormal * paritcleLen * _TexAspectRatio;
    o[0].pos.xyz = worldPos;
    o[0].uv = GetUV(float2(0, 0), particle.uvTransData);
    o[0].interpolation = particle.interpolation;

    worldPos = worldVer + -upDir * paritcleLen + particleNormal * paritcleLen * _TexAspectRatio;
    o[1].pos.xyz = worldPos;
    o[1].uv = GetUV(float2(1, 0), particle.uvTransData);
    o[1].interpolation = particle.interpolation;

    worldPos = worldVer + upDir * paritcleLen + -particleNormal * paritcleLen * _TexAspectRatio;
    o[2].pos.xyz = worldPos;
    o[2].uv = GetUV(float2(0, 1), particle.uvTransData);
    o[2].interpolation = particle.interpolation;

    worldPos = worldVer + upDir * paritcleLen + particleNormal * paritcleLen * _TexAspectRatio;
    o[3].pos.xyz = worldPos;
    o[3].uv = GetUV(float2(1, 1), particle.uvTransData);
    o[3].interpolation = particle.interpolation;

    #ifdef _PARTICLE_NORMAL
        SetParticleNormal(o, worldVer, viewDir, paritcleLen);
    #else
        SetDefaultNormal(o, worldVer, viewDir, paritcleLen);
    #endif
    o[0].pos = mul(UNITY_MATRIX_VP, float4(o[0].pos.xyz, 1));
    o[1].pos = mul(UNITY_MATRIX_VP, float4(o[1].pos.xyz, 1));
    o[2].pos = mul(UNITY_MATRIX_VP, float4(o[2].pos.xyz, 1));
    o[3].pos = mul(UNITY_MATRIX_VP, float4(o[3].pos.xyz, 1));


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
void geom(point ParticleIndex IN[1], inout TriangleStream<FluidFragInput> tristream)
{
    FluidParticle particle = _FluidParticle[IN[0].index];
    //粒子属于死亡状态
    if(particle.mode == 0)
        return;
    
    #ifdef _FOLLOW_SPEED
        speedOutOnePoint(tristream, particle);
    #else
        outOnePoint(tristream, particle);
    #endif
}

float4 GetBaseColor(float4 uv, float interpolation){
    float4 color1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv.xy);
    float4 color2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv.zw);
    return lerp(color1, color2, interpolation);
}

float3 GetNormalTS (float4 uv, float interpolation) {
	float4 map1 = SAMPLE_TEXTURE2D(_NormalMap, sampler_MainTex, uv.xy);
	float4 map2 = SAMPLE_TEXTURE2D(_NormalMap, sampler_MainTex, uv.zw);
    float4 map = lerp(map1, map2, interpolation);
	float3 normal = DecodeNormal(map, 1);
	return normal;
}

float2 NormalFrag(FluidFragInput input) : SV_TARGET{
    float4 color = GetBaseColor(input.uv, input.interpolation);
    clip(color.a - 0.05);
    #ifdef _NORMAL_MAP
        float3 normal = GetNormalTS(input.uv, input.interpolation);
        normal = normalize(float3(dot(input.TtoW0, normal), 
            dot(input.TtoW1, normal), dot(input.TtoW2, normal)));
        return PackNormalOct(normal);
    #else
        float3 normal = normalize(float3(input.TtoW0.z, input.TtoW1.z, input.TtoW2.z));
        return PackNormalOct(normal);
    #endif
}

float4 WidthFrag(FluidFragInput input) : SV_TARGET{
    float4 color = GetBaseColor(input.uv, input.interpolation);
    return color;
}



TEXTURE2D(_WaterDepth);
float4 _WaterDepth_TexelSize;
float _BilaterFilterFactor;
float4 _BlurRadius;
float _MaxFluidWidth;
float _CullOff;

struct Attributes{
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
};

struct Varyings {
    float4 positionCS_SS : SV_POSITION;
    float2 screenUV : VAR_SCREEN_UV;
};

Varyings BlitPassSimpleVertex(Attributes input){
    Varyings output = (Varyings)0;
    output.positionCS_SS = TransformObjectToHClip(input.positionOS);
    output.screenUV = input.baseUV;
    return output;
}

Varyings DefaultPassVertex (uint vertexID : SV_VertexID) {
	Varyings output;
	output.positionCS_SS = float4(
		vertexID <= 1 ? -1.0 : 3.0,
		vertexID == 1 ? 3.0 : -1.0,
		1, 1.0
	);
	output.screenUV = float2(
		vertexID <= 1 ? 0.0 : 2.0,
		vertexID == 1 ? 2.0 : 0.0
	);
	if (_ProjectionParams.x < 0.0) {
		output.screenUV.y = 1.0 - output.screenUV.y;
	}
	return output;
}


half LinearRgbToLuminance(half3 linearRgb)
{
    return dot(linearRgb, half3(0.2126729f,  0.7151522f, 0.0721750f));
}

float CopyDepthPassFragment (Varyings input) : SV_DEPTH {
	return
        SAMPLE_DEPTH_TEXTURE_LOD(_MainTex, sampler_point_clamp, input.screenUV, 0);
}

float CompareColor(float4 col1, float4 col2)
{
	float l1 = LinearRgbToLuminance(col1.rgb);
	float l2 = LinearRgbToLuminance(col2.rgb);
	return smoothstep(_BilaterFilterFactor, 1.0, 1.0 - abs(l1 - l2));
}

float CompareDepth(float col1, float col2)
{
	return smoothstep(_BilaterFilterFactor, 1.0, 1.0 - abs(col1 - col2));
}

float4 BilateralFilterFragment (Varyings input) : SV_TARGET{
	float2 delta = _MainTex_TexelSize.xy * _BlurRadius.xy;
	//采集Normal的颜色值
	float4 col =   SAMPLE_TEXTURE2D(_MainTex, sampler_linear_clamp, input.screenUV);
	float4 col0a = SAMPLE_TEXTURE2D(_MainTex, sampler_linear_clamp, input.screenUV - delta);
	float4 col0b = SAMPLE_TEXTURE2D(_MainTex, sampler_linear_clamp, input.screenUV + delta);
	float4 col1a = SAMPLE_TEXTURE2D(_MainTex, sampler_linear_clamp, input.screenUV - 2.0 * delta);
	float4 col1b = SAMPLE_TEXTURE2D(_MainTex, sampler_linear_clamp, input.screenUV + 2.0 * delta);
	float4 col2a = SAMPLE_TEXTURE2D(_MainTex, sampler_linear_clamp, input.screenUV - 3.0 * delta);
	float4 col2b = SAMPLE_TEXTURE2D(_MainTex, sampler_linear_clamp, input.screenUV + 3.0 * delta);

	float w = 0.37004405286;
	float w0a = CompareColor(col, col0a) * 0.31718061674;
	float w0b = CompareColor(col, col0b) * 0.31718061674;
	float w1a = CompareColor(col, col1a) * 0.19823788546;
	float w1b = CompareColor(col, col1b) * 0.19823788546;
	float w2a = CompareColor(col, col2a) * 0.11453744493;
	float w2b = CompareColor(col, col2b) * 0.11453744493;

	float3 result;
	result = w * col.rgb;
	result += w0a * col0a.rgb;
	result += w0b * col0b.rgb;
	result += w1a * col1a.rgb;
	result += w1b * col1b.rgb;
	result += w2a * col2a.rgb;
	result += w2b * col2b.rgb;

	result /= w + w0a + w0b + w1a + w1b + w2a + w2b;
	return float4(result, 1);
}

float BilateralDepthFilterFragment (Varyings input) : SV_DEPTH{
	float2 delta = _WaterDepth_TexelSize.xy * _BlurRadius.xy;
	//采集Normal的颜色值
	float col =   SAMPLE_DEPTH_TEXTURE_LOD(_WaterDepth, sampler_linear_clamp, input.screenUV, 0);
	float col0a = SAMPLE_DEPTH_TEXTURE_LOD(_WaterDepth, sampler_linear_clamp, input.screenUV - delta, 0);
	float col0b = SAMPLE_DEPTH_TEXTURE_LOD(_WaterDepth, sampler_linear_clamp, input.screenUV + delta, 0);
	float col1a = SAMPLE_DEPTH_TEXTURE_LOD(_WaterDepth, sampler_linear_clamp, input.screenUV - 2.0 * delta, 0);
	float col1b = SAMPLE_DEPTH_TEXTURE_LOD(_WaterDepth, sampler_linear_clamp, input.screenUV + 2.0 * delta, 0);
	float col2a = SAMPLE_DEPTH_TEXTURE_LOD(_WaterDepth, sampler_linear_clamp, input.screenUV - 3.0 * delta, 0);
	float col2b = SAMPLE_DEPTH_TEXTURE_LOD(_WaterDepth, sampler_linear_clamp, input.screenUV + 3.0 * delta, 0);

	float w = 0.37004405286;
	float w0a = CompareDepth(col, col0a) * 0.31718061674;
	float w0b = CompareDepth(col, col0b) * 0.31718061674;
	float w1a = CompareDepth(col, col1a) * 0.19823788546;
	float w1b = CompareDepth(col, col1b) * 0.19823788546;
	float w2a = CompareDepth(col, col2a) * 0.11453744493;
	float w2b = CompareDepth(col, col2b) * 0.11453744493;

	float result;
	result = w * col;
	result += w0a * col0a;
	result += w0b * col0b;
	result += w1a * col1a;
	result += w1b * col1b;
	result += w2a * col2a;
	result += w2b * col2b;

	result /= w + w0a + w0b + w1a + w1b + w2a + w2b;
	return result;
}

float4 _WaterColor;
float2 _SpecularData;
float4x4 _InverseVPMatrix;
TEXTURE2D(_GBufferRT0);
TEXTURE2D(_GBufferRT3);

float3 GetWorldPos(float depth, float2 uv){
    #if defined(UNITY_REVERSED_Z)
        depth = 1 - depth;
    #endif
	float4 ndc = float4(uv.x * 2 - 1, uv.y * 2 - 1, depth * 2 - 1, 1);

	float4 worldPos = mul(_InverseVPMatrix, ndc);
	worldPos /= worldPos.w;
	return worldPos.xyz;
}

float4 BlendToTargetFrag(Varyings input) : SV_TARGET
{
    float width = smoothstep(0, _MaxFluidWidth * 2, SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.screenUV).r);
    clip(width - _CullOff);
    float depth = SAMPLE_DEPTH_TEXTURE(_WaterDepth, sampler_point_clamp, input.screenUV);
    float eyeDepth = LinearEyeDepth(depth, _ZBufferParams);
    float2 normalOct = SAMPLE_TEXTURE2D(_NormalMap, sampler_linear_clamp, input.screenUV).xy;
    float3 normal = normalize(UnpackNormalOct(normalOct));
    float3 position = GetWorldPos(depth, input.screenUV);

    float2 offsetSize = _CameraBufferSize.zw / 100;
    float3 color = SAMPLE_TEXTURE2D(_GBufferRT0, sampler_linear_clamp, input.screenUV + normalOct * _CameraBufferSize.xy * offsetSize * width).rgb;
    float3 reflect = SAMPLE_TEXTURE2D(_GBufferRT3, sampler_linear_clamp, input.screenUV + normalOct * _CameraBufferSize.xy * offsetSize * width).rgb;

    Surface surface = (Surface)0;
    surface.position = position;
    surface.normal = normal;     //法线
    surface.viewDirection = normalize(_WorldSpaceCameraPos - surface.position);                                     //视线方向
    surface.depth = eyeDepth;                                                                                    //深度
    surface.metallic = _SpecularData.x;
    surface.roughness = _SpecularData.y;
	surface.ambientOcclusion = 1;
	surface.color = color * _WaterColor;

    float3 uv_Depth = float3(input.screenUV, eyeDepth);
    color = GetGBufferLight(surface, uv_Depth);
    // color.xyz += reflect * surface.color;

    return float4(color, width);
}

float WriteDepth(Varyings input): SV_DEPTH
{
    float bufferDepth1 = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepth, 
        sampler_point_clamp, input.screenUV, 0);
    float bufferDepth2 = SAMPLE_DEPTH_TEXTURE_LOD(_WaterDepth, 
        sampler_point_clamp, input.screenUV, 0);
    
    float width = smoothstep(0, _MaxFluidWidth * 2, SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.screenUV));
    clip(width - _CullOff);

    return lerp(bufferDepth1, bufferDepth2, width);
}


#endif