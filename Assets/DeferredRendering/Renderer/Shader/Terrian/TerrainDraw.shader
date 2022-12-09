Shader "Terrain/TerrainDraw"
{
    Properties
    {
    }
    SubShader
    {
		HLSLINCLUDE
            #include "../../ShaderLibrary/Common.hlsl"
            #include "HLSL/TerrainDrawInput.hlsl"
		ENDHLSL
        Pass
        {
            Tags {
                "LightMode" = "OutGBuffer"
            }
			Blend One Zero
			ZWrite On
			HLSLPROGRAM

            #pragma target 4.6

            #pragma vertex tessVert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment TerrainFragment
            #pragma require geometry
            #pragma geometry TerrainGeom


            #include "HLSL/TerrainDrawPass.hlsl"


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
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma vertex tessVert
            #pragma require tessellation
            #pragma hull hull
            #pragma domain domain
            #pragma fragment TerrainFragment_Shadow
            #pragma require geometry
            #pragma geometry TerrainGeom_Shadow

			#include "HLSL/TerrainShadowPass.hlsl"
			ENDHLSL
		}

    }
}
