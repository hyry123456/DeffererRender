#ifndef DEFFER_CAMERA_RENDER_PASS
#define DEFFER_CAMERA_RENDER_PASS


#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"

struct Attributes{
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
};

struct Varyings {
    float4 positionCS_SS : SV_POSITION;
    float2 screenUV : VAR_SCREEN_UV;
    float2 screenUV_depth : VAR_SCREEN_UV_DEPTH;
    float4 interpolatedRay : TEXCOORD2;
    float3 viewRay : VAR_VIEWRAY;
};


Varyings BlitPassSimpleVertex(Attributes input){
    Varyings output = (Varyings)0;
    output.positionCS_SS = TransformObjectToHClip(input.positionOS);
    output.screenUV = input.baseUV;
    return output;
}

Varyings BlitPassRayVertex(Attributes input){
    Varyings output = (Varyings)0;
    output.positionCS_SS = TransformObjectToHClip(input.positionOS);
    output.screenUV = input.baseUV;
    output.screenUV_depth = input.baseUV;

    #if UNITY_UV_STARTS_AT_TOP
        if (_GBufferColorTex_TexelSize.y < 0)
            output.screenUV_depth.y = 1 - output.screenUV_depth.y;
    #endif

    int index = 0;
    if (output.screenUV.x < 0.5 && output.screenUV.y < 0.5) {         //位于左下方区域，使用左下方的方向
        index = 0;
    } 
    else if (output.screenUV.x > 0.5 && output.screenUV.y < 0.5) {    //位于右下方
        index = 1;
    } 
    else if (output.screenUV.x > 0.5 && output.screenUV.y > 0.5) {    //右上方
        index = 2;
    } 
    else {                                                  //左上方
        index = 3;
    }

    #if UNITY_UV_STARTS_AT_TOP
    if (_GBufferColorTex_TexelSize.y < 0)
        index = 3 - index;
    #endif

    //获得对应的方向值，之所以我们只用射向远平面的4个点的原因是对于Unity来说，屏幕纹理就是一个正好填充屏幕的4个顶点形成的纹理
    //因此这里描述的顶点也只有4个，因此在传入片元着色器时我们会进行线性插值，插值后的结果就是正确的该纹理方向了
    output.interpolatedRay = _FrustumCornersRay[index];
    return output;
}


float4 CopyFragment(Varyings i) : SV_Target
{
    // return 1;
	return SAMPLE_TEXTURE2D_LOD(_SourceTexture, sampler_linear_clamp, i.screenUV, 0);
}

float CopyDepthPassFragment (Varyings input) : SV_DEPTH {
	return
        SAMPLE_DEPTH_TEXTURE_LOD(_SourceTexture, sampler_point_clamp, input.screenUV, 0);
}


// Varyings SSRPassVertex(Attributes input){
//     Varyings output = (Varyings)0;
//     output.positionCS_SS = TransformObjectToHClip(input.positionOS);
//     output.screenUV = input.baseUV;
    
//     float4 clipPos = float4(input.baseUV * 2 - 1.0, 1.0, 1.0);
//     float4 viewRay = mul(_InverseProjectionMatrix, clipPos);
//     output.viewRay = viewRay.xyz / viewRay.w;
//     return output;
// }

// float4 SSS_Fragment(Varyings i) : SV_Target{
//     float bufferDepth = SAMPLE_DEPTH_TEXTURE_LOD(_GBufferDepthTex, sampler_point_clamp, i.screenUV, 0);
//     float linear01Depth = Linear01Depth(bufferDepth, _ZBufferParams);

//     float3 normalWS = SAMPLE_TEXTURE2D(_GBufferNormalTex, sampler_GBufferNormalTex, i.screenUV).xyz * 2.0 - 1.0;     //法线
//     float3 normalVS = normalize( mul((float3x3)_WorldToCamera, normalWS) );

//     float3 positionVS = linear01Depth * i.viewRay;
//     float3 viewDir = normalize(positionVS);
    
//     float3 reflectDir = reflect(viewDir, normalVS);

//     float2 hitScreenPos = float2(-1, -1);
//     float4 reflectTex = 0;
//     float4 specular = SAMPLE_TEXTURE2D(_GBufferSpecularTex, sampler_SourceTexture, i.screenUV);                   //PBR数据
//     if(specular.w > 0.5){
//         if (screenSpaceRayMarching(positionVS, reflectDir, hitScreenPos))
//         {
//             reflectTex = SAMPLE_TEXTURE2D_LOD(_SourceTexture, sampler_SourceTexture, hitScreenPos, 0);
//         }
//     }
//     return reflectTex;
// }

// float4 BlurHorizontalPassFragment (Varyings input) : SV_TARGET {
// 	float3 color = 0.0;
// 	float offsets[] = {
// 		-4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0
// 	};
// 	float weights[] = {
// 		0.01621622, 0.05405405, 0.12162162, 0.19459459, 0.22702703,
// 		0.19459459, 0.12162162, 0.05405405, 0.01621622
// 	};
// 	for (int i = 0; i < 9; i++) {
// 		float offset = offsets[i] * 2.0 * _SourceTexture_TexelSize.x;
// 		color += SAMPLE_TEXTURE2D(_SourceTexture, sampler_SourceTexture, input.screenUV + float2(offset, 0.0)).rgb * weights[i];
// 	}
// 	return float4(color, 1.0);
// }

// float4 BlurVerticalPassFragment(Varyings input) : SV_TARGET{
// 	float3 color = 0.0;
// 	float offsets[] = {
// 		-3.23076923, -1.38461538, 0.0, 1.38461538, 3.23076923
// 	};
// 	float weights[] = {
// 		0.07027027, 0.31621622, 0.22702703, 0.31621622, 0.07027027
// 	};
// 	for (int i = 0; i < 5; i++) {
// 		float offset = offsets[i] * _SourceTexture_TexelSize.y;
// 		color += SAMPLE_TEXTURE2D(_SourceTexture, sampler_SourceTexture, input.screenUV + float2(0.0, offset)).rgb * weights[i];
// 	}
// 	return float4(color, 1.0);
// }

// float4 Add_SSS_Fragment(Varyings i) : SV_Target{
//     float4 reflectTex = SAMPLE_TEXTURE2D(_SourceTexture, sampler_SourceTexture, i.screenUV );
//     float4 pbr = SAMPLE_TEXTURE2D(_GBufferSpecularTex, sampler_SourceTexture, i.screenUV);                   //PBR数据
//     float3 normalWS = SAMPLE_TEXTURE2D(_GBufferNormalTex, sampler_SourceTexture, i.screenUV).xyz * 2.0 - 1.0;     //法线

//     float bufferDepth = SAMPLE_DEPTH_TEXTURE_LOD(_GBufferDepthTex, sampler_point_clamp, i.screenUV, 0);
//     bufferDepth = LinearEyeDepth(bufferDepth, _ZBufferParams);
//     float3 position = _WorldSpaceCameraPos + bufferDepth * i.interpolatedRay.xyz;
//     float3 viewDirection = normalize(_WorldSpaceCameraPos - position);                                     //视线方向
//     if(pbr.w > 0.5){
//         BRDF brdf = GetBRDF(reflectTex.xyz, pbr.x, pbr.y);
//         float3 specular = ReflectLod(i.screenUV, brdf.roughness );
//         reflectTex.xyz += ReflectBRDF(normalWS, viewDirection, pbr.z, brdf, specular);
//     }
//     return reflectTex;
// }


#endif