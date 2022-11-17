using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{

    /// <summary> /// 根据灯光创建Mesh，用来加入到体积光渲染栈中 /// </summary>
    public class BulkLightNode : MonoBehaviour
    {
        public Vector3 boundMax;
        public Vector3 boundMin;

        BulkLightStruct lightStruct;


        private void Awake()
        {
            lightStruct = new BulkLightStruct()
            {
                boundMax = boundMax + transform.position,
                boundMin = boundMin + transform.position,
            };
            BulkLight bulkLight = BulkLight.CreateInstance();
            //只进行提交，提交后在切换场景时父类会自己清除
            bulkLight.AddBulkLightBox(lightStruct);
        }

        //private void OnDestroy()
        //{
        //    //BulkLight.Instance.RemoveBulkLightBox(lightStruct);
        //}

        private void OnDrawGizmos()
        {
            Gizmos.DrawWireCube((boundMax + boundMin) / 2 + transform.position, 
                boundMax - boundMin);
        }




    }
}