using UnityEngine;


namespace DefferedRender
{
    public class BoxCollsion : IGetCollsion
    {
        public Vector3 cubeSize = Vector3.one;

        public override CollsionStruct GetCollsionStruct()
        {
            CollsionStruct collsion = new CollsionStruct();
            collsion.mode = 0;
            collsion.center = transform.position;
            collsion.offset = cubeSize * 0.5f;
            collsion.localToWorld = transform.localToWorldMatrix;
            collsion.worldToLocal = transform.worldToLocalMatrix;
            return collsion;
        }

#if UNITY_EDITOR
        private void OnDrawGizmos()
        {
            Gizmos.color = Color.green;
            Gizmos.matrix = transform.localToWorldMatrix;
            Gizmos.DrawWireCube(Vector3.zero, cubeSize);
        }
#endif
    }
}