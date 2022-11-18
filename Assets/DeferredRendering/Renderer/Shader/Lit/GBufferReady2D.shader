Shader "Defferer/GBufferReady2D"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0

		[Toggle(_MASK_MAP)] _MaskMapToggle ("Mask Map", Float) = 0
		[NoScaleOffset] _MaskMap("Mask (MODS)", 2D) = "white" {}
		_Metallic ("Metallic", Range(0, 1)) = 0
		_Roughness ("Roughness", Range(0, 1)) = 0.5

		[Toggle(_NORMAL_MAP)] _NormalMapToggle ("Normal Map", Float) = 0
		[NoScaleOffset] _NormalMap("Normals", 2D) = "bump" {}
		_NormalScale("Normal Scale", Range(0, 3.0)) = 1

		[NoScaleOffset] _EmissionMap("Emission", 2D) = "white" {}
		[HDR] _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 0.0)

		[Toggle(_DETAIL_MAP)] _DetailMapToggle ("Detail Maps", Float) = 0
		_DetailMap("Details", 2D) = "linearGrey" {}
		[NoScaleOffset] _DetailNormalMap("Detail Normals", 2D) = "bump" {}
		_DetailAlbedo("Detail Albedo", Range(0, 1)) = 1
		_DetailRoughness("Detail Roughness", Range(0, 1)) = 1
		_DetailNormalScale("Detail Normal Scale", Range(0, 1)) = 1

		// [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		// [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
		// [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1
		// [Enum(UnityEngine.Rendering.CullMode)] _CullBack ("Cull Off", Float) = 0
    }
    SubShader
    {
        HLSLINCLUDE
            #include "../../ShaderLibrary/Common.hlsl"
            #include "HLSL/GBufferInput.hlsl"
		ENDHLSL
        Pass
        {
            Tags {
                "LightMode" = "OutGBuffer"
            }
			Cull Off
			ZWrite On

            HLSLPROGRAM
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

			#pragma target 3.5
			#pragma shader_feature _CLIPPING
			#pragma shader_feature _MASK_MAP
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _DETAIL_MAP
			#pragma multi_compile _ LIGHTMAP_ON
			
			#pragma multi_compile_instancing
			#include "HLSL/GBufferPass2D.hlsl"
			ENDHLSL
        }

		//Pass {
		//	Tags {
		//		"LightMode" = "ShadowCaster"
		//	}

		//	ColorMask 0
		//	Cull Off
		//	
		//	HLSLPROGRAM
		//	#pragma target 3.5
		//	#pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
		//	#pragma shader_feature _CLIPPING
		//	#pragma multi_compile _ LOD_FADE_CROSSFADE
		//	#pragma multi_compile_instancing
		//	#pragma vertex ShadowCasterPassVertex
		//	#pragma fragment ShadowCasterPassFragment
		//	#include "../Common/ShadowCasterPass.hlsl"
		//	ENDHLSL
		//}

		//Pass{		//透明渲染Pass
		//	Tags {
  //              "LightMode" = "FowardShader"
  //          }

		//	Blend SrcAlpha OneMinusSrcAlpha
		//	ZWrite Off
		//	Cull Off

  //          HLSLPROGRAM
  //          #pragma vertex LitPassVertex
  //          #pragma fragment LitPassFragment

		//	#pragma target 3.5
		//	#pragma shader_feature _CLIPPING
		//	#pragma shader_feature _MASK_MAP
		//	#pragma shader_feature _NORMAL_MAP
		//	#pragma shader_feature _DETAIL_MAP
		//	#pragma multi_compile _ LIGHTMAP_ON

		//	#pragma multi_compile _ _USE_CLUSTER
		//	#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
		//	#pragma multi_compile _ _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7
		//	#pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
		//	
		//	#pragma multi_compile_instancing
		//	#include "HLSL/Transperant2DPass.hlsl"
		//	ENDHLSL
		//}

    }
}
