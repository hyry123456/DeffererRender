#ifndef CUSTOM_GI_INCLUDED
#define CUSTOM_GI_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"

TEXTURE2D(unity_Lightmap);
SAMPLER(samplerunity_Lightmap);

TEXTURE2D(unity_ShadowMask);
SAMPLER(samplerunity_ShadowMask);

TEXTURE3D_FLOAT(unity_ProbeVolumeSH);
SAMPLER(samplerunity_ProbeVolumeSH);

// TEXTURE2D(_SSSTargetTex);
// SAMPLER(sampler_SSSTargetTex);
// TEXTURE2D(_SSSPyramid1);
// TEXTURE2D(_SSSPyramid2);
// TEXTURE2D(_SSSPyramid3);
// float4 _SSSTargetTex_TexelSize;

TEXTURECUBE(unity_SpecCube0);
SAMPLER(samplerunity_SpecCube0);
TEXTURECUBE(unity_SpecCube1);
SAMPLER(samplerunity_SpecCube1);


#if defined(LIGHTMAP_ON)
	#define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1;
	#define GI_VARYINGS_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
	#define TRANSFER_GI_DATA(input, output) \
		output.lightMapUV = input.lightMapUV * \
		unity_LightmapST.xy + unity_LightmapST.zw;
	#define GI_FRAGMENT_DATA(input) input.lightMapUV
#else
	#define GI_ATTRIBUTE_DATA
	#define GI_VARYINGS_DATA
	#define TRANSFER_GI_DATA(input, output)
	#define GI_FRAGMENT_DATA(input) 0.0
#endif


float3 SampleLightMap (float2 lightMapUV) {
	#if defined(LIGHTMAP_ON)
  		return SampleSingleLightmap(
			TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap), lightMapUV,
			float4(1.0, 1.0, 0.0, 0.0),
			#if defined(UNITY_LIGHTMAP_FULL_HDR)
				false,
			#else
				true,
			#endif
			float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0, 0.0)
	);
	#else
		return 0.0;
	#endif
}


//---------------------------------------计算烘焙反射数据------------------------------------------------

// float3 GetSkyBox(float3 reflect){
// 	float4 environment = SAMPLE_TEXTURECUBE_LOD(
// 		unity_SpecCube0, samplerunity_SpecCube0, reflect, 0
// 	);
// 	return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
// }

	//重新映射反射方向
inline half3 BoxProjectedDirection(half3 worldRefDir, float3 worldPos, float4 cubemapCenter, float4 boxMin, float4 boxMax)
{
	if (cubemapCenter.w > 0.0)
	{
		boxMax.xyz -= worldPos;
		boxMin.xyz -= worldPos;

		float x = (worldRefDir.x > 0 ? boxMax.x : boxMin.x) / worldRefDir.x;
		float y = (worldRefDir.y > 0 ? boxMax.y : boxMin.y) / worldRefDir.y;
		float z = (worldRefDir.z > 0 ? boxMax.z : boxMin.z) / worldRefDir.z;
		float scalar = min(min(x, y), z);

		return worldRefDir * scalar + (worldPos - cubemapCenter.xyz);
	}
	return worldRefDir;
}

inline half3 SamplerReflectProbe0(half3 refDir, float mip_Level)
{
	float4 environment = SAMPLE_TEXTURECUBE_LOD(
		unity_SpecCube0, samplerunity_SpecCube0, refDir, mip_Level
	);
	return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
}

inline half3 SamplerReflectProbe1(half3 refDir, float mip_Level)
{
	float4 environment = SAMPLE_TEXTURECUBE_LOD(
		unity_SpecCube1, samplerunity_SpecCube1, refDir, mip_Level
	);
	return DecodeHDREnvironment(environment, unity_SpecCube1_HDR);
}


//计算间接光镜面反射
inline half3 ComputeIndirectSpecular(half3 refDir, float3 worldPos, float mip_Level)
{
	half3 specular = 0;
	half3 refDir1 = BoxProjectedDirection(refDir, worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
	half3 ref1 = SamplerReflectProbe0(refDir1, mip_Level);
	// half3 ref1 = SamplerReflectProbe(unity_SpecCube0, refDir);
	// return ref1;


	if (unity_SpecCube0_BoxMin.w < 0.99999)
	{
		//重新映射第二个反射探头的方向
		half3 refDir2 = BoxProjectedDirection(refDir, worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);

		half3 ref2 = SamplerReflectProbe1(refDir2, mip_Level);

		//进行混合
		specular = lerp(ref2, ref1, unity_SpecCube0_BoxMin.w);
	}
	else
	{
		specular = ref1;
	}
	return specular;
}



float3 SampleLightProbe (float3 positionWS, float3 normalWS) {
	#if defined(LIGHTMAP_ON)
		return 0.0;
	#else
		if (unity_ProbeVolumeParams.x) {
			return SampleProbeVolumeSH4(
				TEXTURE3D_ARGS(unity_ProbeVolumeSH, samplerunity_ProbeVolumeSH),
				positionWS, normalWS,
				unity_ProbeVolumeWorldToObject,
				unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
				unity_ProbeVolumeMin.xyz, unity_ProbeVolumeSizeInv.xyz
			);
		}
		else {
			float4 coefficients[7];
			coefficients[0] = unity_SHAr;
			coefficients[1] = unity_SHAg;
			coefficients[2] = unity_SHAb;
			coefficients[3] = unity_SHBr;
			coefficients[4] = unity_SHBg;
			coefficients[5] = unity_SHBb;
			coefficients[6] = unity_SHC;
			return max(0.0, SampleSH9(coefficients, normalWS));
		}
	#endif
}


float3 GetBakeDate(float2 lightMapUV, float3 positionWS, float3 normalWS){
	return SampleLightMap(lightMapUV) + SampleLightProbe(positionWS, normalWS);
	// return SampleLightMap(lightMapUV);
	// return SampleLightProbe(positionWS, normalWS);
}

// float4 GetReflect(float2 screenUV){
// 	return SAMPLE_TEXTURE2D(_SSSTargetTex, sampler_SSSTargetTex, screenUV);
// }

// float3 ReflectLod(float2 screenUV, float roughness)
// {
// 	float i = _SSSTargetTex_TexelSize.x * roughness * 2;
// 	float j = _SSSTargetTex_TexelSize.y * roughness * 2;
// 	float3 color = 0;
// 	color += SAMPLE_TEXTURE2D(_SSSTargetTex, sampler_SSSTargetTex, screenUV).xyz;
// 	color += SAMPLE_TEXTURE2D(_SSSTargetTex, sampler_SSSTargetTex, screenUV + float2(i, j)).xyz;
// 	color += SAMPLE_TEXTURE2D(_SSSTargetTex, sampler_SSSTargetTex, screenUV + float2(-i, j)).xyz;
// 	color += SAMPLE_TEXTURE2D(_SSSTargetTex, sampler_SSSTargetTex, screenUV + float2(i, -j)).xyz;
// 	color += SAMPLE_TEXTURE2D(_SSSTargetTex, sampler_SSSTargetTex, screenUV + float2(-i, -j)).xyz;

// 	return color / 5.0;
// }

#endif