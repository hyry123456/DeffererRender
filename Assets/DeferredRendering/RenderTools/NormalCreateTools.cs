using System.IO;
using UnityEngine;

namespace DefferedRender
{

    public class NormalCreateTools : MonoBehaviour
    {
        //原图片
        public Texture2D origin;
        //处理函数
        public ComputeShader compute;


        public RenderTexture target;

        public bool beginCreate, saveTarget;
        [Range(-3f, 3f)]
        public float _NormalScale = 1;

        private void OnValidate()
        {
            if (origin == null || compute == null) return;
            if (beginCreate)
            {
                int kernelNormalCreate, kernelCopy;
                kernelNormalCreate = compute.FindKernel("NormalCreate");

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
                //设置目标纹理可写
                target.enableRandomWrite = true;
                target.Create();

                compute.SetTexture(kernelNormalCreate, "_OriginTex", origin);
                compute.SetTexture(kernelNormalCreate, "Result", target);
                compute.SetFloat("_NormalScale", _NormalScale);
                compute.SetInts("_TextureCount", new int[2] { origin.width, origin.height });
                compute.Dispatch(kernelNormalCreate, origin.width / 32 + 1,
                    origin.height / 32 + 1, 1);
                beginCreate = false;
            }

            if (saveTarget && target != null)
            {
                RenderTexture.active = target;

                Texture2D png = new Texture2D(target.width, target.height,
                    TextureFormat.ARGB32, false);
                png.ReadPixels(new Rect(0, 0, target.width, target.height), 0, 0);
                byte[] bytes = png.EncodeToPNG();
                string path = string.Format("Assets/" + origin.name +"_Normal.png");
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