#ifndef _SSPInclude
#define _SSPInclude

#define _Offset half2(10,10)

bool isOrthographic()
{
	return UNITY_MATRIX_P[3][3] == 1;
}

bool IsInMirror()
{
	return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

half hash(half p){
	half n = sin(dot(p, 157));    
	return frac(262144*n); 
}

half3 hash33(half3 p){
	half n = sin(dot(p, half3(7, 157, 113)));    
	return frac(half3(2097152, 262144, 32768)*n); 
}

half rand(half3 co)
{
	return frac(sin(dot(co.xyz ,half3(12.9898,78.233,45.5432))) * 43758.5453);
}

#endif