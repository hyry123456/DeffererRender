Shader "Defferer/BulkLight"
{
    Properties
    {
    }
    SubShader
    {
        Pass
        {
            Name "Static Bulk Light"

            Blend One One
            ZWrite Off
            Cull Off
            HLSLPROGRAM

            #pragma target 4.6

			#pragma multi_compile _ _USE_CLUSTER
			#pragma multi_compile _ _DEFFER_FOG
            #pragma vertex vert
            #pragma fragment frag
            #pragma require geometry
            #pragma geometry geom
            #include "../../ShaderLibrary/Common.hlsl"
            #include "HLSL/BulkLightPass.hlsl"

            ENDHLSL
        }
    }
}
