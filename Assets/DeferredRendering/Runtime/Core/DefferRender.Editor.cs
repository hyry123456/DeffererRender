using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

namespace DefferedRender { 
    public partial class DefferRender
    {
		partial void PrepareForSceneWindow();

		partial void PrepareBuffer();

		partial void DrawUnsupportedShaders();

		partial void DrawGizmosBeforeFX();
		partial void DrawGizmosAfterFX();


		string SampleName { get; set; }


#if UNITY_EDITOR //����һЩֻ�ڱ༭�����еķ���
		static ShaderTagId[] legacyShaderTagIds = {
			new ShaderTagId("Always"),
			new ShaderTagId("ForwardBase"),
			new ShaderTagId("PrepassBase"),
			new ShaderTagId("Vertex"),
			new ShaderTagId("VertexLMRGBM"),
			new ShaderTagId("VertexLM")
		};

		static Material errorMaterial;

		/// <summary>	/// ��UI�ܹ��ڴ������������ʾ	/// </summary>
		partial void PrepareForSceneWindow()
		{
			if (camera.cameraType == CameraType.SceneView)
			{   //ֻ�г���������ſ����ò���
				ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
			}
		}

		/// <summary>	/// ׼�����ܷ���������һ�δ��������	/// </summary>
		partial void PrepareBuffer()
		{
			Profiler.BeginSample("Editor Only");
			buffer.name = SampleName = camera.name;
			Profiler.EndSample();
		}

		/// <summary>	/// ����֧�ֵ��������һ�±���Ч��	/// </summary>
		partial void DrawUnsupportedShaders()
		{
			if (errorMaterial == null)
			{
				errorMaterial =
					new Material(Shader.Find("Hidden/InternalErrorShader"));
			}
			var drawingSettings = new DrawingSettings(
				legacyShaderTagIds[0], new SortingSettings(camera)
			)
			{
				overrideMaterial = errorMaterial
			};
			for (int i = 1; i < legacyShaderTagIds.Length; i++)
			{
				drawingSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
			}
			var filteringSettings = FilteringSettings.defaultValue;
			context.DrawRenderers(
				cullingResults, ref drawingSettings, ref filteringSettings
			);
		}

		partial void DrawGizmosBeforeFX()
		{
			if (Handles.ShouldRenderGizmos())
			{
				Draw(gBufferDepthId, BuiltinRenderTextureType.CameraTarget, CameraRenderMode._CopyDepth);
				ExecuteBuffer();
				context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
			}
		}

		partial void DrawGizmosAfterFX()
		{
			if (Handles.ShouldRenderGizmos())
			{
				context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
			}
		}
#endif
	}
}