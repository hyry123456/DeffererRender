using UnityEngine;

namespace DefferedRender
{
    [System.Serializable]
	public struct ClusterLightSetting
	{
		public ComputeShader clusterLightCS;
		public Vector3Int clusterCount;           //ZÖáµÄÇĞ¸î´ÎÊı
		public bool isUse;
	}
}