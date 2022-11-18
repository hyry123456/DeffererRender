using System.Collections.Generic;
using UnityEngine;

namespace DefferedRender
{
    //碰撞结构
    public struct CollsionStruct
    {
        public float radius;
        public Vector3 center;
        public Vector3 offset;      //碰撞偏移，只从中间往四周偏移
    }

    /// <summary>
    /// 粒子碰撞器控制类
    /// </summary>
    public class PhysicsCollsion : MonoBehaviour
    {
        private static PhysicsCollsion instance;
        public static PhysicsCollsion Instance
        {
            get
            {
                if(instance == null)
                {
                    GameObject game = new GameObject("PhysicsCollsion");
                    game.AddComponent<PhysicsCollsion>();
                }
                return instance;
            }
        }

        private Octree octree;

        private void Awake()
        {
            if(instance != null)
            {
                Destroy(gameObject);
                return;
            }
            instance = this;
            octree = new Octree();
            return;
        }

        private void Start()
        {
            
        }

        private void OnDestroy()
        {
            instance = null;
            octree = null;
        }

        /// <summary>
        /// 添加碰撞器节点，只能在Awake中添加，因为Buffer在Start中创建
        /// </summary>
        public void AddCollsionNode(IPhysicsCollider colliderInterface)
        {
            octree.AddNode(colliderInterface.GetCollsionStruct());
        }
    }
}