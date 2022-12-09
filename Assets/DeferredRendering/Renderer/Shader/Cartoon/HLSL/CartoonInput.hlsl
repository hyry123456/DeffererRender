#ifndef DEFFER_CARTOON_INPUT
#define DEFFER_CARTOON_INPUT


TEXTURE2D(_MainTex);
TEXTURE2D(_LightMap);       //g:Ambient occlusion, b:Specular Mask,  r:暂定为smooth, a:emission
TEXTURE2D(_DiffuseRamp);       //漫方式的Ramp贴图
TEXTURE2D(_SpecularRamp);       //高光的Ramp贴图
SAMPLER(sampler_MainTex);
SAMPLER(sampler_LightMap);
SAMPLER(sampler_DiffuseRamp);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)

	UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
    UNITY_DEFINE_INSTANCED_PROP(float, _OutlineWidth)
    UNITY_DEFINE_INSTANCED_PROP(float4, _OutLineCol)
    UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
    UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)


UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

struct CartoonData{
    float specularMask;
    float smoothMap;
};

half LinearRgbToLuminance(half3 linearRgb)
{
    return dot(linearRgb, half3(0.2126729f,  0.7151522f, 0.0721750f));
}

float GetOutline(float2 uv){
    float3 map = SAMPLE_TEXTURE2D_LOD(_MainTex, sampler_MainTex, uv, 0).xyz;
    half width = LinearRgbToLuminance(map);
    return INPUT_PROP(_OutlineWidth) * width;
}

float2 TransformBaseUV (float2 uv) {
	float4 baseST = INPUT_PROP(_MainTex_ST);
	return uv * baseST.xy + baseST.zw;
}



float4 GetOutlineColor(){
    return INPUT_PROP(_OutLineCol);
}

float4 GetBrighnessColor(float2 baseUV){
    float4 brighness = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, baseUV);
    return brighness;
}

float4 GetDiffuseRamp(float x, float y){
    return SAMPLE_TEXTURE2D(_DiffuseRamp, sampler_DiffuseRamp, float2(x, y));
}

float4 GetSpecularRamp(float x, float y){
    return SAMPLE_TEXTURE2D(_SpecularRamp, sampler_linear_clamp, float2(x, y));
}

float3 GetLightMap(float2 baseUV){
    return SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, baseUV).xyz;
}

float GetRougness(){
    return INPUT_PROP(_Roughness);
}

float GetMetallic(){
    return INPUT_PROP(_Metallic);
}

#endif