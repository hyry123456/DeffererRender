Shader "Terrain/TreeLeaf"
{
    Properties
    {
        _BaseMap("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_ShiftColor("BSDF Shift Color", Color) = (0.5, 0.5, 0.5, 1.0)
		_Width("BSDF Width", Range(0.1, 1.0)) = 1
		_Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0

		[Toggle(_MASK_MAP)] _MaskMapToggle ("Mask Map", Float) = 0
		[NoScaleOffset] _MaskMap("Mask (MODS)", 2D) = "white" {}
		_Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.5
		_Fresnel ("Fresnel", Range(0, 1)) = 1

		[Toggle(_NORMAL_MAP)] _NormalMapToggle ("Normal Map", Float) = 0
		[NoScaleOffset] _NormalMap("Normals", 2D) = "bump" {}
		_NormalScale("Normal Scale", Range(0, 1)) = 1

		[NoScaleOffset] _EmissionMap("Emission", 2D) = "white" {}
		[HDR] _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 0.0)

		[Toggle(_DETAIL_MAP)] _DetailMapToggle ("Detail Maps", Float) = 0
		_DetailMap("Details", 2D) = "linearGrey" {}
		[NoScaleOffset] _DetailNormalMap("Detail Normals", 2D) = "bump" {}
		_DetailAlbedo("Detail Albedo", Range(0, 1)) = 1
		_DetailSmoothness("Detail Smoothness", Range(0, 1)) = 1
		_DetailNormalScale("Detail Normal Scale", Range(0, 1)) = 1

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1

		[HideInInspector] _MainTex("Texture for Lightmap", 2D) = "white" {}
		[HideInInspector] _Color("Color for Lightmap", Color) = (0.5, 0.5, 0.5, 1.0)
    }
    SubShader
    {
        HLSLINCLUDE
            #include "../../ShaderLibrary/Common.hlsl"
            #include "HLSL/GBufferInput.hlsl"
            #include "HLSL/TreeInput.hlsl"
		ENDHLSL

        Pass
        {
            Tags {
                "LightMode" = "OutGBuffer"
            }

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
			#include "HLSL/TreeLeafPass.hlsl"
			ENDHLSL
        }

		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			ColorMask 0
			
			HLSLPROGRAM
			#pragma target 3.5
			#pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
			#pragma shader_feature _CLIPPING
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_instancing
			#pragma vertex ShadowCasterPassVertex
			#pragma fragment ShadowCasterPassFragment
			#include "HLSL/TreeShadowCasterPass.hlsl"
			ENDHLSL
		}

		// Pass{		//透明渲染Pass
		// 	Tags {
        //         "LightMode" = "FowardShader"
        //     }

		// 	Blend [_SrcBlend] [_DstBlend]
		// 	ZWrite [_ZWrite]
			

        //     HLSLPROGRAM
        //     #pragma vertex LitPassVertex
        //     #pragma fragment LitPassFragment

		// 	#pragma target 3.5
		// 	#pragma shader_feature _CLIPPING
		// 	#pragma shader_feature _MASK_MAP
		// 	#pragma shader_feature _NORMAL_MAP
		// 	#pragma shader_feature _DETAIL_MAP
		// 	#pragma multi_compile _ LIGHTMAP_ON
		// 	#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
		// 	#pragma multi_compile _ _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7
		// 	#pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
		// 	#pragma multi_compile _ LOD_FADE_CROSSFADE
		// 	#pragma multi_compile_instancing
		// 	#include "HLSL/TransperantPass.hlsl"
		// 	ENDHLSL
		// }
    }
}
