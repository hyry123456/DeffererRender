using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace Common
{
    /// <summary>
    /// 场景对象池，使用池化技术快速加载以及删除物体
    /// </summary>
    public class SceneObjectPool : MonoBehaviour
    {
        private static SceneObjectPool instance;
        public static SceneObjectPool Instance
        {
            get
            {
                if(instance == null)
                {
                    GameObject gameObject = new GameObject("SceneObjectPool");
                    gameObject.AddComponent<SceneObjectPool>();
                }
                return instance;
            }
        }

        private Dictionary<string, PoolingList<ObjectPoolBase>>
            objectPools;

        private void Awake()
        {
            if(instance != null)
            {
                Destroy(gameObject);
                return;
            }
            instance = this;
            objectPools = new Dictionary<string, PoolingList<ObjectPoolBase>>();
        }
        private void OnDestroy()
        {
            instance = null;
            if (objectPools == null) return;
            objectPools.Clear();
        }

        /// <summary>
        /// 在对象池中查找该物体，如果对象池中没有临时物体就会根据传入参数创建一个，
        /// 不会使用到根据的原物体，原物体只是拷贝的根据
        /// </summary>
        /// <param name="name">要查找的物体所属名称</param>
        /// <param name="origin">根据的物体</param>
        /// <param name="postion">初始化的位置</param>
        /// <param name="quaternion">旋转数据</param>
        public T GetObject<T>(string name, GameObject origin,
            Vector3 postion, Quaternion quaternion) where T : ObjectPoolBase
        {
            T objectPool = (T)GetData(name, origin);
            objectPool.InitializeObject(postion, quaternion);
            return objectPool;
        }

        /// <summary>
        /// 在对象池中查找该物体，如果对象池中没有临时物体就会根据传入参数创建一个，
        /// 不会使用到根据的原物体，原物体只是拷贝的根据
        /// </summary>
        /// <param name="name">要查找的物体所属名称</param>
        /// <param name="origin">根据的物体</param>
        /// <param name="postion">初始化的位置</param>
        /// <param name="lookAt">物体看向的目标位置</param>
        public T GetObject<T>(string name, GameObject origin,
            Vector3 postion, Vector3 lookAt) where T : ObjectPoolBase
        {
            T objectPool = (T)GetData(name, origin);
            objectPool.InitializeObject(postion, lookAt);
            return objectPool;
        }

        private ObjectPoolBase GetData(string name, GameObject origin)
        {
            PoolingList<ObjectPoolBase> list;
            if (!objectPools.TryGetValue(name, out list))
            {
                list = new PoolingList<ObjectPoolBase>();
                objectPools.Add(name, list);
            }
            if (list.Count == 0)     //池中为空，创建一个
            {
                //创建一个新对象，作为返回值
                GameObject gameObject = GameObject.Instantiate(origin);
                gameObject.transform.parent = transform;        //放到池中管理
                gameObject.name = name;             //设置统一的名称

                ObjectPoolBase poolBase = gameObject.GetComponent<ObjectPoolBase>();
                if (poolBase == null)
                {
                    Debug.LogError("根据物体不可被对象池管理");
                    return null;
                }
                poolBase.objectName = name;
                return poolBase;
            }
            //从池中取出一个对象
            ObjectPoolBase objectPool = list.GetValue(0);
            list.Remove(0);         //从池中移除该对象
            return objectPool;
        }

        /// <summary>  /// 回收该被游戏对象池管理的物体  /// </summary>
        /// <param name="objectPoolBase">被管理的物体</param>
        public void RecyclingObjects(ObjectPoolBase objectPoolBase)
        {
            objectPoolBase.gameObject.SetActive(false);
            PoolingList<ObjectPoolBase> list;
            if(objectPools.TryGetValue(objectPoolBase.objectName, out list))
            {
                list.Add(objectPoolBase);
                return;
            }
            list = new PoolingList<ObjectPoolBase>();
            list.Add(objectPoolBase);
            objectPools.Add(objectPoolBase.objectName, list);
        }
    }
}