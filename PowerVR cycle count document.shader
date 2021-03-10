// [PowerVR cycle count document]

// Filename : PowerVR Low level GLSL Optimization
// Version : PowerVR SDK REL_17.1@4658063a External Issue
// Issue Date : 07 Apr 2017
// Author : Marton Tamas
// Full version PDF: http://cdn.imgtec.com/sdk-documentation/PowerVR+Low+level+GLSL+Optimization.pdf?fbclid=IwAR08O5o4pAJcgCGbB4nMf13vG-OeAm7xGkwzmNDSqIUBg_21w6JcYt0q3MY
// This document describes ways to optimize GLSL code for PowerVR Series 6 architecture.

// Based on:
// http://www.humus.name/Articles/Persson_LowLevelThinking.pdf
// http://www.humus.name/Articles/Persson_LowlevelShaderOptimization.pdf

//////////////////////////////////////////////////
// 2. Low level optimizations
//////////////////////////////////////////////////

// 2.1. PowerVR Series 6 USC diagram
// Generally shader performance on PowerVR Series 6 architecture GPUs depends on the number of
// cycles it takes to execute a shader.

// 2.2 Writing expressions in MAD form
fragColor.x = (t.x + t.y) * (t.x - t.y); //2 cycles
fragColor.x = t.x * t.x + (-t.y * t.y); //1 cycle

// 2.3 Division
fragColor.x = (t.x * t.y + t.z) / t.x; //3 cycles
fragColor.x = t.y + t.z * (1.0 / t.x); //2 cycles

// 2.4 Sign
fragColor.x = sign(t.x) * t.y; //3 cycles
fragColor.x = (t.x >= 0.0 ? 1.0 : -1.0) * t.y; //2 cycles, so if case (t.x == 0) is not needed it is better to use conditional form instead of sign().

// 2.5 Rcp/rsqrt/sqrt
fragColor.x = 1.0 / t.x; //1 cycle
fragColor.x = inversesqrt(t.x); //1 cycle
fragColor.x = sqrt(t.x); //2 cycles, sqrt() on the other hand is implemented as: 1 / (1/sqrt(x)), Which results in a 2 cycle cost.

fragColor.x = t.x * inversesqrt(t.x); //2 cycles

fragColor.x = sqrt(t.x) > 0.5 ? 0.5 : 1.0; //3 cycles
fragColor.x = (t.x * inversesqrt(t.x)) > 0.5 ? 0.5 : 1.0; //2 cycles, in this case the test instructions can fit into the second instruction.

// 2.6 Abs/Neg/Saturate
fragColor.x = abs(t.x * t.y); //2 cycles
fragColor.x = abs(t.x) * abs(t.y); //1 cycle

fragColor.x = -dot(t.xyz, t.yzx); //3 cycles
fragColor.x = dot(-t.xyz, t.yzx); //2 cycles

fragColor.x = 1.0 - clamp(t.x, 0.0, 1.0); //2 cycles
fragColor.x = clamp(1.0 - t.x, 0.0, 1.0); //1 cycle

fragColor.x = min(dot(t, t), 1.0) > 0.5 ? t.x : t.y; //5 cycles
fragColor.x = clamp(dot(t, t), 0.0, 1.0) > 0.5 ? t.x : t.y; //4 cycles

// normalize() is decomposed into:
vec3 normalize( vec3 v )
{
	return v * inverssqrt( dot( v, v ) );
}

fragColor.xyz = normalize(-t.xyz); //7 cycles
fragColor.xyz = -normalize(t.xyz); //6 cycles

//////////////////////////////////////////////////
// 3. Transcendental functions
//////////////////////////////////////////////////

// 3.1. Exp/Log
fragColor.x = exp2(t.x); //1 cycle
fragColor.x = log2(t.x); //1 cycle

// Exp is implemented as:
float exp2( float x )
{
	return exp2(x * 1.442695); //2 cycles
}
// Log is implemented as:
float log2( float x )
{
	return log2(x * 0.693147); //2 cycles
}
// Pow(x, y) is implemented as:
float pow( float x, float y )
{
	return exp2(log2(x) * y); //3 cycles
}

// 3.2. Sin/Cos/Sinh/Cosh
fragColor.x = sin(t.x); //4 cycles
fragColor.x = cos(t.x); //4 cycles

fragColor.x = cosh(t.x); //3 cycles
fragColor.x = sinh(t.x); //3 cycles

// 3.3. Asin/Acos/Atan /Degrees/Radians
fragColor.x = asin(t.x); //67 cycles (VERY high cost!)
fragColor.x = acos(t.x); //79 cycles (VERY high cost!)
fragColor.x = atan(t.x); //12 cycles (lots of conditionals), Atan is still costly, but it could be used if needed.

fragColor.x = degrees(t.x); //1 cycle
fragColor.x = radians(t.x); //1 cycle

//////////////////////////////////////////////////
// 4. Intrinsic functions
//////////////////////////////////////////////////

// 4.1. Vector*Matrix
fragColor = t * m1; //4x4 matrix, 8 cycles
fragColor.xyz = t.xyz * m2; //3x3 matrix, 4 cycles

// 4.2. Mixed Scalar/Vector math
fragColor.x = length(t-v); 
fragColor.y = distance(v, t); // total of 7 cycles
fragColor.x = length(t-v); 
fragColor.y = distance(t, v); // total of 9 cycles

fragColor.xyz = normalize(t.xyz); //6 cycles
fragColor.xyz = inversesqrt(dot(t.xyz, t.xyz)) * t.xyz; //5 cycles

fragColor.xyz = 50.0 * normalize(t.xyz); //7 cycles
fragColor.xyz = (50.0 * inversesqrt(dot(t.xyz, t.xyz))) * t.xyz; //6 cycles

// Cross() can be expanded to:
vec3 cross( vec3 a, vec3 b )
{
	return vec3( a.y * b.z - b.y * a.z,
	a.z * b.x - b.z * a.x,
	a.x * b.y - b.y * a.y );
}
// Distance can be expanded to:
float distance( vec3 a, vec3 b )
{
	vec3 tmp = a – b;
	return sqrt(dot(tmp, tmp));
}
// Dot can be expanded to:
float dot( vec3 a, vec3 b )
{
	return a.x * b.x + a.y * b.y + a.z * b.z;
}
// Faceforward can be expanded to:
vec3 faceforward( vec3 n, vec3 I, vec3 Nref )
{
	if( dot(Nref, I) < 0 )
	{
		return n;
	}
	else
	{
		return –n:
	}
}
// Length can be expanded to:
float length( vec3 v )
{
	return sqrt(dot(v, v));
}
// Normalize can be expanded to:
vec3 normalize( vec3 v )
{
	return v / sqrt(dot(v, v));
}
// Reflect can be expanded to:
vec3 reflect( vec3 N, vec3 I )
{
	return I - 2.0 * dot(N, I) * N;
}
// Refract can be expanded to:
vec3 refract( vec3 n, vec3 I, float eta )
{
	float k = 1.0 - eta * eta * (1.0 - dot(N, I) * dot(N, I));
	if (k < 0.0)
		return 0.0;
	else
		return eta * I - (eta * dot(N, I) + sqrt(k)) * N;
}

// 4.3. Operation grouping
fragColor.xyz = t.xyz * t.x * t.y * t.wzx * t.z * t.w; //7 cycles
fragColor.xyz = (t.x * t.y * t.z * t.w) * (t.xyz * t.wzx); //4 cycles

//////////////////////////////////////////////////
// 5. FP16 overview
//////////////////////////////////////////////////

// 5.3. Exploiting the SOP/MAD FP16 pipeline
// After applying all this knowledge, we can show off the power of this pipeline by using everything in one cycle:
// All in 1 cycle
mediump vec4 fp16 = t;
highp vec4 res;
res.x = clamp(min(-fp16.y * abs(fp16.z), clamp(fp16.w, 0.0, 1.0) * abs(fp16.x)), 0.0, 1.0);
res.y = clamp(abs(fp16.w) * -fp16.z + clamp(fp16.x, 0.0, 1.0), 0.0, 1.0);
fragColor = res;
{sop, sop}


