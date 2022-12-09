using UnityEngine;

namespace DefferedRender
{

    [CreateAssetMenu(menuName = "GPUDravin/Fuild Draw"), SerializeField]
    public class WaterSetting : ScriptableObject
    {
        [Min(0.01f)]
        public float releaseTime = 1f;
        [Min(0.01f)]
        public float sustainTime = 5;

        //组的位置初始化模式
        public InitialShapeMode groupShapeMode = InitialShapeMode.Pos;
        //单个粒子的位置初始化模式
        public InitialShapeMode particleShadpeMode = InitialShapeMode.Pos;
        //组的速度初始化模式
        public SpeedMode groupSpeedMode = SpeedMode.JustBeginSpeed;
        //单个粒子的速度初始化模式
        public SpeedMode particleSpeedMode = SpeedMode.JustBeginSpeed;
        //粒子大小模式
        public SizeBySpeedMode sizeBySpeedMode = SizeBySpeedMode.TIME;
        //速度映射范围
        public Vector2 speedRange = Vector2.up;
        //大小范围
        public Vector2 sizeRange = Vector2.up;

        public bool groupUseGravity, particleUseGravity;

        [Range(0.01f, 6.28f)]
        public float groupArc = 0.1f;              //粒子组的角度范围
        [Range(0.01f, 6.28f)]
        public float particleArc = 0.1f;            //单个粒子的初始环绕角度
        [Min(0.0001f)]
        public float groupRadius = 1;               //组的圆大小
        [Min(0.0001f)]
        public float particleRadius = 1;            //粒子环绕的圆大小
        public Vector3 groupCubeRange = Vector3.one;          //组矩形大小
        public Vector3 particleCubeRange = Vector3.one;     //环绕矩形大小
        public Vector3 groupVelocityBegin = Vector3.up;      //粒子组的初始速度
        [Min(0.01f)]
        public float particleVelocityBegin = 1;         //粒子释放时的速度缩放

        [Range(1, 8)]
        public int octave = 1;
        public float frequency = 1;
        [Min(0.1f)]
        public float particleIntensity = 0.5f;
        [Range(0, 1f)]
        public float collsionScale = 1;
        [Range(0, 0.3f)]
        public float obstruction = 0.05f;

        [Range(1, 10)]
        public int circleBlur = 1;
        [Range(0f, 0.2f)]
        public float cullOff = 0f;
        [Range(0, 1)]
        public float bilaterFilterFactor = 0;
        [Range(0, 5)]
        public float blurRadius = 0.4f;
        [ColorUsage(true, true)]
        public Color waterCol = Color.blue;
        [Min(0.01f)]
        public float maxFluidWidth = 3;
        [Range(0, 1f)]
        public float metallic = 0.1f;
        [Range(0, 1f)]
        public float roughness = 0.1f;
        [Range(0, 1.0f)]
        public float distorion = 0.5f;
        [Min(0.01f)]
        public float power = 3;
        [Min(0)]
        public float scale = 1;

        public AnimationCurve particleSize = AnimationCurve.Linear(0, 0, 1, 1);
        private Vector4[] particleSizes;

        public Vector4[] GetParticleSizes()
        {
            if (particleSizes == null)
            {
                particleSizes = new Vector4[6];
                int i = 0;
                for (; i < particleSize.length; i++)
                {
                    particleSizes[i] = new Vector4(particleSize.keys[i].time,
                        particleSize.keys[i].value, particleSize.keys[i].inTangent,
                        particleSize.keys[i].outWeight);
                }
                for (; i < 6; i++)
                    particleSizes[i] = Vector4.one;
            }
            return particleSizes;
        }


        private void OnValidate()
        {
            particleSizes = null;
        }

    }
}