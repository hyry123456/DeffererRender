#ifndef CUSTOM_COMMON_INCLUDED
#define CUSTOM_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "UnityInput.hlsl"

#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_MATRIX_P glstate_matrix_projection

#if defined(_SHADOW_MASK_ALWAYS) || defined(_SHADOW_MASK_DISTANCE)
	#define SHADOWS_SHADOWMASK
#endif

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

SAMPLER(sampler_linear_clamp);
SAMPLER(sampler_linear_repeat);
SAMPLER(sampler_point_clamp);

bool IsOrthographicCamera () {
	return unity_OrthoParams.w;
}

float OrthographicDepthBufferToLinear (float rawDepth) {
	#if UNITY_REVERSED_Z
		rawDepth = 1.0 - rawDepth;
	#endif
	return (_ProjectionParams.z - _ProjectionParams.y) * rawDepth + _ProjectionParams.y;
}

#include "Fragment.hlsl"

float Square (float x) {
	return x * x;
}

float DistanceSquared(float3 pA, float3 pB) {
	return dot(pA - pB, pA - pB);
}

void ClipLOD (float2 positionSS, float fade) {
	#if defined(LOD_FADE_CROSSFADE)
		float dither = InterleavedGradientNoise(positionSS, 0);
		clip(fade + (fade < 0.0 ? dither : -dither));
	#endif
}

float3 DecodeNormal (float4 sample, float scale) {
	#if defined(UNITY_NO_DXT5nm)
	    return UnpackNormalRGB(sample, scale);
	#else
	    return UnpackNormalmapRGorAG(sample, scale);
	#endif
}

float signNotZero(float f){
  return(f >= 0.0) ? 1.0 : -1.0;
}
float2 signNotZero(float2 v) {
  return float2(signNotZero(v.x), signNotZero(v.y));
}

static half2 PackNormalOct(half3 normalWS){
    half l = dot(abs(normalWS),1); //l = abs(x) + abs(y) + abs(z)
    half3 normalOct = normalWS * rcp(l); //投影到八面体
    if(normalWS.z > 0){ //八面体的上部分投影到xy平面
        return normalOct.xy; 
    }else{ //八面体下部分按对角线翻转投影到xy平面
        return (1 - abs(normalOct.yx)) * signNotZero(normalOct.xy);
    }
}

static half3 UnpackNormalOct(half2 e){
    half3 v = half3(e.xy,1 - abs(e.x) - abs(e.y));
    if(v.z <= 0){
        v.xy = signNotZero(v.xy) *(1 - abs(v.yx));
    } 
    return normalize(v);
}

float3 NormalTangentToWorld (float3 normalTS, float3 normalWS, float4 tangentWS) {
	float3x3 tangentToWorld =
		CreateTangentToWorld(normalWS, tangentWS.xyz, tangentWS.w);
	return TransformTangentToWorld(normalTS, tangentToWorld);
}

#ifdef _DEFFER_FOG

float3 GetDefferFog (float4 positionCS, float3 positionWS, float3 finalCol) {

	float eyeDepth = IsOrthographicCamera() ?
		OrthographicDepthBufferToLinear(positionCS.z) : positionCS.w;

	float bufferDepth = (1.0 / eyeDepth - _ZBufferParams.w) / _ZBufferParams.z;
	float depth01 = Linear01Depth(bufferDepth, _ZBufferParams);
	//确定在范围中的比例
    float depthX = 1 - saturate( (_FogMaxDepth - depth01) / ( _FogMaxDepth - _FogMinDepth ) );
	//根据平方缩减
    float depthRadio = pow(depthX, _FogDepthFallOff);

	//确定高度比例
    float posX = saturate( (_FogMaxHight - positionWS.y) / ( _FogMaxHight - _FogMinHight ) );
		
	//根据平方缩减
    float posYRadio = pow(posX, _FogPosYFallOff);

	//越趋近0，越接近本来颜色
	float finalRatio = posYRadio * depthRadio;
	return lerp(finalCol, _FogColor.xyz, finalRatio);
}

float3 GetDefferFog(float bufferDepth, float3 positionWS, float3 finalCol){

	float depth01 = Linear01Depth(bufferDepth, _ZBufferParams);
	//确定在范围中的比例
    float depthX = 1 - saturate( (_FogMaxDepth - depth01) / ( _FogMaxDepth - _FogMinDepth ) );
	//根据平方缩减
    float depthRadio = pow(depthX, _FogDepthFallOff);

	//确定高度比例
    float posX = saturate( (_FogMaxHight - positionWS.y) / ( _FogMaxHight - _FogMinHight ) );
		
	//根据平方缩减
    float posYRadio = pow(posX, _FogPosYFallOff);

	//越趋近0，越接近本来颜色
	float finalRatio = posYRadio * depthRadio;
	return lerp(finalCol, _FogColor.xyz, finalRatio);
}

#endif



#endif