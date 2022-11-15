using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    [System.Serializable]
    public struct RenderSetting
    {
        public bool allowHDR;
        public bool 
            useDynamicBatching,      //动态批处理
            useGPUInstancing,        //GPU实例化
            useSRPBatcher;          //SRP批处理
        public bool maskLight;      //是否遮罩灯光
        [Range(0.25f, 1f)]
        public float renderScale;          //渲染缩放

        [RenderingLayerMaskField]
        public int renderingLayerMask;

        public Shader cameraShader;

        public FogSetting fogSetting;
    }

    [System.Serializable]
    public struct FogSetting
    {
        //public Texture fogTex;
        public bool useFog;
        public float fogMaxHeight;
        public float fogMinHeight;

        [Range(0, 1)]
        public float fogMaxDepth;
        [Range(0, 1)]
        public float fogMinDepth;

        [Range(0.001f, 3)]
        public float fogDepthFallOff;
        [Range(0.001f, 3)]
        public float fogPosYFallOff;

        public Color fogColor;     //颜色，只计算灯光颜色
    }

    [System.Serializable]
    public struct LightSetting
    {
        public ClusterLightSetting clusterLightSetting;
        [Range(0, 1.0f)]
        public float lightWrap;
    }


    /// <summary>
    /// Deffer Render Data Asset, Defind and input require data
    /// </summary>
    [CreateAssetMenu(menuName = "Rendering/Deffer Render Pipeline")]
    public class DefferedRenderAsset : RenderPipelineAsset
    {
        [SerializeField]
        RenderSetting renderSetting = new RenderSetting
        {
            allowHDR = false,
            useDynamicBatching = true,
            useGPUInstancing = true,
            useSRPBatcher = true,
            renderingLayerMask = -1,

            renderScale = 1f,
            fogSetting = new FogSetting
            {
                useFog = false,
                fogMaxHeight = 100,
                fogMinHeight = 0,
                fogMaxDepth = 1,
                fogMinDepth = 0.2f,
                fogDepthFallOff = 1,
                fogPosYFallOff = 1,
            },
        };

        [SerializeField]
        LightSetting lightingSettings = new LightSetting
        {
            clusterLightSetting = new ClusterLightSetting
            {
                clusterCount = new Vector3Int(16, 16, 36),
                isUse = false,
            },
            lightWrap = 0,
        };

        /// <summary>	/// 阴影设置参数	/// </summary>
        [SerializeField]
        ShadowSetting shadows = default;

        [SerializeField]
        PostFXSetting postFXSetting = null;


        protected override RenderPipeline CreatePipeline()
        {
            return new DefferRenderPipeline(
                renderSetting, shadows, postFXSetting, lightingSettings
            );
        }
    }
}