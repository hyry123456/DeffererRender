using UnityEngine;

namespace DefferedRender
{
    [ExecuteInEditMode]
    /// <summary>
    /// 角色阴影贴图类，用来传递灯光方向以及灯光坐标对阴影进行偏移
    /// </summary>
    public class CharacterShadowTexture : MonoBehaviour
    {
        public Shader shader;

        public Transform originPos;
        public Transform followCharacter;   //跟随的对象
        public bool beginFollow;
        public LayerMask GroundLayer;
        private Mesh mesh;
        [SerializeField]
        float offsetY;
        [SerializeField]
        private Material material;

        public Color shadowCol;
        public Texture2D mainTex;
        private void OnValidate()
        {
            if (shader == null) return;
            if (mesh == null)
            {
                mesh = new Mesh();
                mesh.vertices = new Vector3[]
                {
                    new Vector3(-1, 0, -1),
                    new Vector3(1, 0, -1),
                    new Vector3(-1, 0, 1),
                    new Vector3(1, 0, 1),
                };
                mesh.triangles = new int[]
                {
                    2, 1, 0, 2, 3, 1
                };
                mesh.normals = new Vector3[]
                {
                    Vector3.up,
                    Vector3.up,
                    Vector3.up,
                    Vector3.up,
                };
                mesh.uv = new Vector2[]
                {
                    Vector2.zero,
                    Vector2.right,
                    Vector2.up,
                    Vector2.one
                };
            }

            MeshFilter mf = GetComponent<MeshFilter>();
            if (mf == null)
            {
                mf = gameObject.AddComponent<MeshFilter>();
            }
            mf.mesh = mesh;

            MeshRenderer mr = GetComponent<MeshRenderer>();
            if (mr == null)
            {
                mr = gameObject.AddComponent<MeshRenderer>();
            }
            if (material == null)
            {
                material = new Material(shader);
                material.renderQueue = 2100;
            }
            mr.material = material;
            if(followCharacter != null && originPos != null)
                offsetY = Mathf.Abs(followCharacter.position.y - originPos.position.y);
        }

        private void Start()
        {
            if(followCharacter != null && originPos != null)
                offsetY = Mathf.Abs(followCharacter.position.y - originPos.position.y);
        }

        private void Update()
        {
            if (originPos == null)
                return;
            material.SetVector("_LightOffset", originPos.position - transform.position);
            if (mainTex)
                material.SetTexture("_MainTex", mainTex);
            material.SetColor("_ShadowColor", shadowCol);
            if(followCharacter != null && beginFollow)
            {
                RaycastHit hit;
                Vector3 temp = transform.position;
                temp.x = followCharacter.position.x;
                temp.z = followCharacter.position.z;
                if (Physics.Raycast(followCharacter.position, Vector3.down, out hit, 10, GroundLayer)){
                    temp.y = hit.point.y + 0.01f;
                }
                transform.position = temp;
                temp = originPos.position;
                temp.y = followCharacter.position.y + offsetY;
                originPos.position = temp;
            }
        }


    }
}