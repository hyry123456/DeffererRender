Shader "Custom RP/GPU Pipeline/ParticleFractoryDraw"
{
    Properties
    {
        [Header(Base Setting)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 2
        [Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 0

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
            
			#pragma multi_compile _ _DEFFER_FOG

            #pragma shader_feature  _NEAR_ALPHA
            #pragma shader_feature  _SOFT_PARTICLE

            #include "HLSL/ParticleFactoryIPass.hlsl"

            ENDHLSL
        }
    }
}
