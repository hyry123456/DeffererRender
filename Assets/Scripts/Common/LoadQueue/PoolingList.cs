using UnityEngine;
namespace Common
{
    [System.Serializable]
    /// <summary>
    /// �ػ����鰸�����Ͽ�Ĳ���ɾ��������
    /// </summary>
    public class PoolingList<T>
    {
        [SerializeField]
        private T[] list = new T[1];
        private int size = 0;

        public T[] Arrays => list;
        public int Count => size;
        /// <summary> /// ��ȡ��ֵ�еĵ�index��Ԫ��    /// </summary>
        public T GetValue(int index)
        {
            return list[index];
        }

        public void SetCapacity(int capacity)
        {
            if (list.Length >= capacity)
                return;
            T[] newList = new T[capacity];
            //������ǰ����
            for (int i = 0; i < size; i++)
                newList[i] = list[i];
            list = newList;
        }

        public void Add(T node)
        {
            if(size == list.Length)
            {
                T[] newList = new T[(size + 1) * 2];
                for(int i=0; i<size; i++)
                    newList[i] = list[i];
                list = newList;
            }
            list[size] = node;
            size++;
        }

        public void AddRange(PoolingList<T> ranges)
        {
            //���ô�С
            this.SetCapacity(Count + ranges.Count + 5);
            //��������
            for(int i=0; i<ranges.Count; i++)
            {
                this.Add(ranges.GetValue(i));
            }
        }

        public void Remove(int removeIndex)
        {
            if (removeIndex >= size) return;
            //�����һ���滻Ҫɾ����һ�����ﵽ���Ӷ�Ϊ1��ɾ��
            list[removeIndex] = list[size - 1];
            size--;
        }

        /// <summary>        /// �Ƴ������ڵ�        /// </summary>
        /// <param name="node">�Ƴ��ĸ��ݵ�</param>
        public void Remove(T node)
        {
            int reIndex = 0;
            for (; reIndex < size; reIndex++)
            {
                if (node.Equals(list[reIndex]))
                    break;
            }
            if (reIndex >= size) return;
            list[reIndex] = list[size - 1];
            size--;
        }
        public void RemoveAll()
        {
            size = 1;
        }

    }
}