using UnityEngine;

namespace DefferedRender
{

    [CreateAssetMenu(menuName = "GPUDravin/Particle Group Data")]
    public class NoiseGroupNodeData : ScriptableObject
    {
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

        //更新
        [Range(1, 8)]
        public int octave = 1;
        public float frequency = 1;
        [Min(0.1f)]
        public float groupIntensity = 0.5f;
        [Min(0.1f)]
        public float particleIntensity = 0.5f;
        [Range(0, 1f)]
        public float collsionScale = 1;

        [GradientUsage(true)]
        public Gradient particleGradient;
        [GradientUsage(true)]
        public Gradient groupGradient;
        public AnimationCurve particleSize = AnimationCurve.Linear(0, 0, 1, 1);
        public AnimationCurve groupSize = AnimationCurve.Linear(0, 0, 1, 1);

        private Vector4[] particleColors;
        private Vector4[] groupColors;
        private Vector4[] particleAlphas;
        private Vector4[] groupAlphas;
        private Vector4[] groupSizes;
        private Vector4[] particleSizes;

        public Vector4[] GetParticleColors()
        {
            if (particleColors == null)
            {
                particleColors = new Vector4[6];
                GradientColorKey[] colorKeys = particleGradient.colorKeys;
                int i = 0;
                for (; i < colorKeys.Length; i++)
                {
                    particleColors[i] = colorKeys[i].color;
                    particleColors[i].w = colorKeys[i].time;
                }
                for (; i < 6; i++)
                    particleColors[i] = Vector4.one;
            }
            return particleColors;
        }
        public Vector4[] GetGroupColors()
        {
            if (groupColors == null)
            {
                groupColors = new Vector4[6];
                GradientColorKey[] colorKeys = groupGradient.colorKeys;
                int i = 0;
                for (; i < colorKeys.Length; i++)
                {
                    groupColors[i] = colorKeys[i].color;
                    groupColors[i].w = colorKeys[i].time;
                }
                for (; i < 6; i++)
                    groupColors[i] = Vector4.one;
            }
            return groupColors;
        }
        public Vector4[] GetParticleAlphas()
        {
            if (particleAlphas == null)
            {
                particleAlphas = new Vector4[6];
                GradientAlphaKey[] alphaKeys = particleGradient.alphaKeys;
                int i = 0;
                for (; i < alphaKeys.Length; i++)
                    particleAlphas[i] = new Vector4(alphaKeys[i].alpha, alphaKeys[i].time);
                for (; i < 6; i++)
                    particleAlphas[i] = Vector4.one;
            }
            return particleAlphas;
        }
        public Vector4[] GetGroupAlphas()
        {
            if (groupAlphas == null)
            {
                groupAlphas = new Vector4[6];
                GradientAlphaKey[] alphaKeys = groupGradient.alphaKeys;
                int i = 0;
                for (; i < alphaKeys.Length; i++)
                    groupAlphas[i] = new Vector4(alphaKeys[i].alpha, alphaKeys[i].time);
                for (; i < 6; i++)
                    groupAlphas[i] = Vector4.one;
            }
            return groupAlphas;
        }
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
        public Vector4[] GetGroupSizes()
        {
            if (groupSizes == null)
            {
                groupSizes = new Vector4[6];
                int i = 0;
                for (; i < groupSize.length; i++)
                {
                    groupSizes[i] = new Vector4(groupSize.keys[i].time, groupSize.keys[i].value,
                        groupSize.keys[i].inTangent, groupSize.keys[i].outWeight);
                }
                for (; i < 6; i++)
                    groupSizes[i] = Vector4.one;
            }
            return groupSizes;
        }

        private void OnValidate()
        {
            groupColors = null;
            particleColors = null;
            groupAlphas = null;
            particleAlphas = null;
            particleSizes = null;
            groupSizes = null;
        }

        [Min(0.01f)]
        public float groupTime = 5;         //组的存在时间
        [Min(0.01f)]
        public float particleTime = 5;      //粒子的存在时间
        [Min(0.1f)]
        public float groupReleaseTime = 1;  //粒子组的释放间隔
    }
}