#ifndef DEFFER_TRANSPARENT2D_PASS_INCLUDED
#define DEFFER_TRANSPARENT2D_PASS_INCLUDED

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

	#if defined(_NORMAL_MAP)
        float3 worldNormal = _2D_Normal;
        float3 worldTangent = TransformObjectToWorldDir(input.tangentOS.xyz);
        float3 worldBinormal = cross(worldNormal, worldTangent) * input.tangentOS.w;
        //按列排序获得切线空间转世界空间的矩阵,顺便加一个世界坐标位置
        output.TtoW0 = float3(worldTangent.x, worldBinormal.x, worldNormal.x);
        output.TtoW1 = float3(worldTangent.y, worldBinormal.y, worldNormal.y);
        output.TtoW2 = float3(worldTangent.z, worldBinormal.z, worldNormal.z);
	#endif

	#if defined(_DETAIL_MAP)
		output.detailUV = TransformDetailUV(input.baseUV);
	#endif
	return output;
}


float4 LitPassFragment (Varyings2D input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);
	InputConfig config = GetInputConfig(input.baseUV);

	
	#if defined(_MASK_MAP)
		config.useMask = true;
	#endif
	#if defined(_DETAIL_MAP)
		config.detailUV = input.detailUV;
		config.useDetail = true;
	#endif
	
	float4 base = GetBase(config) * input.color;
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(config));
	#endif
	
	Surface surface = (Surface)0;
	surface.position = input.positionWS;

	float3 normal = _2D_Normal;    //默认向前
	#if defined(_NORMAL_MAP)
        float3 bump = GetNormalMap(config); //获取法线
        normal = normalize(float3(dot(input.TtoW0, bump), dot(input.TtoW1, bump), dot(input.TtoW2, bump)));
	#else
		normal = _2D_Normal;
	#endif

    surface.normal = normal;
    surface.interpolatedNormal = _2D_Normal;

	surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
	surface.depth = -TransformWorldToView(input.positionWS).z;
	surface.color = base.rgb;
	surface.alpha = base.a;
	surface.metallic = GetMetallic(config);
	surface.smoothness = GetSmoothness(config);
	surface.fresnelStrength = GetFresnel(config);
	surface.dither = InterleavedGradientNoise(input.positionCS_SS.xy, 0);
	
	#if defined(_PREMULTIPLY_ALPHA)
		BRDF brdf = GetBRDF(surface, true);
	#else
		BRDF brdf = GetBRDF(surface);
	#endif

	float3 color = GetGBufferLight(surface, brdf, input.positionCS_SS);
	color += GetEmission(config);
	return float4(color, base.w);
}


#endif