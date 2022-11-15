using UnityEngine;

namespace DefferedRender {

	[DisallowMultipleComponent, RequireComponent(typeof(Camera))]
	public class DefferPipelineCamera : MonoBehaviour
	{

		[SerializeField]
		PostFXSetting settings = null;

		public PostFXSetting Settings => settings;
	}
}