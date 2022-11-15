#ifndef DEFFER_TERRAIN_LEAF_PASS
#define DEFFER_TERRAIN_LEAF_PASS


#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/MyTerrain.hlsl"

struct Varyings_TREE {
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
	// GI_VARYINGS_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};


Varyings_TREE LitPassVertex (Attributes_full input) {
	Varyings_TREE output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
    TreeVertLeaf(input);

	output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
	output.positionCS_SS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS.xyz);
	#if defined(_NORMAL_MAP)
		output.tangentWS = float4(
			TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w
		);
	#endif
	output.baseUV = TransformBaseUV(input.texcoord0.xy);
	#if defined(_DETAIL_MAP)
		output.detailUV = TransformDetailUV(input.texcoord0.xy);
	#endif
	return output;
}

void LitPassFragment (Varyings_TREE input,
        out float4 _GBufferColorTex : SV_Target0,
        out float4 _GBufferNormalTex : SV_Target1,
        out float4 _GBufferSpecularTex : SV_Target2,
        out float4 _GBufferBakeTex : SV_Target3
    ) {
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
	
	//纹理颜色
	float4 base = GetBase(config);
	float3 positionWS = input.positionWS;
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(config));
	#endif
	
	float3 normal;
	float3 perNormal = input.normalWS;
	#if defined(_NORMAL_MAP)
		normal = NormalTangentToWorld(
			GetNormalTS(config), input.normalWS, input.tangentWS
		);
	#else
		normal = normalize(input.normalWS);
	#endif

	float width = GetWidth(config);
	float4 specularData = float4(GetMetallic(config), GetSmoothness(config), GetFresnel(config), width);		//w赋值为1表示开启PBR

	//烘焙灯光，只处理了烘焙贴图，没有处理阴影烘焙，需要注意
	// float3 bakeColor = GetBakeDate(GI_FRAGMENT_DATA(input), positionWS, perNormal);
	float oneMinusReflectivity = OneMinusReflectivity(specularData.r);
	float3 diffuse = base.rgb * oneMinusReflectivity;
	// bakeColor = bakeColor * diffuse + GetEmission(config);				//通过金属度缩减烘焙光，再加上自发光，之后会在着色时直接加到最后的结果上
	float4 shiftColor = GetShiftColor(config);			//分别使用三张图的透明通道写入

	_GBufferColorTex = float4(base.xyz, shiftColor.x);
	_GBufferNormalTex = float4(normal * 0.5 + 0.5, shiftColor.y);
	_GBufferSpecularTex = specularData;

	_GBufferBakeTex = float4(GetEmission(config), shiftColor.z);
}


#endif
