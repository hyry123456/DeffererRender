//片源处理文件，用来读取目前渲染到的主摄像机的数据
#ifndef FRAGMENT_INCLUDED
#define FRAGMENT_INCLUDED

//非透明物体的颜色图
// TEXTURE2D(_CameraColorTexture);
TEXTURE2D(PerFrameFinalTexture);
//非透明物体的深度图
TEXTURE2D(_CameraDepthTexture);
TEXTURE2D(_GBufferDepthTex);

float4 _CameraBufferSize;

struct Fragment {
	float2 positionSS;	//裁剪空间xy值
	float2 screenUV;	//屏幕空间的uv坐标
	float depth;		//深度值，这个是视角空间深度值，也就是视角空间的z
	float bufferDepth;	//存储目前的深度纹理的深度值
};

Fragment GetFragment (float4 positionSS) {
	Fragment f;
	f.positionSS = positionSS.xy;
	f.screenUV = f.positionSS * _CameraBufferSize.xy;	//屏幕空间的uv计算方式
	//视角深度计算方式，这里考虑了正交相机这种特殊情况
	f.depth = IsOrthographicCamera() ?
		OrthographicDepthBufferToLinear(positionSS.z) : positionSS.w;
	//采样buffer深度，目前并不是视角空间的深度
	f.bufferDepth =
		SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_point_clamp, f.screenUV, 0);
	//计算真正的视角空间深度，buffer的深度
	f.bufferDepth = IsOrthographicCamera() ? OrthographicDepthBufferToLinear(f.bufferDepth) 
		: LinearEyeDepth(f.bufferDepth, _ZBufferParams);
	return f;
}

//获得目前渲染的非透明物体的颜色值
float4 GetBufferColor (Fragment fragment, float2 uvOffset = float2(0.0, 0.0)) {
	float2 uv = fragment.screenUV + uvOffset;
	return SAMPLE_TEXTURE2D_LOD(PerFrameFinalTexture, sampler_linear_clamp, uv, 0);
}

float GetBufferDepth(Fragment fragment, float2 uvOffset = float2(0.0, 0.0)){
	float2 uv = fragment.screenUV + uvOffset;
	float bufferDepth =
		SAMPLE_DEPTH_TEXTURE_LOD(_GBufferDepthTex, sampler_point_clamp, uv, 0);
	//计算真正的视角空间深度，buffer的深度
	bufferDepth = IsOrthographicCamera() ?
		OrthographicDepthBufferToLinear(bufferDepth) :
		LinearEyeDepth(bufferDepth, _ZBufferParams);
	return bufferDepth;
}

#endif