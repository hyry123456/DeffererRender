using UnityEngine;

namespace DefferedRender
{
    [System.Serializable]
	public struct ClusterLightSetting
	{
		public ComputeShader clusterLightCS;
		public Vector3Int clusterCount;           //Z����и����
		public bool isUse;
	}
}