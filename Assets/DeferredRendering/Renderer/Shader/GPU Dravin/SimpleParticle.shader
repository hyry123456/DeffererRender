Shader "Unlit/SimpleParticle"
{
    Properties
    {
        [Header(Base Setting)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 2
        [Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 0

        _MainTex("Main Tex", 2D) = "White"{}
        _ParticleSize("Particle Size", Float) = 5
        [HDR]_Color("Color", color) = (1,1,1,1)

        [Header(Particles Setting)]
        [Space(10)]
        [Toggle(_NEAR_ALPHA)] _UseNearAlpha("Use Near Alpha", float) = 0
        _NearFadeDistance("Near Fade Distance", Range(0, 5)) = 1
        _NearFadeRange ("Near Fade Range", Range(0, 5)) = 1

        [Toggle(_SOFT_PARTICLE)] _UseSoftParticle("Use Soft Particle", float) = 0
        _SoftParticlesDistance("Soft Particle Distance", Range(0.0, 10.0)) = 0.01
        _SoftParticlesRange ("Soft Particle Range", Range(0.01, 10.0)) = 1
    }
    SubShader
    {

        Pass
        {
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull Off
            HLSLPROGRAM

            #pragma target 4.6

            #pragma vertex vert
            #pragma fragment frag
            #pragma require geometry
            #pragma geometry geom

            #pragma shader_feature  _NEAR_ALPHA
            #pragma shader_feature  _SOFT_PARTICLE

            #include "../../ShaderLibrary/Common.hlsl"
            #include "../../ShaderLibrary/Fragment.hlsl"

            float3 _WorldPos;
            float _ParticleSize;
            float4 _Color;
            
            //软粒子
            #ifdef _SOFT_PARTICLE
                float _SoftParticlesDistance;
                float _SoftParticlesRange;
            #endif
            //近平面透明
            #ifdef _NEAR_ALPHA
                float _NearFadeDistance;
                float _NearFadeRange;
            #endif

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct ToGeom {
                float3 worldPos : VAR_POSITION;
            };
            struct FragInput
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            ToGeom vert(uint id : SV_InstanceID)
            {
                ToGeom o = (ToGeom)0;
                o.worldPos = _WorldPos;

                return o;
            }

            [maxvertexcount(6)]
            void geom(point ToGeom IN[1], inout TriangleStream<FragInput> tristream)
            {
                FragInput o[4] = (FragInput[4])0;

                float3 worldVer = IN[0].worldPos;
                float paritcleLen = _ParticleSize;

                float3 worldPos = worldVer + -unity_MatrixV[0].xyz * paritcleLen + -unity_MatrixV[1].xyz * paritcleLen;
                o[0].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
                o[0].uv = float2(0, 0);

                worldPos = worldVer + UNITY_MATRIX_V[0].xyz * -paritcleLen
                    + UNITY_MATRIX_V[1].xyz * paritcleLen;
                o[1].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
                o[1].uv = float2(1, 0);

                worldPos = worldVer + UNITY_MATRIX_V[0].xyz * paritcleLen
                    + UNITY_MATRIX_V[1].xyz * -paritcleLen;
                o[2].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
                o[2].uv = float2(0, 1);

                worldPos = worldVer + UNITY_MATRIX_V[0].xyz * paritcleLen
                    + UNITY_MATRIX_V[1].xyz * paritcleLen;
                o[3].pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
                o[3].uv = float2(1, 1);

                tristream.Append(o[1]);
                tristream.Append(o[2]);
                tristream.Append(o[0]);
                tristream.RestartStrip();

                tristream.Append(o[1]);
                tristream.Append(o[3]);
                tristream.Append(o[2]);
                tristream.RestartStrip();
            }

            float ChangeAlpha(Fragment fragment){
                float reAlpha = 1;

                #ifdef _NEAR_ALPHA
                    reAlpha = saturate( (fragment.depth - _NearFadeDistance) / _NearFadeRange );
                #endif

                #ifdef _SOFT_PARTICLE
                    float depthDelta = fragment.bufferDepth - fragment.depth;	//获得深度差
                    reAlpha *= (depthDelta - _SoftParticlesDistance) / _SoftParticlesRange;	//进行透明控制
                #endif
                return saturate( reAlpha );
            }

            float4 frag(FragInput i) : SV_Target
            {
                Fragment fragment = GetFragment(i.pos);

                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy) * _Color;

                color.a *= ChangeAlpha(fragment);

                // #ifdef _DISTORTION
                //     float4 bufferColor = GetBufferColor(fragment, GetDistortion(i, color.a));
                //     color.rgb = lerp( bufferColor.rgb, 
                //         color.rgb, saturate(color.a - GetDistortionBlend()));
                // #endif
                return color;
            }


            ENDHLSL
        }
    }
}
