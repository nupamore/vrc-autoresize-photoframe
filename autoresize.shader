Shader "nupamo/autoresize"
{
    Properties
    {
        _FrameColor ("Frame Color", Color) = (0,0,0,1)
        _MarginColor ("Margin Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Frame ("Frame", Range(0, 5)) = 1
        _Margin ("Margin", Range(0, 10)) = 5
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

        static const float scaleX = length(unity_ObjectToWorld._m00_m10_m20);
        static const float scaleY = length(unity_ObjectToWorld._m01_m11_m21);
        static const float tZ = _MainTex_TexelSize.z * scaleY;
        static const float tW = _MainTex_TexelSize.w * scaleX;
        static const float ratioH = 1 - tW / tZ;
        static const float ratioV = 1 - tZ / tW;
        static const float f = _Frame * 15;
        static const float m = _Margin * 15;
        static const float tX = (tZ < tW) ? 0.0005 * (tW / tZ) : 0.0005;
        static const float tY = (tZ >= tW) ? 0.0005 * (tZ / tW) : 0.0005;

        void vert(inout appdata_full v)
        {
            float2 value = v.texcoord.xy;
            float distX = 0.5 - value.x;
            float distY = 0.5 - value.y;

            // maintex is front face only
            v.color = saturate(v.normal.z);

            // w > h
            if (ratioH > 0) {
                // horizon face
                if (v.normal.y == 0) {
                    v.vertex.y += ratioH * ((v.normal.z == -1) ? -distY : distY);
                    v.vertex.y += 2 * tX / scaleY * (f + m) * ((v.normal.z == -1) ? distY : -distY);
                    v.vertex.x += abs(v.normal.z) != 1 ? v.normal.x * tX * (f + m) : 2 * tX * (f + m) * distX;
                }
                // vertical face
                else {
                    v.vertex.y += -v.normal.y * ratioH * 0.5;
                    v.vertex.y += v.normal.y * tX / scaleY * (f + m);
                    v.vertex.x += 2 * tX * (f + m) * distX;
                }
            }
            // w < h
            else {
                // vertical face
                if (v.normal.x == 0) {
                    v.vertex.x += ratioV * -distX;
                    v.vertex.x += 2 * tY / scaleX * (f + m) * distX;
                    v.vertex.y += 2 * tY * (f + m) * ((v.normal.z == -1) ? distY : -distY);
                    v.vertex.y += (abs(v.normal.y) == 1) ? 2 * tY * (f + m) * distY + tY * (f + m) * v.normal.y : 0;
                }
                // horizon face
                else {
                    v.vertex.x += -v.normal.x * ratioV * 0.5;
                    v.vertex.x += v.normal.x * tY / scaleX * (f + m);
                    v.vertex.y += -2 * tY * (f + m) * distY;
                }
            }
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float uvX = IN.uv_MainTex.x;
            float uvY = IN.uv_MainTex.y;
            float w = uvX * (1 + tX / scaleX * (f + m) * 2) - tX / scaleX * (f + m);
            float h = uvY * (1 + tY / scaleY * (f + m) * 2) - tY / scaleY * (f + m);
            fixed4 c = tex2D (_MainTex, float2(w, h));

            o.Albedo = lerp(_BorderColor, c.rgb, IN.color);
            o.Alpha = c.a;

            // margin
            o.Albedo = (abs(0.5 - uvX) > 0.5 - tX / scaleX * (f + m) || abs(0.5 - uvY) > 0.5 - tY / scaleY * (f + m)) ? lerp(_BorderColor, _MarginColor, IN.color) : o.Albedo;
            // border
            o.Albedo = (abs(0.5 - uvX) > 0.5 - tX / scaleX * f || abs(0.5 - uvY) > 0.5 - tY / scaleY * f) ? _BorderColor : o.Albedo;
        }
        ENDCG
    }
    FallBack "Diffuse"
}