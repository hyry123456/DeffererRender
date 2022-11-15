using UnityEngine;
using UnityEngine.Rendering;

namespace DefferedRender
{
    /// <summary>
    /// Deffer Render invoke class，
    /// 呼叫类，调用实际处理类进行处理
    /// </summary>
    public partial class DefferRenderPipeline : RenderPipeline
    {
        RenderSetting setting;
        DefferRender renderer;
        ShadowSetting shadow;
        PostFXSetting postFX;
        LightSetting lightSetting;

        public DefferRenderPipeline(RenderSetting setting, ShadowSetting shadow,
            PostFXSetting postFXSetting, LightSetting lightSetting)
        {
            this.setting = setting;
            renderer = new DefferRender(setting.cameraShader);
            this.shadow = shadow;
            postFX = postFXSetting;
            this.lightSetting = lightSetting;
        }


        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            foreach (Camera camera in cameras)
            {
                //调用实际渲染类，对单个摄像机进行渲染
                renderer.Render(setting,
                    context, camera, shadow, postFX, lightSetting);
            }
        }
    }
}