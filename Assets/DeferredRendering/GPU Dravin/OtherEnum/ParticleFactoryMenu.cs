using DefferedRender;
using UnityEngine;

[CreateAssetMenu(menuName = "GPUDravin/ParticleFactoryMenu")]
public class ParticleFactoryMenu : ScriptableObject
{
    public Texture2DArray textureArray;
    public ComputeShader compue;
    public Material material;
    [SerializeField]
    public TextureUVCount[] uvCounts;
}
