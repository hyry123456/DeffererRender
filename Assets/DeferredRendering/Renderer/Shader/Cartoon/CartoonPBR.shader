Shader "Defferer/CartoonPBR"
{
    Properties
    {
        _MainTex("Brighness Map", 2D) = "white"{}
        _LightMap("Light Map", 2D) = "white" {}
        _DiffuseRamp("Diffuse Ramp Map", 2D) = "white" {}
        _SpecularRamp("Specular Ramp Map", 2D) = "black" {}
        // _BrighnessCol("Brighness Color", Color) = (1, 1, 1, 1)
        // _DarkFaceColor("_DarkFaceColor", Color) = (1, 1, 1, 1)
        // _DeepDarkColor("_DeepDarkColor", Color) = (1,1,1,1)
        _OutLineCol("Outline Color", Color) = (0, 0, 0, 0)
        _OutlineWidth("Outline Width", Range(0.001, 1)) = 0.1
        // _ShadowAttWeight("Shadow Attenion Weight", Range(0, 1)) = 0.5
        // _DividLineDeepDark("Divid Line Deep Dark", Range(0.3, 1)) = 0.5
        // _DividLineM("Divid Line Media", Range(0, 1)) = 0.1
        // _DividLineD("Divid Line Down", Range(-1.0, 0)) = -0.5
        _Roughness("Roughness", Range(0, 1)) = 0.1
        _Metallic("Metallic", Range(0, 1)) = 0.1
        // _Glossiness("Glossiness", Range(0, 1)) = 0.1
        // _DividSharpness("_DividSharpness", Range(0, 1)) = 0.2
        // _FresnelEff("Fresnel Intensity", Range(0, 1)) = 0.1
        // _DividLineSpec("Specular Start", Range(0.7, 1)) = 0.85
    }
    SubShader
    {
        HLSLINCLUDE
            #include "../../ShaderLibrary/Common.hlsl"
            #include "HLSL/CartoonInput.hlsl"
		ENDHLSL
        //边框Pass
        Pass
	    {
            Name "Outline"
	        Tags {"LightMode" = "FowardAdd" "RenderType" = "Transparent"}
			 
            Cull Front
        
            HLSLPROGRAM
            #pragma vertex outlineVert
            #pragma fragment outlineFrag
            #include "HLSL/CartoonPass.hlsl"


            ENDHLSL 
        }

        //边框简单的着色
        Pass
	    {
            Name "Shade"
	        Tags {"LightMode" = "FowardShader" "RenderType" = "Transparent"}
			 
            Cull Back
            Blend One Zero
        
            HLSLPROGRAM

			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
			#pragma multi_compile _ _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7
			#pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile _ _USE_CLUSTER
			#pragma multi_compile_instancing

            #pragma vertex CartoonVert
            #pragma fragment CartoonFrag
            #include "HLSL/CartoonPass.hlsl"


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
			#pragma fragment DirectCasterPassFragment
			#include "../Common/DiectShadowCasterPass.hlsl"
			ENDHLSL
		}

    }
}
