using UnityEngine;

namespace Common
{
    /// <summary> /// 对象池基类，用来定义对象池使用格式以及封装入池以及出池操作  /// </summary>
    public abstract class ObjectPoolBase : MonoBehaviour
    {
        [System.NonSerialized]
        /// <summary>  /// 对象名称，用来判断这个对象的所属池  /// </summary>
        public string objectName;

        /// <summary> /// 初始化方法，用来对该对象进行初始化，只实现显示以及旋转初始化  /// </summary>
        public virtual void InitializeObject(Vector3 positon, Quaternion quaternion)
        {
            transform.rotation = quaternion;
            transform.position = positon;
            gameObject.SetActive(true);
        }
        /// <summary> /// 初始化方法，用来对该对象进行初始化，只实现显示以及旋转初始化  /// </summary>
        public virtual void InitializeObject(Vector3 positon, Vector3 lookAt)
        {
            gameObject.transform.position = positon;
            gameObject.transform.LookAt(lookAt);
            gameObject.SetActive(true);
        }

        /// <summary>  /// 关闭该对象，将其塞回对象池中   /// </summary>
        public virtual void CloseObject()
        {
            SceneObjectPool.Instance.RecyclingObjects(this);
        }

        /// <summary>
        /// 初始化时的统一补充方法，由Unity调用，每一次Get后就会调用
        /// </summary>
        protected abstract void OnEnable();
    }
}