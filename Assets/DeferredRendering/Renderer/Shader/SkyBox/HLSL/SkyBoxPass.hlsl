#ifndef SKYBOX_PASS
#define SKYBOX_PASS

#include "../../ShaderLibrary/Surface.hlsl"
#include "../../ShaderLibrary/Shadows.hlsl"
#include "../../ShaderLibrary/Light.hlsl"
#include "../../ShaderLibrary/Noise.hlsl"
#include "SkyBoxInput.hlsl"

struct appdata
{
    float3 vertex : POSITION;
    float3 uv3D : TEXCOORD0;
};

struct v2f
{
    float3 uv3D : TEXCOORD0;
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD1;
};


v2f vert(appdata v)
{
    v2f o;
    o.positionWS = TransformObjectToWorld(v.vertex);
    o.uv3D = v.uv3D;
    o.positionCS = TransformWorldToHClip(o.positionWS);
    return o;
}

float4 frag(v2f input) : SV_Target
{
    //所有太阳和月亮的颜色值
    float3 direction = _DirectionalLightDirectionsAndMasks[0].xyz;
    float3 sunColor = _DirectionalLightColors[0].rgb;
    //确定距离中心点的距离
    float sun = distance(input.uv3D, direction);
    //让值变为越近越大
    float sunDisc = 1 - (sun / _SunRadius);
    //以上计算会有明显渐变，所以需要乘以一个较大的数，让渐变消失
    sunDisc = saturate(sunDisc * 50);

    //月亮的计算原理类似，不过方向要相反，在黑夜时才出现月亮
    float moon = distance(input.uv3D, -direction);
    //月亮的球绘制，具体的月亮确实在下面实现
    float moonDisc = 1 - (moon / _MoonRadius);
    moonDisc = saturate(moonDisc * 50);

    //计算月亮被遮挡效果，实际上就是再计算一个球，这个球沿x偏移，将这个球的值与当前月亮值相减
    //达到有一角少了一部分亮度的效果，这一部分亮度，就是月亮缺失的来源
    float crescentMoon = distance(float3(input.uv3D.x + _MoonOffset, input.uv3D.yz), -direction);
    float crescentMoonDisc = 1 - (crescentMoon / _MoonRadius);
    crescentMoonDisc = saturate(crescentMoonDisc * 50);
    moonDisc = saturate(moonDisc - crescentMoonDisc);

    float3 SunAndMoon = (sunDisc * _SunColor.rgb * sunColor) + (moonDisc * _MoonColor.rgb);


    //计算云朵的uv，实际上这种计算方式就是因为xz轴是沿平面延申的，除以y轴后会让近的部分的uv缩小
    //而且根据数学推断，这样除以之后由于uv的距离为1，实际上这些值都会接近一个恒值
    //同时使用世界坐标，可以裁剪掉下面的云层
    float2 skyuv = input.positionWS.xz / (step(0, input.positionWS.y) * input.positionWS.y);


    //星星
    float stars = SAMPLE_TEXTURE2D(_Stars, sampler_Stars, (skyuv + float2(_StarsSpeed, _StarsSpeed) * _Time.x) * _StarsFrequency).r;
    float3 starsCol = step(_StarsCutoff, stars) * _StarsSkyColor * saturate(-direction.y);


    //云朵
    float cloud = SAMPLE_TEXTURE2D(_Cloud, sampler_Cloud, (skyuv + float2(_CloudSpeed, _CloudSpeed) * _Time.x) * _CloudFrequency).r;
    float distort = SAMPLE_TEXTURE2D(_Cloud, sampler_Cloud, (skyuv + (_Time.x * _DistortionSpeed)) * _DistortScale).g;
    float noise = SAMPLE_TEXTURE2D(_Cloud, sampler_Cloud, ((skyuv + distort) - (_Time.x * _CloudSpeed)) * _CloudNoiseScale).b;

    float3 cloudCol = saturate(smoothstep(saturate(_CloudCutoff - 0.2), _CloudCutoff, cloud * noise)) * 
        lerp(_CloudDayColor, _CloudNightColor, saturate(-direction.y * 0.5 + 0.5));
    cloudCol += saturate(smoothstep( _CloudCutoff, saturate(_CloudCutoff + 0.2), cloud * distort)) * 
        lerp(_CloudDayColor * 0.3, _CloudNightColor * 0.3, saturate(-direction.y * 0.5 + 0.5));

    starsCol *= (1 - cloudCol);

    float ypos = saturate(input.uv3D.y);

    float3 gradientDay = lerp(_DayBottomColor, _DayTopColor, ypos);
    float3 gradientNight = lerp(_NightBottomColor, _NightTopColor, ypos);
    float3 skyGradients = lerp(gradientNight, gradientDay, saturate(direction.y * 0.5 + 0.5));

    float horizon = abs((input.uv3D.y * _HorizonIntensity) - _HorizonHeight);
    float midline = saturate((1 - horizon * _MidLightIntensity));
    float3 horizonCol = saturate(1 - horizon) * ((_HorizonColorDay + midline * _HorizonLightDay) * saturate(direction.y * 10)
        + (_HorizonColorNight + midline * _HorizonLightNight) * saturate(-direction.y * 10)) * _HorizonBrightness;

    return float4(starsCol + cloudCol + skyGradients + horizonCol + SunAndMoon,1);
}
#endif