// This shader fills the mesh shape with a color predefined in the code.
Shader "Unlit/ShadowReceiveShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _ShadowCol("Shadow Color", Color) = (1, 1, 1, 1)
        _PlaneShadowBias("ShadowBias", float) = 0
    }
    // The SubShader block containing the Shader code. 
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags
        {
            "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "ShaderModel"="2.0"
        }

        Pass
        {
            // The HLSL code block. Unity SRP uses the HLSL language.
            HLSLPROGRAM
            #pragma enable_d3d11_debug_symbols
            // This line defines the name of the vertex shader. 
            #pragma vertex vert
            // This line defines the name of the fragment shader. 
            #pragma fragment frag

            // The Core.hlsl file contains definitions of frequently used HLSL
            // macros and functions, and also contains #include references to other
            // HLSL files (for example, Common.hlsl, SpaceTransforms.hlsl, etc.).
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // The structure definition defines which variables it contains.
            // This example uses the Attributes structure as an input structure in
            // the vertex shader.
            struct Attributes
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS : SV_POSITION;
                float4 screenUV : TEXCOORD0;
                float depth : TEXCOORD1;
            };

            TEXTURE2D_SHADOW(_PlaneShadowMap);
            SamplerState depth_linear_clamp_sampler;
            SAMPLER_CMP(sampler_PlaneShadowMap);

            half4 _BaseColor;
            half4 _ShadowCol;
            float _PlaneShadowBias;

            // The vertex shader definition with properties defined in the Varyings 
            // structure. The type of the vert function must match the type (struct)
            // that it returns.
            Varyings vert(Attributes input)
            {
                // Declaring the output object (OUT) with the Varyings struct.
                Varyings OUT;
                // The TransformObjectToHClip function transforms vertex positions
                // from object space to homogenous space

                float3 positionWS = TransformObjectToWorld(input.vertex.xyz);
                float worldPlaneHeight = 0;
                float maxHeight = 10;
                float baseHeight = 1;

                Light mainLight = GetMainLight();
                float3 mainLightDir = normalize(mainLight.direction);
                float3 newPositionWS = 0;

                newPositionWS.xz = positionWS.xz - mainLightDir.xz * (positionWS.y - worldPlaneHeight) / mainLightDir.y;

                OUT.positionHCS = TransformObjectToHClip(input.vertex.xyz);

                float4 shadowPos = TransformWorldToHClip(newPositionWS);
                OUT.screenUV = ComputeScreenPos(shadowPos);

                float depth = (positionWS.y + baseHeight) / maxHeight;
                OUT.depth = depth;

                // Returning the output.
                return OUT;
            }

            float SampleDepth(float2 shadowPos)
            {
                half shadowDepth = SAMPLE_TEXTURE2D(_PlaneShadowMap, depth_linear_clamp_sampler, shadowPos.xy);
                #if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
                shadowDepth = 1 - (shadowDepth * 2 - 1);
                #endif
                return shadowDepth;
            }

            float SampleDepthCmp(float3 shadowPos, float2 uvPixel, float2 shadowMapSize)
            {
                half shadow = 0;
                #if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
                half4 pcfShadow = 0;
                pcfShadow.x = SAMPLE_TEXTURE2D_LOD(_PlaneShadowMap, depth_linear_clamp_sampler,
                     shadowPos.xy + float2(1,0) * uvPixel, 0);
                pcfShadow.y = SAMPLE_TEXTURE2D_LOD(_PlaneShadowMap, depth_linear_clamp_sampler,
                     shadowPos.xy + float2(-1,0) * uvPixel , 0);
                pcfShadow.z = SAMPLE_TEXTURE2D_LOD(_PlaneShadowMap, depth_linear_clamp_sampler,
                     shadowPos.xy + float2(0,1) * uvPixel, 0);
                pcfShadow.w = SAMPLE_TEXTURE2D_LOD(_PlaneShadowMap, depth_linear_clamp_sampler,
                      shadowPos.xy + float2(0,-1) * uvPixel, 0);

                pcfShadow =  1 - (pcfShadow * 2 - 1);

                float r0 = (shadowPos.z <= pcfShadow.x) ;
                float r1 = (shadowPos.z <= pcfShadow.y) ;
                float r2 = (shadowPos.z <= pcfShadow.z) ;
                float r3 = (shadowPos.z <= pcfShadow.w) ;

                float2 texPos = shadowPos.xy * shadowMapSize;
                float2 t = frac(texPos);
                
                shadow = 1 - lerp(lerp(r0, r1, t.x), lerp(r2, r3, t.x), t.y);
                
                #else
                half4 pcfShadow = 0;
                pcfShadow.x = SAMPLE_TEXTURE2D_SHADOW(_PlaneShadowMap, sampler_PlaneShadowMap,
                                                      float3(shadowPos.xy + float2(-0.5,-0.5) * uvPixel, shadowPos.z));
                pcfShadow.y = SAMPLE_TEXTURE2D_SHADOW(_PlaneShadowMap, sampler_PlaneShadowMap,
                                                      float3(shadowPos.xy + float2(-0.5,0.5) * uvPixel,shadowPos.z));
                pcfShadow.z = SAMPLE_TEXTURE2D_SHADOW(_PlaneShadowMap, sampler_PlaneShadowMap,
                                                      float3(shadowPos.xy + float2(0.5,0.5) * uvPixel, shadowPos.z));
                pcfShadow.w = SAMPLE_TEXTURE2D_SHADOW(_PlaneShadowMap, sampler_PlaneShadowMap,
                                                      float3(shadowPos.xy + float2(0.5,-0.5) * uvPixel, shadowPos.z));
                shadow = (dot(pcfShadow, 0.25));
                #endif

                return shadow;
            }

            // The fragment shader definition.            
            half4 frag(Varyings IN) : SV_Target
            {
                float2 shadowMapSize = float2(1920, 1080);
                float2 uvPixel = float2(1 / shadowMapSize.x, 1 / shadowMapSize.y);
                float3 shadowPos = float3(IN.screenUV.xy / IN.screenUV.w, IN.depth + _PlaneShadowBias);

                //pcf
                //SampleCmpLevelZero s(p) < d(p) ? 0 : 1, s(p) < d(p) >= 1 : 0
                half shadow = SampleDepthCmp(shadowPos, uvPixel, shadowMapSize);

                //no pcf
                //half shadowDepth = SampleDepth(shadowPos.xy);
                //half shadow = 1 - (shadowPos.z <= shadowDepth);

                return lerp(_BaseColor, _BaseColor * 0.5, 1 - shadow);
            }
            ENDHLSL
        }
    }
}