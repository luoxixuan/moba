// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Unlit/Transparent Colored 1"
{
	Properties
	{
		_MainTex ("Base (RGB), Alpha (A)", 2D) = "black" {}

		//Hue��ֵ��ΧΪ0-359. ��������Ϊ0-1 ,�����������õ�3����Ϊ����3�� ����һ���ܵ�����.
		_Hue("Hue", Range(0,359)) = 0
		_Saturation("Saturation", Range(0,3.0)) = 0
		_Value("Value", Range(0,3.0)) = 1
		_Contrast("Contrast", Range(0,3.0)) = 1
		_Brightness("Brightness", Range(0,3.0)) = 1
	}

	SubShader
	{
		LOD 200

		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}
		
		Pass
		{
			Cull Off
			Lighting Off
			ZWrite Off
			Offset -1, -1
			Fog { Mode Off }
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _ClipRange0 = float4(0.0, 0.0, 1.0, 1.0);
			float2 _ClipArgs0 = float2(1000.0, 1000.0);
			half _Hue;
			half _Saturation;
			half _Value;
			half _Contrast;
			half _Brightness;

			struct appdata_t
			{
				float4 vertex : POSITION;
				half4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				half4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float2 worldPos : TEXCOORD1;
			};

			v2f o;

			v2f vert (appdata_t v)
			{
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.texcoord = v.texcoord;
				o.worldPos = v.vertex.xy * _ClipRange0.zw + _ClipRange0.xy;
				return o;
			}

			//RGB to HSV
			float3 RGBConvertToHSV(float3 rgb)
			{
				float R = rgb.r, G = rgb.g, B = rgb.b;
				float3 hsv;
				float max1 = max(R, max(G, B));
				float min1 = min(R, min(G, B));
				if (R == max1)
				{
					hsv.r = (G - B) / (max1 - min1);
				}
				if (G == max1)
				{
					hsv.r = 2 + (B - R) / (max1 - min1);
				}
				if (B == max1)
				{
					hsv.r = 4 + (R - G) / (max1 - min1);
				}
				hsv.r = hsv.r * 60.0;
				if (hsv.r < 0)
					hsv.r = hsv.r + 360;
				hsv.b = max1;
				hsv.g = (max1 - min1) / max1;
				return hsv;
			}

			//HSV to RGB
			float3 HSVConvertToRGB(float3 hsv)
			{
				float R, G, B;
				//float3 rgb;
				if (hsv.g == 0)
				{
					R = G = B = hsv.b;
				}
				else
				{
					hsv.r = hsv.r / 60.0;
					int i = (int)hsv.r;
					float f = hsv.r - (float)i;
					float a = hsv.b * (1 - hsv.g);
					float b = hsv.b * (1 - hsv.g * f);
					float c = hsv.b * (1 - hsv.g * (1 - f));
					if (i == 0)
					{
						R = hsv.b; G = c; B = a;
					}
					else if (i == 1)
					{
						R = b; G = hsv.b; B = a;
					}
					else if (i == 2)
					{
						R = a; G = hsv.b; B = c;
					}
					else if (i == 3)
					{
						R = a; G = b; B = hsv.b;
					}
					else if (i == 4)
					{
						R = c; G = a; B = hsv.b;
					}
					else
					{
						R = hsv.b; G = a; B = b;
					}
				}
				return float3(R, G, B);
			}

			half4 frag (v2f IN) : SV_Target
			{
				// Softness factor
				float2 factor = (float2(1.0, 1.0) - abs(IN.worldPos)) * _ClipArgs0;
			
				// Sample the texture
				//half4 col = tex2D(_MainTex, IN.texcoord) * IN.color;
				half4 col;
				if (IN.color.r < 0.001f) {
					col = tex2D(_MainTex, IN.texcoord);
					if (_Saturation > 0)
					{
						float3 colorHSV;
						colorHSV.rgb = RGBConvertToHSV(col.rgb);   //ת��ΪHSV
						colorHSV.r += _Hue; //����ƫ��Hueֵ
						colorHSV.r = colorHSV.r % 360;    //����360��ֵ��0��ʼ

						colorHSV.g *= _Saturation;  //�������Ͷ�
						colorHSV.b *= _Value;

						col.rgb = HSVConvertToRGB(colorHSV.rgb) * _Brightness;   //���������HSV��ת��ΪRGB��ɫ
						//contrast�Աȶȣ����ȼ���Աȶ���͵�ֵ  
						fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
						//����Contrast�ڶԱȶ���͵�ͼ���ԭͼ֮���ֵ  
						col.rgb = lerp(avgColor, col.rgb, _Contrast);
					}
					else {
						float grey = dot(col.rgb, float3(0.299, 0.587, 0.114));
						col.rgb = float3(grey, grey, grey);
					}
				}
				else {
					col = tex2D(_MainTex, IN.texcoord) * IN.color;
				}
				col.a *= clamp( min(factor.x, factor.y), 0.0, 1.0);
				return col;
			}
			ENDCG
		}
	}
	
	SubShader
	{
		LOD 100

		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}
		
		Pass
		{
			Cull Off
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMaterial AmbientAndDiffuse
			
			SetTexture [_MainTex]
			{
				Combine Texture * Primary
			}
		}
	}
}
