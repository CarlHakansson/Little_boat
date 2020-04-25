Shader "Unlit/boatShader"
{
    Properties
    {
        _floatPointML ("Float Point Middle Left", Vector) = (0, 0, 0, 0)
        _floatPointMR ("Float Point Middle Right", Vector) = (0, 0, 0, 0)
        _floatPointB ("Float Point Back", Vector) = (0, 0, 0, 0)
        _MainTex ("Texture", 2D) = "white" { }
        _emissionTex ("Emission Texture", 2D) = "white" { }
        _emissionColor ("Emission Color", color) = (0, 0, 0, 0)
        _emissionStrength ("Emission Strength", float) = 0
        _ambientContribution("Ambient Light Contribution", float) = 0.2
        _ambientColor("Ambient Color", color) = (1,1,1,1)
        _lightIntensity("Light Intensity", float) = 1.0

        _scale ("Noise Scale", Float) = 1.0
        _amplitude ("Amplitude", Float) = 1.0
        _heightOffset ("Height Offset", Float) = 0.0
        _waveSpeed ("Wave Speed", Float) = 1.0
        _rotationLerpAmount ("Rotation Lerp Amount", float) = 0.5
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vertexFunction
            #pragma fragment fragmentFunction
            // make fog work
            //#pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                //UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
            };

            sampler2D _MainTex;
            sampler2D _emissionTex;
            float4 _MainTex_ST;
            float4 _emissionTex_ST;
            float4 _emissionColor;
            float _emissionStrength;
            float _ambientContribution;
            float4 _ambientColor;
            float _lightIntensity;

            float4 _floatPointML;
            float4 _floatPointMR;
            float4 _floatPointB;
            float4 _floatPointF;

            float _scale;
            float _amplitude;
            float _heightOffset;
            float _waveSpeed;
            float _rotationLerpAmount;

            //Noise function

            // Copyright (c) 2011 Stefan Gustavson. All rights reserved.
            // Distributed under the MIT license. See LICENSE file.
            // https://github.com/ashima/webgl-noise
            float3 mod289(float3 x)
            {
                return x - floor(x / 289.0) * 289.0;
            }

            float4 mod289(float4 x)
            {
                return x - floor(x / 289.0) * 289.0;
            }

            float4 permute(float4 x)
            {
                return mod289((x * 34.0 + 1.0) * x);
            }

            float4 taylorInvSqrt(float4 r)
            {
                return 1.79284291400159 - r * 0.85373472095314;
            }

            float4 snoise_grad(float3 v)
            {

                v = v * _scale + float3(_Time.y * _waveSpeed, 0, _Time.y * _waveSpeed);

                const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);

                // First corner
                float3 i = floor(v + dot(v, C.yyy));
                float3 x0 = v - i + dot(i, C.xxx);

                // Other corners
                float3 g = step(x0.yzx, x0.xyz);
                float3 l = 1.0 - g;
                float3 i1 = min(g.xyz, l.zxy);
                float3 i2 = max(g.xyz, l.zxy);
                // x1 = x0 - i1  + 1.0 * C.xxx;

                // x2 = x0 - i2  + 2.0 * C.xxx;
                // x3 = x0 - 1.0 + 3.0 * C.xxx;
                float3 x1 = x0 - i1 + C.xxx;
                float3 x2 = x0 - i2 + C.yyy;
                float3 x3 = x0 - 0.5;

                // Permutations
                i = mod289(i);
                // Avoid truncation effects in permutation
                float4 p = permute(permute(permute(i.z + float4(0.0, i1.z, i2.z, 1.0)) + i.y + float4(0.0, i1.y, i2.y, 1.0)) + i.x + float4(0.0, i1.x, i2.x, 1.0));
                // Gradients: 7x7 points over a square, mapped onto an octahedron.

                // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
                float4 j = p - 49.0 * floor(p / 49.0);

                // mod(p,7*7)
                float4 x_ = floor(j / 7.0);
                float4 y_ = floor(j - 7.0 * x_);

                // mod(j,N)
                float4 x = (x_ * 2.0 + 0.5) / 7.0 - 1.0;
                float4 y = (y_ * 2.0 + 0.5) / 7.0 - 1.0;

                float4 h = 1.0 - abs(x) - abs(y);

                float4 b0 = float4(x.xy, y.xy);
                float4 b1 = float4(x.zw, y.zw);
                //float4 s0 = float4(lessThan(b0, 0.0)) * 2.0 - 1.0;

                //float4 s1 = float4(lessThan(b1, 0.0)) * 2.0 - 1.0;
                float4 s0 = floor(b0) * 2.0 + 1.0;
                float4 s1 = floor(b1) * 2.0 + 1.0;
                float4 sh = -step(h, 0.0);

                float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
                float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

                float3 g0 = float3(a0.xy, h.x);
                float3 g1 = float3(a0.zw, h.y);
                float3 g2 = float3(a1.xy, h.z);
                float3 g3 = float3(a1.zw, h.w);

                // Normalise gradients
                float4 norm = taylorInvSqrt(float4(dot(g0, g0), dot(g1, g1), dot(g2, g2), dot(g3, g3)));
                g0 *= norm.x;
                g1 *= norm.y;
                g2 *= norm.z;
                g3 *= norm.w;

                // Compute noise and gradient at P
                float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
                float4 m2 = m * m;
                float4 m3 = m2 * m;
                float4 m4 = m2 * m2;
                float3 grad = -6.0 * m3.x * x0 * dot(x0, g0) + m4.x * g0 + -6.0 * m3.y * x1 * dot(x1, g1) + m4.y * g1 + -6.0 * m3.z * x2 * dot(x2, g2) + m4.z * g2 + -6.0 * m3.w * x3 * dot(x3, g3) + m4.w * g3;
                float4 px = float4(dot(x0, g0), dot(x1, g1), dot(x2, g2), dot(x3, g3));
                return float4(grad, dot(m4, px) * _amplitude + _heightOffset);
            }

            v2f vertexFunction(appdata_full v)
            {
                v2f o;

                //Construct vectors from back point to both front points, Y value is noise value at point location
                float3 rightVec = float3(_floatPointMR.x, snoise_grad(_floatPointMR).w, _floatPointMR.z) - float3(_floatPointB.x, snoise_grad(_floatPointB).w, _floatPointB.z);
                float3 leftVec = float3(_floatPointML.x, snoise_grad(_floatPointML).w, _floatPointML.z) - float3(_floatPointB.x, snoise_grad(_floatPointB).w, _floatPointB.z);

                //Create up vector, "wave normal" by cross product of the two 
                float3 newUp = normalize(cross(leftVec, rightVec));

                //Rodrigues' rotation formula
                //Construct rotation axis from world up direction and wave normal
                float3 axis = cross(float3(0, 1, 0), newUp);
                float angleCos = dot(float3(0, 1, 0), newUp); //cosine of angle
                //Cross product matrix
                float3x3 K = float3x3(0, 			axis.z, 		-axis.y,
                						-axis.z, 	0, 				axis.x,
                						axis.y, 	-axis.x, 		0);
                float3x3 IT = float3x3(1, 0, 0, 0, 1, 0, 0, 0, 1); //identity matrix
                float3x3 R = IT + K + mul(K, K) * (1 / (1 + angleCos)); //final rotation matrix
                //Lerp between original and rotated position to smooth stuff out
                v.vertex.xyz = lerp(v.vertex.xyz, mul(R, v.vertex.xyz), _rotationLerpAmount);

                //Displace vertex vertically by mean noise value of all points
                v.vertex.y += ((snoise_grad(_floatPointML).w + snoise_grad(_floatPointMR).w + snoise_grad(_floatPointB).w) / 3);

                //Standard sendoffs to fragment function
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv2 = TRANSFORM_TEX(v.texcoord, _emissionTex);
                o.normal = v.normal;
              //  UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            fixed4 fragmentFunction(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 em = tex2D(_emissionTex, i.uv2);

                //Create worldspace normal
                float3 normalWorld = UnityObjectToWorldNormal(i.normal);

                //Simple dot product lighting with normal and light direction
                float diffuseLighting = max(dot(normalWorld, _WorldSpaceLightPos0), _ambientContribution);

                //Tint shadows with ambient color and areas in sunlight with sun light color
                float4 lightTint = 1;
                if(diffuseLighting <= _ambientContribution) {
                	lightTint = normalize(_ambientColor);
                } else {
                	lightTint = normalize(_LightColor0);
                }

                //Increase light intensity by specified amount to be able to match scene light
                diffuseLighting *= _lightIntensity;

                
                // apply fog
               // UNITY_APPLY_FOG(i.fogCoord, col);
                return col * diffuseLighting * lightTint + em * _emissionColor * _emissionStrength;
            }
            ENDCG
        }
    }
}