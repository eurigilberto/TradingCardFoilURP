Shader "Unlit/StencilMask"
{
    Properties
    {
        _radius ("Radius", float) = 1
        [IntRange] _StencilRef ("Stencil Reference Value", Range(0,255)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Stencil{
                Ref [_StencilRef]
                Comp Always
                Pass Replace
            }

            ZWrite off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "RecticircleMask.hlsl"

            float _radius;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = fixed4(2,2,2,2);
                float2 size = float2(2.5,3.5);

                float2 posScaled = abs((i.uv.xy - float2(0.5, 0.5)) * size);
                float mask = 0;

                RecticircleMask_float(size, posScaled, _radius, 0, mask);
                clip(mask - 0.5);
                return mask;
            }
            ENDCG
        }
    }
}
