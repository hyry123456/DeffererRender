using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    public class Lighting
    {
		const string bufferName = "Lighting";

		/// <summary>
		/// 支持的直接光和间接光的数量
		/// </summary>
		const int maxDirLightCount = 4, maxOtherLightCount = 64;

		static int
			dirLightCountId = Shader.PropertyToID("_DirectionalLightCount"),
			dirLightColorsId = Shader.PropertyToID("_DirectionalLightColors"),
			dirLightDirectionsAndMasksId =
				Shader.PropertyToID("_DirectionalLightDirectionsAndMasks"),
			dirLightShadowDataId =
				Shader.PropertyToID("_DirectionalLightShadowData");

		static Vector4[]
			dirLightColors = new Vector4[maxDirLightCount],
			dirLightDirectionsAndMasks = new Vector4[maxDirLightCount],
			dirLightShadowData = new Vector4[maxDirLightCount];

		static int
			otherLightCountId = Shader.PropertyToID("_OtherLightCount"),
			otherLightColorsId = Shader.PropertyToID("_OtherLightColors"),
			otherLightPositionsId = Shader.PropertyToID("_OtherLightPositions"),
			otherLightDirectionsAndMasksId = Shader.PropertyToID("_OtherLightDirectionsAndMasks"),
			otherLightSpotAnglesId = Shader.PropertyToID("_OtherLightSpotAngles"),
			otherLightShadowDataId = Shader.PropertyToID("_OtherLightShadowData");

		static Vector4[]
			otherLightColors = new Vector4[maxOtherLightCount],
			otherLightPositions = new Vector4[maxOtherLightCount],
			otherLightDirectionsAndMasks = new Vector4[maxOtherLightCount],
			otherLightSpotAngles = new Vector4[maxOtherLightCount],
			otherLightShadowData = new Vector4[maxOtherLightCount];

		CommandBuffer buffer = new CommandBuffer
		{
			name = bufferName
		};

		CullingResults cullingResults;
		Shadows shadows = new Shadows();
		Camera camera;

		/// <summary>
		/// 准备以及复制灯光数据，在灯光中会一同处理阴影数据
		/// </summary>
		/// <param name="cullingResults">裁剪数据</param>
		/// <param name="shadowSettings">阴影设置数据</param>
		/// <param name="renderingLayerMask">渲染遮罩层</param>
		public void Setup(
			ScriptableRenderContext context, int renderingLayerMask,
			CullingResults cullingResults, ShadowSetting shadowSettings,
			Camera camera, ClusterLightSetting clusterLight
		)
		{
			this.cullingResults = cullingResults;
			this.camera = camera;
			buffer.BeginSample(bufferName);
			shadows.Setup(context, cullingResults, shadowSettings); //注册阴影数据
			SetupLights(renderingLayerMask, clusterLight);  //注册灯光，传递灯光数据
			shadows.Render();                                       //渲染阴影
			buffer.EndSample(bufferName);
			context.ExecuteCommandBuffer(buffer);
			buffer.Clear();
		}

		/// <summary>		/// 清除阴影纹理		/// </summary>
		public void Cleanup()
		{
			shadows.Cleanup();
		}

		/// <summary>	/// 准备以及传递灯光数据	/// </summary>
		void SetupLights(int renderingLayerMask, ClusterLightSetting clusterSetting)
		{
			//所有可见的灯光数据
			NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;
			int dirLightCount = 0, otherLightCount = 0;
			int i;
			//枚举每一个灯光数据进行注册
			for (i = 0; i < visibleLights.Length; i++)
			{
				int newIndex = -1;
				VisibleLight visibleLight = visibleLights[i];   //目前灯光数据
				Light light = visibleLight.light;               //该灯光的灯光内部数据
				if ((light.renderingLayerMask & renderingLayerMask) != 0)
				{   //判断该灯光是否要在本摄像机中支持
					switch (visibleLight.lightType)
					{           //判断灯光类型，进行对应的初始化
						case LightType.Directional:
							if (dirLightCount < maxDirLightCount)
							{
								SetupDirectionalLight(
									dirLightCount++, i, ref visibleLight, light
								);
							}
							break;
						case LightType.Point:
							if (otherLightCount < maxOtherLightCount)
							{
								newIndex = otherLightCount;
								SetupPointLight(
									otherLightCount++, i, ref visibleLight, light
								);
							}
							break;
						case LightType.Spot:
							if (otherLightCount < maxOtherLightCount)
							{
								newIndex = otherLightCount;
								SetupSpotLight(otherLightCount++, i, ref visibleLight, light);
							}
							break;
					}
				}
			}

			buffer.SetGlobalInt(dirLightCountId, dirLightCount);
			if (dirLightCount > 0)
			{
				buffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
				buffer.SetGlobalVectorArray(
					dirLightDirectionsAndMasksId, dirLightDirectionsAndMasks
				);
				buffer.SetGlobalVectorArray(dirLightShadowDataId, dirLightShadowData);
			}

			buffer.SetGlobalInt(otherLightCountId, otherLightCount);

			//灯光裁剪
			buffer.SetGlobalVectorArray(otherLightColorsId, otherLightColors);
			buffer.SetGlobalVectorArray(
				otherLightPositionsId, otherLightPositions
			);
			buffer.SetGlobalVectorArray(
				otherLightDirectionsAndMasksId, otherLightDirectionsAndMasks
			);
			buffer.SetGlobalVectorArray(
				otherLightSpotAnglesId, otherLightSpotAngles
			);
			buffer.SetGlobalVectorArray(
				otherLightShadowDataId, otherLightShadowData
			);
            //ReadyClusterLight(camera, clusterSetting);
        }

		/// <summary>
		/// 注册直接光数据，存储到数组中，之后传递给GPU
		/// </summary>
		/// <param name="index">数组编号</param>
		/// <param name="visibleIndex">灯光中的编号</param>
		/// <param name="visibleLight">可视灯光数据，存储了矩阵数据</param>
		/// <param name="light">灯光数据</param>
		void SetupDirectionalLight(
			int index, int visibleIndex, ref VisibleLight visibleLight, Light light
		)
		{
			dirLightColors[index] = visibleLight.finalColor;                    //存颜色
			Vector4 dirAndMask = -visibleLight.localToWorldMatrix.GetColumn(2); //方向
			dirAndMask.w = light.renderingLayerMask.ReinterpretAsFloat();       //遮罩层
			dirLightDirectionsAndMasks[index] = dirAndMask;                     //存储方向和遮罩层
			dirLightShadowData[index] =
				shadows.ReserveDirectionalShadows(light, visibleIndex);         //存储阴影数据
		}

		/// <summary>	/// 注册点光数据	/// </summary>
		void SetupPointLight(
			int index, int visibleIndex, ref VisibleLight visibleLight, Light light
		)
		{
			otherLightColors[index] = visibleLight.finalColor;
			Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);        //世界坐标
			position.w =
				1f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);  //点光范围
			otherLightPositions[index] = position;                                  //存储点光位置以及范围
			otherLightSpotAngles[index] = new Vector4(0f, 1f);                      //与射灯进行区分的赋值
			Vector4 dirAndmask = Vector4.zero;
			dirAndmask.w = light.renderingLayerMask.ReinterpretAsFloat();
			otherLightDirectionsAndMasks[index] = dirAndmask;
			otherLightShadowData[index] =
				shadows.ReserveOtherShadows(light, visibleIndex);
		}

		/// <summary>	/// 注册射灯数据	/// </summary>
		void SetupSpotLight(
			int index, int visibleIndex, ref VisibleLight visibleLight, Light light
		)
		{
			otherLightColors[index] = visibleLight.finalColor;
			Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);
			position.w =
				1f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);
			otherLightPositions[index] = position;
			Vector4 dirAndMask = -visibleLight.localToWorldMatrix.GetColumn(2);
			dirAndMask.w = light.renderingLayerMask.ReinterpretAsFloat();
			otherLightDirectionsAndMasks[index] = dirAndMask;

			float innerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * light.innerSpotAngle);
			float outerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * visibleLight.spotAngle);
			float angleRangeInv = 1f / Mathf.Max(innerCos - outerCos, 0.001f);
			otherLightSpotAngles[index] = new Vector4(
				angleRangeInv, -outerCos * angleRangeInv, outerCos
			);
			otherLightShadowData[index] =
				shadows.ReserveOtherShadows(light, visibleIndex);
		}

		public void ReadyClusterLight(Camera camera, ClusterLightSetting setting,
			int depthId)
		{
			ClusterLight_VS clusterLight_VS = ClusterLight_VS.Instance;
			if (camera.cameraType == CameraType.Game && setting.isUse && clusterLight_VS == null)
			{
				buffer.EnableShaderKeyword("_USE_CLUSTER");
			}
            else
            {
				buffer.DisableShaderKeyword("_USE_CLUSTER");
				return;
			}

			clusterLight_VS.ComputeLightCluster(buffer, setting, camera, depthId);
		}
	}
}