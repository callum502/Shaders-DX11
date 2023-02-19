
Texture2D shaderTexture : register(t0);
Texture2D depthMapTexture : register(t1);

SamplerState diffuseSampler : register(s0);
SamplerState shadowSampler : register(s1);

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

cbuffer ScreenSizeBuffer : register(b1)
{
    float shadowMapRes;
    int softness;
    float2 padding3;
};

struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
    float4 lightViewPos : TEXCOORD1;
    float3 worldPosition : TEXCOORD2;
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

    //spotlight calculation
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
    float4 colour = saturate(diffuse * intensity );

    //attenuation	
    float attenuation = 1 / (sl_distance_falloff *0.1 + (sl_distance_falloff * 0.025 * distance) + (sl_distance_falloff * 0.001 * pow(distance, 2)));
    
    float4 finalcolour = colour * spotlight * attenuation;

    return finalcolour;
}

// Calculate lighting intensity based on direction and normal. Combine with light colour.
float4 pointlightLighting(float3 lightVector, float3 normal, float4 diffuse, float distance)
{
	//point light
    float intensity = saturate(dot(normalize(normal), lightVector));
    float4 colour = saturate(diffuse * intensity);
    float4 finalcolour = colour ;

    //attenuation	
    float attenuation = 1 / (pl_distance_falloff + (pl_distance_falloff * 0.25 * distance) + (pl_distance_falloff * 0.01 * pow(distance, 2)));
	
    return finalcolour * attenuation;
}

// Is the gemoetry in our shadow map
bool hasDepthData(float2 uv)
{
    if (uv.x < 0.f || uv.x > 1.f || uv.y < 0.f || uv.y > 1.f)
    {
        return false;
    }
    return true;
}

bool isInShadow(Texture2D sMap, float2 uv, float4 lightViewPosition, float bias)
{
    // Sample the shadow map (get depth of geometry)
    float depthValue = sMap.Sample(shadowSampler, uv).r;
	// Calculate the depth from the light.
    float lightDepthValue = lightViewPosition.z / lightViewPosition.w;
    lightDepthValue -= bias;

	// Compare the depth of the shadow map value and the depth of the light to determine whether to shadow or to light this pixel.
    if (lightDepthValue < depthValue)
    {
        return false;
    }
    return true;
}

float2 getProjectiveCoords(float4 lightViewPosition)
{
    // Calculate the projected texture coordinates.
    float2 projTex = lightViewPosition.xy / lightViewPosition.w;
    projTex *= float2(0.5, -0.5);
    projTex += float2(0.5f, 0.5f);
    return projTex;
}

float4 main(InputType input) : SV_TARGET
{
    float shadowMapBias = 0.005f;
    float4 colour = float4(0.f, 0.f, 0.f, 1.f);
    float4 textureColour = shaderTexture.Sample(diffuseSampler, input.tex);

	// Calculate the projected texture coordinates.
    float2 pTexCoord = getProjectiveCoords(input.lightViewPos);
	
    colour = float4(0, 0, 0, 1);
    float texelSize = float(1) / shadowMapRes;
    for (int x = -softness; x <= softness; ++x)
    {
        for (int y = -softness; y <= softness; ++y)
        {
        
             // Shadow test. Is or isn't in shadow
            if (hasDepthData(pTexCoord))
            {
                 // Has depth map data
                if (!isInShadow(depthMapTexture, pTexCoord + float2(x * texelSize, y * texelSize), input.lightViewPos, shadowMapBias))
                {
                    // is NOT in shadow, therefore light
                    colour += calculateLighting(-dl_lightDirection.xyz, input.normal, dl_diffuseColour);
                }
            }
        }
    }
    colour /= (softness * 2 + 1) * (softness * 2 + 1);
    
    float3 lightVector = normalize(sl_position - input.worldPosition);
    float distance = length(sl_position - input.worldPosition);

    //get spotlight colour
    float4 spotlight = spotlightLighting(lightVector, input.normal, sl_diffuseColour, sl_direction, distance);
    
    //get point light colour
    float pl_distance = length(pl_position - input.worldPosition);
    float3 pl_lightVector = normalize(pl_position - input.worldPosition);
    float4 pointlight = pointlightLighting(pl_lightVector, input.normal, pl_diffuseColour, pl_distance);
    
    
    float4 final_colour = saturate(colour) + saturate(spotlight) + saturate(pointlight) + saturate(ambient);
    final_colour.w = 1;
    
    return saturate(final_colour) * textureColour;
}