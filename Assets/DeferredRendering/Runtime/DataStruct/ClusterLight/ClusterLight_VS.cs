using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{

	struct ClusterData
	{
		public Vector3 p0, p1, p2, p3, p4, p5, p6, p7;
	}

    /// <summary>/// �ӽǿռ�ȷ���ƹ�ü�Cluster /// </summary>
    [ExecuteInEditMode]
	public class ClusterLight_VS : MonoBehaviour
	{
		private ComputeBuffer clusterBuffer;
		private ComputeBuffer clusterCountBuffer;
		private ComputeBuffer clusterArrayBuffer;
		Matrix4x4 viewFrustumCorners;
		int readyKernel;


		private static ClusterLight_VS instance;
        public static ClusterLight_VS Instance
        {
            get
            {
                if (instance == null)
                {
					GameObject game = new GameObject("ClusterLight");
					game.AddComponent<ClusterLight_VS>();
					game.hideFlags = HideFlags.HideAndDontSave;
                }
                return instance;
            }
        }

        int viewFrustumCornersId = Shader.PropertyToID("_ViewFrustumCorners"),
			cl_CountXId = Shader.PropertyToID("_CL_CountX"),
			cl_CountYId = Shader.PropertyToID("_CL_CountY"),
			cl_CountZId = Shader.PropertyToID("_CL_CountZ"),
			clusterBufferId = Shader.PropertyToID("_ClusterDataBuffer"),
			clusterCountBufferId = Shader.PropertyToID("_ClusterCountBuffer"),
			clusterArrayBufferId = Shader.PropertyToID("_ClusterArrayBuffer"),
			viewToWorldMatrixId = Shader.PropertyToID("_ViewToWorldMat");

        private void Awake()
        {
            if(instance != null)
            {
				DestroyImmediate(this);
				return;
            }
			instance = this;
        }

		private ClusterLight_VS() { }

        public void ComputeLightCluster(CommandBuffer buffer,
			ClusterLightSetting clusterLight, Camera camera, int depthId)
		{
			ComputeShader createClusterCS = clusterLight.clusterLightCS;
			Vector3Int clusterCount = clusterLight.clusterCount;
			int bufferSize = clusterCount.x * clusterCount.y * clusterCount.z;
			int groupCount = Mathf.CeilToInt(bufferSize / 1024.0f);
			int xyCount = Mathf.CeilToInt(clusterCount.x * clusterCount.y / 1024.0f);

			buffer.SetGlobalInt(cl_CountXId, clusterCount.x);
			buffer.SetGlobalInt(cl_CountYId, clusterCount.y);
			buffer.SetGlobalInt(cl_CountZId, clusterCount.z);

			//���¼���ƹ�ü���������ü�����ֻ��ʶ���������ǰ������ͬ�ڵ�ǰ�����������
			if (clusterBuffer == null || clusterBuffer.count != bufferSize)
			{
				//��һ��4ά�������洢�Ǹ������ֵ
				viewFrustumCorners = Matrix4x4.identity;
				readyKernel = createClusterCS.FindKernel("ReadyLight");

				//������������Ϣ�����ں������
				float fov = camera.fieldOfView;
				float near = camera.nearClipPlane;
				float aspect = camera.aspect;

				//������Ǽ���4�����򣬾���ȥ���ɵ���Чʵ�֣������о�������
				float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
				Vector3 toRight = Vector3.right * halfHeight * aspect;
				Vector3 toTop = Vector3.up * halfHeight;

				Vector3 topLeft = Vector3.forward * near + toTop - toRight;
				float scale = topLeft.magnitude / near;

				topLeft.Normalize();
				topLeft *= scale;

				Vector3 topRight = Vector3.forward * near + toRight + toTop;
				topRight.Normalize();
				topRight *= scale;

				Vector3 bottomLeft = Vector3.forward * near - toTop - toRight;
				bottomLeft.Normalize();
				bottomLeft *= scale;

				Vector3 bottomRight = Vector3.forward * near + toRight - toTop;
				bottomRight.Normalize();
				bottomRight *= scale;

				viewFrustumCorners.SetRow(0, bottomLeft * camera.farClipPlane);
				viewFrustumCorners.SetRow(1, bottomRight * camera.farClipPlane);
				viewFrustumCorners.SetRow(2, topRight * camera.farClipPlane);
				viewFrustumCorners.SetRow(3, topLeft * camera.farClipPlane);


				int kernel = createClusterCS.FindKernel("CSMain");

				clusterBuffer?.Release();
				clusterBuffer = new ComputeBuffer(bufferSize, Marshal.SizeOf(typeof(ClusterData)));

				buffer.SetGlobalMatrix(viewFrustumCornersId, viewFrustumCorners);

				buffer.SetComputeBufferParam(createClusterCS, kernel, clusterBufferId, clusterBuffer);
                buffer.DispatchCompute(createClusterCS, kernel, groupCount, 1, 1);

                clusterCountBuffer?.Release();
				clusterCountBuffer = new ComputeBuffer(bufferSize, sizeof(int));
				clusterArrayBuffer?.Release();
				clusterArrayBuffer = new ComputeBuffer(bufferSize, sizeof(int) * 64);
			}

			buffer.SetComputeTextureParam(createClusterCS, readyKernel, depthId, depthId);

			buffer.SetComputeBufferParam(createClusterCS, readyKernel, clusterBufferId, clusterBuffer);
			buffer.SetComputeBufferParam(createClusterCS, readyKernel, clusterCountBufferId, clusterCountBuffer);
			buffer.SetComputeBufferParam(createClusterCS, readyKernel, clusterArrayBufferId, clusterArrayBuffer);
			buffer.SetComputeMatrixParam(createClusterCS, viewToWorldMatrixId, camera.transform.localToWorldMatrix);
			buffer.SetComputeFloatParam(createClusterCS, "_FarDistance", camera.farClipPlane);
            //buffer.DispatchCompute(createClusterCS, readyKernel, groupCount, 1, 1);
            buffer.DispatchCompute(createClusterCS, readyKernel, xyCount, 1, 1);

            buffer.SetGlobalBuffer(clusterCountBufferId, clusterCountBuffer);
			buffer.SetGlobalBuffer(clusterArrayBufferId, clusterArrayBuffer);
		}

        private void OnDisable()
        {
			clusterBuffer?.Release();
			clusterCountBuffer?.Release();
			clusterArrayBuffer?.Release();
		}

    }
}