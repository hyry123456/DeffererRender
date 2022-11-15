using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    public interface IFluidDraw
    {
        /// <summary> /// Һ����Ⱦ�ĵ��÷���   /// </summary>
        /// <param name="sourceId">Ŀ������</param>
        /// <param name="width">������</param>
        /// <param name="height">����߶�</param>
        public void IFluidDraw(ScriptableRenderContext context, CommandBuffer buffer,
            RenderTargetIdentifier[] gBuffers, int gBufferDepth, int width, int height);
    }


    /// <summary>
    /// Һ����Ⱦջ����������Һ����Ⱦ�ĸ�ʽ
    /// </summary>
    public class FluidDrawStack
    {
        private static FluidDrawStack instance;
        public static FluidDrawStack Instance
        {
            get
            {
                if(instance == null)
                {
                    instance = new FluidDrawStack();
                }
                return instance;
            }
        }

        private List<IFluidDraw> fluids = new List<IFluidDraw>();

        public void InsertDraw(IFluidDraw fluid)
        {
            if (fluids.Contains(fluid))
                return;
            fluids.Add(fluid);
        }

        public void RemoveDraw(IFluidDraw fluid)
        {
            if(fluids.Contains(fluid))
                fluids.Remove(fluid);
        }

        public void BeginDrawFluid(ScriptableRenderContext context, CommandBuffer buffer,
            RenderTargetIdentifier[] gBuffers, int gBufferDepth, int width, int height)
        {
            buffer.BeginSample("DrawFluid");
            for(int i=0; i<fluids.Count; i++)
            {
                fluids[i].IFluidDraw(context, buffer, gBuffers, gBufferDepth, width, height);
            }
            buffer.EndSample("DrawFluid");
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }


    }
}