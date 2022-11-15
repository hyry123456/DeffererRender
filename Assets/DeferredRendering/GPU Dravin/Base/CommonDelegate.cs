using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    //该文件用来定义一些常用的ComputeShader需要的委托
    public delegate void DrawWithCamera(ScriptableRenderContext context,
        CommandBuffer buffer, Camera camera);
}