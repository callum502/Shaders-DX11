Texture2D shaderTexture : register(t0);
Texture2D distortTex : register(t1);
SamplerState SampleType : register(s0);

cbuffer ScreenSizeBuffer : register(b0)
{
    float screenWidth;
    float3 padding;
};

cbuffer DistortBuffer : register(b1)
{
    float time;
    float distortStrength;
    float2 padding2;
};

struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
};

float4 main(InputType input) : SV_TARGET
{
    float weight0, weight1, weight2, weight3, weight4;

    float4 colour;
    
    //get distort value from distortion texture
    float distort = distortTex.Sample(SampleType, input.tex + time * 0.03);
    
    //get distort factor based on how close pixel is to edges
    float xdistort;
    if (input.tex.x<0.5)
    {
        xdistort = smoothstep(0, 0.2, input.tex.x);

    }
    else
    {
        xdistort = smoothstep(1, 0.8, input.tex.x);
    }
    
    float ydistort;
    if (input.tex.y < 0.5)
    {
        ydistort = smoothstep(0, 0.2, input.tex.y);

    }
    else
    {
        ydistort = smoothstep(1, 0.8, input.tex.y);
    }
    //sample the render texture using distorted coords
    colour = shaderTexture.Sample(SampleType, float2(input.tex.x + distort * 0.005 * distortStrength * xdistort, input.tex.y + distort * 0.005 * distortStrength * ydistort));
    
    //apply blue tint
    float4 finalcolour = lerp(colour, float4(0, 0, 1, 1), 0.5);
    finalcolour.a = 1.0f;
    return finalcolour;
}
