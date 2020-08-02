//example .shader to show different ways to access hlsl float4x4's component
Shader "AccessFloat4x4InShader/ExampleCode"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            float4x4 MY_MATRIX_M; //set by AccessMatrix4x4InCSharp.cs

            v2f vert (appdata v)
            {
                v2f o;

                //https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-per-component-math
                //hlsl float4x4 access method
                /* (C0)  (C1)  (C2)  (C3)
                 * _m00, _m01, _m02, _m03 (Row0)
                 * _m10, _m11, _m12, _m13 (Row1)
                 * _m20, _m21, _m22, _m23 (Row2)
                 * _m30, _m31, _m32, _m33 (Row3)
                */
                //example matrix (Scale & Translate)
                /* (C0)  (C1)  (C2)  (C3)
                 *  Sx , _m01, _m02,  Tx  (Row0)
                 * _m10,  Sy , _m12,  Ty  (Row1)
                 * _m20, _m21,  Sz ,  Tz  (Row2)
                 * _m30, _m31, _m32, _m33 (Row3)
                */

                /////////////////////////////////////////////////////////////////////
                //ways to extract renderer's transform.position from a M matrix
                /////////////////////////////////////////////////////////////////////
                float3 translationWS;
                translationWS = float3(MY_MATRIX_M._m03, MY_MATRIX_M._m13, MY_MATRIX_M._m23);    //(method1) extract position from float4x4
                translationWS = float3(MY_MATRIX_M[0][3], MY_MATRIX_M[1][3], MY_MATRIX_M[2][3]); //(method2) extract position from float4x4
                translationWS = float3(MY_MATRIX_M[0].w, MY_MATRIX_M[1].w, MY_MATRIX_M[2].w);    //(method3) extract position from float4x4
                /////////////////////////////////////////////////////////////////////
                //ways to extract transform.lossyScale from a M matrix
                /////////////////////////////////////////////////////////////////////
                float3 scaleWS;
                scaleWS.x = length(float3(MY_MATRIX_M[0].x, MY_MATRIX_M[1].x, MY_MATRIX_M[2].x));
                scaleWS.y = length(float3(MY_MATRIX_M[0].y, MY_MATRIX_M[1].y, MY_MATRIX_M[2].y));
                scaleWS.z = length(float3(MY_MATRIX_M[0].z, MY_MATRIX_M[1].z, MY_MATRIX_M[2].z));

                ////////////////////////////////////////////////
                //build T and IV_T from scratch
                float4x4 T = (float4x4)0;
                T._m00 = 1;
                T._m11 = 1;
                T._m22 = 1;
                T._m33 = 1;
                T._m03 = translationWS.x;
                T._m13 = translationWS.y;
                T._m23 = translationWS.z;
                float4x4 IV_T = T;
                IV_T._m03 = -IV_T._m03;
                IV_T._m13 = -IV_T._m13;
                IV_T._m23 = -IV_T._m23;
                //build S and IV_S from scratch
                float4x4 S = (float4x4)0;
                S._m00 = scaleWS.x;
                S._m11 = scaleWS.y;
                S._m22 = scaleWS.z;
                S._m33 = 1;
                float4x4 IV_S = S;
                IV_S._m00 = 1.0/ IV_S._m00;
                IV_S._m11 = 1.0/ IV_S._m11;
                IV_S._m22 = 1.0/ IV_S._m22;
  
                //build R using T & S
                float4x4 R = mul(IV_S,mul(IV_T,MY_MATRIX_M)); //first remove T, then remove S
                
                //rebuild M (T*S*R)
                float4x4 M = mul(T,mul(S,R)); //in shader, can't do matrix mul using S * R, use mul(S,R) !!!
                
                //apply M
                v.vertex = mul(M, float4(v.vertex.xyz, 1));

                //complete VP as usual
                o.vertex = UnityWorldToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return 1;
            }
            ENDCG
        }
    }
}
