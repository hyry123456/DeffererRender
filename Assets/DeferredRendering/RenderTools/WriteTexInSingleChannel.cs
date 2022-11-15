using System.IO;
using UnityEngine;

namespace DefferedRender
{
    //用来选择根据的轴
    enum ChoseColor
    {
        R,G,B,A,Grey
    }
    //用来选择写入的通道
    enum WriteInChannel
    {
        R,G,B,A
    }

    /// <summary>
    /// 用来将根据图片的颜色值写入目标纹理的某一个通道的工具类,
    /// 前提是图片大小是一致的，不一致就用拷贝工具进行复制
    /// </summary>
    public class WriteTexInSingleChannel : MonoBehaviour
    {
        public Texture2D origin;
        public RenderTexture target;

        //选择原图片的颜色
        [SerializeField]
        ChoseColor originCol;
        //写入的通道
        [SerializeField]
        WriteInChannel writeChannel;

        public bool beginWrite, save;
        public ComputeShader compute;


        private void OnValidate()
        {
            if (compute == null) return;
            if (beginWrite)
            {
                if (target == null)
                    target = RenderTexture.GetTemporary(origin.width,
                        origin.height, 0, RenderTextureFormat.ARGB32);
                if (target.width != origin.width || target.height != origin.height)
                    target = RenderTexture.GetTemporary(origin.width,
                        origin.height, 0, RenderTextureFormat.ARGB32);
                
                target.enableRandomWrite = true;
                target.Create();

                int kernel_WriteChannel = compute.FindKernel("WriteInChannel");
                compute.SetTexture(kernel_WriteChannel, "Result", target);
                compute.SetTexture(kernel_WriteChannel, "_Origin", origin);
                compute.SetInts("_TextureSizes", new int[] { origin.width, origin.height });
                compute.SetInts("_Mode", new int[] { (int)originCol, (int)writeChannel });
                compute.Dispatch(kernel_WriteChannel, 
                    origin.width / 32 + 1, origin.height / 32 + 1, 1);
                beginWrite = false;
            }

            if (save)
            {
                RenderTexture.active = target;

                Texture2D png = new Texture2D(target.width, target.height,
                    TextureFormat.ARGB32, false);
                png.ReadPixels(new Rect(0, 0, target.width, target.height), 0, 0);
                byte[] bytes = png.EncodeToPNG();
                string path = string.Format("Assets/WriteChannel.png");
                FileStream fs = File.Open(path, FileMode.Create);
                BinaryWriter writer = new BinaryWriter(fs);
                writer.Write(bytes);
                writer.Flush();
                writer.Close();
                fs.Close();
                DestroyImmediate(png);
                save = false;
            }
        }

    }
}