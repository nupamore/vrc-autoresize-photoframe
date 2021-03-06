// v1.1.0
Shader "nupamo/AutoResize PhotoFrame"
{
    Properties
    {
        _Lit ("Albedo <-> Emission", Range(0, 1)) = 0
        _MainColor ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
        _RatioWidth ("Set Width ratio", float) = 16
        _RatioHeight ("Set Height ratio", float) = 9
        [Toggle] _RatioAuto ("Get aspect ratio from texture", Int) = 0
        [Space(20)]
        [Enum(Top,2,Center,1,Bottom,0)] _AlignV ("Vertical align", Float) = 1
        [Enum(Right,0,Center,1,Left,2)] _AlignH ("Horizontal align", Float) = 1
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
        Tags { 
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType" = "Transparent" 
        }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows addshadow vertex:vert alpha:fade
        #pragma target 3.0

        struct Input
        {
            float2 uv_MainTex;
            float color : COLOR;
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
        float _RatioWidth;
        float _RatioHeight;
        int _RatioAuto;
        float _AlignH;
        float _AlignV;

        static const float scaleX = length(unity_ObjectToWorld._m00_m10_m20);
        static const float scaleY = length(unity_ObjectToWorld._m01_m11_m21);
        static const float z = _RatioAuto * _MainTex_TexelSize.z + (1 - _RatioAuto) * _RatioWidth;
        static const float w = _RatioAuto * _MainTex_TexelSize.w + (1 - _RatioAuto) * _RatioHeight;
        static const float tZ = z * scaleY;
        static const float tW = w * scaleX;
        static const float ratioH = 1 - tW / tZ;
        static const float ratioV = 1 - tZ / tW;
        static const float f = _Frame * 15;
        static const float m = _Margin * 15;
        static const float fm = f + m;
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
                    v.vertex.y += tX / scaleY * ((v.normal.z == -1) ? distY : -distY);
                    v.vertex.x += abs(v.normal.z) != 1 ? v.normal.x * tX * 0.5 : tX * distX;
                }
                // vertical face
                else {
                    v.vertex.y += -v.normal.y * ratioH * 0.5;
                    v.vertex.y += 0.5 * v.normal.y * tX / scaleY * 1;
                    v.vertex.x += tX * distX;
                }
                // pivot
                v.vertex.y += (_AlignV - 1) * (ratioH - tY * 1) * 0.5;
            }
            // w < h
            else {
                // vertical face
                if (v.normal.x == 0) {
                    v.vertex.x += ratioV * -distX;
                    v.vertex.x += tY / scaleX * distX;
                    v.vertex.y += tY * ((v.normal.z == -1) ? distY : -distY);
                    v.vertex.y += (abs(v.normal.y) == 1) ? tY * distY + tY * 0.5 * v.normal.y : 0;
                }
                // horizon face
                else {
                    v.vertex.x += -v.normal.x * ratioV * 0.5;
                    v.vertex.x += 0.5 * v.normal.x * tY / scaleX * 1;
                    v.vertex.y += -tY * distY;
                }
                // pivot
                v.vertex.x += (_AlignH - 1) * (ratioV - tX * fm)  * 0.5;
            }
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float uvX = IN.uv_MainTex.x;
            float uvY = IN.uv_MainTex.y;
            float w = uvX * (1 + tX / scaleX * fm * 2.2) - tX / scaleX * fm * 1.1;
            float h = uvY * (1 + tY / scaleY * fm * 2.2) - tY / scaleY * fm * 1.1;
            fixed4 main = tex2D(_MainTex, float2(w, h));
            fixed4 margin = tex2D(_MarginTex, IN.uv_MainTex) * _MarginColor;
            fixed4 frame = tex2D(_FrameTex, IN.uv_MainTex) * _FrameColor;

            fixed3 c = lerp(frame.rgb, main.rgb, IN.color);
            fixed a = lerp(frame.a, main.a, IN.color);

            // margin
            float mX = abs(0.5 - uvX) - (0.5 - tX / scaleX * fm);
            float mY = abs(0.5 - uvY) - (0.5 - tY / scaleY * fm);
            float mS = smoothstep(0, 0.15, max(mX, mY) * 100);
            c = lerp(c, (IN.color > 0) ? margin.rgb : frame.rgb, mS);
            a = lerp(a, (IN.color > 0) ? margin.a : frame.a, mS);
            // frame
            float fX = abs(0.5 - uvX) - (0.5 - tX / scaleX * f);
            float fY = abs(0.5 - uvY) - (0.5 - tY / scaleY * f);
            float fS = smoothstep(0, 0.15, max(fX, fY) * 100);
            c = lerp(c, frame.rgb, fS);
            a = lerp(a, frame.a, fS);

            o.Albedo = lerp(c, 0, _Lit);
            o.Emission = lerp(0, c, _Lit);
            o.Alpha = a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}