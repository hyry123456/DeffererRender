using UnityEngine;

namespace DefferedRender
{
    /// <summary>
    /// 定义一个通用的Cluster结构体，只是用来声明数据，可以用这些数据代表其他含义
    /// </summary>
    public struct ClustStruct
    {
        /// <summary>   /// 世界空间坐标    /// </summary>
        public Vector3 positionWS0;
        public Vector3 positionWS1;
        public Vector3 positionWS2;
        /// <summary>   /// UV坐标，设置为4维，方便自定义    /// </summary>
        public Vector4 uv0;
        public Vector4 uv1;
        public Vector4 uv2;
        /// <summary>    /// 法线方向    /// </summary>
        public Vector3 normalWS0;
        public Vector3 normalWS1;
        public Vector3 normalWS2;
        /// <summary>   /// 世界坐标Tangent值   /// </summary>
        public Vector4 tangentWS0;
        public Vector4 tangentWS1;
        public Vector4 tangentWS2;
    }

}