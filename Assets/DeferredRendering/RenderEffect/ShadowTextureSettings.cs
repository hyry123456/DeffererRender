using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DefferedRender
{
    [ExecuteInEditMode]
    public class ShadowTextureSettings : MonoBehaviour
    {
        public Transform bottomLeftPos;
        public Transform bottomRightPos;
        public Transform topLeftPos;
        public Transform topRightPos;
        /// <summary>  /// 根据当前数值创建4个顶点   /// </summary>
        public bool createPosByNow;

        private ShadowTexture shadow;

        private void OnValidate()
        {
            if (shadow == null)
                shadow = GetComponent<ShadowTexture>();
            if (shadow == null)
                return;
            if (!createPosByNow)
                return;
            if(bottomLeftPos == null)
            {
                GameObject bL = new GameObject("bottomLeftPos");
                bL.transform.parent = transform;
                Vector3 rotaPos = transform.TransformDirection(shadow.bottomLeftPos);
                bL.transform.position = transform.position + rotaPos;
                bottomLeftPos = bL.transform;
            }

            if(bottomRightPos == null)
            {
                GameObject bR = new GameObject("bottomRightPos");
                bR.transform.parent = transform;
                Vector3 rotaPos = transform.TransformDirection(shadow.bottomRightPos);
                bR.transform.position = transform.position + rotaPos;
                bottomRightPos = bR.transform;
            }

            if(topLeftPos == null)
            {
                GameObject tL = new GameObject("topLeftPos");
                tL.transform.parent = transform;
                Vector3 rotaPos = transform.TransformDirection(shadow.topLeftPos);
                tL.transform.position = transform.position + rotaPos;
                topLeftPos = tL.transform;
            }


            if(topRightPos == null)
            {
                GameObject tR = new GameObject("topRightPos");
                tR.transform.parent = transform;
                Vector3 rotaPos = transform.TransformDirection(shadow.topRightPos);
                tR.transform.position = transform.position + rotaPos;
                topRightPos = tR.transform;
            }
            createPosByNow = false;
        }

        private void Update()
        {
            if(shadow == null)
                shadow = GetComponent<ShadowTexture>();
            if(shadow == null)
                return;
            if (bottomLeftPos == null
                || bottomRightPos == null
                || topLeftPos == null
                || topRightPos == null) return;


            Vector3 bL = transform.InverseTransformPoint(bottomLeftPos.position);
            shadow.bottomLeftPos = bL;

            Vector3 bR = transform.InverseTransformPoint(bottomRightPos.position);
            shadow.bottomRightPos = bR;

            Vector3 tL = transform.InverseTransformPoint(topLeftPos.position);
            shadow.topLeftPos = tL;

            Vector3 tR = transform.InverseTransformPoint(topRightPos.position);
            shadow.topRightPos = tR;
            shadow.Recaculate();
        }

        private void OnDrawGizmos()
        {
            if (bottomLeftPos == null
                || bottomRightPos == null
                || topLeftPos == null
                || topRightPos == null) return;
            Gizmos.DrawLine(bottomLeftPos.position, bottomRightPos.position);
            Gizmos.DrawLine(bottomRightPos.position, topRightPos.position);
            Gizmos.DrawLine(topRightPos.position, topLeftPos.position);
            Gizmos.DrawLine(topLeftPos.position, bottomLeftPos.position);
        }

    }
}