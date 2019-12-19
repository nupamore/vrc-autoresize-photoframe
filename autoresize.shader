Shader "nupamo/autoresize"
{
    Properties
    {
        _MarginColor ("Margin Color", Color) = (1,1,1,1)
        _BorderColor ("Border Color", Color) = (0,0,0,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows addshadow vertex:vert
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float4 color : COLOR;
        };

        fixed4 _MarginColor;
        fixed4 _BorderColor;
        float4 _MainTex_TexelSize;

        void vert(inout appdata_full v)
        {
            float2 value = v.texcoord.xy;
            float dist = 0.5 - value.y;
            float ratio = _MainTex_TexelSize.w / _MainTex_TexelSize.z;

            // maintex is front face only
            v.color = saturate(v.normal.z);

            // horizon face
            if (v.normal.y == 0) {
                v.vertex.y += (1 - ratio) * ((v.normal.z == -1) ? -dist : dist);
            }
            // vertical face
            else {
                v.vertex.y -= v.normal.y * (1 - ratio) / 2;
            }
        }
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = lerp(_BorderColor, c.rgb, IN.color);
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}