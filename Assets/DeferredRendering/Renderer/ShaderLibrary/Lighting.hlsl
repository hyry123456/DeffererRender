#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

float3 IncomingLight (Surface surface, Light light) {
	float dotV = dot(surface.normal, light.direction);
	float y = (dotV + _LightWrap) / (1 + _LightWrap);
	return
		saturate(y * light.attenuation) * light.color;
}

float3 TransferLight(Surface surface, Light light){
	float3 backLightDir = surface.normal * (1.0 - surface.width) + light.direction ;

	//注意, 直接使用默认的阴影投影方式生成的阴影是有问题的，需要调整阴影投影矩阵，不然这里会出现错误的遮挡
	float fLTDot = pow( saturate( dot(surface.viewDirection, -backLightDir)), 2.0) * light.attenuation * 6;
	// return surface.shiftColor;
	return fLTDot * surface.shiftColor * light.color * (1.0 - surface.width);
}

float3 GetLighting (Surface surface, BRDF brdf, Light light) {
	return (IncomingLight(surface, light) + TransferLight(surface, light)) * DirectBRDF(surface, brdf, light);
	// return TransferLight(surface, light);
}

float3 GetGBufferLight(Surface surface, BRDF brdf, float3 uv_Depth){
	ShadowData shadowData = GetShadowData(surface);

	float3 color = 0;
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surface, shadowData);
		color += GetLighting(surface, brdf, light);
	}

#ifdef _USE_CLUSTER
	uint id = Get1DCluster(uv_Depth.xy, uv_Depth.z);
	int count = _ClusterCountBuffer[id];
	LightArray array = _ClusterArrayBuffer[id];

	for (int j = 0; j < count; j++) {
		Light light = GetOtherLight(array.lightIndex[j], surface, shadowData);
		color += GetLighting(surface, brdf, light);
	}

#else
	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surface, shadowData);
		color += GetLighting(surface, brdf, light);
	}
#endif
	return color;
}

float3 GetGBufferLight(Surface surface, BRDF brdf, float4 clipPos){
	ShadowData shadowData = GetShadowData(surface);

	float3 color = 0;
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surface, shadowData);
		color += GetLighting(surface, brdf, light);
	}

#ifdef _USE_CLUSTER
	uint id = Get1DCluster(clipPos.xy / _ScreenParams.xy, clipPos.w);
	int count = min(_ClusterCountBuffer[id], GetOtherLightCount());
	LightArray array = _ClusterArrayBuffer[id];

	for (int j = 0; j < count; j++) {
		Light light = GetOtherLight(array.lightIndex[j], surface, shadowData);
		color += GetLighting(surface, brdf, light);
	}
#else
	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surface, shadowData);
		color += GetLighting(surface, brdf, light);
	}
#endif
	return color;
}

struct DiffuseData{
	float3 diffuseLightCol;
	float3 specularCol;
};

void GetLightingDiffuse(Surface surface, Light light, inout DiffuseData diffuse){
	diffuse.diffuseLightCol += saturate(dot(surface.normal, light.direction)) * light.attenuation * light.color;
	float3 halfDIr = normalize(surface.viewDirection + light.direction);
	diffuse.specularCol += light.color * pow(max(0, dot(surface.normal, halfDIr)), surface.smoothness) * light.attenuation * light.color;
}

DiffuseData GetLightingDiffuse(Surface surface, float4 clipPos){
	ShadowData shadowData = GetShadowData(surface);
	DiffuseData diffuse = (DiffuseData)0;
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surface, shadowData);
		GetLightingDiffuse(surface, light, diffuse);
	}
	return diffuse;
}

//因为是视线方向作为法线的，因此要注意相反的情况，但是相反应该要也可以看见
float3 BulkIncomingLight(Light light, float3 viewDirection, float g){
	float cosTheta = saturate( dot(-viewDirection, light.direction) );
	return 1 / (4 * 3.14) * (1 - g * g) / pow(abs( 1 + g * g - 2 * g * cosTheta ), 1.5) * light.attenuation * light.color;
}

//获得体积光的光照计算方式
float3 GetBulkLighting(float3 worldPos, float3 viewDirection, float2 screenUV, float scatterRadio, float depth){
	ShadowData shadowData = GetShadowDataByPosition(worldPos);

	float3 color = 0;

	#ifdef _USE_CLUSTER
		uint id = Get1DCluster(screenUV, depth);
		int count = min(_ClusterCountBuffer[id], GetOtherLightCount());
		LightArray array = _ClusterArrayBuffer[id];
		for (int j = 0; j < count; j++) {
			Light light = GetOtherLightByPosition(array.lightIndex[j], worldPos, shadowData);
			color += BulkIncomingLight(light, viewDirection, scatterRadio);
		}

	#else
		for (int i = 0; i < GetOtherLightCount(); i++) {
			Light light = GetOtherLightByPosition(i, worldPos, shadowData);
			color += BulkIncomingLight(light, viewDirection, scatterRadio);
		}
	#endif

	return color;
}

#endif