Shader "Defferer/Thunder"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "black" {}
        [HDR]_FireColor("Thunder Color", COLOR) = (1,1,1,1)      //为了方便，直接用该值作为
        _Cutoff("Thunder Range", Range(0, 1)) = 0
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
                "LightMode" = "FowardShader"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off
            HLSLPROGRAM
            #pragma vertex UIVertex
            #pragma fragment UIFrag

			#pragma target 3.5
			#pragma multi_compile_instancing

            struct Attributes {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 baseUV : TEXCOORD0;
            };

            struct Varyings {
                float4 positionCS_SS : SV_POSITION;
                float3 normalWS : VAR_NORMAL;
                float2 baseUV : VAR_BASE_UV;
            };


            Varyings UIVertex(Attributes input){
                Varyings output;
                output.positionCS_SS = TransformObjectToHClip(input.positionOS);
                output.normalWS = TransformObjectToWorldNormal( input.normalOS );
                output.baseUV = TransformBaseUV( input.baseUV );
                return output;
            }

            float4 UIFrag (Varyings input) : SV_TARGET 
            {
                float4 base = GetBase(input.baseUV);
                float4 color = GetFireColor();
                float cullOff = GetCutoff();
                return color * saturate(base.r - cullOff);
            }


            ENDHLSL

        }
    }
}
