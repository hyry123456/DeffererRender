#ifndef DEFFER_TERRAIN_SHADOW
#define DEFFER_TERRAIN_SHADOW

struct Varyings {
	float4 positionCS_SS : SV_POSITION;
};


[maxvertexcount(3)]
void TerrainGeom_Shadow(triangle TessOutPut IN[3], inout TriangleStream<Varyings> tristream)
{
    Varyings output[3] = (Varyings[3])0;

    IN[0].vertex.y += SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_HeightTex, IN[0].uv, 0).r * _Height;
    IN[1].vertex.y += SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_HeightTex, IN[1].uv, 0).r * _Height;
    IN[2].vertex.y += SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_HeightTex, IN[2].uv, 0).r * _Height;

    output[0].positionCS_SS = TransformWorldToHClip(IN[0].vertex.xyz);
    output[1].positionCS_SS = TransformWorldToHClip(IN[1].vertex.xyz);
    output[2].positionCS_SS = TransformWorldToHClip(IN[2].vertex.xyz);


    tristream.Append(output[0]);
    tristream.Append(output[1]);
    tristream.Append(output[2]);
    tristream.RestartStrip();

}

void TerrainFragment_Shadow (Varyings input) {
}


#endif