using System.Collections.Generic;
using UnityEngine;

namespace DefferedRender
{
    //��ײ�ṹ
    public struct CollsionStruct
    {
        public float radius;
        public Vector3 center;
        public Vector3 offset;      //��ײƫ�ƣ�ֻ���м�������ƫ��
    }

    /// <summary>
    /// ������ײ��������
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
        /// �����ײ���ڵ㣬ֻ����Awake����ӣ���ΪBuffer��Start�д���
        /// </summary>
        public void AddCollsionNode(IPhysicsCollider colliderInterface)
        {
            octree.AddNode(colliderInterface.GetCollsionStruct());
        }
    }
}