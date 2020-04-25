
Shader "Custom/Water Bowl"{

	Properties{
		//Properties are exposed values we can change in the editor
		// and that the CPU can access
		_waterColor("Main Water Color", Color) = (0,0,1,1)
		_mainTexture("Main Texture (optional)", 2D ) = "white" {}
		_displaceAmount("Displace Amount", float) = 0.5

		//Noise properties
		_offsetX("OffsetX",Float) = 0.0
		_offsetY("OffsetY",Float) = 0.0
		_octaves("Octaves",Int) = 7
		_lacunarity("Lacunarity", Range(1.0 , 5.0)) = 2
		_gain("Gain", Range(0.0 , 1.0)) = 0.5
		_value("Value", Range(-2.0 , 2.0)) = 0.0
		_amplitude("Amplitude", Range(0.0 , 5.0)) = 1.5
		_frequency("Frequency", Range(0.0 , 6.0)) = 2.0
		_power("Power", Range(0.1 , 5.0)) = 1.0
		_scale("Scale", Float) = 1.0
		_color("Color", Color) = (1.0,1.0,1.0,1.0)
		[Toggle] _monochromatic("Monochromatic", Float) = 0
		_range("Monochromatic Range", Range(0.0 , 1.0)) = 0.5
	}

	SubShader{

		Pass{
			CGPROGRAM
			//Name vertex and fragment functions and including some useful CG stuff
			#pragma vertex vertexFunction
			#pragma fragment fragmentFunction

			#include "UnityCG.cginc"

			//Create vertex to fragment "data package" struct 
			// with the vertex info we want to use in the vertex function and then pass to the fragment function
			struct v2f {
				float4 position: POSITION;
				float2 uv: TEXCOORD0;
				float3 normal : NORMAL;
				half3 worldRefl: TEXCOORD1;

			};

			//Here we reference the property names and types. We can then access the properties
			float4 _waterColor;
			sampler2D _mainTexture;
			float _displaceAmount;

			//Noise properties referenced
			float _octaves, _lacunarity, _gain, _value, _amplitude, _frequency, _offsetX, _offsetY, _power, _scale, _monochromatic, _range;
			float4 _color;

			//Noise function
			float fbm(float2 p)
			{
				p = p * _scale + float2(_offsetX + _Time.y, _offsetY + _Time.y);
				for (int i = 0; i < _octaves; i++)
				{
					float2 i = floor(p * _frequency);
					float2 f = frac(p * _frequency);
					float2 t = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
					float2 a = i + float2(0.0, 0.0);
					float2 b = i + float2(1.0, 0.0);
					float2 c = i + float2(0.0, 1.0);
					float2 d = i + float2(1.0, 1.0);
					a = -1.0 + 2.0 * frac(sin(float2(dot(a, float2(127.1, 311.7)), dot(a, float2(269.5, 183.3)))) * 43758.5453123);
					b = -1.0 + 2.0 * frac(sin(float2(dot(b, float2(127.1, 311.7)), dot(b, float2(269.5, 183.3)))) * 43758.5453123);
					c = -1.0 + 2.0 * frac(sin(float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5, 183.3)))) * 43758.5453123);
					d = -1.0 + 2.0 * frac(sin(float2(dot(d, float2(127.1, 311.7)), dot(d, float2(269.5, 183.3)))) * 43758.5453123);
					float A = dot(a, f - float2(0.0, 0.0));
					float B = dot(b, f - float2(1.0, 0.0));
					float C = dot(c, f - float2(0.0, 1.0));
					float D = dot(d, f - float2(1.0, 1.0));
					float noise = (lerp(lerp(A, B, t.x), lerp(C, D, t.x), t.y));
					_value += _amplitude * noise;
					_frequency *= _lacunarity;
					_amplitude *= _gain;
				}
				_value = clamp(_value, -1.0, 1.0);
				return pow(_value * 0.5 + 0.5, _power);
			}

			//Vertex function
			v2f vertexFunction(v2f IN) {
				v2f OUT;

				//This is where we can change the vertex positions
				float upMask = clamp(dot(fixed3(0, 1, 0), IN.normal), 0.0, 1.0); //Dot product between the world Y vector and the current normal 
																				 //clamped between 0 and 1 tells if vert is facing upwards
				IN.position.xyz += fixed3(0,1,0) * fbm(mul(unity_ObjectToWorld, IN.position.xz)) * upMask;

				
				//World space pos of vertex
				float3 worldPos = mul(unity_ObjectToWorld, IN.position).xyz; 
				//World space view direction
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				//World space normal
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
				c.rgb = skyColor * _color;
				return c;

				//float4 textureColor = tex2D(_mainTexture, IN.uv);
				//return textureColor * _waterColor;
			}


			ENDCG
		}

	}

}