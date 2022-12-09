
using UnityEditor;
using UnityEngine;

public class CombineTexture : Editor
{
    [MenuItem("MyProjectSetting/CombineTexture/Create")]
    public static void Create()
    {
        GameObject game = GameObject.Find("CombineTextureMenu");
        if(game == null)
        {
            game = new GameObject("CombineTextureMenu");
            game.AddComponent<CombineTextureMenu>();
            return;
        }
        else if(game.GetComponent<CombineTextureMenu>() == null)
        {
            game.AddComponent<CombineTextureMenu>();
            return;
        }
    }

    [MenuItem("MyProjectSetting/CombineTexture/Combine")]
    public static void Combine()
    {
        GameObject game = GameObject.Find("CombineTextureMenu");
        if (game == null || game.GetComponent<CombineTextureMenu>() == null)
            return;
        CombineTextureMenu combine = game.GetComponent<CombineTextureMenu>();
        if (combine.texture2Ds == null || combine.texture2Ds.Length == 0 || combine.saveName.Length == 0)
            return;

        Texture2DArray texture2DArray = DefferedRender.TextureArrayCreate.CreateTextureArrayBySet(combine.texture2Ds);
        AssetDatabase.CreateAsset(texture2DArray, "Assets/" + combine.saveName + ".asset");
    }

}
