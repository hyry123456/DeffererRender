//该代码基本不能支持每一个项目使用，建议是扔到初始加载栈中加载
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class PlugTangentTools
{
    [MenuItem("Tools/模型平均法线写入切线数据")]
    public static void WirteAverageNormalToTangentToos()
    {
        if (Selection.activeGameObject == null) return;
        //MeshFilter[] meshFilters = Selection.activeGameObject.GetComponentsInChildren<MeshFilter>();
        //foreach (var meshFilter in meshFilters)
        //{
        //    Mesh mesh = meshFilter.sharedMesh;
        //    WirteAverageNormalToTangent(mesh);
        //}

        SkinnedMeshRenderer[] skinMeshRenders = Selection.activeGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var skinMeshRender in skinMeshRenders)
        {
            Mesh mesh = skinMeshRender.sharedMesh;
            WirteAverageNormalToTangent(mesh);
        }
    }

    //将相同顶点位置的法线数据进行平均计算，能够让描边变得自然
    public static void WirteAverageNormalToTangent(Mesh mesh)
    {
        var averageNormalHash = new Dictionary<Vector3, Vector3>();
        //没有时加入，重复时求平均
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            if (!averageNormalHash.ContainsKey(mesh.vertices[j]))
            {
                averageNormalHash.Add(mesh.vertices[j], mesh.normals[j]);
            }
            else
            {
                averageNormalHash[mesh.vertices[j]] =
                    (averageNormalHash[mesh.vertices[j]] + mesh.normals[j]).normalized;
            }
        }

        var averageNormals = new Vector3[mesh.vertexCount];
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            averageNormals[j] = averageNormalHash[mesh.vertices[j]];
        }

        var tangents = new Vector4[mesh.vertexCount];
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            tangents[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, 0);
        }

        var colors = new Color[mesh.vertexCount];
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            colors[j] = mesh.tangents[j];
        }
        //将法线平均数据放到切线数据中
        mesh.tangents = tangents;
        //之前的切线数据放到为顶点色数据
        mesh.colors = colors;

    }
}