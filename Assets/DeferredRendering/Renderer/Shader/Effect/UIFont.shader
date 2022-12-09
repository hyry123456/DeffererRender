Shader "Defferer/UI/UIFont"
{
    Properties
    {
		_Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		_Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.5
		_Fresnel ("Fresnel", Range(0, 1)) = 1
        _FontCol ("Color", Color) = (0.5, 0.5, 0.5, 1)

		[HDR] _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 0.0)

    }
    SubShader
    {
        HLSLINCLUDE
            #include "../../ShaderLibrary/Common.hlsl"
            #include "../../ShaderLibrary/Surface.hlsl"
            #include "../../ShaderLibrary/Shadows.hlsl"
            #include "../../ShaderLibrary/Light.hlsl"
            #include "../../ShaderLibrary/BRDF.hlsl"
            #include "../../ShaderLibrary/GI.hlsl"
            #include "../../ShaderLibrary/Lighting.hlsl"
            #include "HLSL/EffectInput.hlsl"
		ENDHLSL
        Pass
        {
            Tags {
                "LightMode" = "OutGBuffer"
            }

            Blend One One
            Cull Off
            ZWrite On
            HLSLPROGRAM
            #pragma vertex UIVertex
            #pragma fragment UIFrag

			#pragma target 3.5
			#pragma multi_compile_instancing

            struct Attributes {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 baseUV : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings {
                float4 positionCS_SS : SV_POSITION;
                float3 normalWS : VAR_NORMAL;
                float2 baseUV : VAR_BASE_UV;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            Varyings UIVertex(Attributes input){
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                output.positionCS_SS = TransformObjectToHClip(input.positionOS);
                output.normalWS = TransformObjectToWorldNormal( input.normalOS );
                output.baseUV = input.baseUV;
                return output;
            }

            void UIFrag (Varyings input,
                    out float4 _GBufferColorTex : SV_Target0,
                    out float4 _GBufferNormalTex : SV_Target1,
                    out float4 _GBufferSpecularTex : SV_Target2,
                    out float4 _GBufferBakeTex : SV_Target3
                ) {
                UNITY_SETUP_INSTANCE_ID(input);
                
                //纹理颜色
                float4 main = GetMain(input.baseUV);
                clip(main.a - GetCutoff());
                
                float3 normal = input.normalWS;

                float4 specularData = float4(GetMetallic(), GetSmoothness(), GetFresnel(), 1);		//w赋值为1表示开启PBR
                float3 emission = GetEmission();

                _GBufferColorTex = float4(main.xyz, 1);
                _GBufferNormalTex = float4(normal * 0.5 + 0.5, 1);
                _GBufferSpecularTex = specularData;

                _GBufferBakeTex = float4(emission, 1);
            }


            ENDHLSL

        }

    }
}
