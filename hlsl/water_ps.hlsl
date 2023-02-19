Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

cbuffer LightBuffer : register(b0)
{
    float4 ambient;
    
    float4 dl_diffuseColour;
    float3 dl_lightDirection;
    float padding;
    
    float4 sl_diffuseColour;
    float4 sl_position;
    float4 sl_direction;
    float sl_inner_angle;
    float sl_outer_angle;
    float sl_angle_falloff;
    float sl_distance_falloff;
    
    float4 pl_diffuseColour;
    float4 pl_position;
    float pl_distance_falloff;
    float3 padding2;
};

cbuffer TimeBuffer : register(b1)
{
    float time;
    float3 padding3;
};

cbuffer WaveBuffer : register(b2)
{
    float speed;
    float height;
};

cbuffer ScreenSizeBuffer : register(b3)
{
    float screenWidth;
    float3 padding4;
};

struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
    float3 worldPosition : TEXCOORD1;
};

// Calculate lighting intensity based on direction and normal. Combine with light colour.
float4 calculateLighting(float3 lightDirection, float3 normal, float4 diffuse)
{
    float intensity = saturate(dot(normal, lightDirection));
    float4 colour = saturate(diffuse * intensity);

    return colour;
}

float4 spotlightLighting(float3 lightVector, float3 normal, float4 diffuse, float3 direction, float distance)
{

    float rho = dot((lightVector), normalize(-direction));
    float phi = radians(sl_outer_angle);
    float theta = radians(sl_inner_angle);

    float spotlight;
    if (rho > cos(theta / 2))
    {
        spotlight = 1;

    }
    else if (rho <= cos(phi / 2))
    {
        spotlight = 0;
    }
    else
    {
        spotlight = pow((rho - cos(phi / 2)) / (cos(theta / 2) - cos(phi / 2)), sl_angle_falloff);
    }
	
    float intensity = saturate(dot(normal, lightVector));
    float4 colour = saturate(diffuse * intensity);

    //attenuation	
    float attenuation = 1 / (sl_distance_falloff * 0.1 + (sl_distance_falloff * 0.025 * distance) + (sl_distance_falloff * 0.001 * pow(distance, 2)));
    
    float4 finalcolour = colour * spotlight * attenuation;

    return finalcolour;
}

// Calculate lighting intensity based on direction and normal. Combine with light colour.
float4 pointlightLighting(float3 lightVector, float3 normal, float4 diffuse, float distance)
{
	//point light
    float intensity = saturate(dot(normalize(normal), lightVector));
    float4 colour = saturate(diffuse * intensity);
    float4 finalcolour = colour;

    //attenuation	
    float attenuation = 1 / (pl_distance_falloff + (pl_distance_falloff * 0.25 * distance) + (pl_distance_falloff * 0.01 * pow(distance, 2)));
	
    return finalcolour * attenuation;
}

float4 main(InputType input) : SV_TARGET
{
    float3 lightVector = normalize(sl_position - input.worldPosition);
    float distance = length(sl_position - input.worldPosition);

    //get spotlight colour
    float4 spotlight = spotlightLighting(lightVector, input.normal, sl_diffuseColour, sl_direction, distance);
    
    //get point light colour
    float pl_distance = length(pl_position - input.worldPosition);
    float3 pl_lightVector = normalize(pl_position - input.worldPosition);
    float4 pointlight = pointlightLighting(pl_lightVector, input.normal, pl_diffuseColour, pl_distance);
    
    float4 colour = calculateLighting(-dl_lightDirection, input.normal, dl_diffuseColour);
    
    float4 final_colour = saturate(colour) + saturate(spotlight) + saturate(pointlight) + saturate(ambient) ;
    final_colour.w = 0.5;
    return saturate(final_colour) * float4(0,0,0.8,1);

}



