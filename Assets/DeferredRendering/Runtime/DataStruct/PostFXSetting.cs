using System;
using UnityEngine;

namespace DefferedRender
{
    [CreateAssetMenu(menuName = "Rendering/Post FX Settings")]
    public class PostFXSetting : ScriptableObject
	{
		[SerializeField]
		Shader postFXShader = default;
        public enum LUTSize { 
			_16x = 16, _32x = 32, _64x = 64
		}

		[SerializeField]
		LUTSize colorLUTResolution = LUTSize._32x;

		public LUTSize LUTResolution => colorLUTResolution;

		[Serializable]
		public struct SSR
		{
			public bool useSSR;
			public int rayMarchingSetp;
            [Range(0, 1)]
			public float marchSetpSize;
			public float maxMarchDistance;
			public float depthThickness;
            [Range(0, 1)]
			public float bilaterFilterFactor;
			[Range(0, 5)]
			public float blurRadius;
		}

			[SerializeField]
		SSR ssrSetting = new SSR
		{
			rayMarchingSetp = 36,
			marchSetpSize = 0.5f,
			maxMarchDistance = 500,
			depthThickness = 1,
			bilaterFilterFactor = 0.6f,
			blurRadius = 2,
		};
		public SSR ssr => ssrSetting;

		/// <summary>	/// 体积光计算，这个是真的奢侈	/// </summary>
		[Serializable]
		public struct BulkLight
		{
			public bool useBulkLight;
			[Range(0, 1000f)]
			public float shrinkRadio;
			[Range(10, 100)]
			public int circleCount;
			[Range(0, 1)]
			public float scatterRadio;
			public float checkDistance;

			//[Range(0, 0.5f)]
			//public float bilaterFilterStrength;
			//public float biurRadius;
		}

		[SerializeField]
		BulkLight bulkLight = new BulkLight
		{
			useBulkLight = false,
			shrinkRadio = 0.00005f,
			checkDistance = 100,
			circleCount = 64,
			//bilaterFilterStrength = 0.25f,
			//biurRadius = 5
		};
		public BulkLight BulkLighting => bulkLight;


		/// <summary>	/// Bloom参数设置	/// </summary>
		[System.Serializable]
		public struct BloomSettings
		{

			/// <summary>		/// 渐变等级		/// </summary>
			[Range(0f, 16f)]
			public int maxIterations;

			/// <summary>		/// Bloom进行到最小的像素，像素量小于该值就不进行下一步		/// </summary>
			[Min(1f)]
			public int downscaleLimit;

			/// <summary>		/// 是否使用三线性插值		/// </summary>
			public bool bicubicUpsampling;

			/// <summary>		/// Bloom的分割线		/// </summary>
			[Min(0f)]
			public float threshold;

			/// <summary>		/// 分割线下降的剧烈程度，不是直接截断		/// </summary>
			[Range(0f, 1f)]
			public float thresholdKnee;

			/// <summary>		/// Bloom叠加在主纹理的强度		/// </summary>
			[Min(0f)]
			public float intensity;

			/// <summary>		/// 是否使用范围颜色限制，即进行颜色限制时采样了周围的颜色		/// </summary>
			public bool fadeFireflies;

			/// <summary>		/// Bloom的混合模式，是添加还是lerp混合		/// </summary>
			public enum Mode { Additive, Scattering }

			public Mode mode;

			/// <summary>		/// lerp混合的比例		/// </summary>
			[Range(0.05f, 0.95f)]
			public float scatter;
		}

		[SerializeField]
		BloomSettings bloom = new BloomSettings
		{
			scatter = 0.7f,
			maxIterations = 1,
			downscaleLimit = 30,
			threshold = 1,
			thresholdKnee = 0.2f,
			intensity = 0.5f,
		};

		public BloomSettings Bloom => bloom;

		/// <summary>	/// HDR映射方式	/// </summary>
		[Serializable]
        public struct ToneMappingSettings
        {

            public enum Mode { None, ACES, Neutral, Reinhard }

            public Mode mode;
        }

        [SerializeField]
        ToneMappingSettings toneMapping = default;

		public ToneMappingSettings ToneMapping => toneMapping;


		/// <summary>	/// 颜色值调整	/// </summary>
		[Serializable]
		public struct ColorAdjustmentsSettings
		{

			/// <summary>		/// 曝光度		/// </summary>
			public float postExposure;

			/// <summary>		/// 对比度		/// </summary>
			[Range(-100f, 100f)]
			public float contrast;
			/// <summary>		/// 颜色过滤		/// </summary>
			[ColorUsage(false, true)]
			public Color colorFilter;

			/// <summary>		/// 色相转移		/// </summary>
			[Range(-180f, 180f)]
			public float hueShift;

			/// <summary>		/// 饱和度		/// </summary>
			[Range(-100f, 100f)]
			public float saturation;
		}

		[SerializeField]
		ColorAdjustmentsSettings colorAdjustments = new ColorAdjustmentsSettings
		{
			colorFilter = Color.white
		};

		public ColorAdjustmentsSettings ColorAdjustments => colorAdjustments;

		public void SetColorFilter(Color filter)
        {
			colorAdjustments.colorFilter = filter;
		}

		/// <summary>	/// 白平衡阐述控制	/// </summary>
		[Serializable]
		public struct WhiteBalanceSettings
		{

			/// <summary>		/// 色温以及色温强度		/// </summary>
			[Range(-100f, 100f)]
			public float temperature, tint;
		}

		[SerializeField]
		WhiteBalanceSettings whiteBalance = default;

		public WhiteBalanceSettings WhiteBalance => whiteBalance;

		/// <summary>	/// 色调分离	/// </summary>
		[Serializable]
		public struct SplitToningSettings
		{

			/// <summary>		/// 阴影颜色和高亮颜色		/// </summary>
			[ColorUsage(false)]
			public Color shadows, highlights;

			/// <summary>		/// 平衡度		/// </summary>
			[Range(-100f, 100f)]
			public float balance;
		}

		[SerializeField]
		SplitToningSettings splitToning = new SplitToningSettings
		{
			shadows = Color.gray,
			highlights = Color.gray
		};

		public SplitToningSettings SplitToning => splitToning;





		/// <summary>		/// 三种抗锯齿模式		/// </summary>
		public enum LuminanceMode { None, Green, Calculate }
		/// <summary>		/// 抗锯齿设置		/// </summary>
		[Serializable]
		public struct FXAASetting
        {
			public LuminanceMode luminanceMode;

			/// <summary>	/// 对比度阈值	/// </summary>
			[Range(0.0312f, 0.0833f)]
			public float contrastThreshold;
			[Range(0.063f, 0.333f)]
			public float relativeThreshold;		//对比度高度阈值，舍去高的部分
			[Range(0f, 1f)]
			public float subpixelBlending;      //模糊程度控制，调整细节显示比例
			/// <summary>			/// 高低质量控制			/// </summary>
			public bool lowQuality;

		}

		[SerializeField]
		FXAASetting fXAA = new FXAASetting
		{
			contrastThreshold = 0.0312f,
			relativeThreshold = 0.063f,
			subpixelBlending = 1f
		};
		public FXAASetting FXAA => fXAA;

		[Serializable]
		public struct CameraStickWater
        {
            [Range(0, 1)]
			public float rainAmount;        //水珠数量
            [Range(0, 1)]
			public float fixedDroplet;      //水珠拉伸程度
            [Range(0, 0.5f)]
			public float dropletSize;       //水珠大小
            [Range(0, 0.5f)]
			public float speed;             //移动速度
			public bool useStickWater;		//是否启用
        }

		[SerializeField]
		private CameraStickWater stickWater = new CameraStickWater
		{
			rainAmount = 0.5f,
			fixedDroplet = 0.5f,
			dropletSize = 0.2f,
			speed = 0.5f,
			useStickWater = false,
		};
		/// <summary>/// 屏幕粘水效果/// </summary>
		public CameraStickWater StickWater => stickWater;

		[Serializable]
		public struct DepthOfFieldSetting
		{
			[Range(0.1f, 100f)]
			public float focusDistance;
			[Range(0.1f, 100f)]
			public float focusRange;
			[Range(2f, 10f)]
			public float bokehRadius;
			public bool useDepthOfField;
		}

		[SerializeField]
		private DepthOfFieldSetting depthOfField = new DepthOfFieldSetting()
		{
			focusDistance = 10f,
			focusRange = 3f,
			bokehRadius = 4f,
			useDepthOfField = false,
		};

		public DepthOfFieldSetting DepthOfField => depthOfField;


		Material material;

		public Material Material
		{
			get
			{
				if (material == null && postFXShader != null)
				{
					material = new Material(postFXShader);
					material.hideFlags = HideFlags.HideAndDontSave;
				}
				return material;
			}
		}
	}
}