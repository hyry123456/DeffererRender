using UnityEngine;

namespace DefferedRender
{
    /// <summary> /// ÇòÐÍÅö×²Æ÷ /// </summary>
    public class SphereCollsion : IGetCollsion
    {
        [Min(0.00001f)]
        public float radius = 1;

#if UNITY_EDITOR
        public void OnDrawGizmos()
        {
            Gizmos.color = Color.green;
            Gizmos.DrawWireSphere(transform.position, radius);
        }
#endif

        public override CollsionStruct GetCollsionStruct()
        {
            CollsionStruct collsionStruct = new CollsionStruct();
            collsionStruct.mode = 1;
            collsionStruct.radius = radius;
            collsionStruct.center = transform.position;
            return collsionStruct;
        }
    }
}