
Shader "Custom/Water Bowl Stegu Noise"{

	Properties{
		//Properties are exposed values we can change in the editor
		// and that the CPU can access
		_waterColor("Main Water Color", Color) = (1,1,1,1)
		_mainTexture("Main Texture (optional)", 2D) = "white" {}
		_offsetX("Offset X", float) = 0.0
		_offsetZ("Offset Z", float) = 0.0
		_scale("Noise Scale", float) = 1.0
		_amplitude("Amplitude", float) = 1.0
		_heightOffset("Height Offset", float) = 0.0
		_waveSpeed("Wave Speed", float) = 1.0

	}

		SubShader{

			Pass{
				CGPROGRAM
				//Name vertex and fragment functions and including some useful CG stuff
				#pragma vertex vertexFunction
				#pragma fragment fragmentFunction

				#include "UnityCG.cginc"

				//Create vertex to fragment "data package" struct 
				// with the vertex info we want to use and then pass to the fragment shader
				struct v2f {
					float4 position: POSITION;
					float2 uv: TEXCOORD0;
					float3 normal : NORMAL;
					half3 worldRefl: TEXCOORD1;

				};

		//Here we reference the property names and types. We can then access the properties
		float4 _waterColor;
		sampler2D _mainTexture;
		float _offsetX;
		float _offsetZ;
		float _scale;
		float _amplitude;
		float _heightOffset;
		float _waveSpeed;

		//Noise function
		// Copyright (c) 2011 Stefan Gustavson. All rights reserved.
		// Distributed under the MIT license. See LICENSE file.
		// https://github.com/ashima/webgl-noise

		float4 mod(float4 x, float4 y)
		{
			return x - y * floor(x / y);
		}

		float4 mod289(float4 x)
		{
			return x - floor(x / 289.0) * 289.0;
		}

		float4 permute(float4 x)
		{
			return mod289(((x*34.0) + 1.0)*x);
		}

		float4 taylorInvSqrt(float4 r)
		{
			return (float4)1.79284291400159 - r * 0.85373472095314;
		}

		float2 fade(float2 t) {
			return t * t*t*(t*(t*6.0 - 15.0) + 10.0);
		}

		// Classic Perlin noise
		float cnoise(float2 P)
		{
			P = P * _scale + float2(_offsetX + _Time.y*_waveSpeed, _offsetZ + _Time.y*_waveSpeed);
			float4 Pi = floor(P.xyxy) + float4(0.0, 0.0, 1.0, 1.0);
			float4 Pf = frac(P.xyxy) - float4(0.0, 0.0, 1.0, 1.0);
			Pi = mod289(Pi); // To avoid truncation effects in permutation
			float4 ix = Pi.xzxz;
			float4 iy = Pi.yyww;
			float4 fx = Pf.xzxz;
			float4 fy = Pf.yyww;

			float4 i = permute(permute(ix) + iy);

			float4 gx = frac(i / 41.0) * 2.0 - 1.0;
			float4 gy = abs(gx) - 0.5;
			float4 tx = floor(gx + 0.5);
			gx = gx - tx;

			float2 g00 = float2(gx.x, gy.x);
			float2 g10 = float2(gx.y, gy.y);
			float2 g01 = float2(gx.z, gy.z);
			float2 g11 = float2(gx.w, gy.w);

			float4 norm = taylorInvSqrt(float4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
			g00 *= norm.x;
			g01 *= norm.y;
			g10 *= norm.z;
			g11 *= norm.w;

			float n00 = dot(g00, float2(fx.x, fy.x));
			float n10 = dot(g10, float2(fx.y, fy.y));
			float n01 = dot(g01, float2(fx.z, fy.z));
			float n11 = dot(g11, float2(fx.w, fy.w));

			float2 fade_xy = fade(Pf.xy);
			float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
			float n_xy = lerp(n_x.x, n_x.y, fade_xy.y);

			return _amplitude * n_xy + _heightOffset;
		}

		//Vertex function
		v2f vertexFunction(v2f IN) {
			v2f OUT;

			//This is where we can change the vertex positions
			float upMask = clamp(dot(fixed3(0, 1, 0), IN.normal), 0.0, 1.0); //Dot product between the world Y vector and the current normal 
																			 //clamped between 0 and 1 tells if vert is facing upwards
																			 // if 0 - normal 100% perpendicular to world Y, if 1 - normal is world Y (0,1,0)
			IN.position.xyz += fixed3(0, 1, 0) * cnoise(mul(unity_ObjectToWorld, IN.position.xz)) * upMask;


			//World space position of vertex
			float3 worldPos = mul(unity_ObjectToWorld, IN.position).xyz;
			//World space view direction, the direction from which we see the vertex
			float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
			//World space normal of the vertex
			float3 worldNormal = UnityObjectToWorldNormal(IN.normal);
			//World space reflection vector
			OUT.worldRefl = reflect(-worldViewDir, worldNormal);
			//Apply camera projection matrix to vert location for perspective
			OUT.position = UnityObjectToClipPos(IN.position);
			OUT.uv = IN.uv;

			return OUT;
		}

		//Fragment function
		fixed4 fragmentFunction(v2f IN) : SV_Target{

			//Sample default reflection cubemap
			half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, IN.worldRefl);
			//Convert cubemap data into color data
			half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);
			//Now output
			fixed4 c = 0;
			c.rgb = skyColor;
			return c * _waterColor;

			//float4 textureColor = tex2D(_mainTexture, IN.uv);
			//return textureColor * _waterColor;
		}


		ENDCG
	}

		}

}