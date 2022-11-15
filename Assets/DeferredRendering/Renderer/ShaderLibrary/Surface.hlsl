#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

struct Surface {
	float3 position;
	float3 normal;
	float3 interpolatedNormal;
	float3 viewDirection;
	float depth;
	float3 color;
	float alpha;
	float metallic;
	float smoothness;
	float fresnelStrength;
	float dither;

	float3 shiftColor;
	float width;

	// #ifdef _USE_BSDF
	// 	float3 shiftColor;
	// 	float distorion;
	// 	float power;
	// 	float scale;
	// 	float3 transferColor;
	// #endif
};

#endif