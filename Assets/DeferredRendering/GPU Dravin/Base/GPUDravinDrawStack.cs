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
        /// 存储用的列表，因为是顺序读取，因为经常需要插入和删除，所以使用链表
        /// </summary>
        private LinkedList<GPUDravinBase> queueStack;

        /// <summary>
        /// 插入一个需要进行渲染的对象，插入后就会正常绘制了
        /// </summary>
        /// <param name="clustBase">插入的对象</param>
        public void InsertRender(GPUDravinBase clustBase)
        {
            if (clustBase == null) return;
            if (queueStack == null)
                queueStack = new LinkedList<GPUDravinBase>();
            if(!queueStack.Contains(clustBase))
                queueStack.AddLast(clustBase);
        }

        /// <summary>        /// 移除出渲染栈        /// </summary>
        public void RemoveRender(GPUDravinBase clustBase)
        {
            if (clustBase == null || queueStack == null) return;
            queueStack.Remove(clustBase);
        }

        /// <summary>
        /// 对所有插入到加载栈中的物体进行绘制，调用对应的绘制方法
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