#ifndef SKYBOX_INPUT
#define SKYBOX_INPUT

TEXTURE2D(_Stars);
TEXTURE2D(_Cloud);
SAMPLER(sampler_Stars);
SAMPLER(sampler_Cloud);


CBUFFER_START(UnityPerMaterial)

float _addHorizon, _addGradient, _addCloud, _addStar, _MirrorMode;

float _SunRadius, _MoonRadius, _MoonOffset;
float3 _StarsSkyColor, _CloudDayColor, _CloudNightColor;
float3 _DayBottomColor, _DayTopColor, _NightBottomColor, _NightTopColor;
float _StarsSpeed, _StarsCutoff, _StarsFrequency;
float _CloudFrequency, _CloudSpeed, _CloudCutoff, _DistortScale, _DistortionSpeed, _CloudNoiseScale;
float _HorizonIntensity, _HorizonHeight, _MidLightIntensity, _HorizonBrightness;
float3 _MoonColor, _SunColor;
float3 _HorizonColorDay, _HorizonLightDay, _HorizonColorNight, _HorizonLightNight;

CBUFFER_END



#endif
