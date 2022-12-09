using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DefferedRender
{
    public class WaterWave : MonoBehaviour
    {
        public Texture2D origin;
        public RenderTexture prevRT;
        public RenderTexture currRT;
        public RenderTexture tempRT;
        public ComputeShader compute;

        public Material setMat;
        [Range(1, 100f)]
        public float frequency = 10;

        public void Start()
        {
            if (compute == null) return;
            prevRT = RenderTexture.GetTemporary(origin.width, origin.height, 0, RenderTextureFormat.RG32);
            currRT = RenderTexture.GetTemporary(origin.width, origin.height, 0, RenderTextureFormat.RG32);
            tempRT = RenderTexture.GetTemporary(origin.width, origin.height, 0, RenderTextureFormat.RG32);

            prevRT.enableRandomWrite = true; prevRT.Create();
            currRT.enableRandomWrite = true; currRT.Create();
            tempRT.enableRandomWrite = true; tempRT.Create();

            int kernel_Copy = compute.FindKernel("Copy");
            //拷贝到第一张贴图
            compute.SetTexture(kernel_Copy, "_OriginTexture", origin);
            compute.SetTexture(kernel_Copy, "_TargetTexture", prevRT);
            compute.SetInts("_TextureSize", new int[] { origin.width, origin.height });
            compute.Dispatch(kernel_Copy, origin.width / 32 + 1, origin.height / 32 + 1, 1);
            //拷贝到第二张贴图
            compute.SetTexture(kernel_Copy, "_OriginTexture", origin);
            compute.SetTexture(kernel_Copy, "_TargetTexture", currRT);
            compute.SetInts("_TextureSize", new int[] { origin.width, origin.height });
            compute.Dispatch(kernel_Copy, origin.width / 32 + 1, origin.height / 32 + 1, 1);

        }

        public bool beginWave;

        private void Update()
        {

            if (beginWave)
            {
                int kernel = compute.FindKernel("WaveWater");
                compute.SetTexture(kernel, "_TargetTexture", tempRT);
                compute.SetTexture(kernel, "_CurrenRT", currRT);
                compute.SetTexture(kernel, "_PrevRT", prevRT);
                compute.Dispatch(kernel, origin.width / 32 + 1, origin.height / 32 + 1, 1);

                int kernel_Copy = compute.FindKernel("Copy");
                //拷贝到第一张贴图
                compute.SetTexture(kernel_Copy, "_OriginTexture", tempRT);
                compute.SetTexture(kernel_Copy, "_TargetTexture", prevRT);
                compute.SetInts("_TextureSize", new int[] { origin.width, origin.height });
                compute.Dispatch(kernel_Copy, origin.width / 32 + 1, origin.height / 32 + 1, 1);

                RenderTexture rt = prevRT;
                prevRT = currRT;
                currRT = rt;
                //beginWave = false;
            }
            setMat.SetTexture("_WaterNormal", currRT);

        }


        private void FixedUpdate()
        {
            if (beginWave)
            {
                DrawWave();
            }
        }

        public void DrawWave()
        {
            //绘制波动
            int kernel_CreateWave = compute.FindKernel("CreateWave");
            compute.SetTexture(kernel_CreateWave, "_TargetTexture", currRT);
            compute.SetInts("_TextureSize", new int[] { origin.width, origin.height });
            compute.SetFloats("_Frequency", new float[] { frequency, Time.time * frequency });
            compute.Dispatch(kernel_CreateWave, origin.width / 32 + 1, origin.height / 32 + 1, 1);
        }

        private void OnDestroy()
        {
            if(prevRT != null)
            {
                RenderTexture.ReleaseTemporary(prevRT);
                RenderTexture.ReleaseTemporary(currRT);
                RenderTexture.ReleaseTemporary(tempRT);
                prevRT = null;
            }
            

        }


    }
}