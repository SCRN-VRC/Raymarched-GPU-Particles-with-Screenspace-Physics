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
	Physics and stuff, then ray marching after grab pass #2
*/

Shader "Simple SSPhysics/SSP Queue 4998"
{
	Properties
	{
		_Color ("Color", Color) = (1,0,1,1)
		_Roughness ("Roughness", Range(0, 10)) = 7.0
		_Specular ("Specular", Float) = 12.0
		_Refraction ("Refraction", Float) = 4.0
		_FresnelScale ("Fresnel Scale", Float) = 1.2
		_FresnelPower ("Fresnel Power", Float) = 3.0
		_MinSize ("Particle Minimum Size", Float) = 0.02
		_MaxSize ("Particle Maximum Size", Float) = 0.05
		_Smoothing ("Particle Smoothness", Float) = 0.05
		[HideInInspector]_Width ("Width", Float) = 1
		[HideInInspector]_Height ("Height", Float) = 50
		_Spread ("Spawn Spread", Float) = 0.005
		_Speed ("Spawn Speed", Float) = 1
		_Gravity ("Gravity", Float) = 0.0007
		_Bounce ("Bounce", Float) = .5
		_Spawn ("Spawn", Range(0, 1)) = 1.0
		_Reset ("Reset", Range(0, 1)) = 0.0
		_Attract ("Attract", Range(0, 1)) = 0.0
		[HideInInspector]_Test ("Test", Vector) = (0,0,0)
	}

	Subshader
	{
		Tags { "Queue"="Overlay+998" "ForceNoShadowCasting"="True" "IgnoreProjector"="True" }

		// Do stuff with positions and velocities
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
			#include "UnityCG.cginc"
			#include "SSPInclude.cginc"

			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

			Texture2D<half4> _SSPQueue0;
			half4 _SSPQueue0_TexelSize;

			half3 _Test;
			half _Spawn;
			half _Reset;
			half _Bounce;
			half _Attract;
			half _Gravity;
			half _Width;
			half _Height;
			half _Spread;
			half _Speed;

			struct appdata
			{
				half4 vertex : POSITION;
				half3 uv : TEXCOORD0;
			};

			struct v2f
			{
				half4 vertex : SV_POSITION;
				half3 uv : TEXCOORD0;
				half3 iniPos : TEXCOORD1;
				half3 iniVel : TEXCOORD2;
				half4 projPos : TEXCOORD3;
				half3 ray : TEXCOORD4;
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

				o.uv.xy = half4(v.vertex.x + 0.5, 
					v.vertex.y + 0.5, 0.0, 0.0);

				// Everything goes really fast in mirrors?
				o.uv.z = (45.0 / unity_DeltaTime.w) * IsInMirror() ? 0.5 : 1.0;

				o.iniPos = _SSPQueue0.Load(int3(_Offset.x,_Offset.y + _Height, 0));
				o.iniVel = _SSPQueue0.Load(int3(_Offset.x,_Offset.y + _Height + 1, 0)) * _Speed;

				half4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.ray = worldPos.xyz - _WorldSpaceCameraPos;
				half4 wvertex = mul(UNITY_MATRIX_VP, worldPos);
				o.projPos = ComputeScreenPos (wvertex);
				o.projPos.z = -mul(UNITY_MATRIX_V, worldPos).z;

				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
				half4 col, col2;

				int _y = _Offset.y + i.uv.y * _Height;
				half ratio = i.uv.z;

				[branch]
				if (_y < _Offset.y + 25) {

					col = _SSPQueue0.Load(int3(_Offset.x,_y,0));
					col2 = _SSPQueue0.Load(int3(_Offset.x,_y+25,0));

					half3 pos = col.xyz;
					half init = col.w;
					half3 vel = col2.xyz;
					//half rand_ = col2.w;

					if (init < 1.0 && _Spawn > 0.5) {
						pos = i.iniPos;
						init = (init < 1e-8) ? i.uv.y : init + 0.01 * ratio;
					}

					init = (_Reset > 0.5) ? 0 : init;

					//init = (_Time.y % 6.0 > 5.5) ? 0 : init;

					pos = pos + vel * ratio;

					return half4(pos, init);
				}
				else {

					col = _SSPQueue0.Load(int3(_Offset.x,_y-25,0));
					col2 = _SSPQueue0.Load(int3(_Offset.x,_y,0));

					half3 pos = col.xyz;
					half init = col.w;
					half3 vel = col2.xyz;
					//half rand_ = col2.w;
					
					if (init < 1.0 && _Spawn > 0.5) {
						pos = i.iniPos;
						vel = i.iniVel;
						vel += normalize(hash33(_y.xxx) - 0.5) * _Spread;
					}

					if (_Attract > 0.5) {
						half dist = length(i.iniPos - pos);
						if (dist > 0) {
							vel += ((i.iniPos - pos) * 0.00075) / clamp(dist * dist, 0.05, 0.5);
							vel *= pow(0.98, ratio);
						}
					}
					else {

						half3 nextPos = pos + vel * ratio;
						half4 vpPos = mul(UNITY_MATRIX_VP, half4(nextPos, 1.0));
						half particleDepth = Linear01Depth(vpPos.z / vpPos.w);

						half4 pos3DScreen = ComputeScreenPos(vpPos);
						half depthValue = Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(pos3DScreen)).r);
						half3 worldPosition = depthValue * i.ray / i.projPos.z + _WorldSpaceCameraPos;
						half3 worldNormal = normalize(cross(-ddx(worldPosition), ddy(worldPosition)));

						vel = (particleDepth > depthValue) ? reflect(vel, worldNormal) * (_Bounce * ratio) :
							vel - half3(0, _Gravity * ratio, 0);

						// vel = (particleDepth > depthValue) ? vel - (dot(vel, worldNormal) * worldNormal * (1.0 + _Bounce)) * ratio :
						// 	vel - half3(0, _Gravity * ratio, 0);
					}
					return half4(vel, 0);
				}
			}
			ENDCG
		}
		
		GrabPass{ "_SSPQueue4998" }

		// Hide the data from the screen after it's stored in the grab pass
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
			};

			v2f vert (appdata v)
			{
				v2f o;

                // +2 for the initial pos and vel from queue 0
				_Height += 2;
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

				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				int _y = _Offset.y + i.uv.y * _Height;
				return _SSPQueue4998.Load(int3(_Offset.x + 1,_y,0));
			}
			ENDCG
		}

		// Ray marching here!
		Pass
		{
			Cull Front
			ZTest Always
			Lighting Off
			SeparateSpecular Off
			Fog { Mode Off }
			
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 5.0
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "SSPInclude.cginc"

			#define FAR 30.

			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

			half3 _Test;
			half3 _Color;
			half _MinSize;
			half _MaxSize;
			half _Smoothing;
			half _Roughness;
			half _Specular;
			half _Refraction;
			half _FresnelScale;
			half _FresnelPower;

			Texture2D<half4> _SSPQueue4998;
			half4 _SSPQueue4998_TexelSize;

			half4 posA[25];
			//half4 velA[25];

			half smin(half a, half b, half k) {
				half h = saturate(0.5 + 0.5 * (b - a) / k);
				return lerp(b, a, h) - k * h * (1.0 - h);
			}

			half fsmin( half a, half b, half k ) // alex evans smin
			{
				half h = max( k-abs(a-b), 0.0 )/k;
				return min( a, b ) - h*h*k*0.25;
			}

			half sphere( half3 p, half r ) 
			{
				return length(p)-r; // sphere
			}

			half dist(half3 pos)
			{
				half d = 1e9;
				[unroll]
				for (int i = 0; i < 25; i++) {
					d = fsmin(d, sphere(pos - posA[i], posA[i].a), _Smoothing);
				}
				return d;
			}

			half march(half3 pos, half3 dir, half zDepth)
			{
				half td = 0, d = 0.0;
				[loop]
				for (int i = 0; i < 64; ++i)
				{
					pos += dir * d;
					d = dist(pos);
					td += d;
					td = td > zDepth ? FAR : td;
					if (d < 0.0075*td  || td >= FAR ) break;
				}

				return td;
			}

			half3 calcNormal( in half3 p ){
				static const half2 e = half2(0.01,-0.01);
				return normalize( e.xyy*dist(p+e.xyy ) + e.yyx*dist(p+e.yyx ) + e.yxy*dist(p+e.yxy ) + e.xxx*dist(p+e.xxx ));
			}

			half fresnel(half3 ray, half3 normal) {
				half c = _FresnelScale*pow(1. + dot(ray, normal), _FresnelPower);
				return saturate(c);
			}

			half3 illuminate( in half3 pos , in half3 camdir, in half4 GrabAssTextureUV)
			{
				half3 normal = calcNormal(pos);

				half rc = fresnel(camdir, normal);
				half3 reflectedRay = reflect(camdir, normal);
				//half3 refractedRay = refract(camdir, normal, _Refraction);

				half4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectedRay, _Roughness);
				half3 reflectedColor = DecodeHDR (skyData, unity_SpecCube0_HDR);

				half4 coords = UNITY_PROJ_COORD( GrabAssTextureUV + (half4(normal, 0.0) * _Refraction));
				coords.xy /= coords.w;
				coords.xy *= _SSPQueue4998_TexelSize.zw;
				half3 refractedColor = _SSPQueue4998.Load(int3(coords.xy, 0)).rgb;
				//half3 refractedColor = tex2Dproj(_SSPQueue0, UNITY_PROJ_COORD( GrabAssTextureUV + (half4(normal, 0.0) * _Refraction))).rgb;

				half3 lightDirection = normalize(UnityWorldSpaceLightDir(pos));
				half specular = pow(max(0., dot(reflectedRay, lightDirection)), _Specular);
				half3 color = lerp(refractedColor, reflectedColor, rc) + _Color + specular * _LightColor0.rgb;

				return color;
			}

			struct custom_type
			{
				half4 screen_vertex : SV_POSITION;
				half3 world_vertex : TEXCOORD0;
				half4 projPos : TEXCOORD1;
				half3 ray : TEXCOORD2;
				half4 GrabAssTextureUV : TEXCOORD3;
			};

			custom_type vertex_shader (half4 vertex : POSITION)
			{
				custom_type vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul(unity_ObjectToWorld, vertex);

				half4 worldPos = mul(UNITY_MATRIX_M, vertex);
				vs.ray = worldPos.xyz - _WorldSpaceCameraPos;
				half4 wvertex = mul(UNITY_MATRIX_VP, worldPos);
				vs.projPos = ComputeScreenPos (wvertex);
				vs.projPos.z = -mul(UNITY_MATRIX_V, worldPos).z;
				vs.GrabAssTextureUV = ComputeGrabScreenPos(vs.screen_vertex);
				return vs;
			}

			half4 pixel_shader(custom_type ps) : SV_Target
			{
				if (IsInMirror() || isOrthographic()) discard;
				half3 pos = _WorldSpaceCameraPos;
				half3 dir = normalize(ps.world_vertex - _WorldSpaceCameraPos);
				half3 col = half3(0,0,0);

				half sceneDepth = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(ps.projPos)));
				half3 depthPosition = sceneDepth * ps.ray / ps.projPos.z + _WorldSpaceCameraPos;
				half zDepth = distance(_WorldSpaceCameraPos, depthPosition);

				[unroll]
				for (int x = 0; x < 25; x++) {
					posA[x].rgb = _SSPQueue4998.Load(int3(_Offset.x,_Offset.y + x, 0)).rgb;
					posA[x].a = hash(x) * _MaxSize + _MinSize;
					// Maybe do something with velocity?
					//velA[x].rgb = _SSPQueue4998.Load(int3(_Offset.x,_Offset.y + x + 25, 0)).rgb;
				}

				half dist = march(pos, dir, zDepth);
				if (dist < FAR) {

					half3 inters = pos + dist * dir;
					col = illuminate(inters, dir, ps.GrabAssTextureUV);

				}
				else discard;

				return half4(min(pow(col, half3(1.3,1.3,1.3)), 1.5), 1.0);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}