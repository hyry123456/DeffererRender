using UnityEngine;
using UnityEngine.Rendering;
using static DefferedRender.PostFXSetting;

namespace DefferedRender
{

    public class PostFXStack 
    {
        enum Pass
        {
			BloomAdd,
			BlurHorizontal,
			BloomPrefilter,
			BloomPrefilterFireflies,
			BloomScatter,
			BloomScatterFinal,
			BlurVertical,
			Copy,
			ColorGradingNone,
			ColorGradingACES,
			ColorGradingNeutral,
			ColorGradingReinhard,
			Final,
			//SSS,
			GBufferFinal,
			BulkLight,
			BilateralFilter,
			BlendBulk,
			//Fog,
			CaculateGray,
			FXAA,
			CopyDepth,
			CameraStickWater,
			CircleOfConfusion,
			PreFilter,
			Bokeh,
			PostFilter,
			Combine,
		}

        const string bufferName = "PostFX";

        const int maxBloomPyramidLevels = 16;

		int
			sssTargetTex = Shader.PropertyToID("_SSSTargetTex"),
			maxRayMarchingStepId = Shader.PropertyToID("_MaxRayMarchingStep"),
			rayMarchingStepSizeId = Shader.PropertyToID("_RayMarchingStepSize"),
			maxRayMarchingDistance = Shader.PropertyToID("_MaxRayMarchingDistance"),
			depthThicknessId = Shader.PropertyToID("_DepthThickness");


		int
			bloomBicubicUpsamplingId = Shader.PropertyToID("_BloomBicubicUpsampling"),
            bloomIntensityId = Shader.PropertyToID("_BloomIntensity"),
            bloomPrefilterId = Shader.PropertyToID("_BloomPrefilter"),
            bloomResultId = Shader.PropertyToID("_BloomResult"),
            bloomThresholdId = Shader.PropertyToID("_BloomThreshold"),
            fxSourceId = Shader.PropertyToID("_PostFXSource"),
            fxSource2Id = Shader.PropertyToID("_PostFXSource2"),
            fxSource3Id = Shader.PropertyToID("_PostFXSource3");

		int
			colorGradingLUTId = Shader.PropertyToID("_ColorGradingLUT"),
			colorGradingLUTParametersId = Shader.PropertyToID("_ColorGradingLUTParameters"),
			colorGradingLUTInLogId = Shader.PropertyToID("_ColorGradingLUTInLogC"),
			colorAdjustmentsId = Shader.PropertyToID("_ColorAdjustments"),
			colorFilterId = Shader.PropertyToID("_ColorFilter"),
			whiteBalanceId = Shader.PropertyToID("_WhiteBalance"),
			splitToningShadowsId = Shader.PropertyToID("_SplitToningShadows"),
			splitToningHighlightsId = Shader.PropertyToID("_SplitToningHighlights"),
			bulkLightTargetTexId = Shader.PropertyToID("_BulkLightTargetTex"),
			bulkLightTempTexId = Shader.PropertyToID("_BulkLightTempTex"),
			bulkLightTemp2TexId = Shader.PropertyToID("_BulkLightTemp2Tex"),
			bulkLightDepthTexId = Shader.PropertyToID("_BulkLightDepthTex"),
			bulkLightShrinkRadioId = Shader.PropertyToID("_BulkLightShrinkRadio"),
			bulkLightSampleCountId = Shader.PropertyToID("_BulkSampleCount"),
			bulkLightScatterRadioId = Shader.PropertyToID("_BulkLightScatterRadio"),
			bulkLightCheckMaxDistanceId = Shader.PropertyToID("_BulkLightCheckMaxDistance"),


			finalTempTexId = Shader.PropertyToID("_FinalTempTexure"),
			fxaaTempTexId = Shader.PropertyToID("_FXAATempTexture"),
			contrastThresholdId = Shader.PropertyToID("_ContrastThreshold"),
			relativeThresholdId = Shader.PropertyToID("_RelativeThreshold"),
			subpixelBlending = Shader.PropertyToID("_SubpixelBlending"),

			stickWaterDataId = Shader.PropertyToID("_StickWaterData");





		CommandBuffer buffer = new CommandBuffer
        {
            name = bufferName
        };

        ScriptableRenderContext context;

        Camera camera;

        PostFXSetting settings;
        int bloomPyramidId;
		bool useHDR;
		CullingResults cullingResults; int depthId;
		public bool IsActive => settings != null;
		int width, height;

		public PostFXStack()
        {
            bloomPyramidId = Shader.PropertyToID("_BloomPyramid0");
			for (int i = 1; i < maxBloomPyramidLevels * 2; i++)
            {
                Shader.PropertyToID("_BloomPyramid" + i);
            }
        }

        /// <summary>	/// ׼������ǰ������׼��	/// </summary>
        public void Setup(
            ScriptableRenderContext context, Camera camera, PostFXSetting settings,
            bool useHDR, CullingResults cullingResults, int depthId,
			int width, int height
        )
        {
            this.useHDR = useHDR;
            this.context = context;
            this.camera = camera;
            this.settings = settings;
			this.cullingResults = cullingResults;
			this.depthId = depthId;
			this.width = width;
			this.height = height;

			////ˮ����Ⱦʱ��Ҫ�õ������ݣ��жϷ������ݵĲɼ�ģʽ
			//if (settings.UseSSR())
			//	buffer.EnableShaderKeyword("_USE_SSR");
			//else
			//	buffer.DisableShaderKeyword("_USE_SSR");
		}

		/// <summary>
		/// �Դ����������к���
		/// </summary>
		/// <param name="sourceId">Ӱ�������</param>
		public void Render(int sourceId)
        {
			if (settings.BulkLighting.useBulkLight && BulkLight.UseBulkLight)
            {
                DrawBulkLight(sourceId);
            }

            if (settings.StickWater.useStickWater)
            {
				DoCameraStickWater(sourceId);
            }

			if(settings.DepthOfField.useDepthOfField)
				DepthOfField(sourceId);

			if (DoBloom(sourceId))
			{
                DoColorGradingAndToneMapping(bloomResultId);
                buffer.ReleaseTemporaryRT(bloomResultId);
			}
			else
			{
                DoColorGradingAndToneMapping(sourceId);
            }

			context.ExecuteCommandBuffer(buffer);
			buffer.Clear();
		}

		bool useSSR;

		/// <summary>/// ׼��SSR�����Ŀ����ͼ/// </summary>
		/// <param name="preFrameRenderFinal">��һ֡��Ⱦ����������</param>
		/// <param name="reflectTex">�ɼ����ķ�����ͼ</param>
		public void DrawSSS(RenderTexture preFrameRenderFinal, int[] gBuffers)
        {
            if (settings.UseSSR() && preFrameRenderFinal != null
				&& camera.cameraType == CameraType.Game)
            {
				if(preFrameRenderFinal.width != width
					|| preFrameRenderFinal.height != height)
                {
					useSSR = false;
					return;
                }

				buffer.GetTemporaryRT(sssTargetTex, width, height, 0, FilterMode.Bilinear,
					RenderTextureFormat.DefaultHDR, RenderTextureReadWrite.Linear, 1, true);

				SSR ssr = settings.ssr;

				buffer.SetComputeIntParam(settings.ComputeShader, maxRayMarchingStepId, ssr.rayMarchingSetp);
				buffer.SetComputeFloatParam(settings.ComputeShader, rayMarchingStepSizeId, ssr.marchSetpSize);
				buffer.SetComputeFloatParam(settings.ComputeShader, maxRayMarchingDistance, ssr.maxMarchDistance);
				buffer.SetComputeFloatParam(settings.ComputeShader, depthThicknessId, ssr.depthThickness);

				buffer.SetComputeIntParams(settings.ComputeShader, "_PixelCount",
					new int[] { width, height });
				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel, "Result", sssTargetTex);
				//����GBuffer
				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel, "_GBufferRT1", gBuffers[1]);
				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel, "_GBufferRT2", gBuffers[2]);
				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel, "_GBufferRT3", gBuffers[3]);
				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel, "_OriginTex", preFrameRenderFinal);
				buffer.DispatchCompute(settings.ComputeShader, settings.SSR_Kernel,
					width / 32 + 1, height / 32 + 1, 1);
				useSSR = true;


				buffer.GetTemporaryRT(bulkLightTempTexId, width, height,
					0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR, 
					RenderTextureReadWrite.Linear, 1, true);

				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel + 1, "Result", bulkLightTempTexId);
				//����GBuffer
				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel + 1, "_GBufferRT1", gBuffers[1]);
				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel + 1, "_GBufferRT2", gBuffers[2]);
				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel + 1, "_GBufferRT3", gBuffers[3]);
				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel + 1, "_OriginTex", sssTargetTex);

				buffer.SetComputeFloatParam(settings.ComputeShader, 
					"_BilaterFilterFactor", ssr.bilaterFilterFactor);
				buffer.SetComputeIntParam(settings.ComputeShader,
					"_BlurRadius", settings.ssr.blurRadius);
				buffer.DispatchCompute(settings.ComputeShader, settings.SSR_Kernel + 1,
					width / 32 + 1, height / 32 + 1, 1);

				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel + 2, "Result", sssTargetTex);
				buffer.SetComputeTextureParam(settings.ComputeShader,
					settings.SSR_Kernel + 2, "_OriginTex", bulkLightTempTexId);
				buffer.DispatchCompute(settings.ComputeShader, settings.SSR_Kernel + 2,
					width / 32 + 1, height / 32 + 1, 1);
				buffer.ReleaseTemporaryRT(bulkLightTempTexId);
			}
            else
            {
				useSSR = false;
            }
			//buffer.GetTemporaryRT(sssTargetTex, this.width, this.height,
			//	0, FilterMode.Bilinear, useHDR ?
			//		RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default);

			////�Ѿ�̬���䱣������
			//Draw(reflectTex, sssTargetTex, Pass.Copy);
			//if (settings.ssr.useSSR && camera.cameraType == CameraType.Game)
   //         {
			//	SSR ssr = settings.ssr;
			//	buffer.SetGlobalInt(maxRayMarchingStepId, ssr.rayMarchingSetp);
			//	buffer.SetGlobalFloat(rayMarchingStepSizeId, ssr.marchSetpSize);
			//	buffer.SetGlobalFloat(maxRayMarchingDistance, ssr.maxMarchDistance);
			//	buffer.SetGlobalFloat(depthThicknessId, ssr.depthThickness);
			//	//����ʵʱ����
			//	Draw(preFrameRenderFinal, sssTargetTex, Pass.SSS);
   //         }

			//buffer.GetTemporaryRT(bulkLightTempTexId, this.width, this.height,
			//	0, FilterMode.Bilinear, useHDR ?
			//		RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default);

			//buffer.SetGlobalFloat("_BilaterFilterFactor", settings.ssr.bilaterFilterFactor);
			//buffer.SetGlobalVector("_BlurRadius", new Vector4(settings.ssr.blurRadius, 0));
			//Draw(sssTargetTex, bulkLightTempTexId, Pass.BilateralFilter);
			//buffer.SetGlobalVector("_BlurRadius", new Vector4(0, settings.ssr.blurRadius));
			//Draw(bulkLightTempTexId, sssTargetTex, Pass.BilateralFilter);
			//buffer.ReleaseTemporaryRT(bulkLightTempTexId);


			//����ģ������
			//buffer.GetTemporaryRT(bulkLightTempTexId, this.width, this.height,
			//0, FilterMode.Bilinear, useHDR ?
			//	RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default);

			//Draw(sssTargetTex, bulkLightTempTexId, Pass.BlurHorizontal);
			//Draw(bulkLightTempTexId, sssTargetTex, Pass.BlurVertical);
			//buffer.ReleaseTemporaryRT(bulkLightTempTexId);
		}

		/// <summary>
		/// ������������Ҳ���Ǹ���SSS��GBuffer������Ⱦ����������
		/// </summary>
		public void DrawGBufferFinal(int targetTexId, int gBufferRefl)
		{
			if (!useSSR)
			{
				buffer.SetGlobalTexture(sssTargetTex, gBufferRefl);
				//buffer.SetGlobalTexture(sssTargetTex, sssTargetTex);
			}
			//else
            Draw(0, targetTexId, Pass.GBufferFinal);
			buffer.ReleaseTemporaryRT(sssTargetTex);
			ExecuteBuffer();
		}

		/// <summary>		/// ��Ⱦ�����		/// </summary>
		public void DrawBulkLight(int source)
        {
			buffer.BeginSample("BulkLight");

            buffer.SetGlobalFloat(bulkLightShrinkRadioId, settings.BulkLighting.shrinkRadio / 100000f);
            buffer.SetGlobalInt(bulkLightSampleCountId, settings.BulkLighting.circleCount);
            buffer.SetGlobalFloat(bulkLightScatterRadioId, settings.BulkLighting.scatterRadio);
            buffer.SetGlobalFloat(bulkLightCheckMaxDistanceId, settings.BulkLighting.checkDistance);

            RenderTextureFormat format = useHDR ?
                RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default;
            int width = this.width / 2, height = this.height / 2;
            buffer.GetTemporaryRT(bulkLightTargetTexId, width, height, 0, FilterMode.Bilinear, format);
            buffer.GetTemporaryRT(bulkLightTempTexId, width, height, 0, FilterMode.Bilinear, format);
			buffer.GetTemporaryRT(bulkLightDepthTexId, width, height, 32, 
				FilterMode.Point, RenderTextureFormat.Depth);
            //���Target����ɫ
            Draw(Texture2D.blackTexture, bulkLightTargetTexId, Pass.Copy);
            Draw(depthId, bulkLightDepthTexId, Pass.CopyDepth);
            //Draw(0, bulkLightTargetTexId, Pass.BulkLight);      //���Bulk Lightǿ��ͼ
            buffer.SetRenderTarget(
				bulkLightTargetTexId, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store,
				bulkLightDepthTexId, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store);

            BulkLight.Instance.DrawBulkLight(buffer);

			buffer.ReleaseTemporaryRT(bulkLightDepthTexId);

            //��˹ģ���������ͼ
            Draw(bulkLightTargetTexId, bulkLightTempTexId, Pass.BlurHorizontal);
			Draw(bulkLightTempTexId, bulkLightTargetTexId, Pass.BlurVertical);

            buffer.SetGlobalTexture(fxSource2Id, bulkLightTargetTexId);	//ģ�����ǿ��ͼ

			buffer.GetTemporaryRT(bulkLightTemp2TexId, this.width, this.height,
				0, FilterMode.Bilinear, format);
			Draw(source, bulkLightTemp2TexId, Pass.BlendBulk);         //����Ŀ������
			Draw(bulkLightTemp2TexId, source, Pass.Copy);         //������Ŀ������ԭ����

			buffer.ReleaseTemporaryRT(bulkLightTemp2TexId);
			buffer.ReleaseTemporaryRT(bulkLightTempTexId);
			buffer.ReleaseTemporaryRT(bulkLightTargetTexId);

			buffer.EndSample("BulkLight");
			ExecuteBuffer();
		}

		/// <summary>		/// �����������ͼ���λ�ý��п����		/// </summary>
		public void DrawFXAAInFinal(int soure)
        {
			buffer.BeginSample("FXAA");
			FXAASetting fXAA = settings.FXAA;

			buffer.SetGlobalFloat(contrastThresholdId, fXAA.contrastThreshold);
			buffer.SetGlobalFloat(relativeThresholdId, fXAA.relativeThreshold);
			buffer.SetGlobalFloat(subpixelBlending, fXAA.subpixelBlending);

			if (fXAA.lowQuality)
				buffer.EnableShaderKeyword("LOW_QUALITY");
			else
				buffer.DisableShaderKeyword("LOW_QUALITY");
			
			if(fXAA.luminanceMode == LuminanceMode.Green)
            {
				buffer.DisableShaderKeyword("LUMINANCE_GREEN");
				Draw(soure, BuiltinRenderTextureType.CameraTarget, Pass.FXAA);
			}
			else
            {
				buffer.EnableShaderKeyword("LUMINANCE_GREEN");
				buffer.GetTemporaryRT(fxaaTempTexId, this.width, this.height,
					0, FilterMode.Bilinear, RenderTextureFormat.Default);
				Draw(soure, fxaaTempTexId, Pass.CaculateGray);
				Draw(fxaaTempTexId, BuiltinRenderTextureType.CameraTarget, Pass.FXAA);
				buffer.ReleaseTemporaryRT(fxaaTempTexId);
			}
			buffer.EndSample("FXAA");

		}

		/// <summary>	/// ����Bloom����	/// </summary>
		/// <returns>�Ƿ�ɹ�����Bloom</returns>
		bool DoBloom(int sourceId)
		{
			BloomSettings bloom = settings.Bloom;
            int width = this.width / 2, height = this.height / 2;
            if (
				bloom.maxIterations == 0 || bloom.intensity <= 0f ||
				height < bloom.downscaleLimit * 2 || width < bloom.downscaleLimit * 2
			)
			{
				return false;
			}

			buffer.BeginSample("Bloom");
			Vector4 threshold;
			threshold.x = Mathf.GammaToLinearSpace(bloom.threshold);
			threshold.y = threshold.x * bloom.thresholdKnee;
			threshold.z = 2f * threshold.y;
			threshold.w = 0.25f / (threshold.y + 0.00001f);
			threshold.y -= threshold.x;
			buffer.SetGlobalVector(bloomThresholdId, threshold);        //Bloom����׼��

			RenderTextureFormat format = useHDR ?
				RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default;
			buffer.GetTemporaryRT(
				bloomPrefilterId, width, height, 0, FilterMode.Bilinear, format
			);

			Draw(
				sourceId, bloomPrefilterId, bloom.fadeFireflies ?
					Pass.BloomPrefilterFireflies : Pass.BloomPrefilter
			);
			width /= 2;
			height /= 2;

			int fromId = bloomPrefilterId, toId = bloomPyramidId + 1;
			int i;
			//���ѭ���������𼶸�˹ģ��
			for (i = 0; i < bloom.maxIterations; i++)
			{

				if (height < bloom.downscaleLimit || width < bloom.downscaleLimit)
				{
					break;
				}
				int midId = toId - 1;
				buffer.GetTemporaryRT(
					midId, width, height, 0, FilterMode.Bilinear, format
				);
				buffer.GetTemporaryRT(
					toId, width, height, 0, FilterMode.Bilinear, format
				);
				//ˮƽ�Լ���ֱ��˹ģ��
				Draw(fromId, midId, Pass.BlurHorizontal);
				Draw(midId, toId, Pass.BlurVertical);
				//ģ��������������ش�С
				fromId = toId;
				toId += 2;
				width /= 2;
				height /= 2;
			}

			buffer.ReleaseTemporaryRT(bloomPrefilterId);
			buffer.SetGlobalFloat(
				bloomBicubicUpsamplingId, bloom.bicubicUpsampling ? 1f : 0f
			);

			//��������Ļ��ģʽ����ʹ�ý����ϻ���ֱ�����
			Pass combinePass, finalPass;
			float finalIntensity;
			if (bloom.mode == BloomSettings.Mode.Additive)
			{
				combinePass = finalPass = Pass.BloomAdd;
				buffer.SetGlobalFloat(bloomIntensityId, 1f);
				finalIntensity = bloom.intensity;
			}
			else
			{
				combinePass = Pass.BloomScatter;
				finalPass = Pass.BloomScatterFinal;
				buffer.SetGlobalFloat(bloomIntensityId, bloom.scatter);
				finalIntensity = Mathf.Min(bloom.intensity, 1f);
			}

			//ѭ����ϵ����ϼ�������
			if (i > 1)
			{
				buffer.ReleaseTemporaryRT(fromId - 1);
				toId -= 5;
				for (i -= 1; i > 0; i--)
				{
					buffer.SetGlobalTexture(fxSource2Id, toId + 1);
					Draw(fromId, toId, combinePass);
					buffer.ReleaseTemporaryRT(fromId);
					buffer.ReleaseTemporaryRT(toId + 1);
					fromId = toId;
					toId -= 2;
				}
			}
			else
			{
				buffer.ReleaseTemporaryRT(bloomPyramidId);
			}
			buffer.SetGlobalFloat(bloomIntensityId, finalIntensity);
			buffer.SetGlobalTexture(fxSource2Id, sourceId);
			buffer.GetTemporaryRT(
				bloomResultId, this.width, this.height, 0,
				FilterMode.Bilinear, format
			);
			//���Ƶ�Ŀ��������
			Draw(fromId, bloomResultId, finalPass);
			buffer.ReleaseTemporaryRT(fromId);
			buffer.EndSample("Bloom");
			return true;
		}

		/// <summary>	/// ����ɫ�ʷּ��Լ���Ⱦ���������	/// </summary>
		/// <param name="sourceId">Դ����</param>
		void DoColorGradingAndToneMapping(int sourceId)
		{
			ConfigureColorAdjustments();
			ConfigureWhiteBalance();
			ConfigureSplitToning();

			int lutHeight = (int)settings.LUTResolution;
			int lutWidth = lutHeight * lutHeight;
			buffer.GetTemporaryRT(
				colorGradingLUTId, lutWidth, lutHeight, 0,
				FilterMode.Bilinear, RenderTextureFormat.DefaultHDR
			);
			buffer.SetGlobalVector(colorGradingLUTParametersId, new Vector4(
				lutHeight, 0.5f / lutWidth, 0.5f / lutHeight, lutHeight / (lutHeight - 1f)
			));

			ToneMappingSettings.Mode mode = settings.ToneMapping.mode;
			Pass pass = Pass.ColorGradingNone + (int)mode;
			buffer.SetGlobalFloat(
				colorGradingLUTInLogId, useHDR && pass != Pass.ColorGradingNone ? 1f : 0f
			);
			//���Ʋ��Ҽ�����
			Draw(sourceId, colorGradingLUTId, pass);

			buffer.SetGlobalVector(colorGradingLUTParametersId,
				new Vector4(1f / lutWidth, 1f / lutHeight, lutHeight - 1f)
			);

			if(settings.FXAA.luminanceMode == LuminanceMode.None)
            {
				//��������ͼ��
				DrawFinal(sourceId);
            }
            else
            {
				buffer.GetTemporaryRT(finalTempTexId, this.width, this.height, 
					0, FilterMode.Bilinear, RenderTextureFormat.Default);
				Draw(sourceId, finalTempTexId, Pass.Final);
				DrawFXAAInFinal(finalTempTexId);
				buffer.ReleaseTemporaryRT(finalTempTexId);
			}
			buffer.ReleaseTemporaryRT(colorGradingLUTId);
		}

		/// <summary>/// ����һ����Ļճˮ��Ч��/// </summary>
		void DoCameraStickWater(int sourceId)
        {
			buffer.GetTemporaryRT(bulkLightTempTexId, width, height, 0, FilterMode.Bilinear,
				(useHDR) ? RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default);
			CameraStickWater stickWater = settings.StickWater;
			buffer.SetGlobalVector(stickWaterDataId,
				new Vector4(stickWater.rainAmount, stickWater.fixedDroplet,
				stickWater.dropletSize, stickWater.speed));
			Draw(sourceId, bulkLightTempTexId, Pass.CameraStickWater);
			Draw(bulkLightTempTexId, sourceId, Pass.Copy);

			buffer.ReleaseTemporaryRT(bulkLightTempTexId);
        }

		void DepthOfField(int sourceId)
        {
			buffer.BeginSample("DepthOfField");
			DepthOfFieldSetting depthOfField = settings.DepthOfField;
			buffer.SetGlobalFloat("_BokehRadius", depthOfField.bokehRadius);
			buffer.SetGlobalFloat("_FocusDistance", depthOfField.focusDistance);
			buffer.SetGlobalFloat("_FocusRange", depthOfField.focusRange);
			buffer.GetTemporaryRT(bulkLightTempTexId, width, height, 0,
				FilterMode.Bilinear, RenderTextureFormat.RHalf);

			int widthT = width / 2;
			int heightT = height / 2;
			RenderTextureFormat format = (useHDR) ? RenderTextureFormat.DefaultHDR :
				RenderTextureFormat.Default;
			buffer.GetTemporaryRT(bulkLightTemp2TexId, widthT, heightT, 0,
				FilterMode.Bilinear, format);
			buffer.GetTemporaryRT(fxaaTempTexId, widthT, heightT, 0,
				FilterMode.Bilinear, format);

			buffer.GetTemporaryRT(finalTempTexId, width, height, 0,
				FilterMode.Bilinear, format);

			buffer.SetGlobalTexture(fxSource2Id, bulkLightTempTexId);
			buffer.SetGlobalTexture(fxSource3Id, bulkLightTemp2TexId);

			//Graphics.Blit(sourceId, fxSourceId, dofMaterial, circleOfConfusionPass);     //ȷ��Ҫ���Ƶķ�Χ
			Draw(sourceId, bulkLightTempTexId, Pass.CircleOfConfusion);
			Draw(sourceId, bulkLightTemp2TexId, Pass.PreFilter);
			Draw(bulkLightTemp2TexId, fxaaTempTexId, Pass.Bokeh);
			Draw(fxaaTempTexId, bulkLightTemp2TexId, Pass.PostFilter);

			Draw(sourceId, finalTempTexId, Pass.Combine);
			Draw(finalTempTexId, sourceId, Pass.Copy);

			buffer.ReleaseTemporaryRT(bulkLightTempTexId);
			buffer.ReleaseTemporaryRT(bulkLightTemp2TexId);
			buffer.ReleaseTemporaryRT(fxaaTempTexId);
			buffer.ReleaseTemporaryRT(finalTempTexId);
			buffer.EndSample("DepthOfField");
		}

		/// <summary>	/// ��ɫ����������ֵ	/// </summary>
		void ConfigureColorAdjustments()
		{
			ColorAdjustmentsSettings colorAdjustments = settings.ColorAdjustments;
			buffer.SetGlobalVector(colorAdjustmentsId, new Vector4(
				Mathf.Pow(2f, colorAdjustments.postExposure),
				colorAdjustments.contrast * 0.01f + 1f,
				colorAdjustments.hueShift * (1f / 360f),
				colorAdjustments.saturation * 0.01f + 1f
			));
			buffer.SetGlobalColor(colorFilterId, colorAdjustments.colorFilter.linear);
		}

		/// <summary>	/// ��ƽ��	/// </summary>
		void ConfigureWhiteBalance()
		{
			WhiteBalanceSettings whiteBalance = settings.WhiteBalance;
			buffer.SetGlobalVector(whiteBalanceId, ColorUtils.ColorBalanceToLMSCoeffs(
				whiteBalance.temperature, whiteBalance.tint
			));
		}

		/// <summary>	/// ɫ������	/// </summary>
		void ConfigureSplitToning()
		{
			SplitToningSettings splitToning = settings.SplitToning;
			Color splitColor = splitToning.shadows;
			splitColor.a = splitToning.balance * 0.01f;
			buffer.SetGlobalColor(splitToningShadowsId, splitColor);
			buffer.SetGlobalColor(splitToningHighlightsId, splitToning.highlights);
		}


		/// <summary>        /// �����������        /// </summary>
		/// <param name="from">��������</param>
		/// <param name="to">Ŀ������</param>
		/// <param name="isDepth">�Ƿ�Ϊ���</param>
		void Draw(
			RenderTargetIdentifier from, RenderTargetIdentifier to, Pass mode
		)
		{
			buffer.SetGlobalTexture(fxSourceId, from);
			buffer.Blit(null, to, settings.Material, (int)mode);
		}

		/// <summary>	/// ��������������Ⱦ���������ʵ�ʿ�����������	/// </summary>
		/// <param name="from">���ݵ�����</param>
		void DrawFinal(RenderTargetIdentifier from)
		{
			buffer.SetGlobalTexture(fxSourceId, from);
			buffer.Blit(null, BuiltinRenderTextureType.CameraTarget,
				settings.Material, (int)Pass.Final);
		}

		void ExecuteBuffer()
        {
			context.ExecuteCommandBuffer(buffer);
			buffer.Clear();
		}
	}
}