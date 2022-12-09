using System.Collections;
using UnityEngine;

namespace Common
{
    /// <summary>    /// 用来给协程运行用的方法，返回true时死亡    /// </summary>
    public delegate bool CoroutinesAction();

    /// <summary>
    /// 配合携程加载用的数组，用池来优化协程的插入以及删除
    /// </summary>
    class SustainList<T>
    {
        public T[] coroutines = new T[1];
        public int size = 0;

        public void Add(T coroutine)
        {
            T[] newCorutines;
            if (size == coroutines.Length)
            {
                newCorutines = new T[size + 5];
                for (int i = 0; i < size; i++)
                    newCorutines[i] = coroutines[i];
                coroutines = newCorutines;
            }
            coroutines[size] = coroutine;
            size++;
        }

        /// <summary>   /// 移除传入编号的协程    /// </summary>
        public void Remove(int removeIndex)
        {
            if (removeIndex >= size) return;
            coroutines[removeIndex] = coroutines[size - 1];
            size--;
        }

        /// <summary>   /// 判断是否在协程栈中已经存在此物体     /// </summary>
        /// <param name="find">判断的对象</param>
        /// <returns>true是存在，false是不存在</returns>
        public bool IsHave(T find)
        {
            for(int i=0; i<size; i++)
            {
                if (find.Equals(coroutines[i]))
                    return true;
            }
            return false;
        }
    }



    public class SustainCoroutine : MonoBehaviour
    {
        private static SustainCoroutine instance;
        public static SustainCoroutine Instance
        {
            get
            {
                if (instance == null)
                {
                    GameObject gameObject = new GameObject("SustainCoroutine");
                    gameObject.AddComponent<SustainCoroutine>();
                    DontDestroyOnLoad(gameObject);
                }
                return instance;
            }
        }
        private bool isRunning = false;
        private SustainList<CoroutinesAction> sustainList = new SustainList<CoroutinesAction>();

        private void Awake()
        {
            if (instance != null)
            {
                Destroy(gameObject);
                return;
            }
            instance = this;
            isRunning = true;
            sustainList = new SustainList<CoroutinesAction>();
            StartCoroutine(Run());
        }

        private IEnumerator Run()
        {
            while (isRunning)
            {
                if (sustainList.size == 0)
                    yield return new WaitForSeconds(0.2f);

                for (int i = sustainList.size - 1; i >= 0; i--)
                {
                    if (sustainList.coroutines[i]())
                        sustainList.Remove(i);
                }
                yield return null;
            }
        }


        private void OnDisable()
        {
            isRunning = false;
        }

        /// <summary>        /// 加入方法到持续协程栈中，进行逐帧运行        /// </summary>
        /// <param name="action">方法</param>
        /// <param name="canWait">是否可以等待，false时会立刻执行</param>
        public void AddCoroutine(CoroutinesAction action, bool canWait = true)
        {
            if (sustainList.IsHave(action))
                return;
            sustainList.Add(action);
            if (canWait) return;
            StopAllCoroutines();
            StartCoroutine(Run());
        }

    }

}
