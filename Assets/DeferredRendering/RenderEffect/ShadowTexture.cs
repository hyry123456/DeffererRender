using UnityEngine;

namespace DefferedRender
{
    enum BlurMode
    {
        X,Y
    }

    public class ShadowTexture : MonoBehaviour
    {
        public Shader shader;
        public Color shadowCol;
        public Texture2D shadowTex;
        [Range(0f, 2f)]
        public float blurRadio;
        /// <summary>   /// 模糊的开始位置    /// </summary>
        [Range(-3f, 3f)]
        public float blurBeginSize = 0;
        [SerializeField]
        private BlurMode blur;

        public Vector3 bottomLeftPos = new Vector3(-1, 0, -1);
        public Vector3 bottomRightPos = new Vector3(1, 0, -1);
        public Vector3 topLeftPos = new Vector3(-1, 0, 1);
        public Vector3 topRightPos = new Vector3(1, 0, 1);

        private Material material;
        private Mesh mesh;

        private void OnValidate()
        {
            Recaculate();
        }

        private void Start()
        {
            Recaculate();
        }

        public void Recaculate()
        {
            CaculateMesh();
            MeshFilter mf = GetComponent<MeshFilter>();
            if (mf == null)
                mf = gameObject.AddComponent<MeshFilter>();
            mf.mesh = mesh;

            MeshRenderer mr = GetComponent<MeshRenderer>();
            if (mr == null)
                mr = gameObject.AddComponent<MeshRenderer>();
            if (material == null)
            {
                material = new Material(shader);
                material.renderQueue = 2100;
            }
            mr.material = material;

            material.SetTexture("_MainTex", shadowTex);
            material.SetColor("_ShadowColor", shadowCol);
            Vector3 blurMode = Vector3.zero;
            blurMode.x = blurRadio;
            blurMode.y = (blur == BlurMode.X)? 1 : 0;
            blurMode.z = blurBeginSize;
            material.SetVector("_BlurData", blurMode);
        }

        private void CaculateMesh()
        {
            if (mesh != null)
                DestroyImmediate(mesh);
            mesh = new Mesh();
            mesh.vertices = new Vector3[]
            {
                bottomLeftPos,
                topLeftPos,
                bottomRightPos,
                topRightPos,
            };
            mesh.triangles = new int[]
            {
                0, 1, 2, 1, 3, 2
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
            mesh.RecalculateTangents();

        }
    }
}