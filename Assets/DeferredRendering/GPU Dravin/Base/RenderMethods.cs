
using UnityEngine;

namespace DefferedRender
{

    /// <summary>  /// ��̬�࣬��װ��Ⱦ�е�ͨ�÷���  /// </summary>
    public static class RenderMethods
    {
        /// <summary>    /// ���ݶ����������ɼ�������    /// </summary>
        /// <param name="curve">��������</param>
        /// <param name="maxSize">��ֵ���ֵ</param>
        /// <returns>�������</returns>
        public static Vector4[] GetCurveArray(AnimationCurve curve, int maxSize)
        {
            Vector4[] re = new Vector4[maxSize];
            int i = 0;
            for (; i < curve.length; i++)
            {
                re[i] = new Vector4(curve.keys[i].time,
                    curve.keys[i].value, curve.keys[i].inTangent,
                    curve.keys[i].outWeight);
            }
            for (; i < maxSize; i++)
                re[i] = Vector4.one;
            return re;
        }

        /// <summary>/// ����Gradient����͸���ȼ�������  /// </summary>
        /// <param name="gradient">��ɫ����</param>
        /// <param name="maxSize">��������С</param>
        /// <returns>��������</returns>
        public static Vector4[] GetGradientAlphas(Gradient gradient, int maxSize)
        {
           Vector4[] re = new Vector4[maxSize];
            GradientAlphaKey[] alphaKeys = gradient.alphaKeys;
            int i = 0;
            for (; i < alphaKeys.Length; i++)
                re[i] = new Vector4(alphaKeys[i].alpha, alphaKeys[i].time);
            for (; i < maxSize; i++)
                re[i] = Vector4.one;
            return re;
        }

        /// <summary>/// ����Gradient������ɫ��������  /// </summary>
        /// <param name="gradient">��ɫ����</param>
        /// <param name="maxSize">��������С</param>
        /// <returns>��������</returns>
        public static Vector4[] GetGradientColors(Gradient gradient, int maxSize)
        {
            Vector4[] re = new Vector4[maxSize];
            GradientColorKey[] colorKeys = gradient.colorKeys;
            int i = 0;
            for (; i < colorKeys.Length; i++)
            {
                re[i] = colorKeys[i].color;
                re[i].w = colorKeys[i].time;
            }
            for (; i < maxSize; i++)
                re[i] = Vector4.one;
            return re;
        }
    }
}