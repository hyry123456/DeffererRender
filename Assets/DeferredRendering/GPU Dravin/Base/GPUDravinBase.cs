using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    public enum ClustDrawType
    {
        Simple = 0,
        Shadow = 1,
    }

    /// <summary>
    /// 直接调用GPU接口进行直接渲染的方法基类，定义统一的调用格式
    /// </summary>
    public abstract class GPUDravinBase : MonoBehaviour
    {
        /// <summary>
        /// 绘制物体，这个一般是绘制结果为颜色的物体 
        /// </summary>
        public abstract void DrawByCamera(ScriptableRenderContext context,
            CommandBuffer buffer, ClustDrawType drawType, Camera camera);

        /// <summary>
        /// 这个一般是绘制阴影，当为阴影时调用该函数
        /// </summary>
        public abstract void DrawByProjectMatrix(ScriptableRenderContext context,
            CommandBuffer buffer, ClustDrawType drawType, Matrix4x4 projectMatrix);

        /// <summary>
        /// 在渲染SSS前调用的方法，用来写入标准Lit数据
        /// </summary>
        public abstract void DrawPreSSS(ScriptableRenderContext context,
            CommandBuffer buffer, Camera camera);

        /// <summary>
        /// 准备方法，如果需要进行进行一些ComputeShader准备之类的
        /// </summary>
        public abstract void SetUp(ScriptableRenderContext context,
            CommandBuffer buffer, Camera camera);

        protected void ExecuteBuffer(ref CommandBuffer buffer, ScriptableRenderContext context)
        {
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        //一个点和一个法向量确定一个平面,也就是平面方程Ax+By+Cz+D=0的(A,B,C,D)值
        public static Vector4 GetPlane(Vector3 normal, Vector3 point)
        {
            return new Vector4(normal.x, normal.y, normal.z, -Vector3.Dot(normal, point));
        }

        //三点确定一个平面
        public static Vector4 GetPlane(Vector3 a, Vector3 b, Vector3 c)
        {
            Vector3 normal = Vector3.Normalize(Vector3.Cross(b - a, c - a));
            return GetPlane(normal, a);
        }

        //获取视锥体远平面的四个点
        public static Vector3[] GetCameraFarClipPlanePoint(Camera camera)
        {
            Vector3[] points = new Vector3[4];
            Transform transform = camera.transform;
            float distance = camera.farClipPlane;
            float halfFovRad = Mathf.Deg2Rad * camera.fieldOfView * 0.5f;
            float upLen = distance * Mathf.Tan(halfFovRad);
            float rightLen = upLen * camera.aspect;
            Vector3 farCenterPoint = transform.position + distance * transform.forward;
            Vector3 up = upLen * transform.up;
            Vector3 right = rightLen * transform.right;
            points[0] = farCenterPoint - up - right;//left-bottom
            points[1] = farCenterPoint - up + right;//right-bottom
            points[2] = farCenterPoint + up - right;//left-up
            points[3] = farCenterPoint + up + right;//right-up
            return points;
        }

        //获取视锥体的六个平面
        public static Vector4[] GetFrustumPlane(Camera camera)
        {
            Vector4[] planes = new Vector4[6];
            Transform transform = camera.transform;
            Vector3 cameraPosition = transform.position;
            Vector3[] points = GetCameraFarClipPlanePoint(camera);
            //顺时针
            planes[0] = GetPlane(cameraPosition, points[0], points[2]);//left
            planes[1] = GetPlane(cameraPosition, points[3], points[1]);//right
            planes[2] = GetPlane(cameraPosition, points[1], points[0]);//bottom
            planes[3] = GetPlane(cameraPosition, points[2], points[3]);//up
            planes[4] = GetPlane(-transform.forward, transform.position + transform.forward * camera.nearClipPlane);//near
            planes[5] = GetPlane(transform.forward, transform.position + transform.forward * camera.farClipPlane);//far
            return planes;
        }

        public bool IsOutsideThePlane(Vector4 plane, Vector3 pointPosition)
        {
            if (Vector3.Dot(plane, pointPosition) + plane.w > 0)
                return true;
            return false;
        }
    }
}