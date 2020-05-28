Shader "Custom/bolires"
{
	//TODO:加边缘光
	Properties
	{
		_Diffuse("Diffuse", Color) = (1,1,1,1)
		_RimColor("RimColor", Color) = (1,1,1,1)
		_RimPower("RimPower", Range(0.000001, 3.0)) = 0.1
		_MainTex("Texture", 2D) = "white" {}
	}
	
	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Opaque" }
		LOD 100
		GrabPass{ "_ScreenTex" }
		
		Pass
		{
			CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_fog

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"


		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _ScreenTex;

		
		//边缘辉光
		fixed4 _RimColor;
		float _RimPower;
	

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float4 uv : TEXCOORD0;
			float2 uv2 : TEXCOORD1;
			float4 vertex : SV_POSITION;
		};

	
		v2f vert(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv2 = TRANSFORM_TEX(v.uv, _MainTex);
			o.uv = ComputeGrabScreenPos(o.vertex);
			//o.uv.x = 1 - o.uv.x;
			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			// sample the texture
			i.uv.xy += float2(0.1,0.1);
			fixed4 fra = tex2D(_ScreenTex, i.uv.xy / i.uv.w);
			fixed4 fle = tex2D(_MainTex, i.uv2);
			// apply fog
			return lerp(fra, fle, 0.2);
		}
			ENDCG
		}

		//边缘光
	/*	Pass
		{

			CGPROGRAM
#include "Lighting.cginc"
		fixed4 _RimColor;
		float _RimPower;

		struct v2f
		{
			float4 pos : SV_POSITION;
			float3 worldNormal : TEXCOORD0;
			float3 worldViewDir : TEXCOORD2;
		};

		v2f vert(appdata_base v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			o.worldViewDir = _WorldSpaceCameraPos.xyz - worldPos;
			return o;
		}

		fixed3 frag(v2f i) : SV_Target
		{
		fixed3 worldNormal = normalize(i.worldNormal);
	
		float3 worldViewDir = normalize(i.worldViewDir);
		float rim = 1 - max(0, dot(worldViewDir, worldNormal));
		fixed3 rimColor = _RimColor * pow(rim, 1 / _RimPower);

		return fixed3(rimColor);
		}
#pragma vertex vert
#pragma fragment frag	

			ENDCG
		}
*/

	}
}
