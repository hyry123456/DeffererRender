Shader "Terrain/DrawDetail"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {

        Pass{
            HLSLPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "../../ShaderLibrary/Common.hlsl"

                struct Attributes {
                    float3 positionOS : POSITION;
                    float2 baseUV : TEXCOORD0;
                };

                struct Varyings {
                    float4 positionCS_SS : SV_POSITION;
                    float2 baseUV : VAR_BASE_UV;
                };

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
                float3 _OffsetData;

                Varyings vert (Attributes input) {
                    Varyings output;
                    output.positionCS_SS = TransformObjectToHClip(input.positionOS);
                    output.positionCS_SS.xy = float2(-1, -1) + output.positionCS_SS.xy * _OffsetData.z + _OffsetData.xy * 2.0;
                    // output.positionCS_SS.y = 1.0 - output.positionCS_SS.y;
                    // output.positionCS_SS.xy = float2(1, 1) - output.positionCS_SS.xy * _OffsetData.z - _OffsetData.xy * 2.0;
                    // output.positionCS_SS.x = -1.0 + output.positionCS_SS.x * _OffsetData.z + _OffsetData.x * 2.0;
                    // output.positionCS_SS.y = 1.0 - output.positionCS_SS.y * _OffsetData.z - _OffsetData.y * 2.0;
                    output.baseUV = input.baseUV;
                    return output;
                }

                float4 frag (Varyings input) : SV_Target
                {
                    // float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.baseUV);
                    float dis = saturate( distance(input.baseUV, float2(0.5, 0.5)) );
                    return dis;
                }


            ENDHLSL
        }

    }
}
