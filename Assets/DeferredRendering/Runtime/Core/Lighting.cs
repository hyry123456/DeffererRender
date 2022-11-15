using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    public class Lighting
    {
		const string bufferName = "Lighting";

		/// <summary>
		/// ֧�ֵ�ֱ�ӹ�ͼ�ӹ������
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
		/// ׼���Լ����Ƶƹ����ݣ��ڵƹ��л�һͬ������Ӱ����
		/// </summary>
		/// <param name="cullingResults">�ü�����</param>
		/// <param name="shadowSettings">��Ӱ��������</param>
		/// <param name="renderingLayerMask">��Ⱦ���ֲ�</param>
		public void Setup(
			ScriptableRenderContext context, int renderingLayerMask,
			CullingResults cullingResults, ShadowSetting shadowSettings,
			Camera camera, ClusterLightSetting clusterLight
		)
		{
			this.cullingResults = cullingResults;
			this.camera = camera;
			buffer.BeginSample(bufferName);
			shadows.Setup(context, cullingResults, shadowSettings); //ע����Ӱ����
			SetupLights(renderingLayerMask, clusterLight);  //ע��ƹ⣬���ݵƹ�����
			shadows.Render();                                       //��Ⱦ��Ӱ
			buffer.EndSample(bufferName);
			context.ExecuteCommandBuffer(buffer);
			buffer.Clear();
		}

		/// <summary>		/// �����Ӱ����		/// </summary>
		public void Cleanup()
		{
			shadows.Cleanup();
		}

		/// <summary>	/// ׼���Լ����ݵƹ�����	/// </summary>
		void SetupLights(int renderingLayerMask, ClusterLightSetting clusterSetting)
		{
			//���пɼ��ĵƹ�����
			NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;
			int dirLightCount = 0, otherLightCount = 0;
			int i;
			//ö��ÿһ���ƹ����ݽ���ע��
			for (i = 0; i < visibleLights.Length; i++)
			{
				int newIndex = -1;
				VisibleLight visibleLight = visibleLights[i];   //Ŀǰ�ƹ�����
				Light light = visibleLight.light;               //�õƹ�ĵƹ��ڲ�����
				if ((light.renderingLayerMask & renderingLayerMask) != 0)
				{   //�жϸõƹ��Ƿ�Ҫ�ڱ��������֧��
					switch (visibleLight.lightType)
					{           //�жϵƹ����ͣ����ж�Ӧ�ĳ�ʼ��
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

			//�ƹ�ü�
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
		/// ע��ֱ�ӹ����ݣ��洢�������У�֮�󴫵ݸ�GPU
		/// </summary>
		/// <param name="index">������</param>
		/// <param name="visibleIndex">�ƹ��еı��</param>
		/// <param name="visibleLight">���ӵƹ����ݣ��洢�˾�������</param>
		/// <param name="light">�ƹ�����</param>
		void SetupDirectionalLight(
			int index, int visibleIndex, ref VisibleLight visibleLight, Light light
		)
		{
			dirLightColors[index] = visibleLight.finalColor;                    //����ɫ
			Vector4 dirAndMask = -visibleLight.localToWorldMatrix.GetColumn(2); //����
			dirAndMask.w = light.renderingLayerMask.ReinterpretAsFloat();       //���ֲ�
			dirLightDirectionsAndMasks[index] = dirAndMask;                     //�洢��������ֲ�
			dirLightShadowData[index] =
				shadows.ReserveDirectionalShadows(light, visibleIndex);         //�洢��Ӱ����
		}

		/// <summary>	/// ע��������	/// </summary>
		void SetupPointLight(
			int index, int visibleIndex, ref VisibleLight visibleLight, Light light
		)
		{
			otherLightColors[index] = visibleLight.finalColor;
			Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);        //��������
			position.w =
				1f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);  //��ⷶΧ
			otherLightPositions[index] = position;                                  //�洢���λ���Լ���Χ
			otherLightSpotAngles[index] = new Vector4(0f, 1f);                      //����ƽ������ֵĸ�ֵ
			Vector4 dirAndmask = Vector4.zero;
			dirAndmask.w = light.renderingLayerMask.ReinterpretAsFloat();
			otherLightDirectionsAndMasks[index] = dirAndmask;
			otherLightShadowData[index] =
				shadows.ReserveOtherShadows(light, visibleIndex);
		}

		/// <summary>	/// ע���������	/// </summary>
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
			if (camera.cameraType != CameraType.Game || !setting.isUse || clusterLight_VS == null)
			{
				buffer.DisableShaderKeyword("_USE_CLUSTER");
				return;
			}
			else
				buffer.EnableShaderKeyword("_USE_CLUSTER");

			clusterLight_VS.ComputeLightCluster(buffer, setting, camera, depthId);
		}
	}
}