using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{


    public class ParticleNoiseFactory : GPUDravinBase
    {
        /// <summary>        /// 粒子组的数量，粒子组一个Pass只渲染1800组        /// </summary>
        const int particleGroupCount = 7200;
        /// <summary>        /// 粒子组        /// </summary>
        ParticleNodeData[] particleNodes;
        /// <summary>        /// 粒子组存储位置，每一次更新都只会更新该数据        /// </summary
        ComputeBuffer groupsBuffer;
        /// <summary>        /// 所有粒子的存储位置，只会进行初始化，之后由GPU控制        /// </summary>
        ComputeBuffer particlesBuffer;
        [SerializeField]
        ComputeShader compute;
        //[SerializeField, GradientUsage(true)]
        //Gradient[] gradients = new Gradient[6];
        //颜色数组，默认6个，且是固定的
        [SerializeField]
        Gradient[] gradients;
        //大小数组，默认6个
        [SerializeField]
        AnimationCurve[] curves;
        [SerializeField]
        TextureUVCount[] uvCounts;

        [SerializeField]
        Material material;      //渲染用的材质
        /// <summary>        /// 当前循环到的组数，用来控制影响的组数        /// </summary>
        public int index = 0;

        [SerializeField]
        /// <summary>        /// 渲染时用到的图集        /// </summary>
        Texture2DArray textureArray;

        int colorsId = Shader.PropertyToID("_GradientColor"),
            alphasId = Shader.PropertyToID("_GradientAlpha"),
            sizesId = Shader.PropertyToID("_GradientSizes"),
            particlesBufferId = Shader.PropertyToID("_ParticlesBuffer"),
            groupsBufferId = Shader.PropertyToID("_GroupNodeBuffer"),
            timeId = Shader.PropertyToID("_Time");

        int kernel_PerFrame, kernel_PerFix;

        private static ParticleNoiseFactory instance;
        public static ParticleNoiseFactory Instance
        {
            get
            {
                if(instance == null)
                {
                    GameObject game = new GameObject("ParticleFactory");
                    game.AddComponent<ParticleNoiseFactory>();
                }
                return instance;
            }
        }


        private void Awake()
        {
            if(instance != null)
            {
                Destroy(gameObject);
                return;
            }
            instance = this;
            DontDestroyOnLoad(gameObject);
            ParticleFactoryMenu factoryMenu = 
                Resources.Load<ParticleFactoryMenu>("Render/ParticleFactory/ParticleFactoryMenu");
            compute = factoryMenu.compue;
            material = factoryMenu.material;
            textureArray = factoryMenu.textureArray;
            uvCounts = factoryMenu.uvCounts;

            kernel_PerFrame = compute.FindKernel("Particles_PerFrame");
            kernel_PerFix = compute.FindKernel("Particles_PerFixFrame");
            InitializeMode();       //先初始化所有加载模式
            InitializeParticle();   //再初始化粒子，以及传递数据到GPU
        }
        bool isInsert = false;
        private void Start()
        {
            GPUDravinDrawStack.Instance.InsertRender(this);
            isInsert = true;
        }

        private void OnDestroy()
        {
            if(isInsert)
                GPUDravinDrawStack.Instance.RemoveRender(this);
            groupsBuffer.Release();
            particlesBuffer.Release();
        }

        private void Update()
        {
            compute.SetVector(timeId, new Vector4(Time.time, Time.deltaTime, Time.fixedDeltaTime));
            compute.SetBuffer(kernel_PerFrame, particlesBufferId, particlesBuffer);
            compute.SetBuffer(kernel_PerFrame, groupsBufferId, groupsBuffer);
            compute.Dispatch(kernel_PerFrame, particleGroupCount, 1, 1);
        }

        private void FixedUpdate()
        {
            compute.SetVector(timeId, new Vector4(Time.time, Time.deltaTime, Time.fixedDeltaTime));
            compute.SetBuffer(kernel_PerFix, particlesBufferId, particlesBuffer);
            compute.SetBuffer(kernel_PerFix, groupsBufferId, groupsBuffer);
            compute.Dispatch(kernel_PerFix, particleGroupCount, 1, 1);
        }

        /// <summary>        /// 初始化所有的条目，也就是颜色和大小        /// </summary>
        private void InitializeMode()
        {
            curves = new AnimationCurve[3];
            Keyframe keyframe = new Keyframe();
            //第一个，逐渐变大
            keyframe.time = 0; keyframe.value = 0; keyframe.inTangent = 2; keyframe.outTangent = 2;
            curves[0] = new AnimationCurve();
            curves[0].AddKey(keyframe);
            keyframe.time = 1; keyframe.value = 1; keyframe.inTangent = 0; keyframe.outTangent = 0;
            curves[0].AddKey(keyframe);
            //第二个，正态分布
            curves[1] = new AnimationCurve();
            keyframe.time = 0; keyframe.value = 0; keyframe.inTangent = 5; keyframe.outTangent = 5;
            curves[1].AddKey(keyframe);
            keyframe.time = 0.5f; keyframe.value = 1f; keyframe.inTangent = 0; keyframe.outTangent = 0;
            curves[1].AddKey(keyframe);
            keyframe.time = 1; keyframe.value = 0; keyframe.inTangent = -5; keyframe.outTangent = -5;
            curves[1].AddKey(keyframe);
            //第三个，下凹曲线
            curves[2] = new AnimationCurve();
            keyframe.time = 0; keyframe.value = 0; keyframe.inTangent = 0; keyframe.outTangent = 0;
            curves[2].AddKey(keyframe);
            keyframe.time = 1; keyframe.value = 1; keyframe.inTangent = 2; keyframe.outTangent = 2;
            curves[2].AddKey(keyframe);


            //添加颜色
            gradients = new Gradient[4];
            //添加第一个
            gradients[0] = new Gradient();
            GradientColorKey[] colorKeys = new GradientColorKey[2];
            colorKeys[0] = new GradientColorKey(); colorKeys[0].color = Color.white; colorKeys[0].time = 0;
            colorKeys[1] = new GradientColorKey(); colorKeys[1].color = Color.white; colorKeys[0].time = 1;
            GradientAlphaKey[] alphaKeys = new GradientAlphaKey[4];
            alphaKeys[0] = new GradientAlphaKey(); alphaKeys[0].alpha = 0; alphaKeys[0].time = 0;
            alphaKeys[1] = new GradientAlphaKey(); alphaKeys[1].alpha = 1; alphaKeys[1].time = 0.2f;
            alphaKeys[2] = new GradientAlphaKey(); alphaKeys[2].alpha = 1; alphaKeys[2].time = 0.8f;
            alphaKeys[3] = new GradientAlphaKey(); alphaKeys[3].alpha = 0; alphaKeys[3].time = 1f;
            gradients[0].SetKeys(colorKeys, alphaKeys);

            //添加第二个
            gradients[1] = new Gradient();
            colorKeys = new GradientColorKey[5]; 
            colorKeys[0] = new GradientColorKey(); colorKeys[0].color = new Color(4.0f, 0.6f, 0); 
            colorKeys[0].time = 0;
            colorKeys[1] = new GradientColorKey(); colorKeys[1].color = new Color(32.0f, 2.133f, 0);
            colorKeys[1].time = 0.18f;
            colorKeys[2] = new GradientColorKey(); colorKeys[2].color = new Color(29, 8f, 0);
            colorKeys[2].time = 0.5f;
            colorKeys[3] = new GradientColorKey(); colorKeys[3].color = new Color(25f, 4f, 0f);
            colorKeys[3].time = 0.8f;
            colorKeys[4] = new GradientColorKey(); colorKeys[4].color = new Color(20f, 2f, 0f);
            colorKeys[4].time = 1f;
            gradients[1].SetKeys(colorKeys, alphaKeys);     //透明度不变

            //添加第三个
            gradients[2] = new Gradient();
            alphaKeys = new GradientAlphaKey[3];
            alphaKeys[0] = new GradientAlphaKey(); alphaKeys[0].alpha = 1; alphaKeys[0].time = 0;
            alphaKeys[1] = new GradientAlphaKey(); alphaKeys[1].alpha = 1; alphaKeys[1].time = 0.8f;
            alphaKeys[2] = new GradientAlphaKey(); alphaKeys[2].alpha = 0; alphaKeys[2].time = 1f;
            gradients[2].SetKeys(colorKeys, alphaKeys);     //颜色值不变

            //添加第四个,黄高光到蓝高光
            gradients[3] = new Gradient();
            alphaKeys = new GradientAlphaKey[4];
            alphaKeys[0] = new GradientAlphaKey(); alphaKeys[0].alpha = 1; alphaKeys[0].time = 0;
            alphaKeys[1] = new GradientAlphaKey(); alphaKeys[1].alpha = 1; alphaKeys[1].time = 0f;
            alphaKeys[2] = new GradientAlphaKey(); alphaKeys[2].alpha = 1; alphaKeys[2].time = 0.8f;
            alphaKeys[3] = new GradientAlphaKey(); alphaKeys[3].alpha = 0; alphaKeys[3].time = 1f;
            colorKeys = new GradientColorKey[2];
            colorKeys[0] = new GradientColorKey(); colorKeys[0].color = new Color(24.0f, 2.3f, 0);
            colorKeys[0].time = 0f;
            colorKeys[1] = new GradientColorKey(); colorKeys[1].color = new Color(0f, 4f, 24);
            colorKeys[1].time = 1f;
            gradients[3].SetKeys(colorKeys, alphaKeys);
        }

        /// <summary>        /// 初始化所有粒子        /// </summary>
        private void InitializeParticle()
        {
            particleNodes = new ParticleNodeData[particleGroupCount];
            //初始化组数据
            for (int i=0; i<particleNodes.Length; i++)
            {
                particleNodes[i] = new ParticleNodeData
                {
                    initEnum = Vector3Int.zero,
                    lifeTimeRange = -Vector3.one
                };
            }
            groupsBuffer?.Release();
            groupsBuffer = new ComputeBuffer(particleGroupCount, Marshal.SizeOf(particleNodes[0]));
            groupsBuffer.SetData(particleNodes);

            NoiseParticleData[] noiseParticles = new NoiseParticleData[particleGroupCount * 64];
            particlesBuffer?.Release();
            particlesBuffer = new ComputeBuffer(particleGroupCount * 64, Marshal.SizeOf(noiseParticles[0]));
            for(int i=0; i< noiseParticles.Length; i++)
            {
                Vector4 random = new Vector4(Random.value, Random.value, Random.value, 0);
                noiseParticles[i] = new NoiseParticleData
                {
                    random = random,
                    index = Vector2Int.zero
                };
            }
            particlesBuffer.SetData(noiseParticles);

            //加载全部颜色
            Vector4[] colors = new Vector4[36];
            for(int i=0; i<6 && i < gradients.Length; i++)
            {
                GradientColorKey[] gradientColorKeys = gradients[i].colorKeys;
                for(int j=0; j< gradientColorKeys.Length && j < 6; j++)
                {
                    colors[i * 6 + j] = gradientColorKeys[j].color;
                    colors[i * 6 + j].w = gradientColorKeys[j].time;
                }
            }
            compute.SetVectorArray(colorsId, colors);
            //加载全部的透明度
            Vector4[] alphas = new Vector4[36];
            for (int i = 0; i < 6 && i < gradients.Length; i++)
            {
                GradientAlphaKey[] gradientAlphaKeys = gradients[i].alphaKeys;
                for (int j = 0; j < gradientAlphaKeys.Length && j < 6; j++)
                {
                    alphas[i * 6 + j] = new Vector4(gradientAlphaKeys[j].alpha,
                        gradientAlphaKeys[j].time);
                }
            }
            compute.SetVectorArray(alphasId, alphas);

            //加载全部的大小
            Vector4[] sizes = new Vector4[36];
            for (int i = 0; i < 6 && i < curves.Length; i++)
            {
                AnimationCurve curve = curves[i];
                for (int j = 0; j < curve.keys.Length && j < 6; j++)
                {
                    sizes[i * 6 + j] = new Vector4(curve.keys[j].time, curve.keys[j].value,
                        curve.keys[j].inTangent, curve.keys[j].outTangent);
                }
            }
            compute.SetVectorArray(sizesId, sizes);

        }

        /// <summary>        /// 渲染一组球形粒子在指定位置        /// </summary>
        public void DrawSphere(ParticleDrawData drawData)
        {
            for(int i=0; i< drawData.groupCount; i++)
            {
                if (particleNodes[index].lifeTimeRange.z > Time.time)   //没有粒子可以释放
                    return;
                particleNodes[index].initEnum = new Vector3Int(1, drawData.useGravity ? 1 : 0, drawData.textureIndex);
                SetGroupData(index, drawData);
                index++; index %= particleGroupCount;
            }


        }

        /// <summary>        /// 在一个矩形中渲染粒子        /// </summary>
        /// <param name="cubeOffset">粒子对于Y和X的偏移值</param>
        public void DrawCube(ParticleDrawData drawData)
        {
            for (int i = 0; i < drawData.groupCount; i++)
            {
                if (particleNodes[index].lifeTimeRange.z > Time.time)   //没有粒子可以释放
                    return;
                //设置为cube模式
                particleNodes[index].initEnum = new Vector3Int(2, drawData.useGravity ? 1 : 0, drawData.textureIndex);
                SetGroupData(index, drawData);
                index++; index %= particleGroupCount;
            }
        }

        /// <summary>        /// 在点上渲染粒子        /// </summary>
        public void DrawPos(ParticleDrawData drawData)
        {
            for (int i = 0; i < drawData.groupCount; i++)
            {
                if (particleNodes[index].lifeTimeRange.z > Time.time)   //没有粒子可以释放
                    return;
                particleNodes[index].initEnum = new Vector3Int(0, 
                    drawData.useGravity ? 1 : 0, drawData.textureIndex);
                SetGroupData(index, drawData);
                index++; index %= particleGroupCount;
            }
        }


        /// <summary>
        /// 设置统一的粒子组数据，不包含初始化等设置, 要在前面先处理先，之后可能有其他内容
        /// </summary>
        /// <param name="index">设置的编号</param>
        /// <param name="drawData">设置的根据数据</param>
        private void SetGroupData(int index, ParticleDrawData drawData)
        {
            particleNodes[index].beginPos = drawData.beginPos;
            particleNodes[index].endPos = drawData.endPos;
            particleNodes[index].beginSpeed = drawData.beginSpeed;
            particleNodes[index].cubeRange = drawData.cubeOffset;
            particleNodes[index].sphereData = new Vector2(drawData.radian, drawData.radius);
            particleNodes[index].lifeTimeRange = new Vector3(drawData.lifeTime
                - drawData.showTime, drawData.showTime, Time.time + drawData.lifeTime);
            particleNodes[index].noiseData = new Vector3(drawData.frequency, drawData.octave, drawData.intensity);
            particleNodes[index].smoothRange = drawData.sizeRange;
            particleNodes[index].uvCount = new Vector2Int(uvCounts[drawData.textureIndex].rowCount,
                uvCounts[drawData.textureIndex].columnCount);
            particleNodes[index].drawData = new Vector2Int((int)drawData.colorIndex, (int)drawData.sizeIndex);
            particleNodes[index].outEnum.x = drawData.followSpeed ? 1 : 0;
            particleNodes[index].outEnum.y = (int)drawData.speedMode;
            groupsBuffer.SetData(particleNodes, index, index, 1);
        }


        public override void DrawByCamera(ScriptableRenderContext context, CommandBuffer buffer, ClustDrawType drawType, Camera camera)
        {

            buffer.SetGlobalBuffer(particlesBufferId, particlesBuffer);
            buffer.SetGlobalBuffer(groupsBufferId, groupsBuffer);
            buffer.SetGlobalTexture("_Textures", textureArray);
            buffer.DrawProcedural(Matrix4x4.identity, material, 0, MeshTopology.Points,
                64, particleGroupCount);
            ExecuteBuffer(ref buffer, context);
            return;
        }

        public override void DrawByProjectMatrix(ScriptableRenderContext context, CommandBuffer buffer, ClustDrawType drawType, Matrix4x4 projectMatrix)
        {
            return;
        }
        public override void DrawPreSSS(ScriptableRenderContext context, CommandBuffer buffer, Camera camera)
        {
            return;
        }
        public override void SetUp(ScriptableRenderContext context, CommandBuffer buffer, Camera camera)
        {
            return;
        }
    }
}