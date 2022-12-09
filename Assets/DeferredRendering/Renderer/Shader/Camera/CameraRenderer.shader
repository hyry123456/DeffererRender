Shader "Unlit/CameraRenderer"
{
    SubShader
    {
        HLSLINCLUDE
            #include "../../ShaderLibrary/Common.hlsl"
            #include "HLSL/CameraRenderInput.hlsl"
            #include "HLSL/CameraRenderPass.hlsl"
		ENDHLSL

        Pass
        {
			Name "Copy Bilt"
			ZWrite Off
            HLSLPROGRAM
            #pragma vertex BlitPassSimpleVertex
            #pragma fragment CopyFragment
            ENDHLSL
        }


		Pass {
			Name "Copy Depth"

			// ColorMask 0
			ZWrite On
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment CopyDepthPassFragment
			ENDHLSL
		}

        Pass {
			Name "Debug Depth"

            ZTest Off
			ZWrite On
			
			HLSLPROGRAM
				#pragma target 3.5
				#pragma vertex BlitPassSimpleVertex
				#pragma fragment DebugDrawGBuffer
			ENDHLSL
		}
    }
}
