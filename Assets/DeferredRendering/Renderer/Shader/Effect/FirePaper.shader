Shader "UI/FirePaper"
{
    Properties
    {
		_Cutoff ("Alpha Cutoff", Range(0, 1.0)) = 0.5
		_Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.5
		_Fresnel ("Fresnel", Range(0, 1)) = 1
        _FontCol ("Color", Color) = (0.5, 0.5, 0.5, 1)

        _NoiseTex("Noise Texture", 2D) = "grey" {}
        [HDR]_FireColor("Fire Color", COLOR) = (0.5, 0.5, 0.5, 0.5)
        _PaperTex("Paper Texture", 2D) = "white" {}
        [NoScaleOffset]_PaperedTex("Papered Texture", 2D) = "black" {}
        _WaveSpeed("Noise Wave Speed", VECTOR) = (1, 1, 1.3, 1.3)
        _FireBegin("Fired Begin Radio", Range(0.3, 1.0)) = 0.8
        _BlendBegin("Blend Begin X", Range(0, 1)) = 0
        _BlendRange("Blend Range", Range(0, 1)) = 0

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

            Blend One Zero
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
                float4 waveUV : VAR_NOISE;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            Varyings UIVertex(Attributes input){
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                output.positionCS_SS = TransformObjectToHClip(input.positionOS);
                output.normalWS = TransformObjectToWorldNormal( input.normalOS );
                output.baseUV = TransformPaperUV( input.baseUV );
                output.waveUV = TransformNoiseUV( input.baseUV ).xyxy * float4(1, 1, 1.3, 1.3) + GetWaveSpeed() * _Time.x;
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
                float4 paperCol = SAMPLE_TEXTURE2D(_PaperTex, sampler_PaperTex, input.baseUV);
                clip(paperCol.a - GetCutoff());
                float4 paperedCol = SAMPLE_TEXTURE2D(_PaperedTex, sampler_PaperTex, input.baseUV);
                float noise = GetNoise(input.waveUV);

                // float4 firCol = GetFireValue(noise);
                float fireRadio = GetFireRadio(noise);
                float4 fireColor = GetFireColor();
                float4 fireEmssion = fireRadio * fireColor;

                float2 blendData = GetBlendDate();  //x=begin，y=Range
                float blendValue = smoothstep(blendData.x - blendData.y, blendData.x + blendData.y, input.baseUV.x + noise * blendData.y);
                float3 burnRange = (1.0 - smoothstep(0.15, 0.35, abs( blendValue - 0.5 ))) * fireColor * noise;
                float4 col = lerp(paperedCol, paperCol, blendValue);

                clip(paperCol.a * (input.baseUV.x + noise * blendData.y)  -  (blendData.x - 0.3)) ;


                float3 normal = input.normalWS;

                float4 specularData = float4(GetMetallic(), GetSmoothness(), GetFresnel(), 1);		//w赋值为1表示开启PBR
                float3 emission = GetEmission();

                _GBufferColorTex = float4(col.xyz, 1);
                _GBufferNormalTex = float4(normal * 0.5 + 0.5, 1);
                _GBufferSpecularTex = specularData;
                _GBufferBakeTex = float4(fireEmssion.xyz * (1.0 - blendValue) + burnRange, 1);
            }


            ENDHLSL

        }

    }
}
