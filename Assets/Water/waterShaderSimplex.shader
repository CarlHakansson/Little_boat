Shader "Custom/Water Bowl Simplex"
{

    Properties
    {
        //Properties are exposed values we can change in the editor
        // and that the CPU can access. They can be changed at runtime.
        _waterColor ("Main Water Color", Color) = (1, 1, 1, 1)
        _SSSColor ("SSS Water Color", Color) = (1, 1, 1, 1)
        _scale ("Noise Scale", Float) = 1.0
        _amplitude ("Amplitude", Float) = 1.0
        _heightOffset ("Height Offset", Float) = 0.0
        _waveSpeed ("Wave Speed", Float) = 1.0
        _waveSharpness ("Wave Crest Sharpness", Range(0, 3)) = 0.0
        _octaves ("Noise Octaves", Int) = 2
        _normalCalcOffset ("FD Normal Calculation Offset", Float) = 0.1
        _normalCalcMethod("Normal Calculation Method", Range(0,2)) = 0
        _reflectionSharpnessExp ("Reflection Sharpness", Float) = 512.0
        _reflectionIntensity ("Reflection Intensity", Float) = 10.0

    }

    SubShader
    {

        Pass
        {
            CGPROGRAM
            //Name vertex and fragment functions and including some useful CG stuff
            #pragma vertex vertexFunction
            #pragma fragment fragmentFunction

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            //Create vertex to fragment "data package" struct 
            // with the vertex info we want to use and then pass to the fragment shader
            struct v2f
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 worldPos : TEXCOORD3;

            };

            //Here we reference the property names and types. We can then access the properties
            float4 _waterColor;
            float4 _SSSColor;
            float _scale;
            float _amplitude;
            float _heightOffset;
            float _waveSpeed;
            float _waveSharpness;
            int _octaves;
            float _normalCalcOffset;
            int _normalCalcMethod;
            float _reflectionSharpnessExp;
            float _reflectionIntensity;
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

                //Noise function modified to make use of property values to enable changes to be made in the unity editor
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

            float getHeight(float3 worldPos)
            {
                //Helper function to implement FBM version of earlier noise function
                //World XZ scale of noise is halved every octave by doubling uv scale, at the same time the amplitude is halved.
                //This makes the noise add up and become "finer" with every octave, while kind of retaining the general shape of the noise
                // at 1 octave
                float2 uv = worldPos.xz;

                float value = 0.0;
                float amplitude = 0.5;

                for(int i = 0; i < _octaves; i++)
                {
                    value += amplitude * snoise_grad(float3(uv, 0)).w;
                    uv *= 2.0;
                    amplitude *= 0.5;
                }

                return value;
            }

            float3 getNormal(float3 worldPos, out float height)
            {
                //Normal calculation and modification using forward difference method
                // kinda cheating and "ugly" but slightly cheaper, runs better on my laptop
                //_normalCalcOffset enables variable offset for normal calculation

                //Establish one point on both the "right" and "forward" axes
                float3 worldPos1 = worldPos + float3(1, 0, 0) * _normalCalcOffset;
                float3 worldPos2 = worldPos + float3(0, 0, 1) * _normalCalcOffset;

                //Sample noise function for all points
                worldPos.y += getHeight(worldPos);
                worldPos1.y += getHeight(worldPos1);
                worldPos2.y += getHeight(worldPos2);

                //Cross product of the two vectors extending from the vertex location will give us the normal of the vertex
                float3 normal = -normalize(cross(worldPos1 - worldPos, worldPos2 - worldPos));

                //Return the new world position of the vertex as the height
                height = worldPos.y;
                return normal;
            }

            float3 getNormalAnalytical (float3 worldPos, out float height) {

            	worldPos.y += getHeight(worldPos);

            	float3 normal = normalize(snoise_grad(worldPos).xyz);

            	height = worldPos.y;
            	return normal;
            }

            //Vertex function
            v2f vertexFunction(appdata_full IN)
            {
                v2f OUT;
                //This is where we can change the vertex positions

                //Dot product between the world Y vector and the current normal 
                //clamped between 0 and 1 tells if vert is facing upwards
                // if 0 - normal 100% perpendicular to world Y, if 1 - normal is world Y (0,1,0)
                float upMask = clamp(IN.normal.y, -0.1, 1.0);
                //float upMask = clamp(dot(IN.normal, (0, 1, 0)), -0.1, 1.0);

                //World space position of vertex
                float3 worldPos = mul(UNITY_MATRIX_M, IN.vertex).xyz;

                float height;
                float3 normal;

                if(_normalCalcMethod < 1) {
                	normal = getNormal(worldPos, height);
                } else {
                	normal = normalize(getNormalAnalytical(worldPos, height));
                }

                if(upMask > -0.1) {
                	worldPos.y = height;
            	}

                OUT.worldPos = worldPos;

                //Displace vertex along negative xz-component of normal to "squeeze" waves together and make them sharper
                worldPos.xz -= normal.xz * _waveSharpness * upMask;

                //World space normal of the vertex
                float3 worldNormal = UnityObjectToWorldNormal(IN.normal);

                //Apply camera projection matrix to vert location for perspective
                //OUT.position = UnityObjectToClipPos(IN.position);
                OUT.position = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
                OUT.uv = IN.texcoord.xy;

                float3 i = normalize(ObjSpaceViewDir(IN.vertex));

                OUT.normal = worldNormal;

                return OUT;
            }

            //Fragment function
            fixed4 fragmentFunction(v2f IN) : SV_Target
            {
                //Same upMask as in vertex function
                float upMask = clamp(IN.normal.y, 0.0, 1.0);

                IN.normal = normalize(IN.normal);

                float height;
                float3 normal;
                
                if(_normalCalcMethod < 1) {
                	normal = lerp(IN.normal, getNormal(IN.worldPos, height), upMask);
                } else {
                	normal = lerp(IN.normal, normalize(getNormalAnalytical(IN.worldPos, height)), upMask);
                }

                //Calculate vector from active camera to current vertex
                float3 viewDir = normalize(IN.worldPos - _WorldSpaceCameraPos);
                //Calculate reflection direction of "view ray" for use in calculating reflections
                float3 reflDir = reflect(viewDir, normal);

                //Fresnel multiplier for reflection strength. Water reflects approx. 5% when you look straight on
                //I looked at the real fresnel function of water and tried to replicate it below
                float F0 = 0.05;
                float fresnel = pow(1 - dot(-viewDir, normal), 4) * (1 - F0) + F0;

                //Sample reflection cubemap
                half4 reflection = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflDir);

                //Super fake specular highlight on the waves using incoming light direction from 
                //the Directional Light. Reflection sharpness can be controlled with _reflectionSharpnessExp
                //Not at all physically correct, does not account for dispersion of light intensity
                //across the reflection or probably a bunch of other things. The effect has to be dialed in
                // by the user to not look too wild
                reflection += pow(max(dot(reflDir, _WorldSpaceLightPos0.xyz), 0), _reflectionSharpnessExp) * normalize(_LightColor0) * _reflectionIntensity;

                // Lerp the base water color with a lighter, greener color by world space height to achieve a super fake 
                // light dispersion effect below the surface of the water and in the tips of the waves.
                // This is then lerped with the reflection from the sky and sun by the fresnel multiplier
                fixed4 r = lerp(lerp(_waterColor, _SSSColor * normalize(_LightColor0), height), reflection, fresnel);

                return r;
            }

            ENDCG
        }

    }

}