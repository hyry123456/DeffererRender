//靠灯光偏移的阴影平面
Shader "Defferer/ShadowPlaneOffsetByLight"
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

            // float4 _OriginLightCenter;
            float4 _LightOffset;

			#pragma target 3.5

            struct Attributes {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct Varyings {
                float4 positionCS_SS : SV_POSITION;
                float3 positionWS : VAR_POSITION;
                float2 uv : VAR_TEXCOORD;
            };



            Varyings vert (Attributes input) {
                Varyings output;

                float3 positionOS = input.positionOS;

                float3 offsetDir = _LightOffset - positionOS; 
                float dis = length(_LightOffset);
                float cosRadio = dot(normalize(positionOS), normalize(offsetDir)) - 1.0; //得到灯光与顶点的夹角，映射到-2-0之间，保证越近越小
                offsetDir.y = 0;
                positionOS += offsetDir * cosRadio * dis;
                float3 worldPos = TransformObjectToWorld(positionOS);

                // float3 worldCenter = TransformObjectToWorld(0);
                // 
                // float3 lightDir = _OriginLightCenter - worldCenter;
                // lightDir.y = 0; lightDir = normalize(lightDir);                 //得到灯光的平面方向
                // float3 objPointDir = worldPos - worldCenter;
                // float3 positionWS = worldPos + lightDir * cosRadio * distance(_OriginLightCenter, worldCenter);

                // float sinRadio = sqrt(1 - cosRadio * cosRadio);
                // float dis = distance(_OriginLightCenter, positionWS) * _OffsetSize;
                // float3 offsetDir = dis * sinRadio * lightDir;
                // offsetDir.y = 0;        //清除Y轴偏移
                // positionWS += offsetDir;
                output.positionWS = worldPos;
                output.uv = input.uv;
                output.positionCS_SS = TransformWorldToHClip(worldPos);

                return output;
            }

            void frag (Varyings input,
                    out float4 _GBufferColorTex : SV_Target0,
                    out float4 _ReflectTargetTex : SV_Target4
                ) {
                
                float4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy);
                _GBufferColorTex = float4(_ShadowColor.xyz, baseCol.w);
                _ReflectTargetTex = float4(0, 0, 0, baseCol.w);
            }

			ENDHLSL
        }

    }
}
