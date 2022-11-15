using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    public class GPUDravinDrawStack
    {
        private GPUDravinDrawStack() { }

        private static GPUDravinDrawStack instance;
        public static GPUDravinDrawStack Instance
        {
            get
            {
                if (instance == null) instance = new GPUDravinDrawStack();
                return instance;
            }
        }

        /// <summary>
        /// �洢�õ��б���Ϊ��˳���ȡ����Ϊ������Ҫ�����ɾ��������ʹ������
        /// </summary>
        private LinkedList<GPUDravinBase> queueStack;

        /// <summary>
        /// ����һ����Ҫ������Ⱦ�Ķ��󣬲����ͻ�����������
        /// </summary>
        /// <param name="clustBase">����Ķ���</param>
        public void InsertRender(GPUDravinBase clustBase)
        {
            if (clustBase == null) return;
            if (queueStack == null)
                queueStack = new LinkedList<GPUDravinBase>();
            if(!queueStack.Contains(clustBase))
                queueStack.AddLast(clustBase);
        }

        /// <summary>        /// �Ƴ�����Ⱦջ        /// </summary>
        public void RemoveRender(GPUDravinBase clustBase)
        {
            if (clustBase == null || queueStack == null) return;
            queueStack.Remove(clustBase);
        }

        /// <summary>
        /// �����в��뵽����ջ�е�������л��ƣ����ö�Ӧ�Ļ��Ʒ���
        /// </summary>
        public void BeginDraw(ScriptableRenderContext context, CommandBuffer buffer,
             ClustDrawType clustDrawSubPass, Matrix4x4 projectMatrix)
        {
            if (queueStack == null) return;
            foreach (GPUDravinBase index in queueStack)
            {
                index.DrawByProjectMatrix(context, buffer,
                    clustDrawSubPass, projectMatrix);
            }
        }

        public void BeginDraw(ScriptableRenderContext context, CommandBuffer buffer,
            ClustDrawType clustDrawSubPass, Camera camera)
        {
            if (queueStack == null) return;
            foreach (GPUDravinBase index in queueStack)
            {
                index.DrawByCamera(context, buffer,
                    clustDrawSubPass, camera);
            }
        }

        public void DrawPreSSS(ScriptableRenderContext context, CommandBuffer buffer,Camera camera)
        {
            if (queueStack == null) return;
            foreach (GPUDravinBase index in queueStack)
            {
                index.DrawPreSSS(context, buffer, camera);
            }
        }

        public void SetUp(ScriptableRenderContext context, CommandBuffer buffer, Camera camera)
        {
            if (queueStack == null) return;
            foreach (GPUDravinBase index in queueStack)
            {
                index.SetUp(context, buffer, camera);
            }
        }
    }
}