#ifndef DEFFER_EFFER_INPUT
#define DEFFER_EFFER_INPUT

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);

TEXTURE2D(_PaperTex);
TEXTURE2D(_PaperedTex);
SAMPLER(sampler_PaperTex);

TEXTURE2D(_NoiseTex);
SAMPLER(sampler_NoiseTex);


UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)

	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
	UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
	UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
	UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
	UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)


	UNITY_DEFINE_INSTANCED_PROP(float4, _FontCol)
	UNITY_DEFINE_INSTANCED_PROP(float4, _FireColor)
	UNITY_DEFINE_INSTANCED_PROP(float4, _PaperTex_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _NoiseTex_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _WaveSpeed)
	UNITY_DEFINE_INSTANCED_PROP(float, _FireBegin)
	UNITY_DEFINE_INSTANCED_PROP(float, _BlendBegin)
	UNITY_DEFINE_INSTANCED_PROP(float, _BlendRange)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

#define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

float2 TransformPaperUV(float2 uv){
	float4 baseST = INPUT_PROP(_PaperTex_ST);
	return uv * baseST.xy + baseST.zw;
}

float2 TransformBaseUV(float2 uv){
	float4 baseST = INPUT_PROP(_MainTex_ST);
	return uv * baseST.xy + baseST.zw;
}


float2 TransformNoiseUV(float2 uv){
	float4 noiseST = INPUT_PROP(_NoiseTex_ST);
	return uv * noiseST.xy + noiseST.zw;
}

float4 GetMain (float2 uv) {
	float4 map = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
	float4 font = INPUT_PROP(_FontCol);
	return float4(font.xyz, map.w);
}

float4 GetBase(float2 uv){
	return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
}

float3 GetEmission () {
	float4 color = INPUT_PROP(_EmissionColor);
	return color.rgb;
}

float GetCutoff () {
	return INPUT_PROP(_Cutoff);
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

float4 GetWaveSpeed() {
	return INPUT_PROP(_WaveSpeed);
}

float GetNoise(float4 noiseUV) {
	return saturate( SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV.xy).r 
		+ SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV.zw).r - 1.0 );
}

float GetFireRadio(float noise){
	return smoothstep(INPUT_PROP(_FireBegin), 1.0, noise);
}

float4 GetFireColor(){
	return INPUT_PROP(_FireColor);
}

float2 GetBlendDate(){
	return float2( INPUT_PROP(_BlendBegin) * 3.0 - 1.0, INPUT_PROP(_BlendRange));
}


#endif
