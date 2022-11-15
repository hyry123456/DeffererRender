#ifndef DEFFER_TERRAIN_LEAF_INPUT
#define DEFFER_TERRAIN_LEAF_INPUT
//处理一些Unity要求但是我没有使用过的数据
UNITY_INSTANCING_BUFFER_START(UnityPerTree)

	UNITY_DEFINE_INSTANCED_PROP(float4, _TranslucencyColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _TranslucencyViewDependency)
	UNITY_DEFINE_INSTANCED_PROP(float, _ShadowStrength)
// float4 _Wind;    //Unity的树提供的数据
    UNITY_DEFINE_INSTANCED_PROP(float4, _Wind)

UNITY_INSTANCING_BUFFER_END(UnityPerTree)

#endif