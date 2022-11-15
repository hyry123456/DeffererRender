using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    enum CameraRenderMode
    {
        _CopyBilt = 0,
        _CopyDepth = 1,
    }

    public partial class DefferRender
    {
        const string bufferName = "Render Camera";

        static ShaderTagId
            litShaderTagId = new ShaderTagId("FowardShader"),       //透明物体，使用前向渲染
            gBufferShaderTagId = new ShaderTagId("OutGBuffer");     //输出GBuffer

        //存储GBuffer的一般贴图的数组
        static int[] gBufferIds = 
        {
            Shader.PropertyToID("_GBufferColorTex"),    //颜色纹理
            Shader.PropertyToID("_GBufferNormalTex"),   //法线纹理
            Shader.PropertyToID("_GBufferSpecularTex"), //高光纹理
        };

        //存储GBuffer中HDR贴图的数组
        static int[] gBufferHDRIds =
        {
            Shader.PropertyToID("_GBufferBakeTex"),     //烘焙、自发光纹理
            Shader.PropertyToID("_ReflectTargetTex"),   //GBuffer的反射贴图
        };

        /// <summary>        /// 上一帧的最终纹理，用来给SSS采样        /// </summary>
        RenderTexture preFrameFinalTex;


        //存储一般的id
        static int
            gBufferDepthId = Shader.PropertyToID("_GBufferDepthTex"),       //Gbuffer的深度图
            cameraDepthTexId = Shader.PropertyToID("_CameraDepthTexture"), //渲染粒子时需要的深度图

            //雾效数据
            fogMaxHight = Shader.PropertyToID("_FogMaxHight"),
            fogMinHight = Shader.PropertyToID("_FogMinHight"),
            fogMaxDepth = Shader.PropertyToID("_FogMaxDepth"),
            fogMinDepth = Shader.PropertyToID("_FogMinDepth"),
            fogDepthFallOff = Shader.PropertyToID("_FogDepthFallOff"),
            fogPosYFallOff = Shader.PropertyToID("_FogPosYFallOff"),
            fogColor = Shader.PropertyToID("_FogColor"),

            lightWrapId = Shader.PropertyToID("_LightWrap"),

            bufferSizeId = Shader.PropertyToID("_CameraBufferSize"),
            colorAttachmentId = Shader.PropertyToID("_CameraColorAttachment"),
            frustumCornersRayId = Shader.PropertyToID("_FrustumCornersRay"),
            inverseVPMatrixId = Shader.PropertyToID("_InverseVPMatrix"),
            sourceTextureId = Shader.PropertyToID("_SourceTexture"),
            inverseProjectionMatrix = Shader.PropertyToID("_InverseProjectionMatrix"),
            viewToScreenMatrixId = Shader.PropertyToID("_ViewToScreenMatrix"),
            cameraProjectMatrixId = Shader.PropertyToID("_CameraProjectionMatrix"),
            worldToCameraMatrixId = Shader.PropertyToID("_WorldToCamera"),
            screenSizeId = Shader.PropertyToID("_ScreenSize");


        CommandBuffer buffer = new CommandBuffer
        {
            name = bufferName
        };

        Camera camera;
        ScriptableRenderContext context;
        CullingResults cullingResults;
        /// <summary>        /// 灯光处理类        /// </summary>
        Lighting lighting = new Lighting();
        PostFXSetting defaultPostSetting = default;

        bool useHDR;
        RenderSetting renderSetting;
        LightSetting lightSetting;
        /// <summary>        /// 渲染时进行后处理用的材质        /// </summary>
        Material material;

        //int sssPyramidId;
        PostFXStack postFXStack = new PostFXStack();
        //最终存储所有GBuffer的数组
        RenderTargetIdentifier[] gBuffers;
        int width, height;
        public DefferRender(Shader shader)
        {
            //创建一个材质用来渲染buffer
            material = CoreUtils.CreateEngineMaterial(shader);
        }

        public void Render(RenderSetting render,
            ScriptableRenderContext context, Camera camera, 
            ShadowSetting shadowSetting, PostFXSetting postFXSetting,
            LightSetting lightSetting)
        {
            this.camera = camera;
            this.context = context;
            renderSetting = render;
            this.lightSetting = lightSetting;

            PrepareBuffer();
            PrepareForSceneWindow();        //准备UI数据

            PostFXSetting thisCameraSetting = camera.GetComponent<DefferPipelineCamera>()?.Settings;
            if (thisCameraSetting != null)
                postFXSetting = thisCameraSetting;
            if (postFXSetting == null)
                postFXSetting = defaultPostSetting;


            //准备剔除数据
            if (!Cull(shadowSetting.maxDistance))
            {   //摄像机剔除准备
                return;     //准备失败就退出
            }

            useHDR = render.allowHDR && camera.allowHDR;

            buffer.BeginSample(SampleName);
            ExecuteBuffer();

            //之后加后处理、灯光等数据准备
            //准备灯光数据，在灯光数据中会进行阴影数据准备
            lighting.Setup(
                context, renderSetting.maskLight ? renderSetting.renderingLayerMask : -1,
                cullingResults, shadowSetting, camera, lightSetting.clusterLightSetting
            );

            //本摄像机渲染准备
            Setup();

            postFXStack.Setup(context, camera, postFXSetting, useHDR, cullingResults,
                gBufferDepthId, width, height);

            buffer.EndSample(SampleName);


            //渲染Gbuffer数据，准备深度图
            DrawGBuffer();
            if(camera.cameraType == CameraType.Game)
                lighting.ReadyClusterLight(camera, lightSetting.clusterLightSetting, gBufferDepthId);

            //渲染GBuffer最终颜色以及透明队列以及天空盒
            DrawGBufferLater();
            DrawUnsupportedShaders();   //绘制不支持的纹理

            DrawGizmosBeforeFX();       //在后处理前准备一下Gizmos需要的数据

            if (postFXStack.IsActive)
            {
                //保存颜色贴图
                SavePreFrameTex();
                postFXStack.Render(colorAttachmentId);
            }
            else
            {
                DrawFinal();
            }


            DrawGizmosAfterFX();    //绘制最终的Gizmos效果

            Cleanup();              //清除数据
            Submit();
        }

        /// <summary>	/// 执行摄像机数据进行阴影剔除，将不需要的部分进行剔除	/// </summary>
        /// <param name="maxShadowDistance">剔除距离</param>
        /// <returns>是否成功剔除</returns>
        bool Cull(float maxShadowDistance)
        {
            GPUDravinDrawStack.Instance.SetUp(context, buffer, camera);
            //执行剔除，有可能剔除失败，因为要进行区分
            if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
            {
                //控制阴影距离
                p.shadowDistance = Mathf.Min(maxShadowDistance, camera.farClipPlane);
                //赋值裁剪结果
                cullingResults = context.Cull(ref p);
                return true;
            }
            return false;
        }

        /// <summary>	/// 封装一个Buffer写入函数，方便调用	/// </summary>
        void ExecuteBuffer()
        {
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        /// <summary>	/// 渲染开始的准备方法  	/// </summary>
        void Setup()
        {
            //准备摄像机数据，剔除之类的
            context.SetupCameraProperties(camera);
            width = (int)(camera.pixelWidth * renderSetting.renderScale);
            height = (int)(camera.pixelHeight * renderSetting.renderScale);
            buffer.SetGlobalVector(bufferSizeId, new Vector4(
                1f / width, 1f / height, width, height));

            //GBuffer后处理到的目标纹理
            buffer.GetTemporaryRT(
                colorAttachmentId, width, height,0, FilterMode.Bilinear, useHDR ?
                    RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default
            );

            //获取深度图
            buffer.GetTemporaryRT(
                gBufferDepthId, width, height,
                32, FilterMode.Point, RenderTextureFormat.Depth
            );
            //存储全部的Gbuffer数组
            gBuffers = new RenderTargetIdentifier[gBufferIds.Length + gBufferHDRIds.Length];

            //准备的一般的GBuffer，也就是不需要HDR存储的
            for (int i=0; i<gBufferIds.Length; i++)
            {
                buffer.GetTemporaryRT(
                    gBufferIds[i], width, height,
                    0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR
                );
                gBuffers[i] = gBufferIds[i];
            }
            //准备需要HDR存储的GBuffer数据
            for (int i=0; i<gBufferHDRIds.Length; i++)
            {
                buffer.GetTemporaryRT(
                    gBufferHDRIds[i], width, height,
                    0, FilterMode.Bilinear, useHDR ?
                    RenderTextureFormat.DefaultHDR : RenderTextureFormat.Default
                );
                gBuffers[gBufferIds.Length + i] = gBufferHDRIds[i];
            }

            //清除上一帧的数据
            buffer.ClearRenderTarget(true, true, Color.clear);

            //设置渲染目标，传递所有的渲染目标
            buffer.SetRenderTarget(
                gBuffers,
                gBufferDepthId
            );

            buffer.BeginSample(SampleName);

            //清除上一帧的数据
            buffer.ClearRenderTarget(true, true, Color.clear);

            Matrix4x4 frustum = GetFrustumMatrix();
            buffer.SetGlobalMatrix(frustumCornersRayId, frustum);

            Matrix4x4 matrix4X4 = camera.projectionMatrix * camera.worldToCameraMatrix;
            buffer.SetGlobalMatrix(inverseVPMatrixId, matrix4X4.inverse);
            buffer.SetGlobalMatrix(inverseProjectionMatrix, camera.projectionMatrix.inverse);

            Matrix4x4 clipToScreenMatrix = Matrix4x4.identity;
            clipToScreenMatrix.SetRow(0, new Vector4(width * 0.5f, 0, 0, width * 0.5f));
            clipToScreenMatrix.SetRow(1, new Vector4(0, height * 0.5f, 0, height * 0.5f));
            clipToScreenMatrix.SetRow(2, new Vector4(0, 0, 1.0f, 0));
            clipToScreenMatrix.SetRow(3, new Vector4(0, 0, 0, 1.0f));
            var viewToScreenMatrix = clipToScreenMatrix * camera.projectionMatrix;
            buffer.SetGlobalMatrix(viewToScreenMatrixId, viewToScreenMatrix);

            buffer.SetGlobalVector(screenSizeId, new Vector4(1.0f / width, 1.0f / height, width, height));
            buffer.SetGlobalMatrix(cameraProjectMatrixId, camera.projectionMatrix);
            buffer.SetGlobalMatrix(worldToCameraMatrixId, camera.worldToCameraMatrix);

            FogSetting fog = renderSetting.fogSetting;
            //准备雾效数据
            if (fog.useFog)
            {
                buffer.EnableShaderKeyword("_DEFFER_FOG");
                buffer.SetGlobalFloat(fogMaxHight, fog.fogMaxHeight);
                buffer.SetGlobalFloat(fogMinHight, fog.fogMinHeight);
                buffer.SetGlobalFloat(fogMaxDepth, fog.fogMaxDepth);
                buffer.SetGlobalFloat(fogMinDepth, fog.fogMinDepth);
                buffer.SetGlobalFloat(fogDepthFallOff, fog.fogDepthFallOff);
                buffer.SetGlobalFloat(fogPosYFallOff, fog.fogPosYFallOff);
                buffer.SetGlobalColor(fogColor, fog.fogColor);
            }
            else
            {
                buffer.DisableShaderKeyword("_DEFFER_FOG");
            }

            buffer.SetGlobalFloat(lightWrapId, lightSetting.lightWrap);

            ExecuteBuffer();
        }

        SortingSettings sortingSettings;
        DrawingSettings drawingSettings;
        FilteringSettings filteringSettings;

        /// <summary>  /// 渲染GBuffer的数据   /// </summary>
        void DrawGBuffer()
        {
            //设置该摄像机的物体排序模式，目前是渲染普通物体，因此用一般排序方式
            sortingSettings = new SortingSettings(camera)
            {
                criteria = SortingCriteria.CommonOpaque
            };

            //第一次渲染只绘制GBuffer，且GBuffer仅渲染非透明
            drawingSettings = new DrawingSettings(
                gBufferShaderTagId, sortingSettings
            )
            {
                enableDynamicBatching = renderSetting.useDynamicBatching,
                enableInstancing = renderSetting.useGPUInstancing,
                perObjectData =
                PerObjectData.ReflectionProbes |
                PerObjectData.Lightmaps | PerObjectData.ShadowMask |
                PerObjectData.LightProbe | PerObjectData.OcclusionProbe |
                PerObjectData.LightProbeProxyVolume |
                PerObjectData.OcclusionProbeProxyVolume
            };
            filteringSettings = new FilteringSettings(
                RenderQueueRange.opaque, renderingLayerMask: (uint)renderSetting.renderingLayerMask
            );
            //进行渲染的执行方法
		    context.DrawRenderers(
			    cullingResults, ref drawingSettings, ref filteringSettings
		    );

            //渲染GPU驱动的标准PBR数据
            GPUDravinDrawStack.Instance.DrawPreSSS(context, buffer, camera);


            ExecuteBuffer();
        }

        /// <summary>
        /// 渲染GBuffer的最终的颜色数据，以及之后的数据，比如天空盒以及透明队列的物体，
        /// 分配到这里是为了中间插入灯光数据，用深度图进行裁剪
        /// </summary>
        void DrawGBufferLater()
        {
            //设置渲染目标，传递所有的渲染目标
            buffer.SetRenderTarget(
                gBuffers,
                gBufferDepthId
            );
            ExecuteBuffer();

            //绘制天空盒
            context.DrawSkybox(camera);
            FluidDrawStack.Instance.BeginDrawFluid(context, buffer,
                gBuffers, gBufferDepthId, width, height);

            //用上一帧的颜色值作为当前的颜色贴图
            buffer.SetGlobalTexture("PerFrameFinalTexture", preFrameFinalTex);


            DrawGBufferFinal();         //BRDF
            buffer.GetTemporaryRT(cameraDepthTexId, width, height,
                32, FilterMode.Point, RenderTextureFormat.Depth);
            Draw(gBufferDepthId, cameraDepthTexId, CameraRenderMode._CopyDepth);

            buffer.SetRenderTarget(
                colorAttachmentId, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store,
                gBufferDepthId, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store);

            sortingSettings.criteria = SortingCriteria.CommonTransparent;
            drawingSettings.sortingSettings = sortingSettings;
            filteringSettings.renderQueueRange = RenderQueueRange.transparent;
            drawingSettings.SetShaderPassName(0, litShaderTagId);

            ExecuteBuffer();

            context.DrawRenderers(
                cullingResults, ref drawingSettings, ref filteringSettings
            );
            //绘制ComputeShader实现的物体
            GPUDravinDrawStack.Instance.BeginDraw(context, buffer,
                ClustDrawType.Simple, camera);
            ExecuteBuffer();
        }

        /// <summary>        /// 确定GBuffer最后的颜色        /// </summary>
        void DrawGBufferFinal()
        {
            postFXStack.DrawSSS(preFrameFinalTex, gBufferHDRIds[1]);
            postFXStack.DrawGBufferFinal(colorAttachmentId);
            ExecuteBuffer();
        }

        /// <summary>        /// 进行纹理绘制        /// </summary>
        /// <param name="from">根据纹理</param>
        /// <param name="to">目标纹理</param>
        /// <param name="isDepth">是否为深度</param>
        void Draw(
            RenderTargetIdentifier from, RenderTargetIdentifier to, CameraRenderMode mode
        )
        {
            buffer.SetGlobalTexture(sourceTextureId, from);
            buffer.Blit(null, to, material, (int)mode);
        }

        void DrawFinal()
        {
            buffer.SetGlobalTexture(sourceTextureId, colorAttachmentId);

            buffer.Blit(null, BuiltinRenderTextureType.CameraTarget,
                material, (int)CameraRenderMode._CopyBilt);

            ExecuteBuffer();
        }

        void SavePreFrameTex()
        {
            if (camera.cameraType != CameraType.Game)
                return;

            //提前存储，不要后处理后再存储
            if (preFrameFinalTex != null)
                RenderTexture.ReleaseTemporary(preFrameFinalTex);
            preFrameFinalTex = RenderTexture.GetTemporary(width, height,
                0, RenderTextureFormat.Default);
            preFrameFinalTex.name = "PerFrameFinalTexture";
            Draw(colorAttachmentId, preFrameFinalTex, CameraRenderMode._CopyBilt);
            ExecuteBuffer();
        }

        /// <summary>	/// 清除使用过的数据，因为纹理图大多数都是在内存中的，因此需要我们手动释放	/// </summary>
        void Cleanup()
        {
            buffer.ReleaseTemporaryRT(colorAttachmentId);
            buffer.ReleaseTemporaryRT(gBufferDepthId);
            buffer.ReleaseTemporaryRT(cameraDepthTexId);
            //buffer.ReleaseTemporaryRT(reflectTargetTexId);
            //buffer.ReleaseTemporaryRT(tempRenderTexId);
            //buffer.ReleaseTemporaryRT(cameraColorTexId);
            //buffer.ReleaseTemporaryRT(cameraDepthTexId);
            //buffer.ReleaseTemporaryRT(cameraNormalTexId);
            for(int i=0; i<gBufferIds.Length; i++)
            {
                buffer.ReleaseTemporaryRT(gBufferIds[i]);
            }
            for(int i=0; i<gBufferHDRIds.Length; i++)
            {
                buffer.ReleaseTemporaryRT(gBufferHDRIds[i]);
            }

            lighting.Cleanup();		//灯光数据清除
        }

        /// <summary>        /// 提交方法，将所有命令上传        /// </summary>
        void Submit()
        {
            buffer.EndSample(SampleName);
            ExecuteBuffer();
            context.Submit();
        }

        Matrix4x4 GetFrustumMatrix()
        {
            Matrix4x4 frustumCorners = Matrix4x4.identity;
            Transform cameraTransform = camera.transform;
            float fov = camera.fieldOfView;
            float near = camera.nearClipPlane;
            //aspect = width / height
            float aspect = camera.aspect;

            //计算近平面的高度，fov*0.5*Mathf.Deg2Red获得了摄像机的一半角度值，使用tan求值就是高度了，具体画个图
            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
            //halfHeight * aspect获得width大小，乘以其方向获得去到右边缘的方向
            Vector3 toRight = cameraTransform.right * halfHeight * aspect;
            //同理，获得到达上面的方向
            Vector3 toTop = cameraTransform.up * halfHeight;

            //左上方
            Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
            //获得当near为1时，到达左上方的长度
            float scale = topLeft.magnitude / near;
            //标准化该方向
            topLeft.Normalize();
            //缩放大小，使其变为当near为1时的大小
            topLeft *= scale;

            //右上方
            Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;

            //左下方
            Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            //右下方
            Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;

            //以上确定了，当near为1时从原点到达四个方向的顶点的方向，且是包含长度的方向值
            //下面将这些数据传递给矩阵
            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            return frustumCorners;
        }


    }
}