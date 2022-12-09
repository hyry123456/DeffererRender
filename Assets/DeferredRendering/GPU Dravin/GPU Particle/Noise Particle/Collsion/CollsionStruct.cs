using UnityEngine;

namespace DefferedRender
{
    /// <summary> /// 输入到粒子中的碰撞器 /// </summary>
    public struct CollsionStruct
    {
        public float radius;
        public Vector3 center;
        public Vector3 offset;      //碰撞偏移，只从中间往四周偏移
        public int mode;            //碰撞器类型
        public Matrix4x4 localToWorld;
        public Matrix4x4 worldToLocal;
    }

    public abstract class IGetCollsion : MonoBehaviour
    {
        public abstract CollsionStruct GetCollsionStruct();
    }
}