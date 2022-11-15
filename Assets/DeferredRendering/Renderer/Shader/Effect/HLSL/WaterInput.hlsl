#ifndef DEFFER_WATER_INPUT_INCLUDE
#define DEFFER_WATER_INPUT_INCLUDE

TEXTURE2D(_MainTex);
TEXTURE2D(_NormalMap);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_MainTex);

TEXTURE2D(_WaterTex);
SAMPLER(sampler_WaterTex);

TEXTURE2D(_WaterNormal);


UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)

	UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _WaterTex_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
	UNITY_DEFINE_INSTANCED_PROP(float4, _WaterColor)
	UNITY_DEFINE_INSTANCED_PROP(float4, _ShiftColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _Width)
	UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
	UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
	UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
	UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
	UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)

	UNITY_DEFINE_INSTANCED_PROP(float4, _OffsetSize)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

float4 TransformBaseUV (float2 baseUV) {
	float4 baseST = INPUT_PROP(_MainTex_ST);
	float4 waterST = INPUT_PROP(_WaterTex_ST);
	float4 reUV;
	reUV.xy = baseUV * baseST.xy + baseST.zw;
	reUV.zw = baseUV * waterST.xy + waterST.zw;
	return reUV;
}


float4 GetBase (float2 uv) {
	float4 map = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
	float4 color = INPUT_PROP(_Color);

	return map * color;
}

float4 GetWater(float2 uv){
	float4 map = SAMPLE_TEXTURE2D(_WaterTex, sampler_WaterTex, uv);
	return map;
}

float3 GetNoiseNormal(float4 noiseUV) {
	float2 map = (SAMPLE_TEXTURE2D(_WaterNormal, sampler_MainTex, noiseUV.xy).xy - SAMPLE_TEXTURE2D(_WaterNormal, sampler_MainTex, noiseUV.zw).xy);
	return (map.x + map.y) * _OffsetSize.xyz;
}

float4 GetWaterCol(){
	return INPUT_PROP(_WaterColor);
}

float GetCutoff () {
	return INPUT_PROP(_Cutoff);
}

float3 GetNormalTS (float2 uv) {
	float4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_MainTex, uv);
	float scale = INPUT_PROP(_NormalScale);
	float3 normal = DecodeNormal(map, scale);
	
	return normal;
}

float GetWidth(){
	return INPUT_PROP(_Width);
}


float3 GetEmission (float2 uv) {
	float4 map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_MainTex, uv);
	float4 color = INPUT_PROP(_EmissionColor);
	return map.rgb * color.rgb;
}

float GetMetallic () {
	float metallic = INPUT_PROP(_Metallic);
	return metallic;
}

float GetSmoothness () {
	float smoothness = INPUT_PROP(_Smoothness);
	
	return smoothness;
}

float GetFresnel () {
	return INPUT_PROP(_Fresnel);
}

float4 GetShiftColor(){
	return INPUT_PROP(_ShiftColor);
}


#endif
