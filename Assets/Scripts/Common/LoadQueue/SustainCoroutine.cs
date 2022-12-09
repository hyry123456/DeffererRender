using System.Collections;
using UnityEngine;

namespace Common
{
    /// <summary>    /// ������Э�������õķ���������trueʱ����    /// </summary>
    public delegate bool CoroutinesAction();

    /// <summary>
    /// ���Я�̼����õ����飬�ó����Ż�Э�̵Ĳ����Լ�ɾ��
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

        /// <summary>   /// �Ƴ������ŵ�Э��    /// </summary>
        public void Remove(int removeIndex)
        {
            if (removeIndex >= size) return;
            coroutines[removeIndex] = coroutines[size - 1];
            size--;
        }

        /// <summary>   /// �ж��Ƿ���Э��ջ���Ѿ����ڴ�����     /// </summary>
        /// <param name="find">�жϵĶ���</param>
        /// <returns>true�Ǵ��ڣ�false�ǲ�����</returns>
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

        /// <summary>        /// ���뷽��������Э��ջ�У�������֡����        /// </summary>
        /// <param name="action">����</param>
        /// <param name="canWait">�Ƿ���Եȴ���falseʱ������ִ��</param>
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
