using System.Collections.Generic;
using UnityEngine;

namespace DefferedRender
{

    public class SetDefaultMaterial : MonoBehaviour
    {
        public Shader defaultShader;
        [Range(0, 1)]
        public float metallic = 0.5f;
        [Range(0, 1)]
        public float roughness = 0.5f;
        public bool begin;

        private void OnValidate()
        {
            if (defaultShader == null) return;

            Queue<Transform> queue = new Queue<Transform>();
            queue.Enqueue(transform);
            while(queue.Count > 0)
            {
                Transform tran = queue.Dequeue();
                MeshRenderer meshRenderer = tran.gameObject.GetComponent<MeshRenderer>();
                if(meshRenderer != null)
                {
                    if(meshRenderer.sharedMaterial.shader != defaultShader)
                        meshRenderer.sharedMaterial.shader = defaultShader;
                    meshRenderer.sharedMaterial.SetFloat("_Metallic", metallic);
                    meshRenderer.sharedMaterial.SetFloat("_Roughness", roughness);
                }
                for(int i=0; i<tran.childCount; i++)
                {
                    queue.Enqueue(tran.GetChild(i));
                }
            }

        }
    }
}