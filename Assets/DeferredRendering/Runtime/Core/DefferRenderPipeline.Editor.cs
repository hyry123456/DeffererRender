using Unity.Collections;
using UnityEngine;
using UnityEngine.Experimental.GlobalIllumination;
using LightType = UnityEngine.LightType;


namespace DefferedRender
{
    public partial class DefferRenderPipeline
    {
		partial void InitializeForEditor();

		partial void DisposeForEditor();

#if UNITY_EDITOR

		/// <summary>	/// 编译器中渲染管线对象需要调用的方法，其实就是重写烘焙贴图的生成方法	/// </summary>
		partial void InitializeForEditor()
		{
			Lightmapping.SetDelegate(lightsDelegate);
		}

		/// <summary>	/// 不需要时释放对于光照贴图的重写	/// </summary>
		partial void DisposeForEditor()
		{
			Lightmapping.ResetDelegate();
		}

		/// <summary>	/// 重写烘焙贴图生成方法的方法，根据不同的光源类型调整其实际使用模式	/// </summary>
		static Lightmapping.RequestLightsDelegate lightsDelegate =
			(Light[] lights, NativeArray<LightDataGI> output) => {
				var lightData = new LightDataGI();
				for (int i = 0; i < lights.Length; i++)
				{
					Light light = lights[i];
					switch (light.type)
					{
						case LightType.Directional:
							var directionalLight = new DirectionalLight();
							LightmapperUtils.Extract(light, ref directionalLight);
							lightData.Init(ref directionalLight);
							break;
						case LightType.Point:
							var pointLight = new PointLight();
							LightmapperUtils.Extract(light, ref pointLight);
							lightData.Init(ref pointLight);
							break;
						case LightType.Spot:
							var spotLight = new SpotLight();
							LightmapperUtils.Extract(light, ref spotLight);
							lightData.Init(ref spotLight);
							break;
						case LightType.Area:
							var rectangleLight = new RectangleLight();
							LightmapperUtils.Extract(light, ref rectangleLight);
							rectangleLight.mode = LightMode.Baked;
							lightData.Init(ref rectangleLight);
							break;
						default:
							lightData.InitNoBake(light.GetInstanceID());
							break;
					}
					lightData.falloff = FalloffType.InverseSquared;
					output[i] = lightData;
				}
			};

#endif
	}
}