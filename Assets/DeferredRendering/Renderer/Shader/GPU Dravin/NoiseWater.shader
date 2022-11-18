Shader "Defferer/Fluid Draw"
{
    Properties
    {
        // _NormalMap("Normal Map", 2D) = "bump"{}
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
            Name "Normal"
            Blend One Zero
            ZWrite On
            Cull Off
            ZTest On
            HLSLPROGRAM

            #pragma target 4.6

            #pragma vertex vert
            #pragma fragment NormalFrag
            #pragma require geometry
            #pragma geometry geom
            
			#pragma multi_compile _ _DEFFER_FOG

            #pragma shader_feature  _NEAR_ALPHA
            #pragma shader_feature  _SOFT_PARTICLE
            #pragma shader_feature _FOLLOW_SPEED
            #pragma shader_feature _PARTICLE_NORMAL
            #pragma shader_feature _NORMAL_MAP

            #include "HLSL/NoiseWater.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Width"
            Blend SrcAlpha One
            ZWrite Off
            ZTest On
            Cull Off
            HLSLPROGRAM

            #pragma target 4.6

            #pragma vertex vert
            #pragma fragment WidthFrag
            #pragma require geometry
            #pragma geometry geom
            
			#pragma multi_compile _ _DEFFER_FOG

            #pragma shader_feature _FOLLOW_SPEED
            // #pragma shader_feature _PARTICLE_NORMAL
            // #pragma shader_feature _NORMAL_MAP

            #include "HLSL/NoiseWater.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "CopyDepth"
            ZWrite On
            ZTest Off
            Cull Off
            HLSLPROGRAM
            #pragma target 4.6

            #include "HLSL/NoiseWater.hlsl"

            #pragma vertex BlitPassSimpleVertex
            #pragma fragment CopyDepthPassFragment

            ENDHLSL
        }

        Pass{
            Name "Blend Target"

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off
            ZTest Off
            HLSLPROGRAM

            #include "HLSL/NoiseWater.hlsl"

			#pragma multi_compile _ _USE_CLUSTER
            #pragma vertex DefaultPassVertex
            #pragma fragment BlendToTargetFrag

            ENDHLSL
        }

        Pass{
            Name "Bilater"

            HLSLPROGRAM

            #include "HLSL/NoiseWater.hlsl"
            
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment BilateralFilterFragment

            ENDHLSL
        }

        Pass{
            Name "Bilater Depth"
            ZWrite On
            ZTest Off
            Cull Off
            HLSLPROGRAM

            #include "HLSL/NoiseWater.hlsl"
            
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment BilateralDepthFilterFragment

            ENDHLSL
        }

        Pass{
            Name "Write Depth"
            ZWrite On
            ZTest On
            Cull Off
            HLSLPROGRAM

            #include "HLSL/NoiseWater.hlsl"
            
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment WriteDepth

            ENDHLSL
        }
    }
}
