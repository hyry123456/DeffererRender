#ifndef CUSTOM_BRDF_INCLUDED
#define CUSTOM_BRDF_INCLUDED

struct BRDF {
	float3 diffuse;
	float3 specular;
	float roughness;
	// float perceptualRoughness;
	float fresnel;
};

#define MIN_REFLECTIVITY 0.04

float OneMinusReflectivity (float metallic) {
	float range = 1.0 - MIN_REFLECTIVITY;
	return range - metallic * range;
}

BRDF GetBRDF (Surface surface) {
	BRDF brdf;
	float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);
	brdf.diffuse = surface.color * oneMinusReflectivity;
	brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);
	float roughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
	brdf.roughness = PerceptualRoughnessToRoughness(roughness);
	brdf.fresnel = saturate(surface.smoothness + 1.0 - oneMinusReflectivity);
	return brdf;
}

BRDF GetBRDF(float3 albedo, float metallic, float smoothess) {
	BRDF brdf;
	float oneMinusReflectivity = OneMinusReflectivity(metallic);
	brdf.diffuse = albedo * oneMinusReflectivity;
	brdf.specular = lerp(MIN_REFLECTIVITY, albedo, metallic);
	float roughness = PerceptualSmoothnessToPerceptualRoughness(smoothess);
	brdf.roughness = PerceptualRoughnessToRoughness(roughness);
	brdf.fresnel = saturate(smoothess + 1.0 - oneMinusReflectivity);
	return brdf;
}

float SpecularStrength (Surface surface, BRDF brdf, Light light) {
	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float nh2 = Square(saturate(dot(surface.normal, h)));
	float lh2 = Square(saturate(dot(light.direction, h)));
	float r2 = Square(brdf.roughness);
	float d2 = Square(nh2 * (r2 - 1.0) + 1.00001);
	float normalization = brdf.roughness * 4.0 + 2.0;
	return r2 / (d2 * max(0.1, lh2) * normalization);
}

float3 DirectBRDF (Surface surface, BRDF brdf, Light light) {
	return SpecularStrength(surface, brdf, light) * brdf.specular + brdf.diffuse;
}

//采集计算经过BRDF调整后的反射光
float3 ReflectBRDF (
	float3 normal, float3 viewDir, float fresnel, BRDF brdf, float3 specular
) {
	float fresnelStrength = fresnel *
		Pow4(1.0 - saturate(dot(normal, viewDir)));

	float3 reflection =
		specular * lerp(brdf.specular, brdf.fresnel, fresnelStrength);
	reflection /= brdf.roughness * brdf.roughness + 1.0;
    return reflection;
}

#endif