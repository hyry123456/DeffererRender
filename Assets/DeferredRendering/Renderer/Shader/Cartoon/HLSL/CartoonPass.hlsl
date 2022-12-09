#ifndef DEFFER_CARTOON_PASS
#define DEFFER_CARTOON_PASS

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"

struct a2v 
{
    float3 vertex : POSITION;
    // float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};
struct v2f
{
    float4 pos : SV_POSITION;
};

v2f outlineVert (a2v input) 
{
    v2f output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    float4 pos = TransformObjectToHClip(input.vertex);
    //获得视角空间的法线坐标,由于我们将平均后的法线坐标存储在了顶点色中，所以使用这个属性
    float3 viewNormal = mul((float3x3)unity_IT_MatrixMV,  input.tangent.xyz);
    //将法线变换到NDC空间，NDC空间看起来是一个长方形，可以保证在法线在任何情况下看起来都是一样长的
    // float3 ndcNormal = normalize(TransformWViewToHClip(viewNormal).xyz) * pos.w;
    float3 ndcNormal = normalize(TransformWViewToHClip(viewNormal).xyz);
    float3 normal = input.tangent.xyz;
    float outlineWidth = GetOutline(input.uv);
    // pos.xy += 0.01 * outlineWidth * ndcNormal.xy;
    pos.xy += ndcNormal.xy * (pos.w * outlineWidth * 0.1);
    output.pos = pos;
    return output;
}

half4 outlineFrag(v2f i) : SV_TARGET 
{
    return GetOutlineColor();
}

struct Attributes{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 baseUV : TEXCOORD0;
};

struct Varyings{
    float4 positionCS : SV_POSITION;
    float3 positionWS : VAR_POSITION;
    float3 normalWS : VAR_NORMAL;
    float2 baseUV : VAR_UV;
};

Varyings CartoonVert(Attributes input){
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.baseUV = TransformBaseUV(input.baseUV);
    return output;
}



half3 LightingToon(Surface surface, Light light, CartoonData cart) {
    //首先采集漫方式
	float3 lightDir = light.direction, viewDir = surface.viewDirection, normal = surface.normal;

	//计算BRDF需要用到一些项
	// 高光数据
	half3 halfDir = normalize(lightDir + viewDir);
	//视线方向与法线方向的余弦值
	half nv = saturate(dot(normal,viewDir));
	//法线方向与灯光方向的余弦值
	half nl = saturate(dot(normal,lightDir));
	//高光数据与世界法线的余弦值
	half nh = saturate(dot(normal,halfDir));
	//灯光方向与视线方向的余弦值
	half lv = saturate(dot(lightDir,viewDir));
	//灯光方向与高光方向的余弦值
	half lh = saturate(dot(lightDir,halfDir));

    //半漫反射
    half nl_half = dot(normal,lightDir) * 0.5 + 0.5;
    float radius = 1.0 /( length(fwidth(normalize(surface.normal))) / length(fwidth(surface.position)));
    float3 specularCol = lerp(0.4, surface.color, surface.metallic);

    //高光
    half V = ComputeSmithJointGGXVisibilityTerm(nl, nv, surface.roughness);//计算BRDF高光反射项，可见性V  这里把分母已经除了
    half D = ComputeGGXTerm(nh, surface.roughness);//计算BRDF高光反射项,法线分布函数D
	half3 F = ComputeFresnelTerm(specularCol, lh);//计算BRDF高光反射项，菲涅尔项F

    float3 specularRamp = GetSpecularRamp(V * D, radius).xyz;
    float3 spec = saturate(specularRamp * F * D * V * nl);

    float3 rampColor = GetDiffuseRamp((nl_half + V * D) * light.attenuation, radius).rgb;

    return rampColor * surface.color + spec * light.attenuation;

}

float3 GetCartoonLight(Surface surface, float4 clipPos, CartoonData cart){
	ShadowData shadowData = GetShadowData(surface);

	float3 re = 0;
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surface, shadowData);
        re += LightingToon(surface, light, cart);
	}
    return re;

}

float4 CartoonFrag(Varyings input) : SV_TARGET{
	UNITY_SETUP_INSTANCE_ID(input);
    float4 brighnessCol = GetBrighnessColor(input.baseUV);
    float3 lightMap = GetLightMap(input.baseUV);

    Surface surface = (Surface)0;
    surface.depth = -TransformWorldToView(input.positionWS).z;
    surface.dither = InterleavedGradientNoise(input.positionCS.xy, 0);
    surface.position = input.positionWS;
    surface.normal = input.normalWS;
    surface.color = brighnessCol.xyz;
    surface.alpha = brighnessCol.w;
    surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
    surface.roughness = GetRougness();
    surface.metallic = GetMetallic();


    surface.ambientOcclusion = lightMap.y;

    CartoonData cartoon;
    cartoon.specularMask = lightMap.z;
    cartoon.smoothMap = lightMap.x;

    float3 color = GetCartoonLight(surface, input.positionCS, cartoon);


    
    return float4(color, 1);
}

#endif