using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

namespace DefferedRender
{
    [System.Serializable]
    struct ThunderNode
    {
        public Vector2 begin;
        public Vector2 end;
        public float radio;

    };

    public class Thunder : MonoBehaviour
    {
        [SerializeField]
        List<ThunderNode> thunderNodes;

        public int textureSize = 256;
        public RenderTexture renderTexture;
        public ComputeShader compute;
        ComputeBuffer buffer;
        int kernel_Thunder, kernel_BilateralFilter;
        public MeshRenderer thunderRender;
        [Range(0, 1)]
        public float bilaterFilterFactor = 0.7f;
        [Range(0, 5)]
        public int blurRadius = 1;

        //��ǰ�ȴ�ʱ��
        float currentTime;
        [Range(0.0001f, 5)]
        public float maxWaitTime = 3;      //���ȴ�ʱ��
        [Range(0.0001f, 1f)]
        public float maxLuminanceSusTime = 0.3f;    //������ȳ���ʱ��
        float waitTime;             //��εĵȴ�ʱ��
        [Min(0.0001f)]
        public float thunderSustainTime = 0.8f;

        private Material setMat;

        private ThunderNode origin = new ThunderNode()
        {
            begin = Vector2.zero,
            end = Vector2.right * 0.8f,
            radio = 1.0f
        };

        private void Start()
        {
            thunderNodes = new List<ThunderNode>();
            renderTexture = 
                RenderTexture.GetTemporary(textureSize, textureSize, 0, RenderTextureFormat.R16);
            renderTexture.enableRandomWrite = true;
            renderTexture.Create();
            buffer = new ComputeBuffer(81, Marshal.SizeOf<ThunderNode>());
            kernel_Thunder = compute.FindKernel("Thunder");
            kernel_BilateralFilter = compute.FindKernel("BilateralFilter");
            setMat = thunderRender.material;
            setMat.SetTexture("_MainTex", renderTexture);

            currentTime = 0; waitTime = maxWaitTime;
            Common.SustainCoroutine.Instance.AddCoroutine(WaitThunder);
        }

        //private void OnValidate()
        //{
        //    if (add)
        //    {
        //        CreateThunder();
        //        add = false;
        //    }
        //}


        private void CreateTexture()
        {
            buffer.SetData(thunderNodes, 0, 0, 81);
            compute.SetTexture(kernel_Thunder, "Result", renderTexture);
            compute.SetBuffer(kernel_Thunder, "_ThundersBuffer", buffer);
            compute.SetInt("_TextureSizes", textureSize);
            compute.Dispatch(kernel_Thunder, 1, 1, 1);

            compute.SetTexture(kernel_BilateralFilter, "Result", renderTexture);
            compute.SetFloat("_BilaterFilterFactor", bilaterFilterFactor);
            compute.SetInts("_BlurRadius", new int[] { blurRadius, 0 });
            compute.Dispatch(kernel_BilateralFilter, textureSize / 32 + 1, textureSize / 32 + 1, 1);
            compute.SetInts("_BlurRadius", new int[] { 0, blurRadius });
            compute.Dispatch(kernel_BilateralFilter, textureSize / 32 + 1, textureSize / 32 + 1, 1);

        }

        private void OnDestroy()
        {
            RenderTexture.ReleaseTemporary(renderTexture);
            buffer.Release();
        }



        /// <summary>  /// �ȴ�����   /// </summary>
        private bool WaitThunder()
        {
            currentTime += Time.deltaTime;
            if(currentTime > waitTime)
            {
                ReadyCreateThunder();
                //����һ���µ�����
                Common.SustainCoroutine.Instance.AddCoroutine(CereateThunderNode);
                return true;
            }
            return false;
        }
        /// <summary>  /// ��������ǰ��ǰ��׼��   /// </summary>
        private void ReadyCreateThunder()
        {
            //�������
            Graphics.Blit(Texture2D.blackTexture, renderTexture);
            thunderNodes.Clear();       //��յ�ǰ����
            origin.end = Vector2.right * 0.8f + Vector2.up * Random.Range(-0.3f, 0.3f);
            origin.begin = Vector2.up * Random.Range(-0.5f, 0.5f);
            thunderNodes.Add(origin);
        }

        /// <summary>  /// ����ȫ��������ڵ㣬�Լ���������   /// </summary>
        private bool CereateThunderNode()
        {
            int size = thunderNodes.Count;
            if (size == 81)
            {
                CreateTexture();        //��������
                thunderRender.enabled = true;   //��������
                currentTime = 0;
                Common.SustainCoroutine.Instance.AddCoroutine(ShowThunder); //��ʾ����
                return true;
            }
            for (int i = 0; i < size; i++)
            {
                ThunderNode node = thunderNodes[0];
                thunderNodes.RemoveAt(0);
                Vector3 center = (node.end + node.begin) / 2.0f;
                float dis = (node.begin - node.end).magnitude;
                center += Vector3.up * Random.Range(-1.0f, 1.0f) * dis * 0.2f;
                ThunderNode new1 = new ThunderNode()
                {
                    begin = node.begin,
                    end = center,
                    radio = node.radio
                };
                ThunderNode new2 = new ThunderNode()
                {
                    begin = center,
                    end = node.end,
                    radio = node.radio,
                };
                Vector2 direction = (Vector2)center - node.begin;
                direction.Normalize();
                if (node.end.y - center.y < 0)
                    direction.y = Mathf.Abs(direction.y);
                else
                    direction.y = -Mathf.Abs(direction.y);
                dis = (Vector3.right - center).magnitude;
                ThunderNode new3 = new ThunderNode()
                {
                    begin = center,
                    end = direction * 0.7f * dis + (Vector2)center,
                    radio = node.radio * 0.4f,
                };

                thunderNodes.Add(new1);
                thunderNodes.Add(new2);
                thunderNodes.Add(new3);

            }
            return false;
        }

        /// <summary>   /// ����ѭ������������ʾ    /// </summary>
        private bool ShowThunder()
        {
            currentTime += Time.deltaTime;
            float midTime = thunderSustainTime / 2.0f;
            if(currentTime < midTime)   //��ʾ�׶�
            {
                setMat.SetFloat("_Cutoff", Mathf.Lerp(0.6f, 0, currentTime / midTime));
            }
            else if(currentTime < thunderSustainTime + maxLuminanceSusTime)   //��ʧ�׶�
            {
                setMat.SetFloat("_Cutoff", Mathf.Lerp(0f, 0.6f, 
                    (currentTime - midTime - maxLuminanceSusTime) / midTime));
            }
            else        //ֹͣ�׶�
            {
                thunderRender.enabled = false;
                currentTime = 0;
                waitTime = maxWaitTime * Random.Range(0.5f, 1.0f);
                Common.SustainCoroutine.Instance.AddCoroutine(WaitThunder);
                return true;
            }
            return false;
        }


    }
}