using UnityEngine;

namespace DefferedRender
{

    public class TextureArrayCreate
    {

        /// <summary>
        /// 该方法和Copy的作用一样，但是由于图像API底层的原因，对于引擎生成的图片使用Copy，
        /// 一般的纹理使用该方法拷贝
        /// </summary>
        public static Texture2DArray CreateTextureArrayBySet(Texture2D[] texture2D)
        {
            if (texture2D == null || texture2D.Length == 0) return null;
            for (int i = 1; i < texture2D.Length; i++)
            {
                if (texture2D[i].width != texture2D[i - 1].width)
                {
                    Debug.LogError("Use Texture Pixel None Equal");
                    return null;
                }
            }
            Texture2DArray texture2DArray = new Texture2DArray(texture2D[0].width, texture2D[0].height,
                texture2D.Length, TextureFormat.ARGB32, true, true);

            for (int i = 0; i < texture2D.Length; i++)
            {
                for (int j = 0; j < texture2DArray.mipmapCount; j++)
                {
                    texture2DArray.SetPixels(texture2D[i].GetPixels(j), i, j);
                }
            }
            texture2DArray.Apply();
            return texture2DArray;
        }

        public static Texture2D CreateTexture2D(int size, Color color)
        {
            Texture2D texture = new Texture2D(size, size, TextureFormat.RGBA32, true, true);
            Color[] colors = new Color[size * size];
            for (int i = 0; i < size * size; i++) colors[i] = color; 
            for(int i=0; i<texture.minimumMipmapLevel; i++)
            {
                texture.SetPixels(colors, i);
            }
            texture.Apply();
            return texture;
        }

    }
}