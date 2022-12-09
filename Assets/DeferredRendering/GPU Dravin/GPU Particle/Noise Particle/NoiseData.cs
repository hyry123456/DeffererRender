using UnityEngine;

namespace DefferedRender
{
    [System.Serializable]
    public struct NoiseParticleData
    {
        public Vector4 random;          //xyz是随机数，w是目前存活时间
        public Vector2Int index;             //状态标记，x是当前编号，y是是否存活
        public Vector3 worldPos;        //当前位置
        public Vector4 uvTransData;     //uv动画需要的数据
        public float interpolation;    //插值需要的数据
        public Vector4 color;           //颜色值，包含透明度
        public float size;             //粒子大小
        public Vector3 nowSpeed;        //xyz是当前速度，w是存活时间
    };


    public struct ParticleInitializeData
    {
        public Vector3 beginPos;        //该组粒子运行初始位置
        public Vector3 velocityBeg;     //初始速度范围
        public Vector3 velocityEnd;     //初始速度范围
        public Vector3Int InitEnum;     //初始化的根据编号
        public Vector2 sphereData;      //初始化球坐标需要的数据
        public Vector3 cubeRange;       //初始化矩形坐标的范围
        public Matrix4x4 transfer_M;    //初始化矩形坐标的范围
        public Vector2 lifeTimeRange;   //生存周期的范围

        public Vector3 noiseData;       //噪声调整速度时需要的数据

        public Vector3Int outEnum;      //确定输出时算法的枚举
        public Vector2 smoothRange;       //粒子的大小范围

        public uint arriveIndex;
    };

    public enum SizeBySpeedMode
    {
        TIME = 0,
        X = 1,
        Y = 2,
        Z = 3,
    }

    public enum InitialShapeMode
    {
        Pos = 0,
        Sphere = 1,
        Cube = 2
    }


    /// <summary>   /// 用来控制单组噪声粒子的数据结构体    /// </summary>
    [System.Serializable]
    public class NoiseData
    {
        //该节点所在位置
        public Transform position;
        public NoisePerNodeData perNodeData;
    }


    #region 粒子工厂需要的数据


    [System.Serializable]
    /// <summary>    /// 粒子的根据数据    /// </summary>
    public struct ParticleNodeData
    {
        public Vector3 beginPos;        //该组粒子运行初始位置
        public Vector3 endPos;          //方形物体需要用到的结束位置
        public Vector3 beginSpeed;      //初始速度
        public Vector3Int initEnum;     //x:初始化的形状,y:是否使用重力，z:图片编号
        public Vector2 sphereData;      //初始化球坐标需要的数据, x=角度, y=半径
        public Vector3 cubeRange;       //初始化矩形坐标的范围
        public Vector3 lifeTimeRange;   //生存周期的范围,x:随机释放时间,Y:存活时间,Z:最大生存到的时间
        public Vector3 noiseData;       //噪声调整速度时需要的数据
        public Vector3Int outEnum;      //确定输出时算法的枚举,x:followSpeed?
        public Vector2 smoothRange;     //粒子的大小范围
        public Vector2Int uvCount;        //x:row，y:column,
        public Vector2Int drawData;     //x:颜色条编号,y是大小的编号
    };

    /// <summary>    /// 当个图片中的图集数量    /// </summary>
    [System.Serializable]
    public struct TextureUVCount
    {
        public int rowCount;
        public int columnCount;
    }

    /// <summary>    /// 速度模式，控制初始化速度的方式    /// </summary>
    public enum SpeedMode
    {
        /// <summary>        /// 传入速度就是初始化的速度        /// </summary>
        JustBeginSpeed = 0,
        /// <summary>   /// 垂直于速度，此时传入的速度表示法线，
        /// 长度表示速度大小，且方向是垂直法线向外   /// </summary>
        VerticalVelocityOutside = 1,
        /// <summary>   /// 垂直于速度，此时传入的速度表示法线，
        /// 长度表示速度大小，且方向是垂直法线向内  /// </summary>
        VerticalVelocityInside = 2,
        /// <summary>   /// 根据当前位置向中心偏移，速度长度为速度大小   /// </summary>
        PositionInside = 3,
        /// <summary>   /// 根据当前位置向外偏移，速度长度为速度大小   /// </summary>
        PositionOutside = 4,
    }

    /// <summary>
    /// 渲染粒子时的根据数据，设置一个结构体方便确定形参类型，不然数据太多了,不好检查
    /// </summary>
    public struct ParticleDrawData
    {
        /// <summary>        /// 初始位置，会在该位置及其周围生成粒子        /// </summary>
        public Vector3 beginPos;
        /// <summary>       
        /// 方形粒子需要赋值的方形终止位置，在球型物体时为欧拉角
        /// </summary>
        public Vector3 endPos;
        /// <summary>        /// 初始速度，用来进行默认速度初始化        /// </summary>
        public Vector3 beginSpeed;
        /// <summary>        /// 速度模式，控制粒子释放的模式        /// </summary>
        public SpeedMode speedMode;
        /// <summary>        /// 是否对粒子使用重力        /// </summary>
        public bool useGravity;
        /// <summary>        /// 粒子渲染是否要跟随速度，而不是朝向摄像机        /// </summary>
        public bool followSpeed;
        /// <summary>        /// radius是半径，radian是弧度(0-6.28)，用来控制这个球渲染的范围        /// </summary>
        public float radius, radian;
        /// <summary>        
        /// 矩形生成粒子时确定这个矩形的大小，分别表示xyz的偏移值，
        /// 其中的X轴被我定义为球型时的旋转模式，如果需要让球为水平生成，就赋值为1
        /// </summary>
        public Vector3 cubeOffset;
        /// <summary>        /// 这个粒子的最长生存周期        /// </summary>
        public float lifeTime;
        /// <summary>        /// 单个粒子的显示时间，注意，显示时间请不要超过生存时间        /// </summary>
        public float showTime;
        /// <summary>        /// 噪声采样的频率        /// </summary>
        public float frequency;
        /// <summary>        /// 噪声采样的循环次数，次数越多越混乱，更有噪声的感觉，不要超过8次        /// </summary>
        public int octave;
        /// <summary>        /// 噪声的强度，越强粒子移动变化越快        /// </summary>
        public float intensity;
        /// <summary>        /// 粒子的大小范围，size曲线的结果会映射到该数据中        /// </summary>
        public Vector2 sizeRange;
        /// <summary>        /// 颜色编号，用来确定粒子的颜色以及透明度        /// </summary>
        public ColorIndexMode colorIndex;
        /// <summary>        /// 选择的大小曲线编号        /// </summary>
        public SizeCurveMode sizeIndex;
        /// <summary>        /// 选择的图片编号        /// </summary>
        public int textureIndex;
        /// <summary>        /// 粒子组数量，也就是要生成的粒子数量，一组有64个粒子        /// </summary>
        public int groupCount;
    }

    /// <summary>    /// 颜色条目的可选模式    /// </summary>
    public enum ColorIndexMode
    {
        /// <summary>   /// 全白，且透明到透明，中间一部分为白色    /// </summary>
        AlphaToAlpha = 0,
        /// <summary>        /// 透明到透明，中间是明亮的黄光        /// </summary>
        HighlightAlphaToAlpha = 1,
        /// <summary>        /// 强光，前面不透明，后面透明        /// </summary>
        HighlightToAlpha = 2,
        /// <summary>        /// 强光，从黄高光到蓝高光        /// </summary>
        HighlightRedToBlue = 3,
    }

    public enum SizeCurveMode
    {
        /// <summary>        /// 从小到大，且上凸        /// </summary>
        SmallToBig_Epirelief = 0,
        /// <summary>        /// 从小到大再到小，类似正态分布曲线        /// </summary>
        Small_Hight_Small = 1,
        /// <summary>        /// 从小到大，下凸        /// </summary>
        SmallToBig_Subken = 2,
    }

    #endregion
}