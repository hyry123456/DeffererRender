using System.IO;
using UnityEngine;
using System.Collections.Generic;

namespace DefferedRender {

    public enum RampSize
    {
        _32 = 32,
        _64 = 64,
        _128 = 128,
        _256 = 256,
        _512 = 512,
    }

    [System.Serializable]
    public enum RampMode
    {
        LerpUp_Down = 0,    //上下Lerp
        DotUp = 1,       //对下面逐渐模糊
    }

    /// <summary>/// Ramp贴图生成/// </summary>
    public class RampMapCreate : MonoBehaviour
    {
        //ramp贴图的上面
        public Gradient upGradient;
        //ramp贴图的下面
        public Gradient downGradient;
        //混合曲线
        public AnimationCurve lerpCurve = AnimationCurve.Linear(0, 0, 1, 1);
        //生成的Shader
        public ComputeShader rampCreateCS;

        public RampSize rampSize = RampSize._64;

        public RenderTexture target;
        public bool save = false;
        public bool upToDown, downToUp;
        public RampMode rampMode = RampMode.LerpUp_Down;

        public List<Vector2> center = new List<Vector2>();
        public bool createCenterPos;

        public Material setMat;

        private void OnValidate()
        {
            if (createCenterPos)
            {
                createCenterPos = false;
                center.Clear();
                var colorKeys = upGradient.colorKeys;
                for (int i = 1; i < colorKeys.Length; i++) 
                {
                    center.Add(new Vector2(colorKeys[i - 1].time + (colorKeys[i].time -
                        colorKeys[i - 1].time) * 0.5f, 0));
                }
            }
            ClampKey();
            if (upToDown)
            {
                downGradient.colorKeys = upGradient.colorKeys;
                upToDown = false;
            }
            if (downToUp)
            {
                downToUp = false;
                upGradient.colorKeys = downGradient.colorKeys;
            }
            int size = (int)rampSize;

            if (rampCreateCS != null)
            {
                if(target != null)
                    RenderTexture.ReleaseTemporary(target);
                target = RenderTexture.GetTemporary(size, size,
                    0, RenderTextureFormat.ARGB64);
                target.enableRandomWrite = true;
                target.Create();
                Vector4[] up = RenderMethods.GetGradientColors(upGradient, 16);
                Vector4[] down = RenderMethods.GetGradientColors(downGradient, 16);
                Vector4[] lerp = RenderMethods.GetCurveArray(lerpCurve, 16);
                rampCreateCS.SetVectorArray("_UpColors", up);
                rampCreateCS.SetVectorArray("_DownColors", down);
                rampCreateCS.SetVectorArray("_LerpSizes", lerp);

                switch (rampMode)
                {
                    case RampMode.LerpUp_Down:
                        LerpUp_Down();
                        break;
                    case RampMode.DotUp:
                        BlurDown();
                        break;
                }
            }
            if (save)
            {
                save = false;
                RenderTexture temp = RenderTexture.GetTemporary(size,
                    size, 0, RenderTextureFormat.ARGB32);
                Graphics.Blit(target, temp);
                RenderTexture.active = temp;

                Texture2D png = new Texture2D(target.width, target.height,
                    TextureFormat.ARGB32, false);
                png.ReadPixels(new Rect(0, 0, target.width, target.height), 0, 0);
                byte[] bytes = png.EncodeToPNG();
                string path = string.Format("Assets/Ramp.png");
                FileStream fs = File.Open(path, FileMode.Create);
                BinaryWriter writer = new BinaryWriter(fs);
                writer.Write(bytes);
                writer.Flush();
                writer.Close();
                fs.Close();
                DestroyImmediate(png);
                RenderTexture.ReleaseTemporary(temp);
            }

            if(setMat != null)
            {
                setMat.SetTexture("_DiffuseRamp", target);
            }
        }

        private void LerpUp_Down()
        {
            int size = (int)rampSize;
            rampCreateCS.SetTexture((int)rampMode, "Result", target);
            rampCreateCS.Dispatch((int)rampMode, size / 32 + 1, size / 32 + 1, 1);
        }

        private void ClampKey()
        {
            var colorKeys = upGradient.colorKeys;
            if (center.Count != colorKeys.Length - 1) return;
            for(int i = 1; i < colorKeys.Length; i++)
            {
                Vector2 vector2 = center[i - 1];
                vector2.x = Mathf.Clamp(vector2.x, 
                    colorKeys[i - 1].time, colorKeys[i].time);
                vector2.y = Mathf.Clamp(vector2.y, 0, (colorKeys[i].time - vector2.x) * 2);
                center[i - 1] = vector2;
            }
        }

        private void BlurDown()
        {
            int size = (int)rampSize;
            rampCreateCS.SetTexture((int)rampMode, "Result", target);
            Vector4[] set = new Vector4[16];
            int i = 0;
            for (; i < center.Count; i++)
                set[i] = new Vector4(center[i].x, center[i].y);
            for (; i < 16; i++)
                set[i] = new Vector4(1, 0);
            rampCreateCS.SetVectorArray("_Poss", set);
            rampCreateCS.Dispatch((int)rampMode, size / 32 + 1, size / 32 + 1, 1);
        }


    }
}