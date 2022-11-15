#ifndef BULK_LIGHT_PASS
#define BULK_LIGHT_PASS

//体积光裁剪后的数据
struct BulkLightStruct
{
	float3 boundMax;
	float3 boundMin;
	/// <summary>  /// 灯光编号，最多一个体积块中支持4个灯光   /// </summary>
	float4 lightIndex;
};

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "../../ShaderLibrary/Noise.hlsl"

StructuredBuffer<BulkLightStruct> _ClusterDataBuffer;      //组数据

float _BulkSampleCount;
float _BulkLightShrinkRadio;
float _BulkLightScatterRadio;

struct GemoInput{
    uint index : VAR_INDEX;
};

struct FragmentInput{
    float4 positionCS : SV_POSITION;
    //用W轴存储Box的距离
    float4 positionWS : VAR_POSITION;
    uint mode : VAR_MODE;       //0为外部看内部，1为内部开始看
    float4 lightIndex : VAR_LIGHTING;
    float3 boxMax : VAR_BOXMAX;
    float3 boxMin : VAR_BOXMIN;
};

GemoInput vert(uint id : SV_InstanceID){
    GemoInput output;
    output.index = id;
    return output;
}

[maxvertexcount(36)]
void geom(point GemoInput IN[1], inout TriangleStream<FragmentInput> tristream)
{
    BulkLightStruct bulk = _ClusterDataBuffer[IN[0].index];
    // bulk.boundMax = 10;
    // bulk.boundMin = 0;
    float3 bounds[8];
	bounds[0] = float3(bulk.boundMin.x, bulk.boundMin.y, bulk.boundMin.z);
	bounds[1] = float3(bulk.boundMax.x, bulk.boundMin.y, bulk.boundMin.z);
	bounds[2] = float3(bulk.boundMax.x, bulk.boundMin.y, bulk.boundMax.z);
	bounds[3] = float3(bulk.boundMin.x, bulk.boundMin.y, bulk.boundMax.z);
    
	bounds[4] = float3(bulk.boundMin.x, bulk.boundMax.y, bulk.boundMin.z);
	bounds[5] = float3(bulk.boundMax.x, bulk.boundMax.y, bulk.boundMin.z);
	bounds[6] = float3(bulk.boundMax.x, bulk.boundMax.y, bulk.boundMax.z);
	bounds[7] = float3(bulk.boundMin.x, bulk.boundMax.y, bulk.boundMax.z);

    int mode;

    //判断灯光方向
    if(_WorldSpaceCameraPos.x > bulk.boundMax.x || _WorldSpaceCameraPos.x < bulk.boundMin.x 
        || _WorldSpaceCameraPos.y > bulk.boundMax.y || _WorldSpaceCameraPos.y < bulk.boundMin.y
        || _WorldSpaceCameraPos.z > bulk.boundMax.z || _WorldSpaceCameraPos.z < bulk.boundMin.z){
            mode = 0;       //在外部
        }
    else
        mode = 1;   //在内部

    float4 positionCS[8];
    FragmentInput frags[8];
    float dis = distance(bulk.boundMax, bulk.boundMin);
    for(int i=0; i<8; i++){
        frags[i].positionCS = mul(UNITY_MATRIX_VP, float4(bounds[i], 1));
        frags[i].positionWS = float4( bounds[i], dis);
        frags[i].mode = mode;
        frags[i].lightIndex = bulk.lightIndex;
        frags[i].boxMax = bulk.boundMax;
        frags[i].boxMin = bulk.boundMin;
    }

    float3 camToCenter, centerDir, center;
    float3 midPos = float3((bulk.boundMax.x + bulk.boundMin.x) / 2, 
        (bulk.boundMax.y + bulk.boundMin.y) / 2, (bulk.boundMax.z + bulk.boundMin.z) / 2);

    center = float3(midPos.x, midPos.y, bulk.boundMin.z);
    camToCenter = normalize(center - _WorldSpaceCameraPos);
    centerDir = float3(0, 0, -1);
    if(mode == 1 || (dot(camToCenter, centerDir) < 0 && _WorldSpaceCameraPos.z < bulk.boundMin.z) ){
        tristream.Append(frags[4]);
        tristream.Append(frags[0]);
        tristream.Append(frags[1]);
        tristream.RestartStrip();
        tristream.Append(frags[1]);
        tristream.Append(frags[5]);
        tristream.Append(frags[4]);
        tristream.RestartStrip();
    }

    center = float3(bulk.boundMin.x, midPos.y, midPos.z);
    camToCenter = normalize(center - _WorldSpaceCameraPos);
    centerDir = float3(-1, 0, 0);
    if(mode == 1 || (dot(camToCenter, centerDir) < 0 && _WorldSpaceCameraPos.x < bulk.boundMin.x)){
        tristream.Append(frags[0]);
        tristream.Append(frags[3]);
        tristream.Append(frags[7]);
        tristream.RestartStrip();
        tristream.Append(frags[7]);
        tristream.Append(frags[4]);
        tristream.Append(frags[0]);
        tristream.RestartStrip();
    }

    center = float3(midPos.x, midPos.y, bulk.boundMax.z);
    camToCenter = normalize(center - _WorldSpaceCameraPos);
    centerDir = float3(0, 0, 1);
    if(mode == 1 || (dot(camToCenter, centerDir) < 0 && _WorldSpaceCameraPos.z > bulk.boundMax.z)){
        tristream.Append(frags[3]);
        tristream.Append(frags[2]);
        tristream.Append(frags[6]);
        tristream.RestartStrip();
        tristream.Append(frags[6]);
        tristream.Append(frags[7]);
        tristream.Append(frags[3]);
        tristream.RestartStrip();
    }

    center = float3(bulk.boundMax.x, midPos.y, midPos.z);
    camToCenter = normalize(center - _WorldSpaceCameraPos);
    centerDir = float3(1, 0, 0);
    if(mode == 1 || (dot(camToCenter, centerDir) < 0 && _WorldSpaceCameraPos.x > bulk.boundMax.x)){
        tristream.Append(frags[2]);
        tristream.Append(frags[1]);
        tristream.Append(frags[5]);
        tristream.RestartStrip();
        tristream.Append(frags[5]);
        tristream.Append(frags[6]);
        tristream.Append(frags[2]);
        tristream.RestartStrip();
    }

    center = float3(midPos.x, bulk.boundMax.y, midPos.z);
    camToCenter = normalize(center - _WorldSpaceCameraPos);
    centerDir = float3(0, 1, 0);
    if(mode == 1 || (dot(camToCenter, centerDir) < 0 && _WorldSpaceCameraPos.y > bulk.boundMax.y)){
        tristream.Append(frags[4]);
        tristream.Append(frags[7]);
        tristream.Append(frags[5]);
        tristream.RestartStrip();
        tristream.Append(frags[5]);
        tristream.Append(frags[7]);
        tristream.Append(frags[6]);
        tristream.RestartStrip();
    }

    center = float3(midPos.x, bulk.boundMin.y, midPos.z);
    camToCenter = normalize(center - _WorldSpaceCameraPos);
    centerDir = float3(0, -1, 0);
    if(mode == 1 || (dot(camToCenter, centerDir) < 0 && _WorldSpaceCameraPos.y < bulk.boundMin.y)){
        tristream.Append(frags[1]);
        tristream.Append(frags[3]);
        tristream.Append(frags[0]);
        tristream.RestartStrip();
        tristream.Append(frags[1]);
        tristream.Append(frags[3]);
        tristream.Append(frags[2]);
        tristream.RestartStrip();
    }
}


//因为是视线方向作为法线的，因此要注意相反的情况，但是相反应该要也可以看见
// float3 BulkIncomingLight(Light light, float3 viewDirection, float g){
// 	float cosTheta = saturate( dot(-viewDirection, light.direction) );
// 	return 1 / (4 * 3.14) * (1 - g * g) / pow(abs( 1 + g * g - 2 * g * cosTheta ), 1.5) * light.attenuation * light.color;
// }

//获得体积光的光照计算方式
float3 GetStaticBulkLighting(float3 worldPos, float3 viewDirection, float2 screenUV, float scatterRadio, float4 lightIndex){
	ShadowData shadowData = GetShadowDataByPosition(worldPos);

	float3 color = 0;
    for (int i = 0; i < 4 && lightIndex[i] >= 0; i++) {
        Light light = GetOtherLightByPosition(lightIndex[i], worldPos, shadowData);
        color += BulkIncomingLight(light, viewDirection, scatterRadio);
    }

	return color;
}

#define random(seed) sin(seed * 641.5467987313875 + 1.943856175)

bool CheckOutBox(int mode, float maxV, float minV, float value){
    switch(mode){
        case 1:
            return value > maxV;
        default:
            return value < minV;
    }
}

//外部观看体积光时的处理函数
float3 GetBulkLight(float4 worldPos, float2 screenUV, float4 lightIndex, float3 boxMax, float3 boxMin, float3 direction){


    float perNodeLength = worldPos.w / _BulkSampleCount / 2;
    float3 currentPoint = worldPos.xyz;
    float3 viewDirection = -direction;

    float3 color = 0;
    float seed = random((screenUV.y + screenUV.x) * _ScreenParams.x * _ScreenParams.y + 0.2312312);

    int3 mode3;
    mode3.x = (direction.x > 0)? 1 : 0;     //1为判断x的大
    mode3.y = (direction.y > 0)? 1 : 0;
    mode3.z = (direction.z > 0)? 1 : 0;

    int i = 0;
    for(; i < _BulkSampleCount; i++){
        currentPoint += direction * perNodeLength;
        if(CheckOutBox(mode3.x, boxMax.x, boxMin.x, currentPoint.x))
            break;
        if(CheckOutBox(mode3.y, boxMax.y, boxMin.y, currentPoint.y))
            break;
        if(CheckOutBox(mode3.z, boxMax.z, boxMin.z, currentPoint.z))
            break;

        float3 tempPosition = lerp(currentPoint, currentPoint + direction * perNodeLength, seed);
        color += GetStaticBulkLighting(tempPosition, viewDirection, screenUV, _BulkLightScatterRadio, lightIndex);
    }
    color *= i * perNodeLength * _BulkLightShrinkRadio;

    return color;
}


float3 GetBulkLightOutside(float3 worldPos, float2 screenUV, float4 lightIndex, float3 boxMax, float3 boxMin, float3 direction){
    
    float perNodeLength = distance(worldPos, _WorldSpaceCameraPos) / _BulkSampleCount;
    float3 currentPoint = _WorldSpaceCameraPos;
    float3 viewDirection = -direction;

    float3 color = 0;
    float seed = random((screenUV.y + screenUV.x) * _ScreenParams.x * _ScreenParams.y + 0.2312312);
    // float seed = Perlin2DFBM(screenUV, 8);

    int3 mode3;
    mode3.x = (direction.x > 0)? 1 : 0;     //1为判断x的大
    mode3.y = (direction.y > 0)? 1 : 0;
    mode3.z = (direction.z > 0)? 1 : 0;

    int i = 0;
    for(; i < _BulkSampleCount; i++){
        currentPoint += direction * perNodeLength;
        if(CheckOutBox(mode3.x, boxMax.x, boxMin.x, currentPoint.x))
            break;
        if(CheckOutBox(mode3.y, boxMax.y, boxMin.y, currentPoint.y))
            break;
        if(CheckOutBox(mode3.z, boxMax.z, boxMin.z, currentPoint.z))
            break;

        float3 tempPosition = lerp(currentPoint, currentPoint + direction * perNodeLength, seed);
        color += GetStaticBulkLighting(tempPosition, viewDirection, screenUV, _BulkLightScatterRadio, lightIndex);
    }
    color *= i * perNodeLength * _BulkLightShrinkRadio;

    return color;
}



float4 frag(FragmentInput input) : SV_TARGET{
    float3 direction = normalize(input.positionWS.xyz - _WorldSpaceCameraPos);
    switch (input.mode){
        case 0:     //外部，从边界开始
            return float4(GetBulkLight(input.positionWS, input.positionCS.xy, 
                input.lightIndex, input.boxMax, input.boxMin, direction), 1);
        default:    //内部，从摄像机开始
            return float4(GetBulkLightOutside(input.positionWS.xyz, input.positionCS.xy, 
                input.lightIndex, input.boxMax, input.boxMin, direction), 1);
    }
    // return float4(GetBulkLight(input.positionWS, input.positionCS.xy * _CameraBufferSize.xy, input.lightIndex, input.boxMax, input.boxMin), 1);
    return 1;
}


#endif