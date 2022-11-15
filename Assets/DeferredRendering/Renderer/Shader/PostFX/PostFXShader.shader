Shader "Unlit/PostFXShader"
{
    SubShader
    {
        Cull Off
		ZTest Always
		ZWrite Off
		
		HLSLINCLUDE
            #include "../../ShaderLibrary/Common.hlsl"
            #include "HLSL/PostFXPass.hlsl"
		ENDHLSL

		Pass {	//0
			Name "Bloom Add"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment BloomAddPassFragment
			ENDHLSL
		}
		
		Pass {	//1
			Name "Bloom Horizontal"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment BloomHorizontalPassFragment
			ENDHLSL
		}

		Pass {	//2
			Name "Bloom Prefilter"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment BloomPrefilterPassFragment
			ENDHLSL
		}
		
		Pass {	//3
			Name "Bloom Prefilter Fireflies"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment BloomPrefilterFirefliesPassFragment
			ENDHLSL
		}
		
		Pass {	//4
			Name "Bloom Scatter"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment BloomScatterPassFragment
			ENDHLSL
		}
		
		Pass {	//5
			Name "Bloom Scatter Final"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment BloomScatterFinalPassFragment
			ENDHLSL
		}
		
		Pass {	//6
			Name "Bloom Vertical"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment BloomVerticalPassFragment
			ENDHLSL
		}
		
		Pass {	//7
			Name "Copy"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment CopyPassFragment
			ENDHLSL
		}
		
		Pass {	//8
			Name "Color Grading None"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment ColorGradingNonePassFragment
			ENDHLSL
		}

		Pass {	//9
			Name "Color Grading ACES"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment ColorGradingACESPassFragment
			ENDHLSL
		}

		Pass {	//10
			Name "Color Grading Neutral"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment ColorGradingNeutralPassFragment
			ENDHLSL
		}
		
		Pass {	//11
			Name "Color Grading Reinhard"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment ColorGradingReinhardPassFragment
			ENDHLSL
		}

		Pass {	//12
			Name "Final"
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment FinalPassFragment
			ENDHLSL
		}

		Pass{	//13
            Name "SSR"

            HLSLPROGRAM
                #pragma target 3.5
				#pragma vertex SSRPassVertex
				#pragma fragment SSS_Fragment
            ENDHLSL
        }

		Pass	//14
        {
			Name "GBuffer Draw"

            HLSLPROGRAM
            #pragma vertex BlitPassRayVertex
            #pragma fragment DrawGBufferColorFragment
			#pragma multi_compile _ _USE_CLUSTER
			#pragma multi_compile _ _DEFFER_FOG
			#pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
			#pragma multi_compile _ _OTHER_PCF3 _OTHER_PCF5 _OTHER_PCF7
			#pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
			// #pragma multi_compile _ _SHADOW_MASK_ALWAYS _SHADOW_MASK_DISTANCE
			// #pragma multi_compile _ _LIGHTS_PER_OBJECT
			// #pragma multi_compile _ LIGHTMAP_ON
			// #pragma multi_compile _ LOD_FADE_CROSSFADE


            ENDHLSL
        }

		Pass	//15
        {
			Name "BulkLight"

            HLSLPROGRAM
            #pragma vertex BlitPassRayVertex
            #pragma fragment BulkLightFragment
			#pragma multi_compile _ _USE_CLUSTER

            ENDHLSL
        }

		Pass	//16
        {
			Name "BilateralFilter"

            HLSLPROGRAM
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment BilateralFilterFragment

            ENDHLSL
        }

		Pass	//17
        {
			Name "Blend Bulk"

            HLSLPROGRAM
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment BlendBulkLightFragment

            ENDHLSL
        }

		Pass	//18
		{
			Name "CaculateGray"

            HLSLPROGRAM
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment CaculateGray

            ENDHLSL
		}

		Pass	//19
		{
			Name "FXAA"
            HLSLPROGRAM
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment FXAAFragment

			#pragma multi_compile _ LUMINANCE_GREEN
			#pragma multi_compile _ LOW_QUALITY

            ENDHLSL

		}

		Pass {	//20
			Name "Copy Depth"

			// ColorMask 0
			ZWrite On
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment CopyDepthPassFragment
			ENDHLSL
		}

		Pass{	//21
			Name "Camera Stick Water"
			HLSLPROGRAM
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment CameraStickWaterFragment
            ENDHLSL
		}

		Pass{	//22
			Name "Circle Of Confusion"
			HLSLPROGRAM
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment CircleOfConfusionFragment
            ENDHLSL
		}

		Pass{	//23
			Name "PreFilter"
			HLSLPROGRAM
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment PreFilterFragment
            ENDHLSL
		}

		Pass{	//24
			Name "Bokeh"
			HLSLPROGRAM
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment BokehFragment
            ENDHLSL
		}

		Pass{	//25
			Name "Post Filter"
			HLSLPROGRAM
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment PostFilterFragment
            ENDHLSL
		}

		Pass{	//26
			Name "Combine"
			HLSLPROGRAM
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment CombineFragment
            ENDHLSL
		}
    }
}
