//曲面细分文件，用来处理一系列曲面细分，建议与几何着色器配合使用，
//将输入值重新计算再生成实际上的顶点传递给片源着色器
#ifndef CUSTOM_TESSEILATION
#define CUSTOM_TESSEILATION

CBUFFER_START(UnityPerMaterial)
    float _TessDegree;       //细分程度参数
    float _TessDistanceMin; //最小距离
    float _TessDistanceMax; //最大距离
CBUFFER_END

//---------------------------------曲面细分案例1，仅进行传递简单的曲面细分数据--------------------------------------
struct TessVertexSimple{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};

struct TessOutPutSimple{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};

//细分着色器进行控制的根据值，细分程度由这个结构体定义，因此这个结构体不能变
struct OutputPatchConstant{
    float edge[3]        : SV_TessFactor;
    float inside         : SV_InsideTessFactor;
    float3 vTangent[4]   : TANGENT;
    float2 vUV[4]        : TEXCOORD;
    float3 vTanUCorner[4]: TANUCORNER;
    float3 vTanVCorner[4]: TANVCORNER;
    float4 vCWts         : TANWEIGHTS;
};

//细分着色器的顶点着色器，本质上就是一个顶点着色器
void tessvert (inout TessVertexSimple v){}

//细分参数控制着色器，细分的前置准备
OutputPatchConstant hullconst(InputPatch<TessVertexSimple, 3>v){
    OutputPatchConstant o = (OutputPatchConstant)0;
    float size = _TessDegree;
    //获得三个顶点的细分距离值
    float4 ts = float4(size, size, size, size);
    //本质上下面的赋值操作是对细分三角形的三条边以及里面细分程度的控制
    //这个值本质上是一个int值，0就是不细分，每多1细分多一层
    //控制边缘的细分程度，这个边缘程度的值不是我们用的，而是给Tessllation进行细分控制用的
    o.edge[0] = ts.x;
    o.edge[1] = ts.y;
    o.edge[2] = ts.z;
    //内部的细分程度
    o.inside = ts.w;
    return o;
}

[domain("tri")]    //输入图元的是一个三角形
//确定分割方式
[partitioning("fractional_odd")]
//定义图元朝向，一般用这个即可，用切线为根据
[outputtopology("triangle_cw")]
//定义补丁的函数名，也就是我们上面的函数，hull函数的返回值会传到这个函数中，然后进行曲面细分
[patchconstantfunc("hullconst")]
//定义输出图元是一个三角形，和上面对应
[outputcontrolpoints(3)]
TessVertexSimple hull (InputPatch<TessVertexSimple, 3> v, uint id : SV_OutputControlPointID){
    return v[id];
}

//细分后对每一个图元的计算，这下面都是标准的获取新顶点数据的方式，输出后会传递给片源或者几何着色器
[domain("tri")]
TessOutPutSimple domain (OutputPatchConstant tessFactors, const OutputPatch<TessOutPutSimple, 3> vi, float3 bary : SV_DomainLocation){
    TessOutPutSimple v = (TessOutPutSimple)0;
    v.vertex = vi[0].vertex * bary.x + vi[1].vertex*bary.y + vi[2].vertex * bary.z;
    v.normal = vi[0].normal * bary.x + vi[1].normal*bary.y + vi[2].normal * bary.z;
    v.tangent = vi[0].tangent * bary.x + vi[1].tangent*bary.y + vi[2].tangent * bary.z;
    v.uv = vi[0].uv * bary.x + vi[1].uv*bary.y + vi[2].uv * bary.z;
    return v;
}

//---------------------------------曲面细分案例1，仅进行传递简单的曲面细分数据--------------------------------------

//---------------------------------曲面细分案例2，将能准备的数据都进行曲面细分--------------------------------------
struct TessVertex_All{
    float4 vertex : POSITION;
    float4 color : COLOR;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
    float2 uv3 : TEXCOORD3;
    float2 uv4 : TEXCOORD4;
    float2 uv5 : TEXCOORD5;
    float2 uv6 : TEXCOORD6;
};

struct TessOutput_All{
    float4 vertex : Var_POSITION;
    float4 color : Var_COLOR;
    float3 normal : Var_NORMAL;
    float4 tangent : Var_TANGENT;
    float2 uv0 : Var_TEXCOORD0;
    float2 uv1 : Var_TEXCOORD1;
    float2 uv2 : Var_TEXCOORD2;
    float2 uv3 : Var_TEXCOORD3;
    float2 uv4 : Var_TEXCOORD4;
    float2 uv5 : Var_TEXCOORD5;
    float2 uv6 : Var_TEXCOORD6;
};


//顶点着色器的输入值，直接传递不进行操作
void tessVertAll (inout TessVertex_All v){}

//细分参数控制着色器，细分的前置准备
OutputPatchConstant hullconst_All(InputPatch<TessVertex_All, 3>v){
    OutputPatchConstant o = (OutputPatchConstant)0;
    float size = _TessDegree;
    //获得三个顶点的细分距离值
    float4 ts = float4(size, size, size, size);
    //本质上下面的赋值操作是对细分三角形的三条边以及里面细分程度的控制
    //这个值本质上是一个int值，0就是不细分，每多1细分多一层
    //控制边缘的细分程度，这个边缘程度的值不是我们用的，而是给Tessllation进行细分控制用的
    o.edge[0] = ts.x;
    o.edge[1] = ts.y;
    o.edge[2] = ts.z;
    //内部的细分程度
    o.inside = ts.w;
    return o;
}

[domain("tri")]    //输入图元的是一个三角形
//确定分割方式
[partitioning("fractional_odd")]
//定义图元朝向，一般用这个即可，用切线为根据
[outputtopology("triangle_cw")]
//定义补丁的函数名，也就是我们上面的函数，hull函数的返回值会传到这个函数中，然后进行曲面细分
[patchconstantfunc("hullconst_All")]
//定义输出图元是一个三角形，和上面对应
[outputcontrolpoints(3)]
TessOutput_All hull_All (InputPatch<TessVertex_All, 3> v, uint id : SV_OutputControlPointID){
    return v[id];
}

[domain("tri")]
TessOutput_All domain_All (OutputPatchConstant tessFactors, const OutputPatch<TessOutput_All, 3> vi, float3 bary : SV_DomainLocation){
    TessOutput_All v = (TessOutput_All)0;
    v.vertex = vi[0].vertex * bary.x + vi[1].vertex*bary.y + vi[2].vertex * bary.z;
    v.normal = vi[0].normal * bary.x + vi[1].normal*bary.y + vi[2].normal * bary.z;
    v.tangent = vi[0].tangent * bary.x + vi[1].tangent*bary.y + vi[2].tangent * bary.z;
    v.color = vi[0].color * bary.x + vi[1].color*bary.y + vi[2].color * bary.z;
    v.uv0 = vi[0].uv0 * bary.x + vi[1].uv0*bary.y + vi[2].uv0 * bary.z;
    v.uv1 = vi[0].uv1 * bary.x + vi[1].uv1*bary.y + vi[2].uv1 * bary.z;
    v.uv2 = vi[0].uv2 * bary.x + vi[1].uv2*bary.y + vi[2].uv2 * bary.z;
    v.uv3 = vi[0].uv3 * bary.x + vi[1].uv3*bary.y + vi[2].uv3 * bary.z;
    v.uv4 = vi[0].uv4 * bary.x + vi[1].uv4*bary.y + vi[2].uv4 * bary.z;
    v.uv5 = vi[0].uv5 * bary.x + vi[1].uv5*bary.y + vi[2].uv5 * bary.z;
    v.uv6 = vi[0].uv6 * bary.x + vi[1].uv6*bary.y + vi[2].uv6 * bary.z;
    return v;
}

//---------------------------------曲面细分案例2，将能准备的数据都进行曲面细分--------------------------------------



//---------------------------------曲面细分案例3，根据距离细分--------------------------------------

float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess)
{
    float3 wpos = mul(unity_ObjectToWorld,vertex).xyz;
    float dist = distance (wpos, _WorldSpaceCameraPos);
    float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
    return f;
}

float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
{
    float4 tess;
    tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
    tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
    tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
    tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
    return tess;
}

float4 DistanceBasedTess (float4 v0, float4 v1, float4 v2, float minDist, float maxDist, float tess)
{
    float3 f;
    f.x = CalcDistanceTessFactor (v0, minDist, maxDist, tess);
    f.y = CalcDistanceTessFactor (v1, minDist, maxDist, tess);
    f.z = CalcDistanceTessFactor (v2, minDist, maxDist, tess);

    return CalcTriEdgeTessFactors (f);
}

//细分参数控制着色器，根据距离控制细分数量
OutputPatchConstant distanceHull(InputPatch<TessVertexSimple, 3>v){
    OutputPatchConstant o = (OutputPatchConstant)0;
    float size = _TessDegree;
    //获得三个顶点的细分距离值
    // float4 ts = float4(size, size, size, size);
    float4 ts = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, _TessDistanceMin, _TessDistanceMax, _TessDegree);
    //本质上下面的赋值操作是对细分三角形的三条边以及里面细分程度的控制
    //这个值本质上是一个int值，0就是不细分，每多1细分多一层
    //控制边缘的细分程度，这个边缘程度的值不是我们用的，而是给Tessllation进行细分控制用的
    o.edge[0] = ts.x;
    o.edge[1] = ts.y;
    o.edge[2] = ts.z;
    //内部的细分程度
    o.inside = ts.w;
    return o;
}

[domain("tri")]    //输入图元的是一个三角形
//确定分割方式
[partitioning("fractional_odd")]
//定义图元朝向，一般用这个即可，用切线为根据
[outputtopology("triangle_cw")]
//定义补丁的函数名，也就是我们上面的函数，hull函数的返回值会传到这个函数中，然后进行曲面细分
[patchconstantfunc("distanceHull")]
//定义输出图元是一个三角形，和上面对应
[outputcontrolpoints(3)]
TessVertexSimple hull_Distance (InputPatch<TessVertexSimple, 3> v, uint id : SV_OutputControlPointID){
    return v[id];
}

//---------------------------------曲面细分案例3，根据距离细分--------------------------------------

#endif