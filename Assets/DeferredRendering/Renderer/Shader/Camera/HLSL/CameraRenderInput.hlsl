#ifndef DEFFER_CAMERA_RENDER_INPUT
#define DEFFER_CAMERA_RENDER_INPUT

TEXTURE2D(_SourceTexture);
SAMPLER(sampler_SourceTexture);




UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    half4 _GBufferColorTex_TexelSize;
    float4x4 _FrustumCornersRay;
    float4x4 _InverseVPMatrix;
    float4x4 _InverseProjectionMatrix;
    float4x4 _CameraProjectionMatrix;

    float4 _SourceTexture_ST;


UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

// float3 GetScreenPos(float2 uv, float depth){
//     return float3(uv.xy * 2 - 1, depth);
// }

// inline half3 GetWorldSpacePos(half3 screenPos)
// {
//     half4 worldPos = mul(_InverseVPMatrix, half4(screenPos, 1));
//     return worldPos.xyz / worldPos.w;
// }

// inline half3 GetViewSpacePos(half3 screenPos)
// {
//     half4 viewPos = mul(_InverseProjectionMatrix, half4(screenPos, 1));
//     return viewPos.xyz / viewPos.w;
// }

// inline half3 GetViewDir(half3 worldPos)
// {
//     return normalize(worldPos - _WorldSpaceCameraPos);
// }

// bool Intersect_Linear(float2 hitUV, float startDepth, float sampleDepth){
//     float FrontDepth = SAMPLE_DEPTH_TEXTURE_LOD(_GBufferDepthTex, sampler_point_clamp, hitUV, 0);
//     float BackDepth = FrontDepth + _DepthThickness;
//     return sampleDepth > FrontDepth && sampleDepth < BackDepth;
// }


// bool RayMarch_Linear(float3 reflectDir, float3 viewPos, float3 screenPos, float2 screenUV, float stepSize, float bufferDepth, out float3 hitPos){
//     float4 dirProject = float4(
//         abs(_CameraProjectionMatrix._m00 * 0.5),
//         abs(_CameraProjectionMatrix._m11 * 0.5),
//         ((_ProjectionParams.z * _ProjectionParams.y) / (_ProjectionParams.y - _ProjectionParams.z)) * 0.5,
//         0
//     );
//     float eyeDepth = LinearEyeDepth(bufferDepth, _ZBufferParams);
//     float3 ray = viewPos / viewPos.z;
//     float3 rayDir = normalize(float3(reflectDir.xy - ray.xy * reflectDir.z, reflectDir.z / eyeDepth) * dirProject.xyz);
//     rayDir.xy *= 0.5;

//     float3 rayStart = float3(screenPos.xy * 0.5 + 0.5, screenPos.z);
//     hitPos = rayStart;
//     float sampleDepth = rayStart.z;

//     for(int i=0; i < _MaxRayMarchingStep; i++){
//         if(Intersect_Linear(hitPos.xy, rayStart.z, sampleDepth)){
//             return true;
//         }
//         hitPos += rayDir * stepSize;
//         sampleDepth = hitPos.z;
//     }
//     return false;
// }

#endif