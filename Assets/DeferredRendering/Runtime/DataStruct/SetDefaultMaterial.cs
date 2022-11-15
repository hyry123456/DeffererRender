using System.Collections.Generic;
using UnityEngine;

namespace DefferedRender
{

    public class SetDefaultMaterial : MonoBehaviour
    {
        public Material defaultMat;
        public bool begin;

        private void OnValidate()
        {
            if (defaultMat == null) return;

            Queue<Transform> queue = new Queue<Transform>();
            queue.Enqueue(transform);
            while(queue.Count > 0)
            {
                Transform tran = queue.Dequeue();
                MeshRenderer meshRenderer = tran.gameObject.GetComponent<MeshRenderer>();
                if(meshRenderer != null)
                    meshRenderer.sharedMaterial = defaultMat;
                for(int i=0; i<tran.childCount; i++)
                {
                    queue.Enqueue(tran.GetChild(i));
                }
            }

        }
    }
}