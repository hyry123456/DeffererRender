Shader "Unlit/TerrainDrawTemp"
{
    Properties
    {
        _TessDegree("Tess Degree", Range(0, 80)) = 50
    }
    SubShader
    {
        Pass
        {
            Tags {
                "LightMode" = "OutGBuffer"
            }
            Blend One Zero
			ZWrite On
            HLSLPROGRAM

            #pragma vertex tessvert
            #pragma require tessellation
            //细分控制
            #pragma hull hull
            //细分计算
            #pragma domain domain
            #pragma require geometry
            #pragma geometry geom

            #pragma fragment frag

            #include "../../ShaderLibrary/Common.hlsl"
            #include "../../ShaderLibrary/Surface.hlsl"
            #include "../../ShaderLibrary/Shadows.hlsl"
            #include "../../ShaderLibrary/Light.hlsl"
            #include "../../ShaderLibrary/BRDF.hlsl"
            #include "../../ShaderLibrary/GI.hlsl"
            #include "../../ShaderLibrary/Lighting.hlsl"
            
            #include "../../ShaderLibrary/Tesseilation.hlsl"

            TEXTURE2D(_HeightTex);
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_HeightTex);
            SAMPLER(sampler_NormalTex);
            float _Height;


            // struct VertInput{
            //     float3 positionOS : POSITION;
            //     float2 uv : TEXCOORD0;
            // };

            struct FragInput{
                float2 uv : VAR_UV;
                float4 positionCS : SV_POSITION;
                float3 normalWS : NORMAL;
                float4 tangetWS : TANGENT;
            };

            [maxvertexcount(9)]
		    void geom(triangle TessOutPutSimple IN[3], inout TriangleStream<FragInput> tristream){
                FragInput o;
                float height = SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_HeightTex, IN[0].uv.xy, 0).r * _Height;
                IN[0].vertex.y = height;
                float3 positionWS = TransformObjectToWorld(IN[0].vertex.xyz);
                o.normalWS = TransformObjectToWorldNormal(IN[0].normal);
                o.tangetWS = float4( TransformObjectToWorldDir(IN[0].tangent.xyz), IN[0].tangent.w);
                o.uv = IN[0].uv;
                o.positionCS = TransformWorldToHClip(positionWS);
                tristream.Append(o);

                height = SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_HeightTex, IN[1].uv.xy, 0).r * _Height;
                IN[1].vertex.y = height;
                positionWS = TransformObjectToWorld(IN[1].vertex.xyz);
                o.normalWS = TransformObjectToWorldNormal(IN[1].normal);
                o.tangetWS = float4( TransformObjectToWorldDir(IN[1].tangent.xyz), IN[1].tangent.w);
                o.uv = IN[1].uv;
                o.positionCS = TransformWorldToHClip(positionWS);
                tristream.Append(o);

                height = SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_HeightTex, IN[2].uv.xy, 0).r * _Height;
                IN[2].vertex.y = height ;
                positionWS = TransformObjectToWorld(IN[2].vertex.xyz);
                o.normalWS = TransformObjectToWorldNormal(IN[2].normal);
                o.tangetWS = float4( TransformObjectToWorldDir(IN[2].tangent.xyz), IN[2].tangent.w);
                o.uv = IN[2].uv;
                o.positionCS = TransformWorldToHClip(positionWS);
                tristream.Append(o);
                tristream.RestartStrip();
            }

            void frag(FragInput i,
                out float4 _GBufferColorTex : SV_Target0,
                out float4 _GBufferNormalTex : SV_Target1,
                out float4 _GBufferSpecularTex : SV_Target2,
                out float4 _GBufferBakeTex : SV_Target3) 
            {
                float4 normal = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv);

                // normal.xyz = TransformObjectToWorldDir(normal.xyz * 2.0 - 1.0);

                _GBufferColorTex = 0.5;
                _GBufferNormalTex = float4( normal.xyz, 1);
                // _GBufferNormalTex = float4( normal.xyz * 0.5 + 0.5, 1);
                _GBufferSpecularTex = float4(0.5, 1, 1, 1);
                _GBufferBakeTex = 0;
            }


            ENDHLSL

        }
    }
}
