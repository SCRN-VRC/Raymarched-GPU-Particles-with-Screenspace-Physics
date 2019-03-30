// MIT License

// Copyright (c) 2019 SCRN

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/*
	This just grabs stuff from last frame and adds particle spawn position
	and direction
*/

Shader "Simple SSPhysics/SSP Queue 0"
{
	Properties
	{
		[HideInInspector]_Width ("Width", Float) = 1
		[HideInInspector]_Height ("Height", Float) = 52
		[HideInInspector]_Test ("Test", Vector) = (0,0,0)
	}

	Subshader
	{
		Tags { "Queue"="Background-1000" }

		Pass
		{
			Cull Off
			ZTest Always
			Lighting Off
			SeparateSpecular Off
			Fog { Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0
			#pragma fragmentoption ARB_precision_hint_fastest

			#include "SSPInclude.cginc"

			Texture2D<half4> _SSPQueue4998;
			half4 _SSPQueue4998_TexelSize;

			half3 _Test;
			half _Width;
			half _Height;

			struct appdata
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
			};

			struct v2f
			{
				half4 vertex : SV_POSITION;
				half2 uv : TEXCOORD0;
				half3 iniPos : TEXCOORD1;
				half3 iniVel : TEXCOORD2;
			};

			v2f vert (appdata v)
			{
				v2f o;
				half2 rasterPosition = half2(
					_Offset.x + _Width * (v.vertex.x + 0.5),
					_Offset.y + _Height * (v.vertex.y + 0.5));
				o.vertex = half4(
					2.0 * rasterPosition.x / _ScreenParams.x - 1.0,
					_ProjectionParams.x * (2.0 * rasterPosition.y / _ScreenParams.y - 1.0),
					_ProjectionParams.y,
					1.0);

				o.uv = half4(v.vertex.x + 0.5, 
					v.vertex.y + 0.5, 0.0, 0.0);

				o.iniPos = unity_ObjectToWorld._m03_m13_m23;
				o.iniVel = mul((half3x3)unity_ObjectToWorld, half3(0,0,1));

				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				//if (isOrthographic()) discard;
				if (IsInMirror()) discard;
				int _y = _Offset.y + i.uv.y * _Height;
				half4 col = _SSPQueue4998.Load(int3(_Offset.x,_y,0));
				col = _y >= int(_Offset.y + _Height - 2) ? _y == int(_Offset.y + _Height - 2) ?
					half4(i.iniPos, 0) : half4(i.iniVel, 0) : col;
				return col;
			}
			ENDCG
		}

		GrabPass{ "_SSPQueue0" }
	}

	Fallback "Diffuse"
}