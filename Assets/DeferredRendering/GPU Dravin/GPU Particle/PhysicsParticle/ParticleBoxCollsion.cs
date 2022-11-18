using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DefferedRender {

    public class ParticleBoxCollsion : MonoBehaviour, IPhysicsCollider
    {
        public Vector3 cubeOffset;

        private void Awake()
        {
            PhysicsCollsion.Instance.AddCollsionNode(this);
        }

        private void OnValidate()
        {
            cubeOffset.x = Mathf.Max(0, cubeOffset.x);
            cubeOffset.y = Mathf.Max(0, cubeOffset.y);
            cubeOffset.z = Mathf.Max(0, cubeOffset.z);
        }

        private void OnDrawGizmos()
        {
            Gizmos.color = Color.green;
            Gizmos.DrawWireCube(transform.position, cubeOffset);
        }

        public CollsionStruct GetCollsionStruct()
        {
            CollsionStruct collsionStruct = new CollsionStruct();
            collsionStruct.center = transform.position;
            collsionStruct.offset = cubeOffset;
            return collsionStruct;
        }
    }
}