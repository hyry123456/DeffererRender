#ifndef DEFFER_GBUFFER_READY_PASS_2D
#define DEFFER_GBUFFER_READY_PASS_2D

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"

struct Attributes2D
{
    float4 vertex   : POSITION;
    float2 texcoord : TEXCOORD0;
	float4 color : COLOR;
    float4 tangentOS : TANGENT;
	GI_ATTRIBUTE_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings2D
{
    float4 positionCS_SS   : SV_POSITION;
    float2 baseUV  : TEXCOORD0;
    float3 TtoW0 : NORMAL_TO_WORLD0;
    float3 TtoW1 : NORMAL_TO_WORLD1;
    float3 TtoW2 : NORMAL_TO_WORLD2;
    float3 positionWS : WORLDPOS;
	float4 color : COLOR;
	GI_VARYINGS_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

#define _2D_Normal float3(0, 0, -1)

Varyings2D LitPassVertex (Attributes2D input) {
	Varyings2D output = (Varyings2D)0;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	TRANSFER_GI_DATA(input, output);
	output.positionWS = TransformObjectToWorld(input.vertex.xyz);
	output.positionCS_SS = TransformWorldToHClip(output.positionWS);
	output.baseUV = TransformBaseUV(input.texcoord);
	output.color = input.color;

	float3 tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
	float3 binormalWS = cross(_2D_Normal, tangentWS) * input.tangentOS.w;

	output.TtoW0 = float3(tangentWS.x, binormalWS.x, _2D_Normal.x);
	output.TtoW1 = float3(tangentWS.y, binormalWS.y, _2D_Normal.y);
	output.TtoW2 = float3(tangentWS.z, binormalWS.z, _2D_Normal.z);

	#if defined(_DETAIL_MAP)
		output.detailUV = TransformDetailUV(input.baseUV);
	#endif
	return output;
}

void LitPassFragment (Varyings2D input,
        out float4 _GBufferRT0 : SV_Target0,	//rgb:abledo,w:metalness
        out float2 _GBufferRT1 : SV_Target1,	//R,G:EncodeNormal
        out float4 _GBufferRT2 : SV_Target2,	//rgb:emissive,w:roughness
        out float4 _GBufferRT3 : SV_Target3	//rgb:reflect,w:AO
    ) {
	UNITY_SETUP_INSTANCE_ID(input);
	InputConfig config = GetInputConfig(input.baseUV);
	// ClipLOD(input.positionCS_SS.xy, unity_LODFade.x);
	
	#if defined(_MASK_MAP)
		config.useMask = true;
	#endif
	#if defined(_DETAIL_MAP)
		config.detailUV = input.detailUV;
		config.useDetail = true;
	#endif
	
	//纹理颜色
	float4 base = GetBase(config) * input.color;
	float3 positionWS = input.positionWS;

	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(config));
	#endif
	
	float3 normal = _2D_Normal;    //默认向前
	float3 perNormal = float3(input.TtoW0.z, input.TtoW1.z, input.TtoW2.z);
	#if defined(_NORMAL_MAP)
		normal = GetNormalTS(config);
		normal = normalize(float3(dot(input.TtoW0.xyz, normal), dot(input.TtoW1.xyz, normal), dot(input.TtoW2.xyz, normal)));
	#else
		normal = normalize(perNormal);
	#endif
	half2 normalOct = PackNormalOct(normal);
	float metallic = GetMetallic(config);

	float3 emissive = GetEmission(config);
	float roughness = GetRoughness(config);
	float ao = GetOcclusion(config);
	float3 sh = GetBakeDate(GI_FRAGMENT_DATA(input), positionWS, perNormal) * ao;
	half oneMinusReflectivity = (1 - metallic) * 0.96;
	//计算漫反射率，实际上F0时的漫反射系数，也就是确定漫反射颜色，如果金属度高，那么就说明漫反射很弱，直接就是值为0
	half3 diffColor = base.rgb * oneMinusReflectivity;
	sh *= diffColor;
	emissive += sh;		//计算过OA的间接光数据，之后直接加上去就行了
	
	float3 viewDir = normalize(_WorldSpaceCameraPos - positionWS);
	float3 reflect_dir = reflect(-viewDir, normal);		
	float mip_Level = metallic * (1.7 - 0.7 * metallic);
	float3 refl = ComputeIndirectSpecular(reflect_dir, positionWS, mip_Level);


	_GBufferRT0 = float4(base.rgb, metallic);
	_GBufferRT1 = normalOct;
	_GBufferRT2 = float4(emissive, roughness);
	_GBufferRT3 = float4(refl, ao);

}

#endif