#ifndef PARTICLE_NOISE_GROUP_INCLUDE
#define PARTICLE_NOISE_GROUP_INCLUDE

#include "ParticleNoiseInc.hlsl"

//由组进行管理的粒子
struct GroupControlParticle{
    float dieTime;    //死亡时间
    // //初始化模式,x:粒子组结束模式
    // int3 initialMode;
    //当前模式,x:状态标记(0是未启用,1是组阶段,2是粒子阶段)
    int3 currentMode;
    //世界坐标,随机数用第一个粒子的，避免并行错误
    float3 worldPos;
    //当前速度，初始化方式同上
    float3 currentSpeed;
};

//粒子组控制需要的数据
RWStructuredBuffer<GroupControlParticle> _GroupControlBuffer;

//粒子模式, X为位置初始化模式，Y是速度初始化模式，Z是输出模式，W为是否需要物理模拟
// int4 _Mode;，这个控制的是单个粒子的行为，不控制粒子组的行为
int4 _GroupMode;        //x是组的位置初始化模式，Y是速度初始化模式, z是组是否应用重力,w为是否碰撞后取消组

float _GroupArc;
float _GroupRadius;
float3 _GroupCubeRange;
//_BeginSpeed，xyz表示初始速度，w表示该速度长度
float _ParticleBeginSpeed;      //单个粒子释放时的速度，只表示速度而已

//噪声数据先统一先，不补充噪声设置
//_LifeTime，x：组最大持续时间(超过就标记为死亡)，Y:粒子释放的存活时间

float4 _GroupColors[_COUNT];  //颜色计算用的数据
float4 _GroupAlphas[_COUNT];  //透明度计算用的数据
float4 _GroupSizes[_COUNT];  //大小
float _GroupIntensity;  //组的噪声强度


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

void InitialGroup(inout GroupControlParticle group, float3 random){
    group.worldPos = GetGroupBeginPos(random);      //初始化位置
    float random2 = (random.x + random.y + random.z)/3.0;
    group.currentSpeed = GetGroupBeginSpeed(random2, group.worldPos);       //初始化速度
    // group.currentSpeed = float3(0, 10, 0);       //初始化速度
    group.currentMode.x = 1;        //进入组阶段
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
void InitialParticleBesideGroup(inout NoiseParticleData particle, GroupControlParticle group){
    //在组的位置周围进行位置初始化
    particle.worldPos = group.worldPos + GetControlParticleBeginPos(particle.random.xyz);
    particle.nowSpeed = group.currentSpeed;     //粒子速度为组速度即可
    particle.index.y = 1;       //标记为使用了，这里的1是组粒子标记，此时只需要进行组判断
    
    float time_01 = (_Time.x - (group.dieTime - _LifeTime.y - _LifeTime.x)) / _LifeTime.x;

    //计算颜色数据，暂时全部都是一开始的状态
    AnimateUVData uvData = AnimateUV(time_01);
    particle.uvTransData = uvData.uvData;
    particle.interpolation = uvData.interpolation;
    particle.color = float4(LoadColor(time_01, _GroupColors), LoadAlpha(time_01, _GroupAlphas));

    //大小
    float size01;
    switch (_Mode.z) {      //枚举单个粒子大小模式
    case 1 :
        size01 = LoadSize(smoothstep(_SizeRange.z, _SizeRange.w, abs(particle.nowSpeed.x)), _GroupSizes);
        break;
    case 2 :
        size01 = LoadSize(smoothstep(_SizeRange.z, _SizeRange.w, abs(particle.nowSpeed.y)), _GroupSizes);
        break;
    case 3:
        size01 = LoadSize(smoothstep(_SizeRange.z, _SizeRange.w, abs(particle.nowSpeed.z)), _GroupSizes);
        break;
    default :
        size01 = LoadSize(time_01, _GroupSizes);
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
            return oriSpeed;
    }
}

//粒子不再呆在组旁边，开始自由移动
void OnFreedomParticle(inout NoiseParticleData particle, GroupControlParticle group){

    if(particle.random.w > _LifeTime.y){        //判断是否超时
        particle.index.y = 0;
        return;
    }

    if(particle.index.y < 2){      //第一次释放，需要进行粒子速度初始化
        float random = (particle.random.x + particle.random.y + particle.random.z)/3.0;
        particle.nowSpeed = GetFreedomBeginSpeed(random, particle.worldPos, group.currentSpeed, group.worldPos);
    }
    particle.index.y = 2;       //标记为真正进入组阶段，可以进行自由移动了
    particle.worldPos += particle.nowSpeed * _Time.y;      //更新位置
    particle.random.w += _Time.y;   //增加时间

    float time_01 = particle.random.w / _LifeTime.y;
    AnimateUVData uvData = AnimateUV(time_01);
    particle.uvTransData = uvData.uvData;
    particle.interpolation = uvData.interpolation;
    particle.color = float4(LoadColor(time_01), LoadAlpha(time_01));

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

//更新组粒子的速度
void UpdataGroupSpeed(inout GroupControlParticle group, float3 random){
    group.currentSpeed += CurlNoise3D(group.worldPos * random.xyz * _Frequency, _Octave) * _GroupIntensity * _Time.z;
}

bool CheckCollsion(inout GroupControlParticle group){
    for(uint i = 0; i < _CollsionData; i++){
        CollsionStruct collider = _CollsionBuffer[i];
        switch(collider.mode){
            case 1:     //球型模式
                float3 duration = collider.center - group.worldPos;
                float len = length(duration);
                if(len <= collider.radius){
                    float3 forceDir = normalize(-duration);
                    float3 force = dot(group.currentSpeed, group.currentSpeed) * forceDir;
                    group.currentSpeed += force * _Time.z;
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
                        float3 speed = mul((float3x3)collider.worldToLocal, group.currentSpeed.xyz);
                        speed.x = -speed.x * _CollsionScale;
                        group.currentSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                    else{               //z小于x
                        if(currentPos.z < 0){
                            currentPos.z = boxMin.z;
                        }
                        else{
                            currentPos.z = boxMax.z;
                        }
                        group.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;

                        float3 speed = mul((float3x3)collider.worldToLocal, group.currentSpeed.xyz);
                        speed.z = -speed.z * _CollsionScale;
                        group.currentSpeed = mul((float3x3)collider.localToWorld, speed);
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

                        float3 speed = mul((float3x3)collider.worldToLocal, group.currentSpeed.xyz);
                        speed.y = -speed.y * _CollsionScale;
                        group.currentSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                    else{               //z小于y
                        if(currentPos.z < 0){
                            currentPos.z = boxMin.z;
                        }
                        else{
                            currentPos.z = boxMax.z;
                        }
                        group.worldPos = mul(collider.localToWorld, float4(currentPos, 1)).xyz;
                        float3 speed = mul((float3x3)collider.worldToLocal, group.currentSpeed.xyz);
                        speed.z = -speed.z * _CollsionScale;
                        group.currentSpeed = mul((float3x3)collider.localToWorld, speed);
                    }
                }
                return true;
        }
    }
    return false;
}


#endif