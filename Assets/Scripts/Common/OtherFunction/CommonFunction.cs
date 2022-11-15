using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Common
{
    public class CommonFunction : MonoBehaviour
    {
        private static CommonFunction instance;
        protected static CommonFunction Instance
        {
            get
            {
                if (instance == null)
                {
                    GameObject go = new GameObject("CommonFunction");
                    go.hideFlags = HideFlags.HideAndDontSave;
                    instance = go.AddComponent<CommonFunction>();
                }
                return instance;
            }
        }

        private IEnumerator FindObject(string name, Transform addordTransform, ISetOneParam<Transform> setOneParam)
        {
            Queue<Transform> queue = new Queue<Transform>();
            queue.Enqueue(addordTransform);
            while (queue.Count > 0)
            {
                Transform child = queue.Dequeue();
                if (child.name.Equals(name))
                {
                    queue.Clear();
                    setOneParam(child);
                    yield break;
                }
                else
                {
                    int size = child.childCount;
                    for (int i = 0; i < size; i++)
                    {
                        queue.Enqueue(child.GetChild(i));
                    }
                }
                yield return null;
            }
        }

        /// <summary>
        /// 在这个组件中立刻查找出目标组件
        /// </summary>
        /// <param name="name">目标组件名称</param>
        /// <param name="transform">根据的transform</param>
        /// <returns>目标</returns>
        public static Transform FindChildInTransform(string name, Transform transform)
        {
            int count = transform.childCount;
            Queue<Transform> queue = new Queue<Transform>();
            queue.Enqueue(transform);
            while(queue.Count > 0)
            {
                Transform child = queue.Dequeue();
                if (child.name.Equals(name))
                {
                    queue.Clear();
                    return child;
                }
                else
                {
                    int size = child.childCount;
                    for(int i=0; i<size; i++)
                    {
                        queue.Enqueue(child.GetChild(i));
                    }
                }
            }
            return null;
        }

        /// <summary>
        /// 延迟查找数据，一般用于不是很紧急时查找数据
        /// </summary>
        /// <param name="name">查找名称</param>
        /// <param name="according">根据的Transform</param>
        /// <param name="setOne">设置的方法，因为协程不允许使用in以及out，故用这个</param>
        public static void DelayFindInTransform(string name,Transform according, 
            ISetOneParam<Transform> setOne)
        {
            Instance.StartCoroutine(Instance.FindObject(name, according,  setOne));
        }

        /// <summary>
        /// 在列表中选择一个作为目标，这个函数中有进行判空，返回也有空，需要注意
        /// </summary>
        /// <typeparam name="T">数据类型</typeparam>
        /// <param name="list">传入的列表</param>
        /// <returns>被选中的对象</returns>
        public static T ChoseOneOnList<T>(List<T> list) where T : class
        {
            if(list == null || list.Count <= 0) return null;
            return list[Random.Range(0, list.Count)];
        }

        /// <summary>
        /// 将一个int的特定2进制位数的值化为0，并且不会改变其他位的大小
        /// </summary>
        /// <param name="convertVal">被改变的值</param>
        /// <param name="index">改变的位置</param>
        /// <returns>转化后的值</returns>
        public static void SetBirIndexToZero(ref int convertVal, int index)
        {
            convertVal = convertVal & (int.MaxValue - (1 << index));
        }

        /// <summary>
        /// 在该物体中广度搜索这个组件
        /// </summary>
        /// <typeparam name="T">搜索类型</typeparam>
        public static T GetComponentInChild<T>(Transform transform) where T : Component
        {
            Queue<Transform> queue = new Queue<Transform>();
            queue.Enqueue(transform);
            while(queue.Count > 0)
            {
                int size = queue.Count;
                while(size > 0)
                {
                    Transform child = queue.Dequeue();
                    T get = child.GetComponent<T>();
                    if (get != null)
                        return get;
                    for(int i=0; i<child.childCount; i++)
                        queue.Enqueue(child.GetChild(i));
                    size--;
                }
            }
            return null;
        }

    }
}