using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;
using UnityEngine.Rendering;

namespace DefferedRender
{

    //大水珠需要的数据
    struct FluidGroup
    {
        public Vector3 worldPos;
        public Vector3 nowSpeed;
        //0是未初始化，1是group，2是非组
        public int mode;
        public float dieTime;  //死亡时间
    };

    //液体粒子需要的数据
    struct FluidParticle
    {
        public Vector3 worldPos;
        public Vector3 nowSpeed;
        public Vector3 random;
        public float size;
        //0为使用，1:组阶段，2：自由粒子
        public int mode;
        public Vector4 uvTransData;     //uv动画需要的数据
        public float interpolation;    //插值需要的数据
    };

    enum FluidPass
    {
        Normal = 0,
        Width = 1,
        CopyDepth = 2,
        BlendTarget=3,
        Bilater=4,
        BilaterDepth=5,
        WriteDepth
    };


    public class NoiseFluidNode : MonoBehaviour, IFluidDraw
    {
        [SerializeField]
        /// <summary>  /// 液体组数量  /// </summary>
        private int GroupCount = 100;
        [SerializeField]
        private int PerReleaseCount = 10;

        ComputeBuffer particleBuffer;
        ComputeBuffer groupBuffer;
        ComputeBuffer collsionBuffer;
        int kernel_Perframe, kernel_PerFixframe, kernel_Blend;
        [SerializeField]
        ComputeShader compute;
        [SerializeField]
        Shader shader;
        Material material;

        [SerializeField]
        Cubemap cubemap;

        FluidGroup[] groups;

        [SerializeField]
        List<IGetCollsion> collsions;
        [SerializeField]
        public List<IGetCollsion> Collsions
        {
            get { return collsions; }
            set { collsions = value; }
        }
        [SerializeField]
        WaterSetting waterSetting;
        public WaterSetting WaterSetting => waterSetting;
        [SerializeField]
        bool isAutoPlay;        //是否自动播放
        public void BeginAutoPlay()
        {
            isAutoPlay = true;
        }
        public void StopAutoPlay()
        {
            isAutoPlay = false;
        }

        float time;
        int index = 0;
        bool isInsert;

        //都是同一个Id，因此设置为静态即可,这里是material Data
        private static int
            widthTexId = Shader.PropertyToID("FluidWidth"),
            normalTexId = Shader.PropertyToID("FluidNormalTex"),
            depthTexId = Shader.PropertyToID("FluidDepthTex"),
            tempWidthTexId = Shader.PropertyToID("TempWidthTex"),
            tempNormalTexId = Shader.PropertyToID("TempNormalTex"),
            //tempDepthTexId = Shader.PropertyToID("TempDepthTex"),

            bufferSizeId = Shader.PropertyToID("_CameraBufferSize"),
            mainTexId = Shader.PropertyToID("_MainTex"),
            normalMapId = Shader.PropertyToID("_NormalMap"),
            rowCountId = Shader.PropertyToID("_RowCount"),
            colCountId = Shader.PropertyToID("_ColCount"),
            texAspectRatioId = Shader.PropertyToID("_TexAspectRatio"),
            fluidParticleId = Shader.PropertyToID("_FluidParticle"),
            bilaterFilterFactorId = Shader.PropertyToID("_BilaterFilterFactor"),
            blurRadiusId = Shader.PropertyToID("_BlurRadius"),
            waterDepthId = Shader.PropertyToID("_WaterDepth"),
            //cameraDepthId = Shader.PropertyToID("_CameraDepth"),
            waterColorId = Shader.PropertyToID("_WaterColor"),
            maxFluidWidthId = Shader.PropertyToID("_MaxFluidWidth"),
            cullOffId = Shader.PropertyToID("_CullOff"),
            specularDataId = Shader.PropertyToID("_SpecularData");


        //compute Shader Data
        private static int
            fluidGroupBufferId = Shader.PropertyToID("_FluidGroup"),
            fluidParticleBufferId = Shader.PropertyToID("_FluidParticle"),
            collsionBufferId = Shader.PropertyToID("_CollsionBuffer"),
            collsionDataId = Shader.PropertyToID("_CollsionData"),
            collsionScaleId = Shader.PropertyToID("_CollsionScale"),
            obstructionId = Shader.PropertyToID("_Obstruction"),
            frequencyId = Shader.PropertyToID("_Frequency"),
            octaveId = Shader.PropertyToID("_Octave"),
            intensityId = Shader.PropertyToID("_Intensity"),
            groupModeId = Shader.PropertyToID("_GroupMode"),
            modeId = Shader.PropertyToID("_Mode");


        #region MaterialSetting
        public Texture2D mainTex;
        public Texture2D normalTex;
        public int rowCount = 1;
        public int columnCount = 1;
        public bool particleFollowSpeed;
        public bool useParticleNormal;      //是否使用默认法线，不是就是用法线贴图
        public bool useNormalMap;      //是否使用默认法线，不是就是用法线贴图
        #endregion

        private void Start()
        {
            if (compute == null || shader == null)
                return;

            FluidDrawStack.Instance.InsertDraw(this);
            isInsert = true;

            kernel_Perframe = compute.FindKernel("Water_PerFrame");
            kernel_PerFixframe = compute.FindKernel("Water_PerFixFrame");
            kernel_Blend = compute.FindKernel("BlendDepth_Nomral_Albedo");
            ReadyMaterial();
            ReadyBuffer();
            index = 0;
            time = waterSetting.sustainTime - 0.1f;
        }

        private void OnDestroy()
        {
            if (isInsert)
            {
                FluidDrawStack.Instance.RemoveDraw(this);
                groupBuffer?.Release();
                particleBuffer?.Release();
                collsionBuffer?.Release();
                isInsert = false;
            }

        }

        private void Update()
        {
            if (!isInsert) return;
            if (isAutoPlay)
            {
                time += Time.deltaTime;
                if (time > waterSetting.releaseTime)
                {
                    time = 0;
                    //每次释放的粒子组数量，循环设置
                    for (int i = 0; i < PerReleaseCount; i++)
                    {
                        //到时间就拷贝数据
                        if (groups[index].dieTime < Time.time)
                        {
                            groups[index].dieTime = Time.time + waterSetting.sustainTime;
                            groupBuffer.SetData(groups, index, index, 1);
                            index++;
                            index %= GroupCount;
                        }
                        else
                            break;
                    }
                }
            }

            SetOnCompute();     //设置Shader参数
            compute.Dispatch(kernel_Perframe, GroupCount, 1, 1);    //执行，正好就是组数量
        }

        private void FixedUpdate()
        {
            if (!isInsert) return;

            SetOnFixCompute();
            compute.Dispatch(kernel_PerFixframe, GroupCount, 1, 1);
        }



#if UNITY_EDITOR
        private void OnDrawGizmos()
        {
            if (waterSetting == null)
                return;
            Gizmos.matrix = transform.localToWorldMatrix;
            Gizmos.color = Color.red;
            if (waterSetting.groupShapeMode == InitialShapeMode.Cube)
            {
                Gizmos.DrawWireCube(Vector3.zero, waterSetting.groupCubeRange);
            }
            else if (waterSetting.groupShapeMode == InitialShapeMode.Sphere)
            {
                Gizmos.DrawWireSphere(Vector3.zero, waterSetting.groupRadius);
            }
        }

        private void OnValidate()
        {
            if (!isInsert) return;
            ReadyMaterial();
            ReadyBuffer();
            index = 0;
            time = waterSetting.sustainTime - 0.1f;
        }
#endif


        private void ReadyBuffer()
        {
            particleBuffer?.Release();
            groupBuffer?.Release();
            collsionBuffer?.Release();

            FluidParticle[] particles = new FluidParticle[GroupCount * 64];     //单个粒子数据
            particleBuffer = new ComputeBuffer(particles.Length, Marshal.SizeOf<FluidParticle>());
            for (int i = 0; i < particles.Length; i++)
            {
                particles[i] = new FluidParticle()
                {
                    //设置随机数
                    random = new Vector3(Random.value, Random.value, Random.value),
                };
            }
            particleBuffer.SetData(particles, 0, 0, particles.Length);

            groups = new FluidGroup[GroupCount];    //组数据
            groupBuffer = new ComputeBuffer(groups.Length, Marshal.SizeOf<FluidGroup>());
            for (int i = 0; i < groups.Length; i++)
            {
                groups[i] = new FluidGroup()
                {
                    dieTime = -1,   //初始化为未释放
                };
            }
            groupBuffer.SetData(groups, 0, 0, GroupCount);

            if (this.collsions == null) this.collsions = new List<IGetCollsion>();
            List<CollsionStruct> collsions = new List<CollsionStruct>();
            for(int i=this.collsions.Count - 1; i>=0; i--)
                if (this.collsions[i] == null) this.collsions.RemoveAt(i);
            for (int i = 0; i < this.collsions.Count; i++)
            {
                collsions.Add(this.collsions[i].GetCollsionStruct());
            }
            if(collsions.Count == 0)
            {
                collsions.Add(new CollsionStruct
                {
                    radius = 0,
                    center = Vector3.zero,
                    offset = Vector3.zero,
                    mode = 0
                });
            }
            collsionBuffer = new ComputeBuffer(collsions.Count,
                Marshal.SizeOf<CollsionStruct>());
            collsionBuffer.SetData(collsions, 0, 0, collsions.Count);
        }

        private void ReadyMaterial()
        {
            material = new Material(shader);
            if (particleFollowSpeed)
            {
                material.EnableKeyword("_FOLLOW_SPEED");
            }
            else material.DisableKeyword("_FOLLOW_SPEED");

            if (useParticleNormal)
                material.EnableKeyword("_PARTICLE_NORMAL");
            else material.DisableKeyword("_PARTICLE_NORMAL");

            if (useNormalMap)
                material.EnableKeyword("_NORMAL_MAP");
            else material.DisableKeyword("_NORMAL_MAP");
        }

        /// <summary>/// 设置逐帧的Compute shader的数据/// </summary>
        private void SetOnCompute()
        {
            //设置组数据
            compute.SetInts("_GroupMode", new int[]
                {(int)waterSetting.groupShapeMode, (int)waterSetting.groupSpeedMode,
                waterSetting.groupUseGravity? 1:0});
            compute.SetFloat("_GroupArc", waterSetting.groupArc);
            compute.SetFloat("_GroupRadius", waterSetting.groupRadius);
            compute.SetVector("_GroupCubeRange", waterSetting.groupCubeRange);

            //设置单个粒子数据
            compute.SetFloat("_Arc", waterSetting.particleArc);
            compute.SetFloat("_Radius", waterSetting.particleRadius);
            compute.SetVector("_CubeRange", waterSetting.particleCubeRange);
            compute.SetFloat("_ParticleBeginSpeed", waterSetting.particleVelocityBegin);
            compute.SetVector("_LifeTime", new Vector4(waterSetting.sustainTime,
                0, 0, 0));

            compute.SetInts("_Mode", new int[] {(int)waterSetting.particleShadpeMode,
                (int)waterSetting.particleSpeedMode, (int)waterSetting.sizeBySpeedMode,
                waterSetting.particleUseGravity? 1 : 0});
            compute.SetMatrix("_RotateMatrix", transform.localToWorldMatrix);
            Vector3 speed = transform.TransformDirection(waterSetting.groupVelocityBegin);
            compute.SetVector("_BeginSpeed", new Vector4(speed.x,
                speed.y, speed.z, waterSetting.groupVelocityBegin.magnitude));

            compute.SetVector("_SizeRange", new Vector4(
                waterSetting.sizeRange.x, waterSetting.sizeRange.y,
                waterSetting.speedRange.x, waterSetting.speedRange.y));
            compute.SetVector("_Time", new Vector4(Time.time, Time.deltaTime, Time.fixedDeltaTime));
            compute.SetInts("_UVCount", new int[] { rowCount, columnCount });

            compute.SetVectorArray("_Sizes", waterSetting.GetParticleSizes());

            compute.SetBuffer(kernel_Perframe, "_FluidGroup", groupBuffer);
            compute.SetBuffer(kernel_Perframe, "_FluidParticle", particleBuffer);
        }

        /// <summary>
        /// 设置逐固定帧的Compute shader的数据，因为compute shader是全部共用的，
        /// 所以要每次都设置一次
        /// </summary>
        private void SetOnFixCompute()
        {
            int kernel = kernel_PerFixframe;
            compute.SetBuffer(kernel, fluidGroupBufferId, groupBuffer);
            compute.SetBuffer(kernel, fluidParticleBufferId, particleBuffer);
            compute.SetBuffer(kernel, collsionBufferId, collsionBuffer);
            compute.SetInt(collsionDataId, collsions.Count);
            compute.SetFloat(collsionScaleId, waterSetting.collsionScale);
            compute.SetFloat(obstructionId, 1.0f - waterSetting.obstruction);

            compute.SetFloat(frequencyId, waterSetting.frequency);
            compute.SetInt(octaveId, waterSetting.octave);
            compute.SetFloat(intensityId, waterSetting.particleIntensity);
            compute.SetInts(groupModeId, new int[]
                {(int)waterSetting.groupShapeMode, (int)waterSetting.groupSpeedMode,
                waterSetting.groupUseGravity? 1:0});
            compute.SetInts(modeId, new int[] {(int)waterSetting.particleShadpeMode,
                (int)waterSetting.particleSpeedMode, (int)waterSetting.sizeBySpeedMode,
                waterSetting.particleUseGravity? 1 : 0});
        }

        public void IFluidDraw(ScriptableRenderContext context, CommandBuffer buffer,
            int gBufferDepth, int width, int height, int dest)
        {
            float pixelScale = 0.8f;
            int bufferWidth = (int)(pixelScale * width),
                bufferHeight = (int)(pixelScale * height);
            buffer.GetTemporaryRT(widthTexId, bufferWidth, bufferHeight, 0,
                FilterMode.Bilinear, RenderTextureFormat.RFloat);
            buffer.GetTemporaryRT(normalTexId, bufferWidth, bufferHeight, 0,
                FilterMode.Bilinear, RenderTextureFormat.RG32);
            buffer.GetTemporaryRT(depthTexId, bufferWidth, bufferHeight, 32,
                FilterMode.Point, RenderTextureFormat.Depth);

            buffer.GetTemporaryRT(tempWidthTexId, bufferWidth, bufferHeight, 0,
                FilterMode.Point, RenderTextureFormat.RFloat);
            buffer.GetTemporaryRT(tempNormalTexId, bufferWidth, bufferHeight, 0,
                FilterMode.Point, RenderTextureFormat.RG32);

            buffer.SetGlobalTexture(mainTexId, gBufferDepth);
            buffer.Blit(null, depthTexId, material, (int)FluidPass.CopyDepth);

            buffer.SetGlobalTexture(mainTexId, mainTex);
            buffer.SetGlobalTexture(normalMapId, normalTex);
            buffer.SetGlobalInt(rowCountId, rowCount);
            buffer.SetGlobalInt(colCountId, columnCount);
            buffer.SetGlobalFloat(texAspectRatioId, (float)mainTex.width / mainTex.height);
            buffer.SetGlobalBuffer(fluidParticleId, particleBuffer);

            buffer.SetGlobalVector(bufferSizeId, new Vector4(
                1f / bufferWidth, 1f / bufferHeight, bufferWidth, bufferHeight));

            buffer.SetRenderTarget(
                widthTexId, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store,
                depthTexId, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store
            );
            buffer.ClearRenderTarget(false, true, Color.clear);
            buffer.DrawProcedural(Matrix4x4.identity, material, (int)FluidPass.Width,
                MeshTopology.Points, 1, particleBuffer.count);

            buffer.SetRenderTarget(
                normalTexId, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store,
                depthTexId, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store
                );
            buffer.ClearRenderTarget(false, true, Color.clear);

            buffer.DrawProcedural(Matrix4x4.identity, material, (int)FluidPass.Normal,
                MeshTopology.Points, 1, particleBuffer.count);

            for(int i=0; i< waterSetting.circleBlur; i++)
            {
                buffer.SetGlobalFloat(bilaterFilterFactorId, waterSetting.bilaterFilterFactor);
                buffer.SetGlobalVector(blurRadiusId, new Vector4(waterSetting.blurRadius, 0));
                buffer.SetGlobalTexture(mainTexId, widthTexId);
                buffer.Blit(null, tempWidthTexId, material, (int)FluidPass.Bilater);
                buffer.SetGlobalTexture(mainTexId, normalTexId);
                buffer.Blit(null, tempNormalTexId, material, (int)FluidPass.Bilater);

                buffer.SetGlobalVector(blurRadiusId, new Vector4(0, waterSetting.blurRadius));
                buffer.SetGlobalTexture(mainTexId, tempNormalTexId);
                buffer.Blit(null, normalTexId, material, (int)FluidPass.Bilater);
                buffer.SetGlobalTexture(mainTexId, tempWidthTexId);
                buffer.Blit(null, widthTexId, material, (int)FluidPass.Bilater);
            }

            buffer.SetGlobalTexture(waterDepthId, depthTexId);
            buffer.SetGlobalTexture(normalMapId, normalTexId);
            buffer.SetGlobalColor(waterColorId, waterSetting.waterCol);
            buffer.SetGlobalFloat(maxFluidWidthId, waterSetting.maxFluidWidth);
            buffer.SetGlobalFloat(cullOffId, waterSetting.cullOff);
            buffer.SetGlobalVector(specularDataId, new Vector2(waterSetting.metallic,
                waterSetting.roughness));

            material.SetTexture("_CubeMap", cubemap);
            material.SetVector("_BSDFData", new Vector3(
                waterSetting.distorion,waterSetting.power, waterSetting.scale));

            buffer.Blit(null, dest, material, (int)FluidPass.BlendTarget);

            buffer.ReleaseTemporaryRT(widthTexId);
            buffer.ReleaseTemporaryRT(normalTexId);
            buffer.ReleaseTemporaryRT(depthTexId);
            buffer.ReleaseTemporaryRT(tempNormalTexId);
            buffer.ReleaseTemporaryRT(tempWidthTexId);

            //设置回去
            buffer.SetGlobalVector(bufferSizeId, new Vector4(
                1f / width, 1f / height, width, height));
        }

        /// <summary> /// 进行一次液体释放，具体释放的数量由该节点本身决定 /// </summary>
        public void ReleaseOneTime()
        {
            for (int i = 0; i < PerReleaseCount; i++)
            {
                //到时间就拷贝数据
                if (groups[index].dieTime < Time.time)
                {
                    groups[index].dieTime = Time.time + waterSetting.sustainTime;
                    groupBuffer.SetData(groups, index, index, 1);
                    index++;
                    index %= GroupCount;
                }
                else
                    break;
            }
        }

        public void ReCaculateCollsion()
        {
            collsionBuffer?.Release();
            if (this.collsions == null) this.collsions = new List<IGetCollsion>();
            List<CollsionStruct> collsions = new List<CollsionStruct>();
            for (int i = this.collsions.Count - 1; i >= 0; i--)
                if (this.collsions[i] == null) this.collsions.RemoveAt(i);
            for (int i = 0; i < this.collsions.Count; i++)
            {
                collsions.Add(this.collsions[i].GetCollsionStruct());
            }
            if (collsions.Count == 0)
            {
                collsions.Add(new CollsionStruct
                {
                    radius = 0,
                    center = Vector3.zero,
                    offset = Vector3.zero,
                    mode = 0
                });
            }
            collsionBuffer = new ComputeBuffer(collsions.Count,
                Marshal.SizeOf<CollsionStruct>());
            collsionBuffer.SetData(collsions, 0, 0, collsions.Count);
        }
        
    }
}