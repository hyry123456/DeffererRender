#ifndef DEFFER_GBUFFER_READY_PASS_INCLUDED
#define DEFFER_GBUFFER_READY_PASS_INCLUDED

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"

struct Attributes {
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float4 tangentOS : TANGENT;
	float2 baseUV : TEXCOORD0;
	GI_ATTRIBUTE_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings {
	float4 positionCS_SS : SV_POSITION;
	float4 TtoW0 : VAR_TT0;
	float4 TtoW1 : VAR_TT1;
	float4 TtoW2 : VAR_TT2;
	float2 baseUV : VAR_BASE_UV;
	#if defined(_DETAIL_MAP)
		float2 detailUV : VAR_DETAIL_UV;
	#endif
	GI_VARYINGS_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex (Attributes input) {
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	TRANSFER_GI_DATA(input, output);
	float3 positionWS = TransformObjectToWorld(input.positionOS);
	float3 normalWS = TransformObjectToWorldNormal( input.normalOS );
	float3 tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
	float3 binormalWS = cross(normalWS, tangentWS) * input.tangentOS.w;

	output.positionCS_SS = TransformWorldToHClip(positionWS);

	output.TtoW0 = float4(tangentWS.x, binormalWS.x, normalWS.x, positionWS.x);
	output.TtoW1 = float4(tangentWS.y, binormalWS.y, normalWS.y, positionWS.y);
	output.TtoW2 = float4(tangentWS.z, binormalWS.z, normalWS.z, positionWS.z);

	output.baseUV = TransformBaseUV(input.baseUV);
	#if defined(_DETAIL_MAP)
		output.detailUV = TransformDetailUV(input.baseUV);
	#endif
	return output;
}

void LitPassFragment (Varyings input,
        out float4 _GBufferColorTex : SV_Target0,
        out float4 _GBufferNormalTex : SV_Target1,
        out float4 _GBufferSpecularTex : SV_Target2,
        out float4 _GBufferBakeTex : SV_Target3,
		out float4 _ReflectTargetTex : SV_Target4
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
	float3 positionWS = float3(input.TtoW0.w, input.TtoW1.w, input.TtoW2.w);
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(config));
	#endif
	
	float3 normal;
	float3 perNormal = float3(input.TtoW0.z, input.TtoW1.z, input.TtoW2.z);
	#if defined(_NORMAL_MAP)
		normal = GetNormalTS(config);
		normal = normalize(float3(dot(input.TtoW0.xyz, normal), dot(input.TtoW1.xyz, normal), dot(input.TtoW2.xyz, normal)));
	#else
		normal = normalize(perNormal);
	#endif

	float width = GetWidth(config);
	float4 specularData = float4(GetMetallic(config), GetSmoothness(config), GetFresnel(config), width);		//w赋值为1表示开启PBR

	//烘焙灯光，只处理了烘焙贴图，没有处理阴影烘焙，需要注意
	float3 bakeColor = GetBakeDate(GI_FRAGMENT_DATA(input), positionWS, perNormal);
	float oneMinusReflectivity = OneMinusReflectivity(specularData.r);
	float3 diffuse = base.rgb * oneMinusReflectivity;
	bakeColor = bakeColor * diffuse + GetEmission(config);				//通过金属度缩减烘焙光，再加上自发光，之后会在着色时直接加到最后的结果上
	float4 shiftColor = GetShiftColor(config);			//分别使用三张图的透明通道写入

	float3 reflectDir = reflect( normalize((positionWS - _WorldSpaceCameraPos)), normal);

	float3 reflect = ComputeIndirectSpecular(reflectDir, positionWS);

	_GBufferColorTex = float4(base.xyz, shiftColor.x);
	_GBufferNormalTex = float4(normal * 0.5 + 0.5, shiftColor.y);
	_GBufferSpecularTex = specularData;

	_ReflectTargetTex = float4(reflect, 1);
	_GBufferBakeTex = float4(bakeColor, shiftColor.z);
}


#endif