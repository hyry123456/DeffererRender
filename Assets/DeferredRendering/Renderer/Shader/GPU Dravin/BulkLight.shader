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
