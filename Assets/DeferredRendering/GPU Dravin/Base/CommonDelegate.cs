using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    //���ļ���������һЩ���õ�ComputeShader��Ҫ��ί��
    public delegate void DrawWithCamera(ScriptableRenderContext context,
        CommandBuffer buffer, Camera camera);
}