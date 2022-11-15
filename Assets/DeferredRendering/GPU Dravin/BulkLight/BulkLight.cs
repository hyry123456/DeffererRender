using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    public struct BulkLightStruct
    {
        public Vector3 boundMax;
        public Vector3 boundMin;
        public Vector4 lightIndex;
    };

    [ExecuteInEditMode]
    /// <summary> 
    /// 绘制非视角空间体积光用到的类，将所有的Cluster数据传入，进行体积光绘制
    /// </summary>
    public class BulkLight : MonoBehaviour
    {
        private static BulkLight instance;
        public static BulkLight Instance
        {
            get 
            {
                if(instance == null)
                {
                    GameObject game = new GameObject("BulkLight");
                    game.AddComponent<BulkLight>();
                    game.hideFlags = HideFlags.HideAndDontSave;
                }
                return instance;
            }
        }

        List<BulkLightStruct> drawing 
            = new List<BulkLightStruct>();

        List<BulkLightStruct> waiting
            = new List<BulkLightStruct>();

        List<BulkLightStruct> waitRemove
            = new List<BulkLightStruct>();

        ComputeBuffer boxsBuffer;
        BulkLightAssets lightAssets;
        int kernel;

        //public int boxCount;

        private void Awake()
        {
            if(instance != null)
            {
                DestroyImmediate(gameObject);
                return;
            }

            instance = this;
            lightAssets = Resources.Load<BulkLightAssets>
                ("Render/BulkLight/Bulk Light");
            kernel = lightAssets.compute.FindKernel("CaculateBulkBox");
        }

        private void OnDestroy()
        {
            boxsBuffer?.Release();
            boxsBuffer = null;
            waiting.Clear();
            drawing.Clear();
            instance = null;
        }

        public void AddBulkLightBox(BulkLightStruct bulkLight)
        {
            if(waiting.Count == 0)
            {
                Common.SustainCoroutine.Instance.AddCoroutine(RecaculateBulkLight);
                waiting.Add(bulkLight);
            }
            else
            {
                waiting.Add(bulkLight);
            }

        }

        private bool RecaculateBulkLight()
        {
            if(boxsBuffer == null)
            {
                boxsBuffer = new ComputeBuffer(drawing.Count + waiting.Count,
                    Marshal.SizeOf(new BulkLightStruct()));
                return false;
            }

            if (boxsBuffer.count != drawing.Count + waiting.Count)
            {
                boxsBuffer.Release();
                return false;
            }

            drawing.AddRange(waiting);
            waiting.Clear();
            boxsBuffer.SetData(drawing.ToArray(), 0, 0, boxsBuffer.count);
            //BulkLightStruct[] bulkLights = new BulkLightStruct[1];
            //boxsBuffer.GetData(bulkLights);
            return true;
        }

        public void DrawBulkLight( CommandBuffer buffer)
        {
            if (boxsBuffer == null || lightAssets == null) return;
            //设置数据
            buffer.SetComputeBufferParam(lightAssets.compute,
                kernel, "_ClusterDataBuffer", boxsBuffer);
            buffer.SetComputeIntParam(lightAssets.compute, "_BoxCount", boxsBuffer.count);
            //计算数据
            buffer.DispatchCompute(lightAssets.compute, kernel,
               boxsBuffer.count / 64 + 1, 1, 1);

            buffer.SetGlobalBuffer("_ClusterDataBuffer", boxsBuffer);

            buffer.DrawProcedural(Matrix4x4.identity, lightAssets.material,
                0, MeshTopology.Points, 1, boxsBuffer.count);
            //boxCount = boxsBuffer.count;
        }


    }
}