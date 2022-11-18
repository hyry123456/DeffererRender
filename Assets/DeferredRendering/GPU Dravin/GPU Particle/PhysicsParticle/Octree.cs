using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DefferedRender
{
    class OctreeNode
    {
        //���нڵ�
        public OctreeNode[] nodes = new OctreeNode[8];

        //����
        public CollsionStruct value;
    };

    public class Octree
    {
        private OctreeNode first;

        public void AddNode(CollsionStruct value)
        {
            if(first == null)
            {
                first = new OctreeNode();
                first.value = value;
                return;
            }

            InsertNode(value);
        }

        private void InsertNode(CollsionStruct value)
        {
            OctreeNode currentNode = first;
            while (true)
            {
                int index = CheckNode(currentNode.value, value);
                if (currentNode.nodes[index] == null)
                {
                    currentNode.nodes[index] = new OctreeNode();
                    currentNode.nodes[index].value = value;
                    return;
                }
                else
                    currentNode = currentNode.nodes[index];
            }
        }

        /// <summary>   /// ����½ڵ����ԭ�ڵ��λ��   /// </summary>
        /// <param name="compared">�½ڵ�</param>
        /// <param name="origin">ԭ�ڵ�</param>
        /// <returns>λ�ñ��</returns>
        private int CheckNode(CollsionStruct compared, CollsionStruct origin)
        {
            int index = 0;
            if (origin.center.y < compared.center.y)     //�½ڵ���ԭ�ڵ�����
                index += 4;
            if (origin.center.x < compared.center.x)     //�½ڵ���ԭ�ڵ��ұ�
                index += 2;
            if (origin.center.z < compared.center.z)    //�½ڵ���ԭ�ڵ�ǰ��
                index += 1;
            return index;
        }

        //public List<CollsionStruct> collsionArray
        //{
        //    get
        //    {
                
        //    }
        //}

    }
}