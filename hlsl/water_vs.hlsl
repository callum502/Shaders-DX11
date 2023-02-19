Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

cbuffer MatrixBuffer : register(b0)
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
};

cbuffer TimeBuffer : register(b1)
{
    float time;
    float3 padding;
};

cbuffer WaveBuffer : register(b2)
{
    float speed;
    float amplitude;
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
};

float GetHeightDisplacement(float2 uv, float height_offset)
{
    float4 sample = texture0.SampleLevel(sampler0, float2(uv.x, uv.y - time * speed), 0);
    float4 sample2 = texture0.SampleLevel(sampler0, float2(uv.x - time * speed * -0.25, uv.y - time * speed * -0.25), 0);

    return ((sample + sample2) / 2) * amplitude * height_offset;
}

OutputType main(InputType input)
{
    OutputType output;
    
    //get world pos
    output.worldPosition = mul(input.position, worldMatrix).xyz;
	
    //get height offset
    float height_offset = smoothstep(0, -30, output.worldPosition.z);
	
    //calculate normals
    float offset = 0.01;
    float heightN = GetHeightDisplacement(float2(input.tex.x, input.tex.y + offset), height_offset);
    float heightS = GetHeightDisplacement(float2(input.tex.x, input.tex.y - offset), height_offset);
    float heightE = GetHeightDisplacement(float2(input.tex.x + offset, input.tex.y), height_offset);
    float heightW = GetHeightDisplacement(float2(input.tex.x - offset, input.tex.y), height_offset);
    float height = GetHeightDisplacement(input.tex, height_offset);
	
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

	// Store the texture coordinates for the pixel shader.
    output.tex = input.tex;

	// Calculate the normal vector against the world matrix only and normalise.
    output.normal = mul(input.normal, (float3x3) worldMatrix);
    output.normal = normalize(output.normal);

    return output;
}