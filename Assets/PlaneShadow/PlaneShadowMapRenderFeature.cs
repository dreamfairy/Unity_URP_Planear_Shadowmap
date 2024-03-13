using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.UI;

public class PlaneShadowMapRenderFeature : ScriptableRendererFeature
{
    public Vector2Int ShadowMapSize;
    public Material ShadowCasterMat;
    
    class CustomRenderPass : ScriptableRenderPass
    {
        private RenderTexture m_ShadowRenderTarget;

        private Material m_ShadowCasterMat;

        public CustomRenderPass(Vector2Int pShadowMapSize, Material pMat)
        {
            m_ShadowCasterMat = pMat;

            m_ShadowRenderTarget = new RenderTexture(pShadowMapSize.x, pShadowMapSize.y, 24, RenderTextureFormat.Shadowmap);
            m_ShadowRenderTarget.useMipMap = false;
            m_ShadowRenderTarget.autoGenerateMips = false;
            m_ShadowRenderTarget.antiAliasing = 1;
            m_ShadowRenderTarget.dimension = TextureDimension.Tex2D;
            m_ShadowRenderTarget.wrapMode = TextureWrapMode.Clamp;
            m_ShadowRenderTarget.filterMode = FilterMode.Bilinear;
            m_ShadowRenderTarget.Create();
        }
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);
            if (m_ShadowRenderTarget)
            {
                this.ConfigureTarget(m_ShadowRenderTarget);
                this.ConfigureClear(ClearFlag.All, clearColor);
            }
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!m_ShadowCasterMat) return;
            GameObject shadowItemsRoot = GameObject.Find("ShadowItem");
            if (!shadowItemsRoot) return;
            var cmd = CommandBufferPool.Get("PlaneShadow");

            MeshRenderer[] shadowItemsMR = shadowItemsRoot.GetComponentsInChildren<MeshRenderer>();
            if (null != shadowItemsMR && shadowItemsMR.Length > 0)
            {
                for (int i = 0; i < shadowItemsMR.Length; i++)
                {
                    MeshFilter mf = shadowItemsMR[i].gameObject.GetComponent<MeshFilter>();
                    
                    cmd.DrawMesh(mf.sharedMesh, mf.transform.localToWorldMatrix, m_ShadowCasterMat, 0, 0);
                }
            }
            
            cmd.SetGlobalTexture("_PlaneShadowMap", m_ShadowRenderTarget);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);

            GameObject debug = GameObject.Find("RawImage");
            if (debug)
            {
                RawImage img = debug.GetComponent<RawImage>();
                if (img)
                {
                    img.texture = m_ShadowRenderTarget;
                }
            }
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    CustomRenderPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(ShadowMapSize, ShadowCasterMat);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


