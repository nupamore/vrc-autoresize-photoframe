Shader "nupamo/AutoResize PhotoFrame"
{
    Properties
    {
        _Lit ("Albedo <-> Emission", Range(0, 1)) = 0
        _MainColor ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
        [Space(20)]
        _Frame ("Frame Strength", Range(0, 5)) = 1
        _Margin ("Margin Strength", Range(0, 10)) = 5
        _FrameColor ("Frame Color", Color) = (0,0,0,1)
        _FrameTex ("Frame Texture", 2D) = "white" {}
        _MarginColor ("Margin Color", Color) = (1,1,1,1)
        _MarginTex ("Margin Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows addshadow vertex:vert alpha:fade
        #pragma target 3.0

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
            float color;
        };

        sampler2D _MainTex;
        sampler2D _MarginTex;
        sampler2D _FrameTex;
        fixed4 _MarginColor;
        fixed4 _FrameColor;
        float4 _MainTex_TexelSize;
        float _Frame;
        float _Margin;
        float _Lit;

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
                    v.vertex.x += abs(v.normal.z) != 1 ? v.normal.x * tX * (f + m) * 0.5 : tX * (f + m) * distX;
                }
                // vertical face
                else {
                    v.vertex.y += -v.normal.y * ratioH * 0.5;
                    v.vertex.y += v.normal.y * tX / scaleY * (f + m);
                    v.vertex.x += tX * (f + m) * distX;
                }
            }
            // w < h
            else {
                // vertical face
                if (v.normal.x == 0) {
                    v.vertex.x += ratioV * -distX;
                    v.vertex.x += 2 * tY / scaleX * (f + m) * distX;
                    v.vertex.y += tY * (f + m) * ((v.normal.z == -1) ? distY : -distY);
                    v.vertex.y += (abs(v.normal.y) == 1) ? tY * (f + m) * distY + tY * (f + m) * 0.5 * v.normal.y : 0;
                }
                // horizon face
                else {
                    v.vertex.x += -v.normal.x * ratioV * 0.5;
                    v.vertex.x += v.normal.x * tY / scaleX * (f + m);
                    v.vertex.y += -tY * (f + m) * distY;
                }
            }
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float uvX = IN.uv_MainTex.x;
            float uvY = IN.uv_MainTex.y;
            float w = uvX * (1 + tX / scaleX * (f + m) * 2) - tX / scaleX * (f + m);
            float h = uvY * (1 + tY / scaleY * (f + m) * 2) - tY / scaleY * (f + m);
            fixed4 main = tex2D(_MainTex, float2(w, h));
            fixed4 margin = tex2D(_MarginTex, IN.uv_MainTex) * _MarginColor;
            fixed4 frame = tex2D(_FrameTex, IN.uv_MainTex) * _FrameColor;

            fixed3 c = lerp(frame.rgb, main.rgb, IN.color);
            fixed a = lerp(frame.a, main.a, IN.color);

            // margin
            c = (abs(0.5 - uvX) > 0.5 - tX / scaleX * (f + m) || abs(0.5 - uvY) > 0.5 - tY / scaleY * (f + m)) ? lerp(frame.rgb, margin.rgb, IN.color) : c;
            a = (abs(0.5 - uvX) > 0.5 - tX / scaleX * (f + m) || abs(0.5 - uvY) > 0.5 - tY / scaleY * (f + m)) ? lerp(frame.a, margin.a, IN.color) : a;
            // frame
            c = (abs(0.5 - uvX) > 0.5 - tX / scaleX * f || abs(0.5 - uvY) > 0.5 - tY / scaleY * f) ? frame.rgb : c;
            a = (abs(0.5 - uvX) > 0.5 - tX / scaleX * f || abs(0.5 - uvY) > 0.5 - tY / scaleY * f) ? frame.a : a;

            o.Albedo = lerp(c, 0, _Lit);
            o.Emission = lerp(0, c, _Lit);
            o.Alpha = a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}