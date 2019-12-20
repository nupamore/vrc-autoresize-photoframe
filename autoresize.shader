Shader "nupamo/autoresize"
{
    Properties
    {
        _FrameColor ("Frame Color", Color) = (0,0,0,1)
        _MarginColor ("Margin Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Frame ("Frame", Range(0, 10)) = 1
        _Margin ("Margin", Range(0, 20)) = 2
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
        float _Frame;
        float _Margin;

        void vert(inout appdata_full v)
        {
            float2 value = v.texcoord.xy;
            float ratio = 1 - (_MainTex_TexelSize.w / _MainTex_TexelSize.z);
            float distX = 0.5 - value.x;
            float distY = 0.5 - value.y;

            // maintex is front face only
            v.color = saturate(v.normal.z);

            // w > h
            if (ratio > -1) {
                // horizon face
                if (v.normal.y == 0) {
                    v.vertex.y += ratio * ((v.normal.z == -1) ? -distY : distY);
                }
                // vertical face
                else {
                    v.vertex.y += -v.normal.y * ratio * 0.5;
                }
            }
            // w < h
            else {
                ratio =  1 - (_MainTex_TexelSize.z / _MainTex_TexelSize.w);
                // vertical face
                if (v.normal.x == 0) {
                    v.vertex.x += ratio * -distX;
                }
                // horizon face
                else {
                    v.vertex.x += -v.normal.x * ratio * 0.5;
                }
            }
        }
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float f = _Frame * 10;
            float m = _Margin * 10;
            float uvX = IN.uv_MainTex.x;
            float uvY = IN.uv_MainTex.y;
            float tX = _MainTex_TexelSize.x;
            float tY = _MainTex_TexelSize.y;
            float w = uvX * (1 + tX * (f + m) * 2) - tX * (f + m);
            float h = uvY * (1 + tY * (f + m) * 2) - tY * (f + m);
            fixed4 c = tex2D (_MainTex, float2(w, h));

            o.Albedo = lerp(_BorderColor, c.rgb, IN.color);
            o.Alpha = c.a;

            // margin
            o.Albedo = (abs(0.5 - uvX) > 0.5 - tX * (f + m) || abs(0.5 - uvY) > 0.5 - tY * (f + m)) ? lerp(_BorderColor, _MarginColor, IN.color) : o.Albedo;
            // border
            o.Albedo = (abs(0.5 - uvX) > 0.5 - tX * f || abs(0.5 - uvY) > 0.5 - tY * f) ? _BorderColor : o.Albedo;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
