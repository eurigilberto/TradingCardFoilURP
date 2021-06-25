#ifndef CUSTOM_SPECULAR
#define CUSTOM_SPECULAR

float specular(float3 lightDir, float3 normal, float3 viewDir, float specularPower, float specularIntensity){
    // Calculate the reflection vector: 
    float3 R = normalize(2 * dot(normal, -lightDir) * normal + lightDir); 
    // Calculate the speculate component: 
    float s = pow(saturate(dot(R, normalize(viewDir))), specularPower) * specularIntensity;
    return s;
}

void SpecularShaderGraph_float(float3 lightDir, float3 normal, float3 viewDir, float specularPower, float specularIntensity, out float s){
    s = specular(lightDir, normal, viewDir, specularPower, specularIntensity);
}

#endif