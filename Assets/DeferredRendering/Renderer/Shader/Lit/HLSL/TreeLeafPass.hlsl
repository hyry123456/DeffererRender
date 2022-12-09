#ifndef DEFFER_TERRAIN_LEAF_PASS
#define DEFFER_TERRAIN_LEAF_PASS


#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/MyTerrain.hlsl"



// struct Attributes {
// 	float3 positionOS : POSITION;
// 	float3 normalOS : NORMAL;
// 	float4 tangentOS : TANGENT;
// 	float2 baseUV : TEXCOORD0;
// 	GI_ATTRIBUTE_DATA
// 	UNITY_VERTEX_INPUT_INSTANCE_ID
// };

struct Varyings {
	float4 positionCS_SS : SV_POSITION;
	float3 positionWS : VAR_POSITION;
	float3 normalWS : VAR_NORMAL;
	#if defined(_NORMAL_MAP)
		float4 tangentWS : VAR_TANGENT;
	#endif
	float2 baseUV : VAR_BASE_UV;
	#if defined(_DETAIL_MAP)
		float2 detailUV : VAR_DETAIL_UV;
	#endif
	GI_VARYINGS_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex (Attributes_full input) {
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);

	TreeVertLeaf(input);

	TRANSFER_GI_DATA(input, output);
	output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
	output.positionCS_SS = TransformWorldToHClip(output.positionWS);

	float3 normalOS = input.normalOS;
#ifdef _ADJUST_NORMAL
	normalOS = normalize(input.positionOS.xyz);
#endif

	output.normalWS = TransformObjectToWorldNormal(normalOS);
	#if defined(_NORMAL_MAP)
		output.tangentWS = float4(
			TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w
		);
	#endif
	output.baseUV = TransformBaseUV(input.texcoord0.xy);
	#if defined(_DETAIL_MAP)
		output.detailUV = TransformDetailUV(input.baseUV);
	#endif
	return output;
}

float4 LitPassFragment (Varyings input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);
	InputConfig config = GetInputConfig(input.baseUV);
	ClipLOD(input.positionCS_SS.xy, unity_LODFade.x);
	
	#if defined(_MASK_MAP)
		config.useMask = true;
	#endif
	#if defined(_DETAIL_MAP)
		config.detailUV = input.detailUV;
		config.useDetail = true;
	#endif
	
	float4 base = GetBase(config);
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(config));
	#endif
	
	Surface surface = (Surface)0;
	surface.position = input.positionWS;
	#if defined(_NORMAL_MAP)
		surface.normal = NormalTangentToWorld(
			GetNormalTS(config), input.normalWS, input.tangentWS
		);
	#else
		surface.normal = normalize(input.normalWS);
	#endif


	surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
	surface.depth = -TransformWorldToView(input.positionWS).z;
	surface.color = base.rgb;
	surface.alpha = base.a;
	surface.metallic = GetMetallic(config);
	surface.roughness = GetRoughness(config);
	surface.ambientOcclusion = GetOcclusion(config);
	surface.dither = InterleavedGradientNoise(input.positionCS_SS.xy, 0);

	float normalDistorion = GetTranslucencyViewDependency();
	float power = GetTranslucencyPower();
	float scale = GetTranslucencyScale();
	
	float3 color = GetGBufferBSDFLight(surface, input.positionCS_SS, normalDistorion, power, scale);
	
	float3 viewDir = normalize(_WorldSpaceCameraPos - input.positionWS);
	float3 reflect_dir = reflect(-surface.viewDirection, surface.normal);		
	float mip_Level = surface.metallic * (1.7 - 0.7 * surface.metallic);
	float3 refl = ComputeIndirectSpecular(reflect_dir, input.positionWS, mip_Level);

	color.xyz += refl * surface.color;
	color.xyz *= surface.ambientOcclusion;

	color += GetEmission(config);

#ifdef _DEFFER_FOG
	color = GetDefferFog(input.positionCS_SS, surface.position, color);
#endif
	return float4(color, 1);
}

#endif
