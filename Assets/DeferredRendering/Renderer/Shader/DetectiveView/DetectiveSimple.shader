//侦探视觉案例，也就是将物体渲染为抖动的白色而已
Shader "Detevtive/DetectiveSimple"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex("Noise Texture", 2D) = "grey" {}
        _WaveSpeed("Wave Speed", VECTOR) = (1, 1, 1.3, 1.3)
        [HDR]_HeightLight("Height Light Color", COLOR) = (1,1,1,1)
        _MiniLight("Min Light Color", COLOR) = (0.5, .5, .5, .5)
        _ClipOff("Cull Off", Range(0, 1)) = 0.2
    }
    SubShader
    {

        HLSLINCLUDE
            #include "../../ShaderLibrary/Common.hlsl"
		ENDHLSL

        Pass
        {
            Tags {
                "LightMode" = "DetavtiveView"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)

                UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _NoiseTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _WaveSpeed)
                UNITY_DEFINE_INSTANCED_PROP(float4, _HeightLight)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MiniLight)
                UNITY_DEFINE_INSTANCED_PROP(float, _BlendRadio)
                UNITY_DEFINE_INSTANCED_PROP(float, _ClipOff)

            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            #define INPUT_PROP(name) UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, name)

            float2 TransformNoiseUV(float2 uv){
                float4 noiseST = INPUT_PROP(_NoiseTex_ST);
                return uv * noiseST.xy + noiseST.zw;
            }
            float2 TransformBaseUV(float2 uv){
                float4 mainST = INPUT_PROP(_MainTex_ST);
                return uv * mainST.xy + mainST.zw;
            }

            struct appdata
            {
                float3 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 baseUV : TEXCOORD0;
                float4 waveUV : TEXCOORD1;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            v2f vert (appdata input)
            {
                v2f output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                output.vertex = TransformObjectToHClip(input.vertex);
                output.baseUV = TransformBaseUV( input.uv );
                output.waveUV = TransformNoiseUV( input.uv ).xyxy + INPUT_PROP(_WaveSpeed) * _Time.x;
                return output;
            }

            float4 frag (v2f input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float4 mainCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.baseUV);
                clip(mainCol.a - INPUT_PROP(_ClipOff));

                float wave = saturate( SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, input.waveUV.xy).r
                    + SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, input.waveUV.zw).r - 1.0) * mainCol.x;
                
                float3 col = lerp(INPUT_PROP(_MiniLight).xyz, INPUT_PROP(_HeightLight).xyz, wave);

                return float4(col, INPUT_PROP(_BlendRadio));
            }
            ENDHLSL
        }
    }
}
