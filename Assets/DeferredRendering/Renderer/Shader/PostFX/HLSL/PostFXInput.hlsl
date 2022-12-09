#ifndef DEFFER_POST_INPUT
#define DEFFER_POST_INPUT


//获得主纹理的采用模式，因为需要采集雾效
SAMPLER(sampler_PostFXSource);
TEXTURE2D(_PostFXSource);
TEXTURE2D(_PostFXSource2);
TEXTURE2D(_PostFXSource3);

TEXTURE2D(_GBufferRT0);     //rgb:abledo,w:metalness
TEXTURE2D(_GBufferRT1);     //R,G:EncodeNormal
TEXTURE2D(_GBufferRT2);     //rgb:emissive,w:roughness
TEXTURE2D(_GBufferRT3);     //rgb:reflect,w:AO
TEXTURE2D(_SSSTargetTex);
// TEXTURE2D(_GBufferDepthTex);    //depth Tex
SAMPLER(sampler_GBufferRT1);


float4x4 _FrustumCornersRay;
float4x4 _InverseProjectionMatrix;
float4x4 _ViewToScreenMatrix;
float4x4 _InverseVPMatrix;

float4 _ScreenSize;


float4 _PostFXSource_TexelSize;
bool _BloomBicubicUpsampling;
float _BloomIntensity;
float4 _BloomThreshold;

float _BulkLightCheckMaxDistance;
float _BulkSampleCount;
float _BulkLightShrinkRadio;
float _BulkLightScatterRadio;

float _BilaterFilterFactor;
float4 _BlurRadius;

float _FocusDistance;       //聚焦位置
float _FocusRange;          //Fade范围
float _BokehRadius;         //角度调整

// #define _COUNT 6
// float4 _Colors[_COUNT];  //颜色计算用的数据

float4 GetSourceTexelSize () {
	return _PostFXSource_TexelSize;
}

float4 GetSource(float2 screenUV) {
	return SAMPLE_TEXTURE2D_LOD(_PostFXSource, sampler_linear_clamp, screenUV, 0);
}

float4 GetSourceBicubic (float2 screenUV) {
	return SampleTexture2DBicubic(
		TEXTURE2D_ARGS(_PostFXSource, sampler_linear_clamp), screenUV,
		_PostFXSource_TexelSize.zwxy, 1.0, 0.0
	);
}

float4 GetSource2(float2 screenUV) {
	return SAMPLE_TEXTURE2D_LOD(_PostFXSource2, sampler_linear_clamp, screenUV, 0);
}

// float3 GetWorldPos(float depth, float2 uv){
//     #if defined(UNITY_REVERSED_Z)
//         depth = 1 - depth;
//     #endif
// 	float4 ndc = float4(uv.x * 2 - 1, uv.y * 2 - 1, depth * 2 - 1, 1);

// 	float4 worldPos = mul(_InverseVPMatrix, ndc);
// 	worldPos /= worldPos.w;
// 	return worldPos.xyz;
// }


#define random(seed) sin(seed * 641.5467987313875 + 1.943856175)



float3 GetBulkLight(float depth, float2 screenUV, float3 interpolatedRay){
    float bufferDepth = IsOrthographicCamera() ? OrthographicDepthBufferToLinear(depth) 
		: LinearEyeDepth(depth, _ZBufferParams);

    float3 worldPos = _WorldSpaceCameraPos + bufferDepth * interpolatedRay;
    float3 startPos = _WorldSpaceCameraPos + _ProjectionParams.y * interpolatedRay;

    float3 direction = normalize(worldPos - startPos);
    float dis = length(worldPos - startPos);

    float m_length = min(_BulkLightCheckMaxDistance, dis);
    float perNodeLength = m_length / _BulkSampleCount;
    float perDepthLength = bufferDepth / _BulkSampleCount;
    float3 currentPoint = startPos;
    float3 viewDirection = normalize(_WorldSpaceCameraPos - worldPos);

    float3 color = 0;
    float seed = random((screenUV.y + screenUV.x) * _ScreenParams.x * _ScreenParams.y * _ScreenParams.z + 0.2312312);
    // float seed = random((screenUV.y + screenUV.x) * 1000 + 0.2312312);
    float currentDepth = 0;

    // UNITY_UNROLL
    for(int i=0; i<_BulkSampleCount; i++){
        currentPoint += direction * perNodeLength;
        currentDepth += perDepthLength;
        float3 tempPosition = lerp(currentPoint, currentPoint + direction * perNodeLength, seed);
        color += GetBulkLighting(tempPosition, viewDirection, screenUV, _BulkLightScatterRadio, currentDepth);
    }
    color *= m_length * _BulkLightShrinkRadio ;

    return color;
}

half LinearRgbToLuminance(half3 linearRgb)
{
    return dot(linearRgb, half3(0.2126729f,  0.7151522f, 0.0721750f));
}

float CompareColor(float4 col1, float4 col2)
{
	float l1 = LinearRgbToLuminance(col1.rgb);
	float l2 = LinearRgbToLuminance(col2.rgb);
	return smoothstep(_BilaterFilterFactor, 1.0, 1.0 - abs(l1 - l2));
}


float SampleLuminance (float2 uv) {
    #if defined(LUMINANCE_GREEN)
        return GetSource(uv).g;
    #else
        return GetSource(uv).a;
    #endif
}

float SampleLuminance (float2 uv, float uOffset, float vOffset) {
    uv += _PostFXSource_TexelSize.xy * float2(uOffset, vOffset);
    return SampleLuminance(uv);
}

struct LuminanceData {
    float m, n, e, s, w;
    float ne, nw, se, sw;
    float highest, lowest, contrast;
};
float _ContrastThreshold, _RelativeThreshold;
float _SubpixelBlending;

LuminanceData SampleLuminanceNeighborhood (float2 uv) {
    LuminanceData l;
    l.m = SampleLuminance(uv);			//中间
    //上下左右
    l.n = SampleLuminance(uv, 0,  1);
    l.e = SampleLuminance(uv, 1,  0);
    l.s = SampleLuminance(uv, 0, -1);
    l.w = SampleLuminance(uv,-1,  0);

    //东南、东北方向等四个方向
    l.ne = SampleLuminance(uv,  1,  1);
    l.nw = SampleLuminance(uv, -1,  1);
    l.se = SampleLuminance(uv,  1, -1);
    l.sw = SampleLuminance(uv, -1, -1);

    l.highest = max(max(max(max(l.n, l.e), l.s), l.w), l.m);	//最高亮度
    l.lowest = min(min(min(min(l.n, l.e), l.s), l.w), l.m);		//最低亮度
    l.contrast = l.highest - l.lowest;		//获得最高亮度与最低亮度之间的差
    return l;
}
		
//根据传入的阈值以及高度影响值，判断是否应该跳过该像素，不进行FXAA
bool ShouldSkipPixel (LuminanceData l) {
    float threshold =
        max(_ContrastThreshold, _RelativeThreshold * l.highest);
    return l.contrast < threshold;
}

//确定混合因子, 这个只控制边界的直接混合模式, 与边框的混合是独立的
float DeterminePixelBlendFactor (LuminanceData l) {
    float filter = 2 * (l.n + l.e + l.s + l.w);		//上下左右占比
    filter += l.ne + l.nw + l.se + l.sw;			//四边占比小一点
    filter *= 1.0 / 12;
    filter = abs(filter - l.m);			//混合因子由自身以及四周的对比度差决定
    filter = saturate(filter / l.contrast);		//根据对比度差进行归一化,不然进过上面变太小了
    float blendFactor = smoothstep(0, 1, filter);
    return blendFactor * blendFactor * _SubpixelBlending;
}

struct EdgeData {
    bool isHorizontal;
    float pixelStep;
    float oppositeLuminance, gradient;	//沿着边
};

//确定边缘，因为不是直接周围模糊，因此需要根据四周的灰度值判断可能的模糊朝向
//这里为了更好的效果，使用了四周采用，而不是直接十字
EdgeData DetermineEdge (LuminanceData l) {
    EdgeData e;
    float horizontal =
        abs(l.n + l.s - 2 * l.m) * 2 +
        abs(l.ne + l.se - 2 * l.e) +
        abs(l.nw + l.sw - 2 * l.w);
    float vertical =
        abs(l.e + l.w - 2 * l.m) * 2 +
        abs(l.ne + l.nw - 2 * l.n) +
        abs(l.se + l.sw - 2 * l.s);
    //检查水平还是垂直的亮度差大，大的就是要模糊的方向
    e.isHorizontal = horizontal >= vertical;

    //左右选一边
    float pLuminance = e.isHorizontal ? l.n : l.e;
    //上下选一边
    float nLuminance = e.isHorizontal ? l.s : l.w;
    
    //判断与中间的差
    float pGradient = abs(pLuminance - l.m);
    float nGradient = abs(nLuminance - l.m);

    //获得像素尺寸，比较等会是单边模糊，而上下的每一个像素数量是不一致的
    e.pixelStep =
        e.isHorizontal ? _PostFXSource_TexelSize.y : _PostFXSource_TexelSize.x;

    //最后确定偏移的方向，是正方向还是负方向，比较上面只判断了水平还是垂直
    if (pGradient < nGradient) {
        e.pixelStep = -e.pixelStep;
        e.oppositeLuminance = nLuminance;	//偏移值就是差值
        e.gradient = nGradient;		//存储上下的差，之后需要朝这边偏移
    }
    else {
        e.oppositeLuminance = pLuminance;
        e.gradient = pGradient;
    }
    return e;
}

#if defined(LOW_QUALITY)
    #define EDGE_STEP_COUNT 4
    #define EDGE_STEPS 1, 1.5, 2, 4
    #define EDGE_GUESS 12
#else
    #define EDGE_STEP_COUNT 10
    #define EDGE_STEPS 1, 1.5, 2, 2, 2, 2, 2, 2, 2, 4
    #define EDGE_GUESS 8
#endif

static const float edgeSteps[EDGE_STEP_COUNT] = { EDGE_STEPS };

float DetermineEdgeBlendFactor (LuminanceData l, EdgeData e, float2 uv) {
    float2 uvEdge = uv;
    float2 edgeStep;
    //目标是沿着边走，但是并没有必要每一个都这么做，因此对移动方向的另一边偏移，而且只移动一步，采集中间的平均值
    if (e.isHorizontal) {
        uvEdge.y += e.pixelStep * 0.5;
        edgeStep = float2(_PostFXSource_TexelSize.x, 0);
    }
    else {
        uvEdge.x += e.pixelStep * 0.5;
        edgeStep = float2(0, _PostFXSource_TexelSize.y);
    }

    float edgeLuminance = (l.m + e.oppositeLuminance) * 0.5;	//平均值
    float gradientThreshold = e.gradient * 0.25;	
    
    float2 puv = uvEdge + edgeStep * edgeSteps[0];	//进行偏移
    float pLuminanceDelta = SampleLuminance(puv) - edgeLuminance;
    bool pAtEnd = abs(pLuminanceDelta) >= gradientThreshold;		//如果大于，就是到达边缘了

    //持续循环，查找边缘，且使用展开循环指令，优化性能
    int i;
    UNITY_UNROLL
    for (i = 1; i < EDGE_STEP_COUNT && !pAtEnd; i++) {
        puv += edgeStep * edgeSteps[i];
        pLuminanceDelta = SampleLuminance(puv) - edgeLuminance;
        pAtEnd = abs(pLuminanceDelta) >= gradientThreshold;
    }
    if (!pAtEnd) {
        puv += edgeStep * EDGE_GUESS;
    }

    float2 nuv = uvEdge - edgeStep * edgeSteps[0];
    float nLuminanceDelta = SampleLuminance(nuv) - edgeLuminance;
    bool nAtEnd = abs(nLuminanceDelta) >= gradientThreshold;

    // UNITY_UNROLL
    for (i = 1; i < EDGE_STEP_COUNT && !nAtEnd; i++) {
        nuv -= edgeStep * edgeSteps[i];
        nLuminanceDelta = SampleLuminance(nuv) - edgeLuminance;
        nAtEnd = abs(nLuminanceDelta) >= gradientThreshold;
    }
    if (!nAtEnd) {
        nuv -= edgeStep * EDGE_GUESS;
    }

    float pDistance, nDistance;
    if (e.isHorizontal) {
        pDistance = puv.x - uv.x;
        nDistance = uv.x - nuv.x;
    }
    else {
        pDistance = puv.y - uv.y;
        nDistance = uv.y - nuv.y;
    }
    
    float shortestDistance;
    bool deltaSign;
    if (pDistance <= nDistance) {
        shortestDistance = pDistance;
        deltaSign = pLuminanceDelta >= 0;
    }
    else {
        shortestDistance = nDistance;
        deltaSign = nLuminanceDelta >= 0;
    }

    if (deltaSign == (l.m - edgeLuminance >= 0)) {
        return 0;
    }
    return 0.5 - shortestDistance / (pDistance + nDistance);
}

float4 ApplyFXAA (float2 uv) {
    LuminanceData l = SampleLuminanceNeighborhood(uv);
    if (ShouldSkipPixel(l)) {		//跳过不需要的像素
        return GetSource(uv);
    }

    float pixelBlend = DeterminePixelBlendFactor(l);
    EdgeData e = DetermineEdge(l);

    float edgeBlend = DetermineEdgeBlendFactor(l, e, uv);
    float finalBlend = max(pixelBlend, edgeBlend);

    // return finalBlend;

    if (e.isHorizontal) {
        uv.y += e.pixelStep * finalBlend;
    }
    else {
        uv.x += e.pixelStep * finalBlend;
    }
    return float4(GetSource(uv).rgb, l.m);
}

//------------------------------CameraStickWater----------------------------

float4 _StickWaterData;     //x:水珠数量、y:偏移程度、z:大小、w:速度

float3 N13(float p) {
    float3 p3 = frac(float3(p,p,p) * float3(.1031,.11369,.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return frac(float3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}
float4 N14(float t) {
    return frac(sin(t*float4(123., 1024., 1456., 264.))*float4(6547., 345., 8799., 1564.));
}
float N(float t) {
    return frac(sin(t*12345.564)*7658.76);
}
float Saw(float b, float t) {
    return smoothstep(0., b, t)*smoothstep(1., b, t);
}

float2 DropLayer2(float2 uv, float t) {
    float2 UV = uv;
    
    uv.x *= _PostFXSource_TexelSize.y / _PostFXSource_TexelSize.x;
    uv.y += t * 0.75;
    float2 a = float2(_PostFXSource_TexelSize.x / _PostFXSource_TexelSize.y, 1);
    // float2 a = _PostFXSource_TexelSize.x / _PostFXSource_TexelSize.y;
    float2 grid = a * 2.;
    // float2 grid = a;
    float2 id = floor(uv * grid);
    
    float colShift = N(id.x); 
    uv.y += colShift;
    
    id = floor(uv * grid);
    float3 n = N13(id.x * 35.2 + id.y * 2376.1);
    float2 st = frac(uv * grid) - float2(0.5, 0);
    
    float x = n.x - 0.5;
    
    float y = UV.y * 20;
    float wiggle = sin(y + sin(y));
    x += wiggle * (0.5 - abs(x)) * (n.z - 0.5);
    x *= _StickWaterData.y;
    float ti = frac(t + n.z);
    y = (Saw(0.85, ti) - 0.5) * 0.9 + 0.5;
    float2 p = float2(x, y);
    
    float d = length((st - p) * a.yx);
    
    float mainDrop = smoothstep(_StickWaterData.z, 0, d);
    
    float r = sqrt(smoothstep(1, y, st.y));
    float cd = abs(st.x - x);
    float trail = smoothstep(0.23 * r, 0.15 * r * r, cd);
    float trailFront = smoothstep(-0.02, 0.02, st.y - y);
    trail *= trailFront * r * r;
    
    y = UV.y;
    float trail2 = smoothstep(0.2 * r, 0.0, cd);
    float droplets = max(0, (sin(y * (1 - y) * 120) - st.y)) * trail2 * trailFront*n.z;
    y = frac(y*10.)+(st.y-.5);
    float dd = length(st-float2(x, y));
    droplets = smoothstep(.3, 0., dd);
    // float m = mainDrop+droplets*r*trailFront; 
    float m = mainDrop; 
    // float m = droplets*r*trailFront; 
    // float m = mainDrop ; 
    
    return float2(m, trail);
}

float StaticDrops(float2 uv, float t) {
    uv *= 40.;
    uv.x *= _PostFXSource_TexelSize.y / _PostFXSource_TexelSize.x;
    
    float2 id = floor(uv);
    uv = frac(uv)-.5;
    float3 n = N13(id.x * 107.45 + id.y * 3543.654);
    float2 p = (n.xy-.5)*.7;
    float d = length(uv-p);
    
    float fade = Saw(.025, frac(t+n.z));
    float c = smoothstep(.3, 0., d)*frac(n.z*10.)*fade;
    return c;
}

float2 Drops(float2 uv, float t, float l0, float l1, float l2) {
    float s = StaticDrops(uv, t); 
    float2 m1 = 0;
    float2 m2 = DropLayer2(uv, t) * l2;
    
    float c = s + m1.x + m2.x;
    c = smoothstep(0.3, 1, c);
    
    return float2(c, max(m1.y * l0, m2.y * l1));
}

float2 DropsDynamic(float2 uv, float t, float l1, float l2)
{
    //两个水珠，更随机
    float2 m1 = DropLayer2(uv, t)*l1;
    float2 m2 = DropLayer2(uv*1.75, t)*l2;
    
    float c = m1.x+m2.x;
    c = smoothstep(.4, 1., c);
    
    return float2(c, max(0, m2.y*l1));
}

//------------------------------CameraStickWater----------------------------

half Weigh (half3 c) {
    return 1 / (1 + max(max(c.r, c.g), c.b));
}

half Weigh (half coc, half radius) {
    return saturate((coc - radius + 2) / 2);
}

#define BOKEH_KERNEL_MEDIUM

#if defined(BOKEH_KERNEL_SMALL)
    static const int kernelSampleCount = 16;
    static const float2 kernel[kernelSampleCount] = {
        float2(0, 0),
        float2(0.54545456, 0),
        float2(0.16855472, 0.5187581),
        float2(-0.44128203, 0.3206101),
        float2(-0.44128197, -0.3206102),
        float2(0.1685548, -0.5187581),
        float2(1, 0),
        float2(0.809017, 0.58778524),
        float2(0.30901697, 0.95105654),
        float2(-0.30901703, 0.9510565),
        float2(-0.80901706, 0.5877852),
        float2(-1, 0),
        float2(-0.80901694, -0.58778536),
        float2(-0.30901664, -0.9510566),
        float2(0.30901712, -0.9510565),
        float2(0.80901694, -0.5877853),
    };
#elif defined (BOKEH_KERNEL_MEDIUM)
    static const int kernelSampleCount = 22;
    static const float2 kernel[kernelSampleCount] = {
        float2(0, 0),
        float2(0.53333336, 0),
        float2(0.3325279, 0.4169768),
        float2(-0.11867785, 0.5199616),
        float2(-0.48051673, 0.2314047),
        float2(-0.48051673, -0.23140468),
        float2(-0.11867763, -0.51996166),
        float2(0.33252785, -0.4169769),
        float2(1, 0),
        float2(0.90096885, 0.43388376),
        float2(0.6234898, 0.7818315),
        float2(0.22252098, 0.9749279),
        float2(-0.22252095, 0.9749279),
        float2(-0.62349, 0.7818314),
        float2(-0.90096885, 0.43388382),
        float2(-1, 0),
        float2(-0.90096885, -0.43388376),
        float2(-0.6234896, -0.7818316),
        float2(-0.22252055, -0.974928),
        float2(0.2225215, -0.9749278),
        float2(0.6234897, -0.7818316),
        float2(0.90096885, -0.43388376),
    };
#endif

#endif