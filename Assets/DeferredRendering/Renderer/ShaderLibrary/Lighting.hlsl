#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

float3 GetGBufferLight(Surface surface, float3 uv_Depth){
	ShadowData shadowData = GetShadowData(surface);

	float3 color = 0;
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surface, shadowData);
		color += DirectBRDF(surface, light);
	}

#ifdef _USE_CLUSTER
	uint id = Get1DCluster(uv_Depth.xy, uv_Depth.z);
	int count = _ClusterCountBuffer[id];
	LightArray array = _ClusterArrayBuffer[id];

	for (int j = 0; j < count; j++) {
		Light light = GetOtherLight(array.lightIndex[j], surface, shadowData);
		color += DirectBRDF(surface, light);
	}

#else
	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surface, shadowData);
		color += DirectBRDF(surface, light);
	}
#endif
	return color;
}

float3 GetGBufferLight(Surface surface, float4 clipPos){
	ShadowData shadowData = GetShadowData(surface);

	float3 color = 0;
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surface, shadowData);
		color += DirectBRDF(surface, light);
	}

#ifdef _USE_CLUSTER
	uint id = Get1DCluster(clipPos.xy / _ScreenParams.xy, clipPos.w);
	int count = min(_ClusterCountBuffer[id], GetOtherLightCount());
	LightArray array = _ClusterArrayBuffer[id];

	for (int j = 0; j < count; j++) {
		Light light = GetOtherLight(array.lightIndex[j], surface, shadowData);
		color += DirectBRDF(surface, light);
	}
#else
	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surface, shadowData);
		color += DirectBRDF(surface, light);
	}
#endif
	return color;
}

void AdjustWidth(inout float width, float scale){
	width = saturate(width * scale);
}

// float3 GetGBufferBSDFLight(Surface surface, float3 uv_Depth, float normalDistorion, float power, float scale){
// 	ShadowData shadowData = GetShadowData(surface);

// 	float3 color = 0;
// 	for (int i = 0; i < GetDirectionalLightCount(); i++) {
// 		float width;
// 		Light light = GetDirectionalLight_SSS(i, surface, shadowData, width);
// 		AdjustWidth(width);
// 		color += DirectBSDF(surface, light, normalDistorion, power, width, scale);
// 		// return light.lightWidth;
// 	}

// #ifdef _USE_CLUSTER
// 	uint id = Get1DCluster(uv_Depth.xy, uv_Depth.z);
// 	int count = _ClusterCountBuffer[id];
// 	LightArray array = _ClusterArrayBuffer[id];

// 	for (int j = 0; j < count; j++) {
// 		float width;
// 		Light light = GetOtherLight_SSS(array.lightIndex[j], surface, shadowData, width);
// 		AdjustWidth(width);
// 		color += DirectBSDF(surface, light, normalDistorion, power, width, scale);
// 	}

// #else
// 	for (int j = 0; j < GetOtherLightCount(); j++) {
// 		float width;
// 		Light light = GetOtherLight_SSS(j, surface, shadowData, width);
// 		AdjustWidth(width);
// 		color += DirectBSDF(surface, light, normalDistorion, power, width, scale);
// 	}
// #endif
// 	return color;
// }

float3 GetGBufferBSDFLight(Surface surface, float3 uv_Depth, float normalDistorion, float power, float width, float scale){
	ShadowData shadowData = GetShadowData(surface);

	float3 color = 0;
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surface, shadowData);
		color += DirectBSDF(surface, light, normalDistorion, power, width);
	}

#ifdef _USE_CLUSTER
	uint id = Get1DCluster(uv_Depth.xy, uv_Depth.z);
	int count = _ClusterCountBuffer[id];
	LightArray array = _ClusterArrayBuffer[id];

	for (int j = 0; j < count; j++) {
		Light light = GetOtherLight(array.lightIndex[j], surface, shadowData);
		color += DirectBSDF(surface, light, normalDistorion, power, width);
	}

#else
	for (int j = 0; j < GetOtherLightCount(); j++) {
		Light light = GetOtherLight(j, surface, shadowData);
		color += DirectBSDF(surface, light, normalDistorion, power, width);
	}
#endif
	return color;
}

float3 GetGBufferBSDFLight(Surface surface, float4 clipPos, float normalDistorion, float power, float scale){
	ShadowData shadowData = GetShadowData(surface);

	float3 color = 0;
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		float width;
		Light light = GetDirectionalLight_SSS(i, surface, shadowData, width);
		AdjustWidth(width, scale);
		color += DirectBSDF(surface, light, normalDistorion, power, width);
	}

#ifdef _USE_CLUSTER
	uint id = Get1DCluster(clipPos.xy / _ScreenParams.xy, clipPos.w);
	int count = _ClusterCountBuffer[id];
	LightArray array = _ClusterArrayBuffer[id];

	for (int j = 0; j < count; j++) {
		float width;
		Light light = GetOtherLight_SSS(array.lightIndex[j], surface, shadowData, width);
		AdjustWidth(width, scale);
		color += DirectBSDF(surface, light, normalDistorion, power, width);
	}

#else
	for (int j = 0; j < GetOtherLightCount(); j++) {
		float width;
		Light light = GetOtherLight_SSS(j, surface, shadowData, width);
		AdjustWidth(width, scale);
		// return width;
		color += DirectBSDF(surface, light, normalDistorion, power, width);
	}
#endif
	return color;
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