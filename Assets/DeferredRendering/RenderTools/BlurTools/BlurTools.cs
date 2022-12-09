using System.IO;
using UnityEngine;

namespace DefferedRender
{

    //模糊工具，对传入图片进行模糊
    public class BlurTools : MonoBehaviour
    {
        //原图片
        public Texture2D origin;
        //处理函数
        public ComputeShader compute;


        public RenderTexture target;

        public bool beginBlur, saveTarget;

        public int blurVerticalCount = 0;
        public int blurHorizontalCount = 0;
        

        private void OnValidate()
        {
            if (origin == null || compute == null) return;
            if (beginBlur)
            {
                int kernelVertical, kernelHorizontal, kernelCopy;
                kernelVertical = compute.FindKernel("BlurVertical");
                kernelHorizontal = compute.FindKernel("BlurHorizontal");
                kernelCopy = compute.FindKernel("Copy");

                //清除以及创建目标纹理
                if (target == null)
                    target = RenderTexture.GetTemporary(origin.width, origin.height, 0,
                        RenderTextureFormat.Default);
                if (target.width != origin.width || target.height != origin.height)
                {
                    RenderTexture.ReleaseTemporary(target);
                    target = RenderTexture.GetTemporary(origin.width, origin.height, 0,
                        RenderTextureFormat.Default);
                }
                target.enableRandomWrite = true;
                target.Create();

                RenderTexture temp = RenderTexture.GetTemporary(origin.width, origin.height,
                    0, RenderTextureFormat.Default);
                temp.enableRandomWrite = true;
                temp.Create();
                compute.SetTexture(kernelCopy, "_OriginTexture", origin);
                compute.SetTexture(kernelCopy, "_TargetTexture", temp);
                //大小只用设置一次
                compute.SetInts("_TextureSize", new int[] { origin.width, origin.height });
                compute.Dispatch(kernelCopy, origin.width / 32 + 1, origin.height / 32 + 1, 1);

                for (int i=0; i< blurHorizontalCount; i++)
                {
                    compute.SetTexture(kernelHorizontal, "_OriginTexture", temp);
                    compute.SetTexture(kernelHorizontal, "_TargetTexture", target);
                    compute.Dispatch(kernelHorizontal, origin.width / 32 + 1, origin.height / 32 + 1, 1);

                    //拷贝到临时纹理
                    compute.SetTexture(kernelCopy, "_OriginTexture", target);
                    compute.SetTexture(kernelCopy, "_TargetTexture", temp);
                    compute.Dispatch(kernelCopy, origin.width / 32 + 1, origin.height / 32 + 1, 1);
                }

                for(int i=0; i < blurVerticalCount; i++)
                {
                    compute.SetTexture(kernelVertical, "_OriginTexture", temp);
                    compute.SetTexture(kernelVertical, "_TargetTexture", target);
                    compute.Dispatch(kernelVertical, origin.width / 32 + 1, origin.height / 32 + 1, 1);

                    //拷贝到临时纹理
                    compute.SetTexture(kernelCopy, "_OriginTexture", target);
                    compute.SetTexture(kernelCopy, "_TargetTexture", temp);
                    compute.Dispatch(kernelCopy, origin.width / 32 + 1, origin.height / 32 + 1, 1);
                }
                RenderTexture.ReleaseTemporary(temp);

                beginBlur = false;
                Debug.Log("模糊完成");
            }

            if (saveTarget && target != null)
            {
                RenderTexture.active = target;

                Texture2D png = new Texture2D(target.width, target.height, 
                    TextureFormat.ARGB32, false);
                png.ReadPixels(new Rect(0, 0, target.width, target.height), 0, 0);
                byte[] bytes = png.EncodeToPNG();
                string path = string.Format("Assets/BlurTarget.png");
                FileStream fs = File.Open(path, FileMode.Create);
                BinaryWriter writer = new BinaryWriter(fs);
                writer.Write(bytes);
                writer.Flush();
                writer.Close();
                fs.Close();
                DestroyImmediate(png);
                saveTarget = false;
            }
        }

    }
}