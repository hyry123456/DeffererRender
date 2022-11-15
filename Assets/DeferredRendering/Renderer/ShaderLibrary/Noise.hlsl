#ifndef CUSTOM_NOISE_INCLUDE
#define CUSTOM_NOISE_INCLUDE

//生成随机方向
float3 hash3d(float3 input) {
    const float3 k = float3(0.3183099, 0.3678794, 0.38975765);
    input = input * k + k.zyx;
    return -1.0 + 2.0 * frac(16.0 * k * frac(input.x * input.y * input.z * (input.x + input.y + input.z)));
}
float2 hash2d(float2 input) {
    const float2 k = float2(0.3183099, 0.3678794);
    input = input * k + k.yx;
    return -1.0 + 2.0 * frac(16.0 * k * frac(input.x * input.y * (input.x + input.y)));
}

//进行插值
float Cos_Interpolate(float a, float b, float t)
{
    float ft = t * 3.14159;
    t = (1 - cos(ft)) * 0.5;
    return a * (1 - t) + t * b;
}

//根据3维坐标生成一个float值
float Perlin3DFun(float3 pos) {
    float3 i = floor(pos);
    float3 f = frac(pos);

    //获得八个点，也就是立方体的八个点的对应向量
    float3 g0 = hash3d(i + float3(0.0, 0.0, 0.0));
    float3 g1 = hash3d(i + float3(1.0, 0.0, 0.0));
    float3 g2 = hash3d(i + float3(0.0, 1.0, 0.0));
    float3 g3 = hash3d(i + float3(0.0, 0.0, 1.0));
    float3 g4 = hash3d(i + float3(1.0, 1.0, 0.0));
    float3 g5 = hash3d(i + float3(0.0, 1.0, 1.0));
    float3 g6 = hash3d(i + float3(1.0, 0.0, 1.0));
    float3 g7 = hash3d(i + float3(1.0, 1.0, 1.0));

    //获得点乘后的大小
    float v0 = dot(g0, f - float3(0.0, 0.0, 0.0));  //左前下
    float v1 = dot(g1, f - float3(1.0, 0.0, 0.0));  //右前下
    float v2 = dot(g2, f - float3(0.0, 1.0, 0.0));  //左前上
    float v3 = dot(g3, f - float3(0.0, 0.0, 1.0));  //左后下
    float v4 = dot(g4, f - float3(1.0, 1.0, 0.0));  //右前上
    float v5 = dot(g5, f - float3(0.0, 1.0, 1.0));  //左后上
    float v6 = dot(g6, f - float3(1.0, 0.0, 1.0));  //右后下
    float v7 = dot(g7, f - float3(1.0, 1.0, 1.0));  //右后上

    float inter0 = Cos_Interpolate(v0, v2, f.y);
    float inter1 = Cos_Interpolate(v1, v4, f.y);
    float inter2 = Cos_Interpolate(inter0, inter1, f.x);    //前4点

    float inter3 = Cos_Interpolate(v3, v5, f.y);
    float inter4 = Cos_Interpolate(v6, v7, f.y);
    float inter5 = Cos_Interpolate(inter3, inter4, f.x);

    float inter6 = Cos_Interpolate(inter2, inter5, f.z);

    return inter6;
}

float Perlin2DFun(float2 pos) {
    float2 i = floor(pos);
    float2 f = frac(pos);

    //获得四个点，也就是立方体的八个点的对应向量
    float2 g0 = hash2d(i + float2(0.0, 0.0));
    float2 g1 = hash2d(i + float2(1.0, 0.0));
    float2 g2 = hash2d(i + float2(0.0, 1.0));
    float2 g3 = hash2d(i + float2(1.0, 1.0));

    //获得点乘后的大小
    float v0 = dot(g0, f - float2(0.0, 0.0));
    float v1 = dot(g1, f - float2(1.0, 0.0));
    float v2 = dot(g2, f - float2(0.0, 1.0));
    float v3 = dot(g3, f - float2(1.0, 1.0));

    float inter0 = Cos_Interpolate(v0, v1, f.x);
    float inter1 = Cos_Interpolate(v2, v3, f.x);

    return Cos_Interpolate(inter0, inter1, f.y);
}

//采用噪声，且是多次采用
float Perlin3DFBM(float3 pos, int octave) {
    float noise = 0.0;
    float frequency = 1.0;
    float amplitude = 1.0;

    for (int i = 0; i < octave; i++)
    {
        noise += Perlin3DFun(pos * frequency) * amplitude;
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return noise;
}

float Perlin2DFBM(float2 pos, int octave) {
    float noise = 0.0;
    float frequency = 1.0;
    float amplitude = 1.0;

    for (int i = 0; i < octave; i++)
    {
        noise += Perlin2DFun(pos * frequency) * amplitude;
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return noise;
}

struct AnimateUVData {
    float4 uvData;			//uv偏移时需要的数据
    float interpolation;
};


//计算uv偏移数据
AnimateUVData AnimateUV(float time_01, int rowCount, int columnCount) {
    float sumTime = rowCount * columnCount;
    float midTime = time_01 * sumTime;

    float bottomTime = floor(midTime);      //整数最小时间
    float topTime = bottomTime + 1.0;       //整数最大时间
    float interpolation = (midTime - bottomTime) / (topTime - bottomTime);  //确定比例
    float bottomRow = floor(bottomTime / rowCount);
    float bottomColumn = floor(bottomTime - bottomRow * columnCount);
    float topRow = floor(topTime / rowCount);
    float topColumn = floor(topTime - topRow * columnCount);

    AnimateUVData animateUV;
    animateUV.uvData = float4(bottomColumn, -bottomRow, topColumn, -topRow);
    animateUV.interpolation = interpolation;
    return animateUV;
}


#endif