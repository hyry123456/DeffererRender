using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    public class WaterPlane : GPUDravinBase
    {
        private ComputeBuffer planePointBuffer;
        private bool isInsert = false;

        private int 
            pointsBufferId = Shader.PropertyToID("_PointsBuffer"),
            pointsSizeXId = Shader.PropertyToID("_PointsSizeX"),
            objToWorldMatrix = Shader.PropertyToID("_PointsM_Martrix"),
            pointsSizeYId = Shader.PropertyToID("_PointsSizeY");

        public Vector2 planeSize = Vector2.one;
        public Vector2Int pointCount = Vector2Int.one;

        public Shader waterShader;
        public Material copyMat;

        [SerializeField]
        private bool debug = false; //用来开启测试模式
        private Material mat;
        public Material ShowMat
        {
            get
            {
                if (mat == null || mat.shader != waterShader)
                {
                    mat = new Material(waterShader);
                    mat.CopyPropertiesFromMaterial(copyMat);
                }
                return mat;
            }
        }

        private void OnEnable()
        {
            GPUDravinDrawStack.Instance.InsertRender(this);
            isInsert = true;

            ReadyBuffer();
        }

        private void OnDisable()
        {
            if (isInsert)
            {
                GPUDravinDrawStack.Instance.RemoveRender(this);
                isInsert = false;
            }
            planePointBuffer?.Release();
        }

        private void ReadyBuffer()
        {
            planePointBuffer?.Release();
            List<Vector3> points = new List<Vector3>((pointCount.x + 2) * (pointCount.y + 2));
            int countX = pointCount.x + 2, countY = pointCount.y + 2;
            for (int i=0; i< countX; i++)
            {
                for(int j=0; j< countY; j++)
                {
                    points.Add(new Vector3(((float)i / (countX - 1) - 0.5f) * planeSize.x,
                        0, ((float)j / (countY - 1) - 0.5f) * planeSize.y));
                }
            }
            planePointBuffer = new ComputeBuffer(points.Count, sizeof(float) * 3);
            planePointBuffer.SetData(points);
        }

        public override void DrawByCamera(ScriptableRenderContext context, CommandBuffer buffer, ClustDrawType drawType, Camera camera)
        {
            //Material useMat = (debug) ? copyMat : ShowMat;
            //useMat.SetBuffer(pointsBufferId, planePointBuffer);
            //useMat.SetInt(pointsSizeXId, pointCount.x + 2);
            //useMat.SetInt(pointsSizeYId, pointCount.y + 2);
            //useMat.SetMatrix(objToWorldMatrix, transform.localToWorldMatrix);
            //int count = (pointCount.x + 1) * (pointCount.y + 1);
            //buffer.DrawProcedural(Matrix4x4.identity, useMat, 1, MeshTopology.Points, 1, count);
            //ExecuteBuffer(ref buffer, context);
        }

        public override void DrawByProjectMatrix(ScriptableRenderContext context, CommandBuffer buffer, ClustDrawType drawType, Matrix4x4 projectMatrix)
        {
            return;
        }

        public override void DrawPreSSS(ScriptableRenderContext context, CommandBuffer buffer, Camera camera)
        {
            Material useMat = (debug) ? copyMat : ShowMat;
            useMat.SetBuffer(pointsBufferId, planePointBuffer);
            useMat.SetInt(pointsSizeXId, pointCount.x + 2);
            useMat.SetInt(pointsSizeYId, pointCount.y + 2);
            useMat.SetMatrix(objToWorldMatrix, transform.localToWorldMatrix);
            int count = (pointCount.x + 1) * (pointCount.y + 1);
            buffer.DrawProcedural(Matrix4x4.identity, useMat, 0, MeshTopology.Points, 1, count);
            ExecuteBuffer(ref buffer, context);
        }

        public override void SetUp(ScriptableRenderContext context, CommandBuffer buffer, Camera camera)
        {
        }
    }
}