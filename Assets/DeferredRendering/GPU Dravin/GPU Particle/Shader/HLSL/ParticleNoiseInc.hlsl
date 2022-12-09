#ifndef GPUPIPELINE_PARTICLE_NOISE_INCLUDE
#define GPUPIPELINE_PARTICLE_NOISE_INCLUDE

//单个粒子需要的数据
struct NoiseParticleData {
    float4 random;          //xyz是随机数，w是目前存活时间
    int2 index;             //状态标记，x是当前编号，y是是否存活
    float3 worldPos;        //当前位置
    float4 uvTransData;     //uv动画需要的数据
    float interpolation;    //插值需要的数据
    float4 color;           //颜色值，包含透明度
    float size;             //粒子大小
    float3 nowSpeed;        //xyz是当前速度，w是存活时间
};

//一组粒子需要的数据
struct ParticleGroupsData{
    float dieTime;        //死亡时间
};

#define _PI 3.1415926


RWStructuredBuffer<NoiseParticleData> _ParticleNoiseBuffer;     //所有的粒子数据
RWStructuredBuffer<ParticleGroupsData> _GroupBuffer;            //每一组粒子需要的数据
RWStructuredBuffer<CollsionStruct> _CollsionBuffer;            //该粒子可以碰撞到的所有物体

uint _CollsionData;    //碰撞体数量，为0表示不碰撞
float _CollsionScale;   //碰撞后的大小缩放
float _Obstruction;     //阻力

float _Arc;         //设置的角度，圆形初始化位置时用到该数据
float _Radius;      //球的半径
float3 _CubeRange;  //立方体范围

int _Octave;        //循环的次数，控制生成噪声的细节
float _Frequency;   //采样变化的频率，也就是对坐标的缩放大小
float _Intensity;   //影响的强度值

float4 _LifeTime;   //X释放时间，Y为存活时间，Z和W为贴合初始点时间范围
int4 _Mode;         //粒子模式, X为位置初始化模式，Y是速度初始化模式，Z是输出模式，W为是否需要物理模拟
float4x4 _RotateMatrix;   //旋转矩阵，用来确定粒子初始化位置，也就是将模型空间投影到世界空间
float4 _BeginSpeed;         //初始速度,w待定
float4 _SizeRange;          //大小范围，x，y是粒子大小范围，Z,W是当选中某个轴为大小模式时的映射范围


//使用参数方程作为坐标生成的根据
float3 GetSphereBeginPos(float2 random) {
    float3 pos;
    float u, _sin;
    u = lerp(-_Arc/2, _Arc / 2, random.y);
    pos.x = (random.x - 0.5) * 2;
    _sin = sqrt(1.0 - pos.x * pos.x);
    pos.z = cos(u) * _sin;
    pos.y = sin(u) * _sin;
    pos = normalize(pos) * _Radius;

    return mul(_RotateMatrix, float4(pos, 1)).xyz;
}
//根据传入数据进行的初始化
float3 GetSphereBeginPos(float2 random, float arc, float radius) {
    float3 pos;
    float u, _sin;
    u = lerp(-arc/2, arc / 2, random.y);
    pos.x = (random.x - 0.5) * 2;
    _sin = sqrt(1.0 - pos.x * pos.x);
    pos.z = cos(u) * _sin;
    pos.y = sin(u) * _sin;
    pos = normalize(pos) * radius;
    return pos;
}

float3 GetCubeBeginPos(float3 random){
    float3 begin = -_CubeRange/2.0;
    float3 end = _CubeRange/2.0;
    float3 pos = lerp(begin, end, random);
    return mul(_RotateMatrix, float4(pos, 1)).xyz;
}

float3 GetCubeBeginPos(float3 random, float3 cubeRange){
    float3 begin = -cubeRange/2.0;
    float3 end = cubeRange/2.0;
    float3 pos = lerp(begin, end, random);
    return pos;
}

//初始化位置的调用方法
float3 GetBeginPos(float3 ramdom){
    switch (_Mode.x){
        case 1:
            return GetSphereBeginPos(ramdom.yx);
        case 2:
            return GetCubeBeginPos(ramdom.yzx);
        default:
            return mul(_RotateMatrix, float4(0, 0, 0, 1)).xyz;
    }

}

//获得初始速度
float3 GetBeginSpeed(float random, float3 beginPos){

    float speed = length(_BeginSpeed.xyz) * random;    //根据速度大小确定一个随机速度
    float3 normal = normalize(_BeginSpeed.xyz);
    float3 direct = normalize(beginPos - mul(_RotateMatrix, float4(0, 0, 0, 1)).xyz);
    switch(_Mode.y){
        case 1:     //速度是法线以及大小，在粒子位置生成一个垂直于法线且是向外的力度
            return normalize( (direct - normal * dot(direct, normal)) ) * speed;
        case 2:     //在粒子位置生成一个垂直于法线且是向内的力度
            return -normalize( (direct - normal * dot(direct, normal)) ) * speed;
        case 3:     //朝向起始位置的速度，也就是往中间汇集
            return -direct * speed;
        case 4:     //离开起始位置的速度，也就是从中间往外面跑
            return direct * speed;
        default: //默认模式,传入速度就是初始化速度
            return _BeginSpeed.xyz;
    }
}

//初始化粒子
void InitialParticle(inout NoiseParticleData input) {
    input.worldPos = GetBeginPos(input.random.xyz);         //初始化坐标

    //改变取值位置，让速度与位置不要这么随机
    float random = (input.random.x + input.random.y + input.random.z)/3.0;
    input.nowSpeed = GetBeginSpeed(random, input.worldPos);     //初始化速度
    input.random.w = 0;             //初始化时间
    input.index.y = 1;              //标记为使用
}

//更新粒子
void UpdateParticle(inout NoiseParticleData particle, int groupIndex, int originIndex, float parLiveTime){
    particle.worldPos += particle.nowSpeed * _Time.y;      //更新位置
    particle.random.w += _Time.y;

}

//生成随机方向
float3 hash3d(float3 input) {
    const float3 k = float3(0.3183099, 0.3678794, 0.38975765);
    input = input * k + k.zyx;
    return -1.0 + 2.0 * frac(16.0 * k * frac(input.x * input.y * input.z * (input.x + input.y + input.z)));
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

//采样噪声，通过参数确定是否多次采样
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

//根据坐标生成一个方向
float3 CurlNoise3D(float3 pos, int octave)
{
    float eps = 0.1;
    float x = pos.x;
    float y = pos.y;
    float z = pos.z;
    float n1 = Perlin3DFBM(float3(x, y + eps, z), octave);
    float n2 = Perlin3DFBM(float3(x, y - eps, z), octave).x;
    float a = (n1 - n2) / (2.0 * eps);

    float n3 = Perlin3DFBM(float3(x + eps, y, z), octave).x;
    float n4 = Perlin3DFBM(float3(x - eps, y, z), octave).x;
    float b = (n3 - n4) / (2.0 * eps);

    float n5 = Perlin3DFBM(float3(x, y, z + eps), octave).x;
    float n6 = Perlin3DFBM(float3(x, y, z - eps), octave).x;
    float c = (n5 - n6) / (2.0 * eps);

    return float3(a, b, c);
}

void UpdataSpeed(inout NoiseParticleData input){
    input.nowSpeed += CurlNoise3D(input.worldPos * input.random.xyz * _Frequency, _Octave) * _Intensity * _Time.z;
}


// struct CollsionStruct
// {
//     float radius;        //用正负判断碰撞类型
//     float3 center;
//     float3 offset;      //碰撞偏移，只从中间往四周偏移
//     int mode;           //模式
// }


bool CheckCollsion(inout NoiseParticleData input){
    for(uint i = 0; i < _CollsionData; i++){
        CollsionStruct collider = _CollsionBuffer[i];
        switch(collider.mode){
            case 1:     //球型模式
                float3 duration = collider.center - input.worldPos;
                float len = length(duration);
                if(len <= collider.radius){
                    float3 forceDir = normalize(-duration);
                    float3 force = dot(input.nowSpeed, input.nowSpeed) * forceDir;
                    input.nowSpeed += force * _Time.z;
                    input.worldPos = normalize(-duration) * collider.radius + collider.center;
                    return true;
                }
                break;
            default:    //盒子碰撞
                //判断是否超过盒子范围
                float3 boxMax = collider.offset;
                float3 boxMin = -collider.offset;
                float3 currentPos = mul(collider.worldToLocal, float4(input.worldPos, 1)).xyz;
                float3 absDir = 0;
                if(currentPos.x < boxMax.x){
                    if(currentPos.x < boxMin.x)
                        break;
                    absDir.x = collider.offset.x - abs(currentPos.x);
                }
                else break;
                if(currentPos.y < boxMax.y){
                    if(currentPos.y < boxMin.y)
                        break;
                    absDir.y = collider.offset.y - abs(currentPos.y);
                }
                else break;
                if(currentPos.z < boxMax.z){
                    if(currentPos.z < boxMin.z)
                        break;
                    absDir.z = collider.offset.z - abs(currentPos.z);
                }
                else break;

                if(absDir.x < absDir.y){        //x小于y
                    if(absDir.x < absDir.z){    //x小于z
                        if(currentPos.x < 0){
                            currentPos.x = boxMin.x;
                        }
                        else{
                            currentPos.x = boxMax.x;
                        }
                        input.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;
                        float3 speed = mul((float3x3)collider.worldToLocal, input.nowSpeed.xyz);
                        speed.x = -speed.x * _CollsionScale;
                        input.nowSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                    else{               //z小于x
                        if(currentPos.z < 0){
                            currentPos.z = boxMin.z;
                        }
                        else{
                            currentPos.z = boxMax.z;
                        }
                        input.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;

                        float3 speed = mul((float3x3)collider.worldToLocal, input.nowSpeed.xyz);
                        speed.z = -speed.z * _CollsionScale;
                        input.nowSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                }
                else{           //y小于x
                    if(absDir.y < absDir.z){    //y小于z
                        if(currentPos.y < 0){
                            currentPos.y = boxMin.y;
                        }
                        else{
                            currentPos.y = boxMax.y;
                        }
                        input.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;

                        float3 speed = mul((float3x3)collider.worldToLocal, input.nowSpeed.xyz);
                        speed.y = -speed.y * _CollsionScale;
                        input.nowSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                    else{               //z小于y
                        if(currentPos.z < 0){
                            currentPos.z = boxMin.z;
                        }
                        else{
                            currentPos.z = boxMax.z;
                        }
                        input.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;
                        float3 speed = mul((float3x3)collider.worldToLocal, input.nowSpeed.xyz);
                        speed.z = -speed.z * _CollsionScale;
                        input.nowSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                }
                return true;
        }
    }
    return false;
}

void OutParticle(float parLiveTime, inout NoiseParticleData particle){
    //开始计算颜色等数据
    float time_01 = saturate( parLiveTime / _LifeTime.y );
    AnimateUVData uvData = AnimateUV(time_01);
    particle.uvTransData = uvData.uvData;
    particle.interpolation = uvData.interpolation;
    particle.color = float4(LoadColor(time_01), LoadAlpha(time_01));

    //大小
    float size01;
    switch (_Mode.z) {      //枚举大小模式
    case 1 :
        size01 = LoadSize(smoothstep(_SizeRange.z, _SizeRange.w, abs(particle.nowSpeed.x)));
        break;
    case 2 :
        size01 = LoadSize(smoothstep(_SizeRange.z, _SizeRange.w, abs(particle.nowSpeed.y)));
        break;
    case 3:
        size01 = LoadSize(smoothstep(_SizeRange.z, _SizeRange.w, abs(particle.nowSpeed.z)));
        break;
    default :
        size01 = LoadSize(time_01);
        break;
    }
    particle.size = lerp(_SizeRange.x, _SizeRange.y, size01);
}
#endif