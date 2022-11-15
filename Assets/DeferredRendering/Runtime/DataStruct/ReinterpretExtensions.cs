using System.Runtime.InteropServices;

namespace DefferedRender
{
	/// <summary>
	/// ������int����ת��Ϊfloat���࣬ע�����ת��ֵ����2����ת����Ҳ����2����ֵ���
	/// </summary>
	public static class ReinterpretExtensions
	{

		[StructLayout(LayoutKind.Explicit)]
		struct IntFloat
		{

			[FieldOffset(0)]
			public int intValue;

			[FieldOffset(0)]
			public float floatValue;
		}

		public static float ReinterpretAsFloat(this int value)
		{
			IntFloat converter = default;
			converter.intValue = value;
			return converter.floatValue;
		}
	}
}