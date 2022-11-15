//通过设置得到的阴影平面
Shader "Defferer/ShadowPlaneOffsetBySet"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            Tags {
                "LightMode" = "OutGBuffer"
            }
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../../ShaderLibrary/Common.hlsl"

            SAMPLER(sampler_MainTex);
            TEXTURE2D(_MainTex);
            float4 _ShadowColor;
            float4 _MainTex_TexelSize;
            //x存储模糊大小，y存储模糊方向(1为x，0为y)，z是模糊距离大小
            float4 _BlurData;

			#pragma target 3.5

            struct Attributes {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct Varyings {
                float4 positionCS_SS : SV_POSITION;
                float blurRadio : VAR_BLUR;
                float2 uv : VAR_TEXCOORD;
            };



            Varyings vert (Attributes input) {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS);
                int mode = _BlurData.y;
                float radio;
                switch(mode){
                    case 0:
                        radio = distance(input.uv.y, _BlurData.z) * _BlurData.x;
                        break;
                    default:
                        radio = distance(input.uv.x, _BlurData.z) * _BlurData.x;
                        break;
                }
                // float radio = distance(positionWS, _OriginLightCenter) * _BlurRadio;
                output.blurRadio = radio;
                output.uv = input.uv;
                output.positionCS_SS = TransformWorldToHClip(positionWS);

                return output;
            }

            void frag (Varyings input,
                    out float4 _GBufferColorTex : SV_Target0,
                    out float4 _ReflectTargetTex : SV_Target4
                ) {
                float4 baseCol0 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float4 baseCol1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv + float2(_MainTex_TexelSize.x, 0) * input.blurRadio);
                float4 baseCol2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv + float2(-_MainTex_TexelSize.x, 0) * input.blurRadio);
                float4 baseCol3 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv + float2(0, _MainTex_TexelSize.y) * input.blurRadio);
                float4 baseCol4 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv + float2(0, -_MainTex_TexelSize.y) * input.blurRadio);
                float4 baseCol = (baseCol0 + baseCol1 + baseCol2 + baseCol3 + baseCol4) / 5.0;
                _GBufferColorTex = float4(_ShadowColor.xyz, baseCol.a);
                // _ReflectTargetTex = float4(0, 0, 0, baseCol.w);
                _ReflectTargetTex = float4(0, 0, 0, baseCol.g);
            }

			ENDHLSL
        }
    }
}
