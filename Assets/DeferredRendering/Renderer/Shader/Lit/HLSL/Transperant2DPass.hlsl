#ifndef DEFFER_TRANSPARENT2D_PASS_INCLUDED
#define DEFFER_TRANSPARENT2D_PASS_INCLUDED

// #include "../../ShaderLibrary/Surface.hlsl"
// #include "../../ShaderLibrary/Shadows.hlsl"
// #include "../../ShaderLibrary/Light.hlsl"
// #include "../../ShaderLibrary/BRDF.hlsl"
// #include "../../ShaderLibrary/GI.hlsl"
// #include "../../ShaderLibrary/Lighting.hlsl"


struct Attributes2D
{
    float4 vertex   : POSITION;
    float2 texcoord : TEXCOORD0;
	float4 color : COLOR;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings2D
{
    float4 positionCS_SS   : SV_POSITION;
    float2 baseUV  : TEXCOORD0;
	float4 color : COLOR;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

#define _2D_Normal float3(0, 0, -1)

Varyings2D LitPassVertex (Attributes2D input) {
	Varyings2D output = (Varyings2D)0;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	output.positionCS_SS = TransformObjectToHClip(input.vertex.xyz);
	output.baseUV = TransformBaseUV(input.texcoord);
	output.color = input.color;

	return output;
}


float4 LitPassFragment (Varyings2D input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);
	InputConfig config = GetInputConfig(input.baseUV);
	float4 base = GetBase(config) * input.color;

	return base;
}


#endif