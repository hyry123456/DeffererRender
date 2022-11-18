using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DefferedRender
{
    class OctreeNode
    {
        //所有节点
        public OctreeNode[] nodes = new OctreeNode[8];

        //数据
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

        /// <summary>   /// 检查新节点相对原节点的位置   /// </summary>
        /// <param name="compared">新节点</param>
        /// <param name="origin">原节点</param>
        /// <returns>位置编号</returns>
        private int CheckNode(CollsionStruct compared, CollsionStruct origin)
        {
            int index = 0;
            if (origin.center.y < compared.center.y)     //新节点在原节点上面
                index += 4;
            if (origin.center.x < compared.center.x)     //新节点在原节点右边
                index += 2;
            if (origin.center.z < compared.center.z)    //新节点在原节点前面
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