using System.Runtime.InteropServices;

namespace DefferedRender
{
	/// <summary>
	/// 用来将int类型转化为float的类，注意这个转化值的是2进制转化，也就是2进制值相等
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