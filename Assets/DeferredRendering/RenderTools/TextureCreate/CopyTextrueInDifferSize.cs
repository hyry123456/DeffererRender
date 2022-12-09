using System.IO;
using UnityEngine;

namespace DefferedRender
{
    /// <summary> /// 拷贝纹理到不同大小的工具类 /// </summary>
    public class CopyTextrueInDifferSize : MonoBehaviour
    {
        //拷贝到的大小
        public int width = 1, height = 1;
        public Texture2D origin;
        public RenderTexture target;
        public bool beginCopy = false,
            save = false;

        private void OnValidate()
        {
            if (beginCopy)
            {
                if(target == null)
                {
                    target = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGB32);
                }
                if(target.width != width || target.height != height)
                {
                    RenderTexture.ReleaseTemporary(target);
                    target = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGB32);
                }

                Graphics.Blit(origin, target);
                beginCopy = false;
            }
            if (save)
            {
                RenderTexture.active = target;

                Texture2D png = new Texture2D(target.width, target.height,
                    TextureFormat.ARGB32, false);
                png.ReadPixels(new Rect(0, 0, target.width, target.height), 0, 0);
                byte[] bytes = png.EncodeToPNG();
                string path = string.Format("Assets/CopyTarget.png");
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