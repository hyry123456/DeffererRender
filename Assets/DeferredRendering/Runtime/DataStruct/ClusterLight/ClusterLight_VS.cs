using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{

	struct ClusterData
	{
		public Vector3 p0, p1, p2, p3, p4, p5, p6, p7;
	}

    [ExecuteInEditMode]
    /// <summary>/// �ӽǿռ�ȷ���ƹ�ü�Cluster /// </summary>
	public class ClusterLight_VS
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
				if(instance == null)
                {
					instance = new ClusterLight_VS();
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


		Camera preCamera;
		Vector3 leftPoint;
		public void ComputeLightCluster(CommandBuffer buffer,
			ClusterLightSetting clusterLight, Camera camera, int depthId,
			int width, int height, bool isDebug)
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
			if (clusterBuffer == null || clusterBuffer.count != bufferSize
				|| preCamera != camera)
			{
				preCamera = camera;
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

			int kernel2 = (isDebug) ? readyKernel + 1 : readyKernel;

            if (isDebug)
            {
				buffer.GetTemporaryRT(debugTex, width, height, 0, FilterMode.Bilinear,
					RenderTextureFormat.Default, RenderTextureReadWrite.Linear, 1,
					true);
				buffer.SetRenderTarget(debugTex);
				ComputeShader compute = clusterLight.clusterLightCS;
				buffer.SetComputeIntParams(compute, "_Pixel_Count", new int[] { width, height });
                buffer.SetComputeTextureParam(compute, kernel2, "Result", debugTex);
            }

			buffer.SetComputeTextureParam(createClusterCS, kernel2, depthId, depthId);
			buffer.SetComputeBufferParam(createClusterCS, kernel2, clusterBufferId, clusterBuffer);
			buffer.SetComputeBufferParam(createClusterCS, kernel2, clusterCountBufferId, clusterCountBuffer);
			buffer.SetComputeBufferParam(createClusterCS, kernel2, clusterArrayBufferId, clusterArrayBuffer);
			buffer.SetComputeMatrixParam(createClusterCS, viewToWorldMatrixId, camera.transform.localToWorldMatrix);
            buffer.DispatchCompute(createClusterCS, kernel2, xyCount, 1, 1);

            buffer.SetGlobalBuffer(clusterCountBufferId, clusterCountBuffer);
			buffer.SetGlobalBuffer(clusterArrayBufferId, clusterArrayBuffer);



			buffer.ReleaseTemporaryRT(debugTex);
		}


#if UNITY_EDITOR
		ClusterData[] clusters;
		int[] counts;

		int debugTex = Shader.PropertyToID("ClusterTex");

		public void DrawCluster(int lightCount, CommandBuffer buffer, 
			ScriptableRenderContext context, int width, int height,
			ClusterLightSetting clusterLight)
        {
			if (clusterBuffer == null) return;
			if(clusters == null || clusters.Length != clusterBuffer.count)
            {
				clusters = new ClusterData[clusterBuffer.count];
				counts = new int[clusterBuffer.count];
			}
			clusterBuffer.GetData(clusters);
			clusterCountBuffer.GetData(counts);
			for(int i=0; i< clusters.Length; i++)
            {
				ClusterData cluster = clusters[i];
				cluster.p0 = Camera.main.transform.localToWorldMatrix.MultiplyPoint3x4(cluster.p0);
				cluster.p1 = Camera.main.transform.localToWorldMatrix.MultiplyPoint3x4(cluster.p1);
				cluster.p2 = Camera.main.transform.localToWorldMatrix.MultiplyPoint3x4(cluster.p2);
				cluster.p3 = Camera.main.transform.localToWorldMatrix.MultiplyPoint3x4(cluster.p3);
				cluster.p4 = Camera.main.transform.localToWorldMatrix.MultiplyPoint3x4(cluster.p4);
				cluster.p5 = Camera.main.transform.localToWorldMatrix.MultiplyPoint3x4(cluster.p5);
				cluster.p6 = Camera.main.transform.localToWorldMatrix.MultiplyPoint3x4(cluster.p6);
				cluster.p7 = Camera.main.transform.localToWorldMatrix.MultiplyPoint3x4(cluster.p7);
				//Color color = Color.white * counts[i] / lightCount;
				//color = Color.white;
				Color color = counts[i] > 0 ? Color.red : Color.white;
                if (counts[i] == 0) continue;

                Debug.DrawLine(cluster.p0, cluster.p1, color);
                Debug.DrawLine(cluster.p1, cluster.p2, color);
                Debug.DrawLine(cluster.p2, cluster.p3, color);
                Debug.DrawLine(cluster.p3, cluster.p0, color);
                Debug.DrawLine(cluster.p4, cluster.p5, color);
                Debug.DrawLine(cluster.p5, cluster.p6, color);
                Debug.DrawLine(cluster.p6, cluster.p7, color);
                Debug.DrawLine(cluster.p7, cluster.p4, color);
            }


			//buffer.GetTemporaryRT(debugTex, width, height, 0, FilterMode.Bilinear,
			//	RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear, 1,
			//	true);
			//buffer.SetRenderTarget(debugTex);
			//ComputeShader compute = clusterLight.clusterLightCS;
			//int kernel = compute.FindKernel("DebugDraw");
			//buffer.SetComputeTextureParam(compute, kernel, debugTex,
			//	debugTex);
			//buffer.SetComputeIntParams(compute, "_Pixel_Count", new int[] { width, height });
			//buffer.SetComputeTextureParam(compute, kernel, "Result", debugTex);
			//Vector3 clusterCount = clusterLight.clusterCount;
			//int xyCount = Mathf.CeilToInt(clusterCount.x * clusterCount.y / 1024.0f);
			//buffer.DispatchCompute(compute, kernel, xyCount, 1, 1);
			//buffer.ReleaseTemporaryRT(debugTex);
			//context.ExecuteCommandBuffer(buffer);
			//buffer.Clear();
		}
#endif

	}
}