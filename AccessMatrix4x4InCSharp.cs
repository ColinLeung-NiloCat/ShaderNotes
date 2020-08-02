//example C# script to show different ways to access Matrix4x4's component
using UnityEngine;

public class AccessMatrix4x4InCSharp : MonoBehaviour
{
    void Update()
    {
        //unity Matrix4x4 access method in C#
        /* (C0) (C1) (C2) (C3)
         * m00, m01, m02, m03 (Row0)
         * m10, m11, m12, m13 (Row1)
         * m20, m21, m22, m23 (Row2)
         * m30, m31, m32, m33 (Row3)
        */
        //example matrix (Scale & Translate)
        /* (C0) (C1) (C2) (C3)
         * Sx , m01, m02, Tx  (Row0)
         * m10, Sy , m12, Ty  (Row1)
         * m20, m21, Sz , Tz  (Row2)
         * m30, m31, m32, m33 (Row3)
        */

        Matrix4x4 m = transform.localToWorldMatrix;

        /////////////////////////////////////////////////////////////////////
        //ways to extract transform.position from a M matrix
        /////////////////////////////////////////////////////////////////////
        Vector3 posWS;
        posWS = new Vector3(m.m03, m.m13, m.m23);                           //(method 1) extract correct translation from matrix
        posWS = m.GetColumn(3);                                             //(method 2) extract correct translation from matrix
        posWS = new Vector3(m.GetRow(0).w, m.GetRow(1).w, m.GetRow(2).w);   //(method 3) extract correct translation from matrix
        posWS = new Vector3(m[0, 3], m[1, 3], m[2, 3]);                     //(method 4) extract correct translation from matrix
        Debug.Log($"transform.position = {posWS}");

        /////////////////////////////////////////////////////////////////////
        //ways to extract transform.lossyScale from a M matrix
        /////////////////////////////////////////////////////////////////////
        Vector3 scaleWS;
        //(wrong method) can get correct scale ONLY if rotation is all 0
        scaleWS = new Vector3(m.m00, m.m11, m.m22);                         
        //(right method) can get correct scale no matter what rotation is, due to the fact that rotation matrix's each column's length must equals 1 => sqrt(cos^2+sin^2+0) must equals 1
        scaleWS = new Vector3(m.GetColumn(0).magnitude, m.GetColumn(1).magnitude, m.GetColumn(2).magnitude); 
        Debug.Log($"transform.lossyScale = {scaleWS}");

        /////////////////////////////////////////////////////////////////////
        //ways to extract transform.rotation from a M matrix
        /////////////////////////////////////////////////////////////////////
        Matrix4x4 R;

        //(method 1) get rotation matrix
        Quaternion r = m.rotation;
        R = Matrix4x4.Rotate(r);  

        //(method 2) get rotation matrix
        //first remove scale
        Matrix4x4 INV_S = Matrix4x4.identity;
        INV_S.m00 = 1f / scaleWS.x;
        INV_S.m11 = 1f / scaleWS.y;
        INV_S.m22 = 1f / scaleWS.z;
        R = m * INV_S;
        //then remove position
        R.m03 = 0;
        R.m13 = 0;
        R.m23 = 0;
        //finally, at this line matrix will remain rotation

        ////////////////////////////////////////////////
        //build T from scratch
        Matrix4x4 T = Matrix4x4.identity;
        T.m03 = posWS.x;
        T.m13 = posWS.y;
        T.m23 = posWS.z;
        //build S from scratch
        Matrix4x4 S = Matrix4x4.identity;
        S.m00 = scaleWS.x;
        S.m11 = scaleWS.y;
        S.m22 = scaleWS.z;

        Matrix4x4 MY_MATRIX_M = T * R * S;
        if(GetComponent<Renderer>())
            GetComponent<Renderer>().material.SetMatrix("MY_MATRIX_M", MY_MATRIX_M); //it is the same as UNITY_MATRIX_M in shader
    }
}
