#ifndef DEFFER_WATER_PASS_INCLUDE
#define DEFFER_WATER_PASS_INCLUDE

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
	float4 baseUV : VAR_BASE_UV;
    float4 noiseUV : VAR_NOISE;
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
    output.noiseUV = input.baseUV.xyxy * float4(1, 1, 1.3, 1.3) + float4(1, 1, -1, -2) * _Time.x;
	return output;
}


void LitPassFragment (Varyings input,
        out float4 _GBufferRT0 : SV_Target0,	//rgb:abledo,w:metalness
        out float2 _GBufferRT1 : SV_Target1,	//R,G:EncodeNormal
        out float4 _GBufferRT2 : SV_Target2,	//rgb:emissive,w:roughness
        out float4 _GBufferRT3 : SV_Target3		//rgb:reflect,w:AO
    ) {
	UNITY_SETUP_INSTANCE_ID(input);
	ClipLOD(input.positionCS_SS.xy, unity_LODFade.x);
	
	//纹理颜色
	float4 base = GetBase(input.baseUV.xy);
	float3 positionWS = float3(input.TtoW0.w, input.TtoW1.w, input.TtoW2.w);
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff());
	#endif
	
	float3 normal;
	float3 perNormal = float3(input.TtoW0.z, input.TtoW1.z, input.TtoW2.z);
	#if defined(_NORMAL_MAP)
		normal = GetNormalTS(input.baseUV.xy);
		normal = normalize(float3(dot(input.TtoW0.xyz, normal), dot(input.TtoW1.xyz, normal), dot(input.TtoW2.xyz, normal)));
	#else
		normal = normalize(perNormal);
	#endif


	//烘焙灯光，只处理了烘焙贴图，没有处理阴影烘焙，需要注意
	// float3 bakeColor = GetBakeDate(GI_FRAGMENT_DATA(input), positionWS, perNormal);
	// float oneMinusReflectivity = OneMinusReflectivity(specularData.r);
	// float3 diffuse = base.rgb * oneMinusReflectivity;
	// bakeColor = bakeColor * diffuse + GetEmission(input.baseUV.xy);				//通过金属度缩减烘焙光，再加上自发光，之后会在着色时直接加到最后的结果上
	// float4 shiftColor = GetShiftColor();			//分别使用三张图的透明通道写入

    // float3 viewDir = normalize(positionWS - _WorldSpaceCameraPos);
	// float3 reflectDir = reflect(viewDir, normal);

    float3 noiseNor = GetNoiseNormal(input.noiseUV);

	float2 mainBRDF = float2(GetMetallic(), GetRoughness());
	float2 waterBRDF = float2(GetWaterMetallic(), GetWaterRoughness());




    float4 waterVal = GetWater(input.baseUV.zw);
    float4 waterCol = GetWaterCol();
	// perNormal = normalize(noiseNor + perNormal);						//调整法线
	perNormal = lerp(perNormal, normalize(noiseNor + perNormal), waterVal.x);

    float3 buffCol = lerp(base.xyz, waterCol.xyz * base.xyz, waterVal.x);
	float3 buffNor = lerp(normal, perNormal, waterVal.x);
	float2 buffNorOct = PackNormalOct(buffNor);
	float2 buffBRDF = lerp(mainBRDF, waterBRDF, waterVal.x);

	float3 viewDir = normalize(positionWS - _WorldSpaceCameraPos);
	float3 reflectDir = reflect(viewDir, normal);		
    float3 orirefDir = reflect(viewDir, perNormal);
	float mip_Level = mainBRDF.x * (1.7 - 0.7 * mainBRDF.x);
	float mip_Level_Water = waterBRDF.x * (1.7 - 0.7 * waterBRDF.x);

	float3 reflect = ComputeIndirectSpecular(reflectDir, positionWS, mip_Level);
	float3 reflect1 = ComputeIndirectSpecular(buffNor, positionWS + noiseNor * 5, mip_Level_Water);

    float3 buffRef = lerp(reflect, reflect1, waterVal.x);

	float3 emissive = GetEmission(input.baseUV.xy);
	// float ao = GetOcclusion();
	float ao = 1;
	float3 sh = GetBakeDate(GI_FRAGMENT_DATA(input), positionWS, perNormal) * ao;
	half oneMinusReflectivity = (1 - buffBRDF.r) * 0.96;
	half3 diffColor = base.rgb * oneMinusReflectivity;
	sh *= diffColor;
	emissive += sh;		//计算过OA的间接光数据，之后直接加上去就行了
	emissive = lerp(emissive, 0, waterVal.x);

	_GBufferRT0 = float4(buffCol, buffBRDF.x);
	_GBufferRT1 = buffNorOct;
	_GBufferRT2 = float4(emissive, buffBRDF.y);
	_GBufferRT3 = float4(buffRef, ao);
}


#endif