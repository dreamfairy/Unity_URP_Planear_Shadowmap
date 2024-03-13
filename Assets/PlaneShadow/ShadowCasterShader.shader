// This shader fills the mesh shape with a color predefined in the code.
Shader "Unlit/ShadowCasterShader"
{
    // The properties block of the Unity shader. In this example this block is empty
    // because the output color is predefined in the fragment shader code.
    Properties
    { }

    // The SubShader block containing the Shader code. 
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            ZTest LEqual
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
                float4 vertex       : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS  : SV_POSITION;
            };            

            // The vertex shader definition with properties defined in the Varyings 
            // structure. The type of the vert function must match the type (struct)
            // that it returns.
            Varyings vert(Attributes input)
            {
                // Declaring the output object (OUT) with the Varyings struct.
                Varyings output;

                float3 positionWS = TransformObjectToWorld(input.vertex.xyz);
                float worldPlaneHeight = 0;
                float maxHeight = 10;
                float baseHeight = 1;
                
                Light mainLight = GetMainLight();
                float3 mainLightDir = normalize(mainLight.direction);
                float3 newPositionWS = 0;
                
                newPositionWS.xz = positionWS.xz - mainLightDir.xz * (positionWS.y - worldPlaneHeight) / mainLightDir.y;

                float depth = (positionWS.y + baseHeight) / maxHeight;
                // The TransformObjectToHClip function transforms vertex positions
                // from object space to homogenous space
                output.positionHCS = TransformWorldToHClip(newPositionWS.xyz);
                #if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
                output.positionHCS = float4( output.positionHCS.xy/ output.positionHCS.w, 1 - depth, 1);
                #else
                output.positionHCS = float4( output.positionHCS.xy/ output.positionHCS.w, depth, 1);
                #endif
                
                // Returning the output.
                return output;
            }

            // The fragment shader definition.            
            void frag()
            {
                
            }
            ENDHLSL
        }
    }
}