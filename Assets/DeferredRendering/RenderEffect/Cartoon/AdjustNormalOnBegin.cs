using UnityEngine;

public class AdjustNormalOnBegin : MonoBehaviour
{
    private void Start()
    {
        SkinnedMeshRenderer skinnedMesh
            = GetComponent<SkinnedMeshRenderer>();
        if(skinnedMesh != null)
            PlugTangentTools.WirteAverageNormalToTangent(skinnedMesh.sharedMesh);
    }
}
