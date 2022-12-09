using UnityEngine;

namespace DefferedRender
{
    [CreateAssetMenu(menuName = "GPUDravin/Particle Node Data")]
    public class NoisePerNodeData : ScriptableObject
    {
        //λ�ó�ʼ��ģʽ
        public InitialShapeMode shapeMode = InitialShapeMode.Pos;
        //�ٶȳ�ʼ��ģʽ
        public SpeedMode speedMode = SpeedMode.JustBeginSpeed;
        //��Сģʽ
        public SizeBySpeedMode sizeBySpeedMode = SizeBySpeedMode.TIME;
        //�ٶ�ӳ�䷶Χ
        public Vector2 speedRange = Vector2.up;
        //��С��Χ
        public Vector2 sizeRange = Vector2.up;

        [Range(0.01f, 6.28f)]
        public float arc = 0.1f;              //�������ɷ�Χ
        public float radius = 1;           //Բ��С
        public Vector3 cubeRange = Vector3.one;          //���δ�С
        public Vector3 velocityBegin = Vector3.up;      //��ʼ�ٶ�
        public float releaseTime = 1;
        public float liveTime = 1;
        [Range(0, 1f)]
        public float collsionScale = 1;

        //����
        [Range(1, 8)]
        public int octave = 1;
        public float frequency = 1;
        [Min(0.1f)]
        public float intensity = 0.5f;
        public bool useGravity;     //��������

        [GradientUsage(true)]
        public Gradient gradient;
        public AnimationCurve size = AnimationCurve.Linear(0, 0, 1, 1);

        private Vector4[] colors;
        private Vector4[] alphas;
        private Vector4[] sizes;


        public Vector4[] GetColors()
        {
            if(colors == null)
            {
                colors = new Vector4[6];
                GradientColorKey[] colorKeys = gradient.colorKeys;
                int i = 0;
                for (; i< colorKeys.Length; i++)
                {
                    colors[i] = colorKeys[i].color;
                    colors[i].w = colorKeys[i].time;
                }
                for(; i<6; i++)
                    colors[i] = Vector4.one;
            }
            return colors;
        }

        public Vector4[] GetAlphas()
        {
            if(alphas == null)
            {
                alphas = new Vector4[6];
                GradientAlphaKey[] alphaKeys = gradient.alphaKeys;
                int i = 0;
                for(; i<alphaKeys.Length; i++)
                    alphas[i] = new Vector4(alphaKeys[i].alpha, alphaKeys[i].time);
                for(; i < 6; i++)
                    alphas[i] = Vector4.one;
            }
            return alphas;
        }

        public Vector4[] GetSizes()
        {
            if(sizes == null)
            {
                sizes = new Vector4[6];
                int i = 0;
                for(; i< size.length; i++)
                {
                    sizes[i] = new Vector4(size.keys[i].time, size.keys[i].value,
                        size.keys[i].inTangent, size.keys[i].outWeight);
                }
                for (; i < 6; i++)
                    sizes[i] = Vector4.one;
            }
            return sizes;
        }

        private void OnValidate()
        {
            colors = null;
            alphas = null;
            sizes = null;
        }

    }

}