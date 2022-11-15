Shader "Lapu/Skybox"
{
	Properties
	{
		[Header(Sun Settings)]
		[HDR]_SunColor("Sun Color", Color) = (1,1,1,1)
		_SunRadius("Sun Radius",  Range(0, 2)) = 0.1

		[Header(Moon Settings)]
		[HDR]_MoonColor("Moon Color", Color) = (1,1,1,1)
		_MoonRadius("Moon Radius",  Range(0, 2)) = 0.1
		_MoonOffset("Moon Crescent",  Range(-1, 1)) = -0.1

		[Header(Star Settings)]
		_Stars("Stars Texture", 2D) = "black" {}
		_StarsCutoff("Stars Cutoff",  Range(0, 1)) = 0.21
		_StarsSpeed("Stars Move Speed",  Range(-10, 10)) = 0.3
		_StarsFrequency("Star Frequency",  Range(0, 3)) = 2.3
		[HDR]_StarsSkyColor("Stars Sky Color", Color) = (0.0,1,0.5,1)

		[Header(Cloud Settings)]
		_Cloud("Cloud Texture", 2D) = "black" {}
		_CloudCutoff("Cloud Cutoff",  Range(0, 1)) = 0.45
		_CloudSpeed("Cloud Move Speed",  Range(-10, 10)) = 0.3
		_CloudFrequency("Cloud Frequency",  Range(0, 3)) = 0.4

		[Header(Cloud Noise Setting)]
		_DistortScale("Distort Noise Scale",  Range(0, 1)) = 0.1
		_DistortionSpeed("Distortion Speed",  Range(-1, 1)) = -0.3
		_CloudNoiseScale("Cloud Noise Scale",  Range(0, 1)) = 0.6

		[Header(Cloud Color Setting)]
		[HDR]_CloudDayColor("Cloud Day Color", Color) = (0.26, 0.6, 0.5, 1)
		_CloudNightColor("Cloud Night Color", Color) = (0.01, 0.2, 0.22, 1)


		[Header(Day Sky Settings)]
		[HDR]_DayTopColor("Day Top Color", Color) = (0, 0.43, 0.43, 1)
		_DayBottomColor("Day Bottom Color", Color) = (0, 0.43, 0.54,1)

		[Header(Night Sky Settings)]
		[HDR]_NightTopColor("Night Top Color", Color) = (0, 0.17, 0.19,1)
		_NightBottomColor("Night Bottom Color", Color) = (0, 0.1, 0.14,1)

		[Header(Horizon Settings)]
		_HorizonHeight("Horizon Height", Range(-10,10)) = 0				//水平高度
		_HorizonIntensity("Horizon Intensity",  Range(0, 100)) = 2		//扩散强度
		_MidLightIntensity("Mid Light Intensity",  Range(0, 100)) = 5		//中间线强度
		_HorizonBrightness("Horizon Brightness", Range(0, 2)) = 0.5			//整体强度
		_HorizonColorDay("Day Horizon Color", Color) = (0, 0.5, 0.62, 1)
		_HorizonColorNight("Night Horizon Color", Color) = (0, 0.26, 0.3,1)
		_HorizonLightDay("Day Horizon Light", Color) = (0, 0.5, 0.6,1)
		_HorizonLightNight("Night Horizon Light", Color) = (0, 0.08, 0.1,1)

	}
		SubShader
		{

			Tags { "RenderType" = "Opaque" }

			HLSLINCLUDE
				#include "../../ShaderLibrary/Common.hlsl"
				#include "HLSL/SkyBoxPass.hlsl"
			ENDHLSL

			Pass 
			{
				HLSLPROGRAM

				#pragma vertex vert
				#pragma fragment frag

				#pragma shader_feature MIRROR
				#pragma shader_feature ADDCLOUD

				ENDHLSL
			}

			// Pass
			// {
			// 	CGPROGRAM
			// 	#pragma vertex vert
			// 	#pragma fragment frag
			// 	#include "UnityCG.cginc"








			// 	ENDCG
			// }
		}
}