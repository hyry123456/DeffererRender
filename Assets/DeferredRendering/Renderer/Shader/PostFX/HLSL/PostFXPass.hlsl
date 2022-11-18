#ifndef DEFFER_POST_PASS
#define DEFFER_POST_PASS

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/BRDF.hlsl"
#include "../../ShaderLibrary/GI.hlsl"
#include "../../ShaderLibrary/Lighting.hlsl"
#include "PostFXInput.hlsl"

struct Attributes{
	float3 positionOS : POSITION;
	float2 baseUV : TEXCOORD0;
};

struct Varyings {
    float4 positionCS_SS : SV_POSITION;
    float2 screenUV : VAR_SCREEN_UV;
    float2 screenUV_depth : VAR_SCREEN_UV_DEPTH;
    float4 interpolatedRay : TEXCOORD2;
    float3 viewRay : VAR_VIEWRAY;
};

Varyings BlitPassSimpleVertex(Attributes input){
    Varyings output = (Varyings)0;
    output.positionCS_SS = TransformObjectToHClip(input.positionOS);
    output.screenUV = input.baseUV;
    return output;
}

Varyings BlitPassRayVertex(Attributes input){
    Varyings output = (Varyings)0;
    output.positionCS_SS = TransformObjectToHClip(input.positionOS);
    output.screenUV = input.baseUV;
    output.screenUV_depth = input.baseUV;

    #if UNITY_UV_STARTS_AT_TOP
        if (_PostFXSource_TexelSize.y < 0)
            output.screenUV_depth.y = 1 - output.screenUV_depth.y;
    #endif

    int index = 0;
    if (output.screenUV.x < 0.5 && output.screenUV.y < 0.5) {         //位于左下方区域，使用左下方的方向
        index = 0;
    }
    else if (output.screenUV.x > 0.5 && output.screenUV.y < 0.5) {    //位于右下方
        index = 1;
    }
    else if (output.screenUV.x > 0.5 && output.screenUV.y > 0.5) {    //右上方
        index = 2;
    }
    else {                                                  //左上方
        index = 3;
    }

    #if UNITY_UV_STARTS_AT_TOP
    if (_PostFXSource_TexelSize.y < 0)
        index = 3 - index;
    #endif

    output.interpolatedRay = _FrustumCornersRay[index];
    return output;
}



float4 DrawGBufferColorFragment(Varyings i) : SV_Target
{
    float bufferDepth = SAMPLE_DEPTH_TEXTURE_LOD(_GBufferDepthTex, sampler_point_clamp, i.screenUV, 0);
	float depth01 = Linear01Depth(bufferDepth, _ZBufferParams);
	float eyeDepth = IsOrthographicCamera() ? OrthographicDepthBufferToLinear(bufferDepth)
		: LinearEyeDepth(bufferDepth, _ZBufferParams);
    // bufferDepth = 
    Surface surface = (Surface)0;
    surface.position = _WorldSpaceCameraPos + eyeDepth * i.interpolatedRay.xyz;

	float4 rt0 = SAMPLE_TEXTURE2D(_GBufferRT0, sampler_GBufferRT1, i.screenUV);     	//rgb:abledo,w:metalness
	float2 rt1 = SAMPLE_TEXTURE2D(_GBufferRT1, sampler_GBufferRT1, i.screenUV).rg;     	//R,G:EncodeNormal
	float4 rt2 = SAMPLE_TEXTURE2D(_GBufferRT2, sampler_GBufferRT1, i.screenUV);     	//rgb:emissive,w:roughness
	// float4 rt3 = SAMPLE_TEXTURE2D(_GBufferRT3, sampler_GBufferRT1, i.screenUV);     	//rgb:reflect,w:AO
	float4 rt3 = SAMPLE_TEXTURE2D(_SSSTargetTex, sampler_GBufferRT1, i.screenUV);     	//rgb:reflect,w:AO

	float3 normalWS = UnpackNormalOct(rt1);
    surface.normal = normalWS;     //法线
    surface.viewDirection = normalize(_WorldSpaceCameraPos - surface.position);                                     //视线方向
    surface.depth = eyeDepth;                                                                                    //深度
    surface.metallic = rt0.w;
    surface.roughness = rt2.w;
    surface.dither = InterleavedGradientNoise(i.positionCS_SS.xy, 0);
	surface.ambientOcclusion = rt3.w;
	surface.color = rt0.rgb;


    float3 color;
    if(depth01 < 0.9){
		float3 uv_Depth = float3(i.screenUV, eyeDepth);
        color = GetGBufferLight(surface, uv_Depth);
		float3 reflect = rt3.rgb;
		color.xyz += rt3.rgb * surface.color;
		color.xyz *= rt3.w;
    }
    else{
        color = rt0.rgb;
    }
    color += rt2.rgb;

	#ifdef _DEFFER_FOG
		color.xyz = GetDefferFog(bufferDepth, surface.position, color.xyz);
	#endif

    return float4(color, 1);
}

float4 BulkLightFragment(Varyings input) : SV_TARGET{
    float bufferDepth = SAMPLE_DEPTH_TEXTURE_LOD(_GBufferDepthTex, sampler_point_clamp, input.screenUV, 0);
	float3 bulkLight = GetBulkLight(bufferDepth, input.screenUV, input.interpolatedRay.xyz);

	return float4(bulkLight, 1);
}

float4 BilateralFilterFragment (Varyings input) : SV_TARGET{
	float2 delta = _PostFXSource_TexelSize.xy * _BlurRadius.xy;
	//采集Normal的颜色值
	float4 col =   SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV);
	float4 col0a = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV - delta);
	float4 col0b = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + delta);
	float4 col1a = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV - 2.0 * delta);
	float4 col1b = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + 2.0 * delta);
	float4 col2a = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV - 3.0 * delta);
	float4 col2b = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + 3.0 * delta);

	float w = 0.37004405286;
	float w0a = CompareColor(col, col0a) * 0.31718061674;
	float w0b = CompareColor(col, col0b) * 0.31718061674;
	float w1a = CompareColor(col, col1a) * 0.19823788546;
	float w1b = CompareColor(col, col1b) * 0.19823788546;
	float w2a = CompareColor(col, col2a) * 0.11453744493;
	float w2b = CompareColor(col, col2b) * 0.11453744493;

	float3 result;
	result = w * col.rgb;
	result += w0a * col0a.rgb;
	result += w0b * col0b.rgb;
	result += w1a * col1a.rgb;
	result += w1b * col1b.rgb;
	result += w2a * col2a.rgb;
	result += w2b * col2b.rgb;

	result /= w + w0a + w0b + w1a + w1b + w2a + w2b;

	return float4(result, 1);
}

float4 BlendBulkLightFragment (Varyings input) : SV_TARGET{
	float4 originCol = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV);
	float4 bulkCol = SAMPLE_TEXTURE2D(_PostFXSource2, sampler_linear_clamp, input.screenUV);
	return float4(originCol.xyz + bulkCol.xyz, 1);
}

float4 BloomAddPassFragment (Varyings input) : SV_TARGET {
	float3 lowRes;
	if (_BloomBicubicUpsampling) {
		lowRes = GetSourceBicubic(input.screenUV).rgb;
	}
	else {
		lowRes = GetSource(input.screenUV).rgb;
	}
	float4 highRes = GetSource2(input.screenUV);
	return float4(lowRes * _BloomIntensity + highRes.rgb, highRes.a);
}

float4 BloomHorizontalPassFragment (Varyings input) : SV_TARGET {
	float3 color = 0.0;
	float offsets[] = {
		-3.23076923, -1.38461538, 0.0, 1.38461538, 3.23076923
	};
	float weights[] = {
		0.07027027, 0.31621622, 0.22702703, 0.31621622, 0.07027027
	};
	for (int i = 0; i < 5; i++) {
		float offset = offsets[i] * GetSourceTexelSize().y;
		color += GetSource(input.screenUV + float2(offset, 0.0)).rgb * weights[i];
	}
	return float4(color, 1.0);
}

float4 BloomVerticalPassFragment(Varyings input) : SV_TARGET{
	float3 color = 0.0;
	float offsets[] = {
		-3.23076923, -1.38461538, 0.0, 1.38461538, 3.23076923
	};
	float weights[] = {
		0.07027027, 0.31621622, 0.22702703, 0.31621622, 0.07027027
	};
	for (int i = 0; i < 5; i++) {
		float offset = offsets[i] * GetSourceTexelSize().y;
		color += GetSource(input.screenUV + float2(0.0, offset)).rgb * weights[i];
	}
	return float4(color, 1.0);
}


float3 ApplyBloomThreshold (float3 color) {
	float brightness = Max3(color.r, color.g, color.b);
	float soft = brightness + _BloomThreshold.y;
	soft = clamp(soft, 0.0, _BloomThreshold.z);
	soft = soft * soft * _BloomThreshold.w;
	float contribution = max(soft, brightness - _BloomThreshold.x);
	contribution /= max(brightness, 0.00001);
	return color * contribution;
}

float4 BloomPrefilterPassFragment (Varyings input) : SV_TARGET {
	float3 color = ApplyBloomThreshold(GetSource(input.screenUV).rgb);
	color = saturate(color);
	return float4(color, 1.0);
}

float4 BloomPrefilterFirefliesPassFragment (Varyings input) : SV_TARGET {
	float3 color = 0.0;
	float weightSum = 0.0;
	float2 offsets[] = {
		float2(0.0, 0.0),
		float2(-1.0, -1.0), float2(-1.0, 1.0), float2(1.0, -1.0), float2(1.0, 1.0)
	};
	for (int i = 0; i < 5; i++) {
		float3 c =
			GetSource(input.screenUV + offsets[i] * GetSourceTexelSize().xy * 2.0).rgb;
		c = ApplyBloomThreshold(c);
		float w = 1.0 / (Luminance(c) + 1.0);
		color += c * w;
		weightSum += w;
	}
	color /= weightSum;
	color = saturate(color);
	return float4(color, 1.0);
}

float4 BloomScatterPassFragment (Varyings input) : SV_TARGET {
	float3 lowRes;
	if (_BloomBicubicUpsampling) {
		lowRes = GetSourceBicubic(input.screenUV).rgb;
	}
	else {
		lowRes = GetSource(input.screenUV).rgb;
	}
	float3 highRes = GetSource2(input.screenUV).rgb;
	return float4(lerp(highRes, lowRes, _BloomIntensity), 1.0);
}

float4 BloomScatterFinalPassFragment (Varyings input) : SV_TARGET {
	float3 lowRes;
	if (_BloomBicubicUpsampling) {
		lowRes = GetSourceBicubic(input.screenUV).rgb;
	}
	else {
		lowRes = GetSource(input.screenUV).rgb;
	}
	float4 highRes = GetSource2(input.screenUV);
	lowRes += highRes.rgb - ApplyBloomThreshold(highRes.rgb);
	return float4(lerp(highRes.rgb, lowRes, _BloomIntensity), highRes.a);
}



float4 CopyPassFragment (Varyings input) : SV_TARGET {
	return GetSource(input.screenUV);
}

float4 _ColorAdjustments;
float4 _ColorFilter;
float4 _WhiteBalance;
float4 _SplitToningShadows, _SplitToningHighlights;

float Luminance (float3 color, bool useACES) {
	return useACES ? AcesLuminance(color) : Luminance(color);
}

float3 ColorGradePostExposure (float3 color) {
	return color * _ColorAdjustments.x;
}

float3 ColorGradeWhiteBalance (float3 color) {
	color = LinearToLMS(color);
	color *= _WhiteBalance.rgb;
	return LMSToLinear(color);
}

float3 ColorGradingContrast (float3 color, bool useACES) {
	color = useACES ? ACES_to_ACEScc(unity_to_ACES(color)) : LinearToLogC(color);
	color = (color - ACEScc_MIDGRAY) * _ColorAdjustments.y + ACEScc_MIDGRAY;
	return useACES ? ACES_to_ACEScg(ACEScc_to_ACES(color)) : LogCToLinear(color);
}

float3 ColorGradeColorFilter (float3 color) {
	return color * _ColorFilter.rgb;
}

float3 ColorGradingHueShift (float3 color) {
	color = RgbToHsv(color);
	float hue = color.x + _ColorAdjustments.z;
	color.x = RotateHue(hue, 0.0, 1.0);
	return HsvToRgb(color);
}

float3 ColorGradingSaturation (float3 color, bool useACES) {
	float luminance = Luminance(color, useACES);
	return (color - luminance) * _ColorAdjustments.w + luminance;
}

float3 ColorGradeSplitToning (float3 color, bool useACES) {
	color = PositivePow(color, 1.0 / 2.2);
	float t = saturate(Luminance(saturate(color), useACES) + _SplitToningShadows.w);
	float3 shadows = lerp(0.5, _SplitToningShadows.rgb, 1.0 - t);
	float3 highlights = lerp(0.5, _SplitToningHighlights.rgb, t);
	color = SoftLight(color, shadows);
	color = SoftLight(color, highlights);
	return PositivePow(color, 2.2);
}



float3 ColorGrade (float3 color, bool useACES = false) {
	color = ColorGradePostExposure(color);
	color = ColorGradeWhiteBalance(color);
	color = ColorGradingContrast(color, useACES);
	color = ColorGradeColorFilter(color);
	color = max(color, 0.0);
	color =	ColorGradeSplitToning(color, useACES);
	color = max(color, 0.0);
	color = ColorGradingHueShift(color);
	color = ColorGradingSaturation(color, useACES);
	return max(useACES ? ACEScg_to_ACES(color) : color, 0.0);
}

float4 _ColorGradingLUTParameters;

bool _ColorGradingLUTInLogC;

float3 GetColorGradedLUT (float2 uv, bool useACES = false) {
	float3 color = GetLutStripValue(uv, _ColorGradingLUTParameters);
	return ColorGrade(_ColorGradingLUTInLogC ? LogCToLinear(color) : color, useACES);
}

float4 ColorGradingNonePassFragment (Varyings input) : SV_TARGET {
	float3 color = GetColorGradedLUT(input.screenUV);
	return float4(color, 1.0);
}

float4 ColorGradingACESPassFragment (Varyings input) : SV_TARGET {
	float3 color = GetColorGradedLUT(input.screenUV, true);
	color = AcesTonemap(color);
	return float4(color, 1.0);
}

float4 ColorGradingNeutralPassFragment (Varyings input) : SV_TARGET {
	float3 color = GetColorGradedLUT(input.screenUV);
	color = NeutralTonemap(color);
	return float4(color, 1.0);
}

float4 ColorGradingReinhardPassFragment (Varyings input) : SV_TARGET {
	float3 color = GetColorGradedLUT(input.screenUV);
	color /= color + 1.0;
	return float4(color, 1.0);
}

TEXTURE2D(_ColorGradingLUT);


float3 ApplyColorGradingLUT (float3 color) {
	return ApplyLut2D(
		TEXTURE2D_ARGS(_ColorGradingLUT, sampler_linear_clamp),
		saturate(_ColorGradingLUTInLogC ? LinearToLogC(color) : color),
		_ColorGradingLUTParameters.xyz
	);
}

//最终影响后处理结果进行渲染到主摄像机的函数
float4 FinalPassFragment (Varyings input) : SV_TARGET {
	float4 color = GetSource(input.screenUV);
	float4 color2 = GetSource2(input.screenUV);
	color.rgb += color2.rgb;
	color.rgb = ApplyColorGradingLUT(color.rgb);
	return float4(color.rgb, 1);
}


float4 CaculateGray(Varyings input) : SV_TARGET{
	float4 bufferColor = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV);
	bufferColor.a = LinearRgbToLuminance(bufferColor.rgb);
	return bufferColor;
}

//抗锯齿
float4 FXAAFragment(Varyings input) : SV_TARGET{
	return ApplyFXAA(input.screenUV);
}


float CopyDepthPassFragment (Varyings input) : SV_DEPTH {
	return
        SAMPLE_DEPTH_TEXTURE_LOD(_PostFXSource, sampler_point_clamp, input.screenUV, 0);
}

//摄像机粘水
float4 CameraStickWaterFragment(Varyings input) : SV_TARGET{
	float4 fragColor = 0;
	float2 uv = input.screenUV;
	float2 UV = input.screenUV;
	float3 M = 2;
	float T = (_Time.y + M.x * 2) * _StickWaterData.w;

	float t = T*(.2+0.1*_StickWaterData.x);

	float rainAmount = M.y;

	uv *= 0.5;

	float staticDrops = smoothstep(-.5, 1., rainAmount) * 2.;
	float layer1 = smoothstep(.25, .75, rainAmount);
	float layer2 = smoothstep(.0, .5, rainAmount);

	float2 n = float2(0, 0);
	float2 c = Drops(uv, t, staticDrops, layer1, layer2);
	float2 e = float2(0.001, 0.);
	float cx = Drops(uv + e, t, staticDrops, layer1, layer2).x;
	float cy = Drops(uv + e.yx, t, staticDrops, layer1, layer2).x;
	n += float2(cx - c.x, cy - c.x);
	float moreRainAmount = 1.25 + 1.25 * _StickWaterData.x;
	for(float i = 1.25; i < moreRainAmount; i+=0.25)
	{
		float2 _c = DropsDynamic(uv, t*i, layer1, layer2);
		float _cx = DropsDynamic(uv + e, t*i, layer1, layer2).x;
		float _cy = DropsDynamic(uv + e.yx, t*i, layer1, layer2).x;
		n += float2(_cx - _c.x, _cy - _c.x);
	}

	float blend = (n.x + n.y)*(1.75 + _StickWaterData.x);
	// float3 col = tex2D(_MainTex, UV + n).rgb;
	float3 col = SAMPLE_TEXTURE2D_LOD(_PostFXSource, sampler_linear_clamp, UV + n, 0).rgb;
	fragColor = float4(col, blend);
	return fragColor;
}

//----------------------------------DepthOfField-------------------------------

float4 CircleOfConfusionFragment(Varyings input) : SV_TARGET{
	float depth = SAMPLE_DEPTH_TEXTURE(_GBufferDepthTex, sampler_point_clamp, input.screenUV);
	depth = LinearEyeDepth(depth, _ZBufferParams);

	float coc = (depth - _FocusDistance) / _FocusRange;
	coc = clamp(coc, -1, 1) * _BokehRadius;
	return coc;
}

float4 PreFilterFragment(Varyings input) : SV_TARGET{
	float4 o = _PostFXSource_TexelSize.xyxy * float2(-0.5, 0.5).xxyy;

	half3 s0 = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + o.xy).rgb;
	half3 s1 = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + o.zy).rgb;
	half3 s2 = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + o.xw).rgb;
	half3 s3 = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + o.zw).rgb;

	half w0 = Weigh(s0);
	half w1 = Weigh(s1);
	half w2 = Weigh(s2);
	half w3 = Weigh(s3);

	half3 color = s0 * w0 + s1 * w1 + s2 * w2 + s3 * w3;
	color /= max(w0 + w1 + w2 + s3, 0.00001);
	color = saturate(color);

	half coc0 = SAMPLE_TEXTURE2D(_PostFXSource2, sampler_linear_clamp, input.screenUV + o.xy).r;
	half coc1 = SAMPLE_TEXTURE2D(_PostFXSource2, sampler_linear_clamp, input.screenUV + o.zy).r;
	half coc2 = SAMPLE_TEXTURE2D(_PostFXSource2, sampler_linear_clamp, input.screenUV + o.xw).r;
	half coc3 = SAMPLE_TEXTURE2D(_PostFXSource2, sampler_linear_clamp, input.screenUV + o.zw).r;

	half cocMin = min(min(min(coc0, coc1), coc2), coc3);
	half cocMax = max(max(max(coc0, coc1), coc2), coc3);
	half coc = cocMax >= -cocMin ? cocMax : cocMin;

	return float4(color, coc);
}

float4 BokehFragment(Varyings input) : SV_TARGET{
	half coc = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV).a;
	
	half3 bgColor = 0, fgColor = 0;
	half bgWeight = 0, fgWeight = 0;
	for (int k = 0; k < kernelSampleCount; k++) {
		float2 o = kernel[k] * _BokehRadius;
		half radius = length(o);
		o *= _PostFXSource_TexelSize.xy;
		half4 s = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + o);

		half bgw = Weigh(max(0, min(s.a, coc)), radius);
		bgColor += s.rgb * bgw;
		bgWeight += bgw;

		half fgw = Weigh(-s.a, radius);
		fgColor += s.rgb * fgw;
		fgWeight += fgw;
	}
	bgColor *= 1 / (bgWeight + (bgWeight == 0));
	fgColor *= 1 / (fgWeight + (fgWeight == 0));
	half bgfg =
		min(1, fgWeight * 3.14159265359 / kernelSampleCount);
	half3 color = lerp(bgColor, fgColor, bgfg);
	return half4(color, bgfg);
}

float4 PostFilterFragment(Varyings input) : SV_TARGET{
	float4 o = _PostFXSource_TexelSize.xyxy * float2(-0.5, 0.5).xxyy;
	half4 s =
		SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + o.xy) +
		SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + o.zy) +
		SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + o.xw) +
		SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV + o.zw);
	return s * 0.25;
}

float4 CombineFragment(Varyings input) : SV_TARGET{
	half4 source = SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, input.screenUV);
	half coc = SAMPLE_TEXTURE2D(_PostFXSource2, sampler_linear_clamp, input.screenUV).r;
	half4 dof = SAMPLE_TEXTURE2D(_PostFXSource3, sampler_linear_clamp, input.screenUV);

	half dofStrength = smoothstep(0.1, 1, abs(coc));
	half3 color = lerp(
		source.rgb, dof.rgb,
		dofStrength + dof.a - dofStrength * dof.a
	);
	return float4(color, source.a);
}

//----------------------------------DepthOfField-------------------------------
#endif
