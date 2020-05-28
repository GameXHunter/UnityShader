Shader "Custom/AlphaBlendSided"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_Specular("Specular",Color)=(1,1,1,1)
		_Fresnel("Fersnel",Range(0,1))=0.5
		_Smoothness("Smoothness",Range(0.05,1)) = 0.5
		_MainTex("Main Tex", 2D) = "white" {}
	   _AlphaScale("Alpha Scale",Range(0,1)) = 1
		_BumpMap("Normal",2D) = "bump"{}
	   _Reflect("Reflect",cube) = ""{}
	   _Gloss("Gloss", Range(8.0, 256)) = 20
		_Cubemap("Environment Cubemap", Cube) = "_Skybox" {}

	   _Distortion("Distortion", Range(0, 100)) = 10
		_RefractAmount("Refract Amount", Range(0.0, 1.0)) = 1.0
	}
	SubShader{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Opaque" }
		
		GrabPass{ "_RefractionTex" }

		Pass{
			Tags{ "LightMode" = "ForwardBase" }

			// First pass renders only back faces 
			// Cull Front
			Cull Off

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma multi_compile_fwdbase	
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

			#include "Lighting.cginc"
		//	#include "UnityCG.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _AlphaScale;
			fixed4 _Specular;
			float _Gloss;


			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed4 texColor = tex2D(_MainTex, i.uv);

				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
			
				fixed3 halfDir = normalize(worldLightDir + viewDir);

				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				return fixed4(ambient + diffuse+ specular, texColor.a * _AlphaScale);
			}

				ENDCG
		}

		Pass{
			Tags{ "LightMode" = "ForwardBase" }

			// Second pass renders only front faces 
			Cull Back

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma multi_compile_fwdbase	
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _AlphaScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				
				fixed3 worldNormal = normalize(i.worldNormal);
			
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed4 texColor = tex2D(_MainTex, i.uv);

				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
		
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

				fixed3 halfDir = normalize(worldLightDir + viewDir);

				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				return fixed4(ambient + diffuse + specular , texColor.a * _AlphaScale);
			}
			ENDCG
		   }


		Pass{
				// Pass for other pixel lights
				Tags{ "LightMode" = "ForwardAdd" }

				Blend One One

				CGPROGRAM

				// Apparently need to add this declaration
#pragma multi_compile_fwdadd

#pragma vertex vert
#pragma fragment frag

#include "Lighting.cginc"
#include "AutoLight.cginc"

				fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				fixed3 worldNormal = normalize(i.worldNormal);
#ifdef USING_DIRECTIONAL_LIGHT
			fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
#else
			fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
#endif

			fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

			fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
			fixed3 halfDir = normalize(worldLightDir + viewDir);
			fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

#ifdef USING_DIRECTIONAL_LIGHT
			fixed atten = 1.0;
#else
#if defined (POINT)
			float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
			fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
#elif defined (SPOT)
			float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
			fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
#else
			fixed atten = 1.0;
#endif
#endif

			return fixed4((diffuse + specular) * atten, 1.0);
			}
				ENDCG
			}


		GrabPass{ "_RefractionTex" }
		
		Pass{

				CGPROGRAM

#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"

				sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			samplerCUBE _Cubemap;
			float _Distortion;
			fixed _RefractAmount;
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord: TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;
				float4 TtoW1 : TEXCOORD3;
				float4 TtoW2 : TEXCOORD4;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.scrPos = ComputeGrabScreenPos(o.pos);

				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				// Get the normal in tangent space
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));

				// Compute the offset in tangent space
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

				// Convert the normal to world space
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				fixed3 reflDir = reflect(-worldViewDir, bump);
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;

				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;

				return fixed4(finalColor, 1);
			}

				ENDCG
		}
	  
 }
	FallBack "Transparent/VertexLit"
}