Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

cbuffer MatrixBuffer : register(b0)
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
    matrix lightViewMatrix;
    matrix lightProjectionMatrix;
    matrix spotlightViewMatrix;
    matrix spotlightProjectionMatrix;
};

cbuffer TimeBuffer : register(b1)
{
    float time;
    float amplitude;
    float2 planeRes;
};

cbuffer CameraBuffer : register(b2)
{
    float3 cameraPosition;
    float padding2;
};


struct InputType
{
    float4 position : POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};

struct OutputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
    float3 worldPosition : TEXCOORD1;
    float4 lightViewPos : TEXCOORD2;
    float4 spotLightViewPos : TEXCOORD3;
    float3 viewVector : TEXCOORD4;
};

float GetHeightDisplacement(float2 uv)
{
    float4 textureColour = texture0.SampleLevel(sampler0, uv, 0);

    return uv = textureColour * amplitude;
}

OutputType main(InputType input)
{
    OutputType output;

    float4 textureColour = texture0.SampleLevel(sampler0, input.tex, 0);
	
    //calculate normals
    float xoffset = 1.0f / planeRes.x;
    float yoffset = 1.0f / planeRes.y;
    float heightN = GetHeightDisplacement(float2(input.tex.x, input.tex.y + yoffset));
    float heightS = GetHeightDisplacement(float2(input.tex.x, input.tex.y - yoffset));
    float heightE = GetHeightDisplacement(float2(input.tex.x + xoffset, input.tex.y));
    float heightW = GetHeightDisplacement(float2(input.tex.x - xoffset, input.tex.y));
    float height = GetHeightDisplacement(input.tex);
	
    //manipulate y position
    input.position.y = height;
    
    float3 tan1 = normalize(float3(1, heightE - height, 0));
    float3 tan2 = normalize(float3(-1, heightW - height, 0));
    float3 bi1 = normalize(float3(0, heightN - height, 1));
    float3 bi2 = normalize(float3(0, heightS - height, -1));
	
    float3 normal1 = normalize(cross(tan1, bi2));
    float3 normal2 = normalize(cross(bi2, tan2));
    float3 normal3 = normalize(cross(tan2, bi1));
    float3 normal4 = normalize(cross(bi1, tan1));
	
    input.normal = (normal1 + normal2 + normal3 + normal4) * 0.25;
   
	// Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
    
    // Calculate the position of the vertice as viewed by the light source.
    output.lightViewPos = mul(input.position, worldMatrix);
    output.lightViewPos = mul(output.lightViewPos, lightViewMatrix);
    output.lightViewPos = mul(output.lightViewPos, lightProjectionMatrix);
  
    // Calculate the position of the vertice as viewed by the light source.
    output.spotLightViewPos = mul(input.position, worldMatrix);
    output.spotLightViewPos = mul(output.spotLightViewPos, spotlightViewMatrix);
    output.spotLightViewPos = mul(output.spotLightViewPos, spotlightProjectionMatrix);

	// Store the texture coordinates for the pixel shader.
    output.tex = input.tex;

	// Calculate the normal vector against the world matrix only and normalise.
    output.normal = mul(input.normal, (float3x3) worldMatrix);
    output.normal = normalize(output.normal);
	
	//get world pos
    output.worldPosition = mul(input.position, worldMatrix).xyz;
    
    //get view direction vector
    float4 worldPosition = mul(input.position, worldMatrix);
    output.viewVector = cameraPosition.xyz - worldPosition.xyz;
    output.viewVector = normalize(output.viewVector);

    return output;
}