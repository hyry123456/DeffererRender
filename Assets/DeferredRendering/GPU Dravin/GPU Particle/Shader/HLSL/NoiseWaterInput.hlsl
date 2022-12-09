#ifndef NOISE_WATER_INPUT
#define NOISE_WATER_INPUT

#include "ParticleNoiseInc.hlsl"

//大水珠(组)需要的数据
struct FluidGroup{
    float3 worldPos;
    float3 nowSpeed;
    //0是未初始化，1是group，2是非组
    int mode;
    float dieTime;  //死亡时间
};

//液体粒子需要的数据
struct FluidParticle{
    float3 worldPos;
    float3 nowSpeed;
    float3 random;
    float size;
    //0为使用，1:组阶段，2：自由粒子
    int mode;
    float4 uvTransData;     //uv动画需要的数据
    float interpolation;    //插值需要的数据
};

RWStructuredBuffer<FluidGroup> _FluidGroup;
RWStructuredBuffer<FluidParticle> _FluidParticle;


//粒子模式, X为位置初始化模式，Y是速度初始化模式，Z是输出模式，W为是否需要物理模拟
// int4 _Mode;，这个控制的是单个粒子的行为，不控制粒子组的行为
int3 _GroupMode;        //x是组的位置初始化模式，Y是速度初始化模式, z是组是否应用重力

float _GroupArc;
float _GroupRadius;
float3 _GroupCubeRange;
//_BeginSpeed，xyz表示初始速度，w表示该速度长度
float _ParticleBeginSpeed;      //单个粒子释放时的速度，只表示速度而已

//噪声数据先统一先，不补充噪声设置
//_LifeTime，X:粒子释放的存活时间

// float4 _GroupColors[_COUNT];  //颜色计算用的数据
// float4 _GroupAlphas[_COUNT];  //透明度计算用的数据
// float4 _GroupSizes[_COUNT];  //大小
// float _GroupIntensity;  //组的噪声强度


//初始化组位置，也就是确定该组粒子的起始位置
float3 GetGroupBeginPos(float3 random){
    //组中的粒子不需要进行矩阵的大小调整，矩阵只控制组的初始化
    switch(_GroupMode.x){
        case 1:
            return mul(_RotateMatrix, 
                float4(GetSphereBeginPos(random.yx, _GroupArc, _GroupRadius), 1)).xyz;
        case 2:
            return mul(_RotateMatrix, 
                float4(GetCubeBeginPos(random.yzx, _GroupCubeRange), 1)).xyz;
        default:
            return mul(_RotateMatrix, float4(0, 0, 0, 1)).xyz;
    }
}

//初始化组速度
float3 GetGroupBeginSpeed(float random, float3 beginPos){
    float speed = _BeginSpeed.w * random;
    float3 normal = normalize(_BeginSpeed.xyz);
    float3 direct = normalize(beginPos - mul(_RotateMatrix, float4(0, 0, 0, 1)).xyz);
    switch(_GroupMode.y){
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

void InitialGroup(inout FluidGroup group, float3 random){
    group.worldPos = GetGroupBeginPos(random);      //初始化位置
    float random2 = (random.x + random.y + random.z)/3.0;
    group.nowSpeed = GetGroupBeginSpeed(random2, group.worldPos);       //初始化速度
    group.mode = 1;        //进入组阶段
}

//确定单个粒子的位置偏移值
float3 GetControlParticleBeginPos(float3 random){
    switch(_Mode.x){        //单个粒子的位置模式枚举
        case 1:
            return GetSphereBeginPos(random.yx, _Arc, _Radius);
        case 2:
            return GetCubeBeginPos(random.yxz, _CubeRange);
        default:
            return 0;
    }
}

//在组周围初始化粒子
void InitialParticleBesideGroup(inout FluidParticle particle, FluidGroup group){
    //在组的位置周围进行位置初始化
    particle.worldPos = group.worldPos + GetControlParticleBeginPos(particle.random.xyz);
    particle.nowSpeed = group.nowSpeed;     //粒子速度为组速度即可
    particle.mode = 1;       //标记为使用了，这里的1是组粒子标记，此时只需要进行组判断
    
    float time_01 = (_Time.x - (group.dieTime - _LifeTime.x)) / _LifeTime.x;
    AnimateUVData uvData = AnimateUV(time_01);
    particle.uvTransData = uvData.uvData;
    particle.interpolation = uvData.interpolation;

    //大小
    float size01;
    switch (_Mode.z) {      //枚举单个粒子大小模式
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

//只有粒子的第一次速度初始化，
float3 GetFreedomBeginSpeed(float random, float3 currentPos, float3 oriSpeed, float3 oriPos){
    float speed = random * _ParticleBeginSpeed;    //根据速度大小确定一个随机速度
    float3 normal = normalize(oriSpeed);
    float3 direct = normalize(currentPos - oriPos);
    switch(_Mode.y){
        case 1:     //速度是法线以及大小，在粒子位置生成一个垂直于法线且是向外的力度
            return normalize( (direct - normal * dot(direct, normal)) ) * speed;
        case 2:     //在粒子位置生成一个垂直于法线且是向内的力度
            return -normalize( (direct - normal * dot(direct, normal)) ) * speed;
        case 3:     //朝向起始位置的速度，也就是往中间汇集
            return -direct * speed;
        case 4:     //离开起始位置的速度，也就是从中间往外面跑
            return direct * speed;
        default:    //默认模式,传入速度就是初始化速度
            return oriSpeed * speed;
    }
}

//粒子不再呆在组旁边，开始自由移动
void OnFreedomParticle(inout FluidParticle particle, FluidGroup group){
    
    if(particle.mode < 2){      //第一次释放，需要进行粒子速度初始化
        float random = (particle.random.x + particle.random.y + particle.random.z)/3.0;
        particle.nowSpeed = GetFreedomBeginSpeed(random, 
            particle.worldPos, group.nowSpeed, group.worldPos);
    }
    particle.mode = 2;       //标记为真正进入组阶段，可以进行自由移动了
    particle.worldPos += particle.nowSpeed * _Time.y;      //更新位置

    float time_01 = (_Time.x - (group.dieTime - _LifeTime.x)) / _LifeTime.x;
    AnimateUVData uvData = AnimateUV(time_01);
    particle.uvTransData = uvData.uvData;
    particle.interpolation = uvData.interpolation;

    float size01;
    switch (_Mode.z) {      //枚举单个粒子大小模式
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
    // particle.size = 1;
}

//更新组粒子的速度
void UpdataGroupSpeed(inout FluidGroup group, float3 random){
    group.nowSpeed += CurlNoise3D(group.worldPos * random.xyz * _Frequency, _Octave) * _Intensity * _Time.z;
}

bool CheckCollsion(inout FluidGroup group){
    for(uint i = 0; i < _CollsionData; i++){
        CollsionStruct collider = _CollsionBuffer[i];
        switch(collider.mode){
            case 1:     //球型模式
                float3 duration = collider.center - group.worldPos;
                float len = length(duration);
                if(len <= collider.radius){
                    float3 forceDir = normalize(-duration);
                    float3 force = dot(group.nowSpeed, group.nowSpeed) * forceDir;
                    group.nowSpeed += force * _Time.z;
                    group.worldPos = normalize(-duration) * collider.radius + collider.center;
                    return true;
                }
                break;
            default:    //盒子碰撞
                //判断是否超过盒子范围
                float3 boxMax = collider.offset;
                float3 boxMin = -collider.offset;
                float3 currentPos = mul(collider.worldToLocal, float4(group.worldPos, 1)).xyz;
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
                        group.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;
                        float3 speed = mul((float3x3)collider.worldToLocal, group.nowSpeed.xyz);
                        speed.x = -speed.x * _CollsionScale;
                        group.nowSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                    else{               //z小于x
                        if(currentPos.z < 0){
                            currentPos.z = boxMin.z;
                        }
                        else{
                            currentPos.z = boxMax.z;
                        }
                        group.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;

                        float3 speed = mul((float3x3)collider.worldToLocal, group.nowSpeed.xyz);
                        speed.z = -speed.z * _CollsionScale;
                        group.nowSpeed = mul((float3x3)collider.localToWorld, speed);
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
                        group.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;

                        float3 speed = mul((float3x3)collider.worldToLocal, group.nowSpeed.xyz);
                        speed.y = -speed.y * _CollsionScale;
                        group.nowSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                    else{               //z小于y
                        if(currentPos.z < 0){
                            currentPos.z = boxMin.z;
                        }
                        else{
                            currentPos.z = boxMax.z;
                        }
                        group.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;
                        float3 speed = mul((float3x3)collider.worldToLocal, group.nowSpeed.xyz);
                        speed.z = -speed.z * _CollsionScale;
                        group.nowSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                }
                return true;
        }
    }
    return false;
}

bool CheckCollsion(inout FluidParticle particle){
    bool re = false;
    for(uint i = 0; i < _CollsionData; i++){
        CollsionStruct collider = _CollsionBuffer[i];
        switch(collider.mode){
            case 1:     //球型模式
                float3 duration = collider.center - particle.worldPos;
                float len = length(duration);
                if(len <= collider.radius){
                    float3 forceDir = normalize(-duration);
                    float3 force = dot(particle.nowSpeed, particle.nowSpeed) * forceDir;
                    particle.nowSpeed += force * _Time.z;
                    particle.worldPos = normalize(-duration) * collider.radius + collider.center;
                    re = true;
                }
                break;
            default:    //盒子碰撞
                //判断是否超过盒子范围
                float3 boxMax = collider.offset;
                float3 boxMin = -collider.offset;
                float3 currentPos = mul(collider.worldToLocal, float4(particle.worldPos, 1)).xyz;
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
                        particle.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;
                        float3 speed = mul((float3x3)collider.worldToLocal, particle.nowSpeed.xyz);
                        speed.x = -speed.x * _CollsionScale;
                        speed.yz *= _Obstruction;
                        particle.nowSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                    else{               //z小于x
                        if(currentPos.z < 0){
                            currentPos.z = boxMin.z;
                        }
                        else{
                            currentPos.z = boxMax.z;
                        }
                        particle.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;

                        float3 speed = mul((float3x3)collider.worldToLocal, particle.nowSpeed.xyz);
                        speed.z = -speed.z * _CollsionScale;
                        speed.xy *= _Obstruction;
                        particle.nowSpeed = mul((float3x3)collider.localToWorld, speed);
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
                        particle.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;

                        float3 speed = mul((float3x3)collider.worldToLocal, particle.nowSpeed.xyz);
                        speed.y = -speed.y * _CollsionScale;
                        speed.xz *= _Obstruction;
                        particle.nowSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                    else{               //z小于y
                        if(currentPos.z < 0){
                            currentPos.z = boxMin.z;
                        }
                        else{
                            currentPos.z = boxMax.z;
                        }
                        particle.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;
                        float3 speed = mul((float3x3)collider.worldToLocal, particle.nowSpeed.xyz);
                        speed.z = -speed.z * _CollsionScale;
                        speed.xy *= _Obstruction;
                        particle.nowSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                }
                re = true;
                break;
        }
    }
    return re;
}

void UpdataSpeed(inout FluidParticle input){
    input.nowSpeed += CurlNoise3D(input.worldPos * input.random.xyz * _Frequency, _Octave) * _Intensity * _Time.z;
}


#endif