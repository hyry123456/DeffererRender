using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    [System.Serializable]
    struct ParticleGroupsData
    {
        public float dieTime;
    };

    /// <summary>/// 粒子噪声类，用来绘制单个复杂效果的粒子/// </summary>
    public class NoiseParticleNode : GPUDravinBase
    {
        private bool isInsert = false;

        public ComputeShader compute;
        public Shader shader;
        public int groupCount = 10,     //粒子组总共数量
            perReleaseGroup = 1;            //每一次释放的粒子数量
        public NoisePerNodeData noiseData;

        public Texture2D mainTex;
        public int rowCount = 1;
        public int columnCount = 1;
        public bool particleFollowSpeed;

        public bool useNearAlpha = false;
        public float nearFadeDistance = 1;
        public float nearFadeRange = 1;

        public bool useSoftParticle = false;
        public float softParticleDistance = 1;
        public float softParticleRange = 1;

        /// <summary> /// 是否需要开启碰撞  /// </summary>
        public bool useCollsion;
        [SerializeField]
        public List<IGetCollsion> collsions;    //所有碰撞器数据

        ParticleGroupsData[] groups;
        private ComputeBuffer particleBuffer;
        private ComputeBuffer groupBuffer;
        private ComputeBuffer collsionBuffer;

        private int kernel_Perframe, kernel_PerFixframe, kernel_PerFixCollsion;
        [SerializeField]
        private Material material;
        float time = 0; 
        [SerializeField]
        int index = 0;

        private void Start()
        {
            if (compute == null || shader == null)
                return;
            GPUDravinDrawStack.Instance.InsertRender(this);
            isInsert = true;
            kernel_Perframe = compute.FindKernel("Noise_PerFrame");
            kernel_PerFixframe = compute.FindKernel("Noise_PerFixFrame");
            kernel_PerFixCollsion = compute.FindKernel("Noise_PerFixFrameWithCollsion");

            if (collsions != null)
            {
                for (int i = this.collsions.Count - 1; i >= 0; i--)
                    if (this.collsions[i] == null) this.collsions.RemoveAt(i);
            }

            if (collsions == null || collsions.Count == 0)
                useCollsion = false;
            ReadyMaterial();
            ReadyBuffer();
            time = noiseData.releaseTime * 0.8f;
        }

        private void OnDestroy()
        {
            if (isInsert)
            {
                GPUDravinDrawStack.Instance.RemoveRender(this);
                isInsert = false;
            }
            particleBuffer?.Release();
            groupBuffer?.Release();
            collsionBuffer?.Release();
        }

        private void Update()
        {
            if (!isInsert) return;  //没有插入渲染栈就退出

            time += Time.deltaTime;
            if (time > noiseData.releaseTime * 0.9f)
            {
                time = 0;
                for(int i = 0; i<perReleaseGroup; i++)
                {
                    //到时间就拷贝数据
                    if (groups[index].dieTime < Time.time)
                    {
                        groups[index].dieTime = Time.time + noiseData.releaseTime + noiseData.liveTime;
                        groupBuffer.SetData(groups, index, index, 1);
                        index++;
                        index %= groupCount;
                    }
                    else
                        break;
                }

            }
            SetOnCompute();
            compute.Dispatch(kernel_Perframe, groupCount, 1, 1);

        }

        private void FixedUpdate()
        {
            if (!isInsert) return;  //没有插入渲染栈就退出
            SetOnFixCompute();
            compute.Dispatch(useCollsion ? kernel_PerFixCollsion :
                kernel_PerFixframe, groupCount, 1, 1);
        }

#if UNITY_EDITOR
        private void OnDrawGizmos()
        {
            if (noiseData == null)
                return;
            Gizmos.matrix = transform.localToWorldMatrix;
            Gizmos.color = Color.red;
            if(noiseData.shapeMode == InitialShapeMode.Cube)
            {
                Gizmos.DrawWireCube(Vector3.zero, noiseData.cubeRange);
            }
        }

        private void OnValidate()
        {
            if (!isInsert) return;
            ReadyMaterial();
            ReadyBuffer();
            index = 0;
            time = noiseData.releaseTime * 0.8f;
        }
#endif

        private void ReadyMaterial()
        {
            material = new Material(shader);
            if (useSoftParticle)
            {
                material.EnableKeyword("_SOFT_PARTICLE");
                material.SetFloat("_SoftParticlesDistance", softParticleDistance);
                material.SetFloat("_SoftParticlesRange", softParticleRange);
            }
            else
                material.DisableKeyword("_SOFT_PARTICLE");

            if (useNearAlpha)
            {
                material.EnableKeyword("_NEAR_ALPHA");
                material.SetFloat("_NearFadeDistance", nearFadeDistance);
                material.SetFloat("_NearFadeRange", nearFadeRange);
            }
            else
                material.DisableKeyword("_NEAR_ALPHA");
        }

        /// <summary>  /// 创建以及初始化Buffer数据    /// </summary>
        private void ReadyBuffer()
        {
            particleBuffer?.Release();
            groupBuffer?.Release();
            collsionBuffer?.Release();

            NoiseParticleData[] particles = new NoiseParticleData[groupCount * 64];
            particleBuffer = new ComputeBuffer(particles.Length, Marshal.SizeOf<NoiseParticleData>());
            for (int i = 0; i < particles.Length; i++)
            {
                particles[i] = new NoiseParticleData()
                {
                    random = new Vector4(Random.value, Random.value, Random.value, 0),
                    index = new Vector2Int(i, 0),
                };
            }
            particleBuffer.SetData(particles, 0, 0, particles.Length);

            groups = new ParticleGroupsData[groupCount];
            groupBuffer = new ComputeBuffer(groups.Length, Marshal.SizeOf<ParticleGroupsData>());
            for(int i=0; i< groups.Length; i++)
            {
                groups[i] = new ParticleGroupsData()
                {
                    dieTime = -1,
                };
            }
            groupBuffer.SetData(groups, 0, 0, groupCount);

            if (useCollsion)
            {
                CollsionStruct[] collsions = new CollsionStruct[this.collsions.Count];
                for(int i=0; i<collsions.Length; i++)
                {
                    collsions[i] = this.collsions[i].GetCollsionStruct();
                }
                collsionBuffer = new ComputeBuffer(collsions.Length,
                    Marshal.SizeOf<CollsionStruct>());
                collsionBuffer.SetData(collsions, 0, 0, collsions.Length);
            }


        }

        /// <summary>
        /// 设置逐固定帧的Compute shader的数据，因为compute shader是全部共用的，
        /// 所以要每次都设置一次
        /// </summary>
        private void SetOnFixCompute()
        {
            if (useCollsion)
            {
                compute.SetBuffer(kernel_PerFixCollsion, "_ParticleNoiseBuffer", particleBuffer);
                compute.SetBuffer(kernel_PerFixCollsion, "_CollsionBuffer", collsionBuffer);
                compute.SetFloat("_CollsionScale", noiseData.collsionScale);
                compute.SetInt("_CollsionData", collsions.Count);
            }
            else
            {
                compute.SetBuffer(kernel_PerFixframe, "_ParticleNoiseBuffer", particleBuffer);
            }

            compute.SetFloat("_Frequency", noiseData.frequency);
            compute.SetInt("_Octave", noiseData.octave);
            compute.SetFloat("_Intensity", noiseData.intensity);
            compute.SetInts("_Mode", new int[] {(int)noiseData.shapeMode,
                (int)noiseData.speedMode, (int)noiseData.sizeBySpeedMode,
                noiseData.useGravity? 1 : 0});
            //compute.SetFloats("_NearData", new float[] { noiseData.nearTime, noiseData.nearRadio });
        }

        /// <summary>
        /// 设置逐帧的Compute shader的数据
        /// </summary>
        private void SetOnCompute()
        {
            compute.SetFloat("_Arc", noiseData.arc);
            compute.SetFloat("_Radius", noiseData.radius);
            compute.SetVector("_CubeRange", noiseData.cubeRange);
            compute.SetInt("_Octave", noiseData.octave);
            compute.SetFloat("_Frequency", noiseData.frequency);
            compute.SetFloat("_Intensity", noiseData.intensity);
            compute.SetVector("_LifeTime", new Vector4(noiseData.releaseTime, 
                noiseData.liveTime, 0, 0));
            compute.SetInts("_Mode", new int[] {(int)noiseData.shapeMode,
                (int)noiseData.speedMode, (int)noiseData.sizeBySpeedMode,
                noiseData.useGravity? 1 : 0});
            compute.SetMatrix("_RotateMatrix", transform.localToWorldMatrix);
            compute.SetVector("_BeginSpeed", noiseData.velocityBegin);
            compute.SetVector("_SizeRange", new Vector4(
                noiseData.sizeRange.x, noiseData.sizeRange.y,
                noiseData.speedRange.x, noiseData.speedRange.y));
            compute.SetVector("_Time", new Vector4(Time.time, Time.deltaTime, Time.fixedDeltaTime));
            compute.SetInts("_UVCount", new int[] { rowCount, columnCount});
            //compute.SetFloats("_NearData", new float[] { noiseData.nearTime, noiseData.nearRadio });

            compute.SetVectorArray("_Colors", noiseData.GetColors());
            compute.SetVectorArray("_Alphas", noiseData.GetAlphas());
            compute.SetVectorArray("_Sizes", noiseData.GetSizes());

            compute.SetBuffer(kernel_Perframe, "_ParticleNoiseBuffer", particleBuffer);
            compute.SetBuffer(kernel_Perframe, "_GroupBuffer", groupBuffer);
        }

        public override void DrawByCamera(ScriptableRenderContext context, CommandBuffer buffer, ClustDrawType drawType, Camera camera)
        {

            material.SetBuffer("_ParticleNoiseBuffer", particleBuffer);
            material.SetTexture("_MainTex", mainTex);
            material.SetInt("_RowCount", rowCount);
            material.SetInt("_ColCount", columnCount);
            material.SetFloat("_TexAspectRatio", (float)mainTex.width / mainTex.height);
            if (particleFollowSpeed)
                material.EnableKeyword("_FELLOW_SPEED");
            else material.DisableKeyword("_FELLOW_SPEED");


            buffer.DrawProcedural(Matrix4x4.identity, material, 0, MeshTopology.Points,
                1, particleBuffer.count);
            ExecuteBuffer(ref buffer, context);
            return;
        }

        public override void DrawByProjectMatrix(ScriptableRenderContext context, CommandBuffer buffer, ClustDrawType drawType, Matrix4x4 projectMatrix)
        {
        }

        public override void DrawPreSSS(ScriptableRenderContext context, CommandBuffer buffer, Camera camera)
        {
        }

        public override void SetUp(ScriptableRenderContext context, CommandBuffer buffer, Camera camera)
        {
        }
    }
}