#include "Assets\Materials\Shader\Specluar.hlsl"

//The following functions are taken from the awesome tutorial by Inigo Quilez at https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float smoothMaximun(float a, float b, float smoothFactor){
    return ((a + b) + sqrt((a - b)*(a - b) + smoothFactor))/2;
}

float sdCappedCone(float3 p, float3 a, float3 b, float ra, float rb)
{
    float rba  = rb-ra;
    float baba = dot(b-a,b-a);
    float papa = dot(p-a,p-a);
    float paba = dot(p-a,b-a)/baba;
    float x = sqrt( papa - paba*paba*baba );
    float cax = max(0.0,x-((paba<0.5)?ra:rb));
    float cay = abs(paba-0.5)-0.5;
    float k = rba*rba + baba;
    float f = clamp( (rba*(x-ra)+paba*baba)/k, 0.0, 1.0 );
    float cbx = x-ra - f*rba;
    float cby = paba - f;
    float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
    return s*sqrt( min(cax*cax + cay*cay*baba,
                       cbx*cbx + cby*cby*baba) );
}

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float sdRoundCone(float3 p, float3 a, float3 b, float r1, float r2)
{
    // sampling independent computations (only depend on shape)
    float3  ba = b - a;
    float l2 = dot(ba,ba);
    float rr = r1 - r2;
    float a2 = l2 - rr*rr;
    float il2 = 1.0/l2;
    
    // sampling dependant computations
    float3 pa = p - a;
    float y = dot(pa,ba);
    float z = y - l2;
    float x2 = dot( pa*l2 - ba*y, pa*l2 - ba*y );
    float y2 = y*y*l2;
    float z2 = z*z*l2;

    // single square root!
    float k = sign(rr)*rr*rr*x2;
    if( sign(z)*a2*z2 > k ) return  sqrt(x2 + z2)        *il2 - r2;
    if( sign(y)*a2*y2 < k ) return  sqrt(x2 + y2)        *il2 - r1;
                            return (sqrt(x2*a2*il2)+y*rr)*il2 - r1;
}

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return lerp( d2, -d1, h ) + k*h*(1.0-h); 
}

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) + k*h*(1.0-h); }

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) - k*h*(1.0-h); 
}

float toSphere(float3 center, float radius, float3 pos){
    return distance(center, pos) - radius;
}

struct SphereData{
    float dist;
    float3 color;
};
SphereData createSphereData(float dist, float3 color){
    SphereData sphereData;
    sphereData.dist = dist;
    sphereData.color = color;
    return sphereData;
}

#define SphereCount 12
struct SphereAnimData{
    float2 planeOffset;
    float frequency;
    float2 minMaxPos;
    float radius;
    float offsetDist;
    float offsetFreq;
};

float animatedSphere(SphereAnimData sphereAnimData, float3 checkPos){
    float sinVertical = sin(_Time.y * sphereAnimData.frequency) * 0.5 + 0.5;
    float sinOffset = sphereAnimData.offsetDist * sin(checkPos.y * sphereAnimData.offsetFreq);
    float yPos = lerp(sphereAnimData.minMaxPos.x, sphereAnimData.minMaxPos.y, sinVertical);
    float3 spherePos = float3(sphereAnimData.planeOffset.x, yPos, sphereAnimData.planeOffset.y + sinOffset);
    return toSphere(spherePos, sphereAnimData.radius, checkPos);
}

float combinedSpheres(float3 checkPos,SphereAnimData sAnimData[SphereCount]){
    float distSphere[SphereCount];
    for(int i = 0; i < SphereCount; i++){
        float dist = animatedSphere(sAnimData[i], checkPos);
        distSphere[i] = dist;
    }

    float unionFactor = 0.2;
    float sUnion = opSmoothUnion(distSphere[0], distSphere[1], unionFactor);
    for(int i = 2; i < SphereCount; i ++){
        sUnion = opSmoothUnion(sUnion, distSphere[i], unionFactor);
    }

    return sUnion;
}

float liquidInsideLamp(float3 checkPos){
    SphereAnimData sAnimData[SphereCount] = {
        {float2(0.3, 0), 0.6, float2(0, 4), 1, 0.3, 4},
        {float2(0.1, 0.2), 1, float2(1, 3), 0.7, 0.1, 5},
        {float2(0, -0.2), 0.5, float2(0.5, 3.5), 0.5, 0.2, 3},
        {float2(0, 0), 1, float2(-0.5, 4), 0.5, 0.2, 1},
        {float2(0.5, -1), 1, float2(0, 3), 0.8, 0.5, 2},
        {float2(-0.5, 1), 2, float2(1, 3.5), 1, 0.2, 0.5},
        {float2(0.5, -0.5), 1.3, float2(0, 3.2), 0.8, 0.2, 1},
        {float2(1, 0), 2, float2(-0.4, 1), 1.2, 0.2, 1},
        {float2(0, -1), 1, float2(-1.5, -0.8), 1.2, 0.2, 1},
        {float2(0, 1), 1.5, float2(-1.5, -1), 1.2, 0.2, 1},
        {float2(-1, 0), 1, float2(-0.7, 3), 1.2, 0.4, 4},
        {float2(0, 0), 1, float2(4, 5), 1, 0.2, 1}
    };

    return combinedSpheres(checkPos, sAnimData);

    //Generating color
    /*int smallest = 0;
    for(int i = 1; i < 4; i++){
        if(sdata[i].dist < sdata[smallest].dist){
            smallest = i;
        }
    }
    color = sdata[smallest].color;*/
}

float distanceToInsideLampScene(float3 castPosition){
    float sphereUnion = liquidInsideLamp(castPosition);
    float coneDist = sdRoundCone(castPosition, float3(0,0,0), float3(0,4,0), 2, 1);
    float sceneDist = opSmoothIntersection(sphereUnion, coneDist, 1);
    return sceneDist;
}

#define ballCount 5 

float distBaseTop(float3 castPosition){
    return sdCappedCone(castPosition, float3(0,0,0), float3(0,-2,0), 2.6, 1.6);
}

float inoutSphere(float3 p, float3 center, float radius, float depth){
    return abs(length(p - center) - radius) - depth;
}

float distanceToLampBase(float3 castPosition){
    float baseTop = distBaseTop(castPosition);
    float baseBot = sdCappedCone(castPosition, float3(0,-2.4,0), float3(0,-4,0), 1.2, 3);
    float combination =baseTop; //opSmoothUnion(baseTop, baseBot, 0.1);

    float sphereSize = 0.7;
    float2 sideSphere1 = normalize(float2(0, 1)) * 1.5;
    float2 sideSphere2 = normalize(float2(0, -1)) * 1.5;
    float2 sideSphere3 = normalize(float2(-1, 0)) * 1.5;
    float2 sideSphere4 = normalize(float2(-1, 1)) * 1.5;
    float2 sideSphere5 = normalize(float2(-1, -1)) * 1.5;
    SphereAnimData animData[ballCount] = {
        {sideSphere1, 2, float2(-4 + (sphereSize + 0.1), -(sphereSize + 0.1)), sphereSize, 0.2, 4},
        {sideSphere2, 2, float2(-4 + (sphereSize + 0.1), -(sphereSize + 0.1)), sphereSize, 0.2, 4},
        {sideSphere3, 2.2, float2(-4 + (sphereSize + 0.1), -(sphereSize + 0.1)), sphereSize, 0.2, 4},//center
        {sideSphere4, 2.4, float2(-4 + (sphereSize + 0.1), -(sphereSize + 0.1)), sphereSize, 0.2, 4},
        {sideSphere5, 2.4, float2(-4 + (sphereSize + 0.1), -(sphereSize + 0.1)), sphereSize, 0.2, 4}
    };
    float distSpheres[ballCount];
    for(int i=0; i < ballCount; i++){
        distSpheres[i] = animatedSphere(animData[i], castPosition);
    }
    combination = opSmoothUnion(distSpheres[0], combination, 0.2);
    for(int i=1; i < ballCount; i++){
        combination = opSmoothUnion(distSpheres[i], combination, 0.2);
    }
    combination = opSmoothUnion((baseBot - 0.05), (combination - 0.05), 0.3) + 0.02;

    float topSphere = toSphere(float3(0,-0.5,0), 2.3, castPosition);

    float innerS = toSphere(float3(0,0,0), 4, castPosition);
    float outerS = toSphere(float3(0,0,0), 4.5, castPosition);

    float weirdS = inoutSphere(castPosition, float3(0,0,0), 4.2, 0.2);

    float lampBase = opSmoothSubtraction(topSphere, combination, 0.1);
    return opSmoothSubtraction(weirdS, lampBase, 0.3);
}

float3 estimateLampBaseNormal(float3 p){
    /*float2 e = float2(1.0,-1.0)*0.5773*0.001;
    return normalize( e.xyy*distanceToLampBase( p + e.xyy ).x + 
					  e.yyx*distanceToLampBase( p + e.yyx ).x + 
					  e.yxy*distanceToLampBase( p + e.yxy ).x + 
					  e.xxx*distanceToLampBase( p + e.xxx ).x );
    *////*
    float EPSILON = 0.0001;
    return normalize(float3(
        distanceToLampBase(float3(p.x + EPSILON, p.y, p.z)) - distanceToLampBase(float3(p.x - EPSILON, p.y, p.z)),
        distanceToLampBase(float3(p.x, p.y + EPSILON, p.z)) - distanceToLampBase(float3(p.x, p.y - EPSILON, p.z)),
        distanceToLampBase(float3(p.x, p.y, p.z  + EPSILON)) - distanceToLampBase(float3(p.x, p.y, p.z - EPSILON))
    ));//*/
}

/*vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}*/

/*
vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
					  e.yyx*map( pos + e.yyx ).x + 
					  e.yxy*map( pos + e.yxy ).x + 
					  e.xxx*map( pos + e.xxx ).x );
*/

float3 estimateCombinedSpheresNormal(float3 checkPos) {
    float2 e = float2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*distanceToInsideLampScene( checkPos + e.xyy ).x + 
					  e.yyx*distanceToInsideLampScene( checkPos + e.yyx ).x + 
					  e.yxy*distanceToInsideLampScene( checkPos + e.yxy ).x + 
					  e.xxx*distanceToInsideLampScene( checkPos + e.xxx ).x );
};

float3 estimateRoundConeNormal(float3 checkPos, float3 bot, float3 top, float r1, float r2){
    float2 e = float2(1.0,-1.0)*0.5773*0.0001;
    return normalize( e.xyy*sdRoundCone( checkPos + e.xyy, bot, top, r1, r2 ).x + 
					  e.yyx*sdRoundCone( checkPos + e.yyx, bot, top, r1, r2 ).x + 
					  e.yxy*sdRoundCone( checkPos + e.yxy, bot, top, r1, r2 ).x + 
					  e.xxx*sdRoundCone( checkPos + e.xxx, bot, top, r1, r2 ).x );
}

inline float Lerp(float from, float to, float rel)
{
    return ((1 - rel) * from) + (rel * to);
}

inline float InvLerp(float from, float to, float value)
{
    return (value - from) / (to - from);
}

inline float Remap(float orig_from, float orig_to, float target_from, float target_to, float value)
{
    float rel = InvLerp(orig_from, orig_to, value);
    return Lerp(target_from, target_to, rel);
}

float calculateLight(float3 normal, float3 position){
    float3 lightPos = float3(-5,-2.5,0);
    float3 posToLight = lightPos - position;
    float distLight = length(posToLight);
    float3 lightDir = normalize(posToLight);
    float normDotDir = dot(normal, -lightDir);
    float lightIntensity = saturate(normDotDir) * saturate(exp(-distLight * 0.5) * 4);
    return lightIntensity;
}

/*float specular(float3 lightDir, float3 normal, float3 viewDir, float specularPower, float specularIntensity){
    // Calculate the reflection vector: 
    float3 R = normalize(2 * dot(normal, -lightDir) * normal + lightDir); 
    // Calculate the speculate component: 
    float s = pow(saturate(dot(R, normalize(viewDir))), specularPower) * specularIntensity;

    return s;
}*/

float backgroundSphere(float3 castPosition){
    float dist = inoutSphere(castPosition, float3(0,0,0), 4.2, 0.2);
    return dist;
}

float3 estimateBackgroundSphereNormal(float3 checkPos){
    float2 e = float2(1.0,-1.0)*0.5773*0.0001;
    return normalize( e.xyy*backgroundSphere( checkPos + e.xyy).x +
					  e.yyx*backgroundSphere( checkPos + e.yyx).x +
					  e.yxy*backgroundSphere( checkPos + e.yxy).x +
					  e.xxx*backgroundSphere( checkPos + e.xxx).x);
}

void renderSDF_float(float3 viewDirectionNorm, float3 startPosition, float3 baseColor, float3 lampSpheresColor, float3 lampInnerColor, float3 lampOuterColor, float3 backgroundColor1, float3 backgroundColor2, out float alpha, out float3 color){
    float prevDistance = 0;
    alpha = 0;
    color = float3(1,0,0);
    float3 normal = float3(0,1,0);
    float minDist = 0.001;
    float minDistBase = 0.005;

    float depth = 1000000000;
    
    //distanceToLampBase
    [loop]
    for(int i = 0; i < 75; i++){
        float3 checkPos = startPosition + viewDirectionNorm * prevDistance;
        float dist = distanceToLampBase(checkPos);
        
        if(abs(dist) <= minDistBase){
            alpha = 1;
            normal = estimateLampBaseNormal(checkPos) ;//+ estimateLampBaseNormal(checkPos+0.001) + estimateLampBaseNormal(checkPos-0.001);    
            float3 lightDir = normalize(float3(0,0.5,1));
            float dotLight = dot(normal, lightDir);

            float spec = specular(lightDir, normal, viewDirectionNorm, 6, 4);
            color = (max(0, spec + dotLight) + 0.1) * baseColor;
            depth = prevDistance;
            break;
        }
        prevDistance += dist;
    }

//    return;

    startPosition = float3(0, sin(_Time.y * 0.5 * 3.14) * 0.7, 0) + startPosition;

    //Render Spheres
    bool sphereRendered = false;
    prevDistance = 0;
    [loop]
    for(int i = 0; i < 50; i++){
        float3 checkPos = startPosition + viewDirectionNorm * prevDistance;
        float dist = distanceToInsideLampScene(checkPos);
        prevDistance += dist;
        if(dist < minDist){
            if(prevDistance < depth){
                alpha = 1;
                normal = estimateCombinedSpheresNormal(checkPos);
                float normDotDir = dot(normal, float3(0,1,0));
                float fresnel = exp(normDotDir*0.25); //pow(max(0, normDotDir), 4);
                color = lerp(float3(1,1,1), lampSpheresColor, fresnel);
                sphereRendered = true;
            }
            break;
        }
    }

    if(!sphereRendered){
        prevDistance = 0;
        
        //InnerCone
        bool innerConeRendered = false;
        [loop]
        for(int i = 0; i < 20; i++){
            float3 castPosition = startPosition + viewDirectionNorm * prevDistance;
            float dist = sdRoundCone(castPosition, float3(0,0,0), float3(0,4,0), 2.1, 1.1);
            prevDistance += dist;
            if(dist < minDist /* && castPosition.y >= 0 */ && prevDistance < depth){
                color = float3(0,1,1);
                alpha = 1;
                float3 normal = estimateRoundConeNormal(castPosition, float3(0,0,0), float3(0,4,0), 2.1, 1.1);
                normal = normal * float3(1,1,1);
                float lightIntensity = calculateLight(-normal, castPosition);
                float fresnel = saturate(pow(dot(normal, -viewDirectionNorm), 1) * 1.8);
                color = lerp(lampInnerColor, 1, lightIntensity);
                color = lerp(color, lampOuterColor, (1 - fresnel));
                innerConeRendered = true;
                break;
            }
        }
    }
    if(alpha < 0.5){
        prevDistance = 0;
        [loop]
        for(int i = 0; i < 50; i++){
            float3 castPosition = startPosition + viewDirectionNorm * prevDistance;
            float size = 7;
            float dist = inoutSphere(castPosition - float3(-3.3, 0, 0), float3(0,0,0), size, 0.2);
            prevDistance += dist;
            if(dist < minDist){
                color = float3(0,1,1);
                alpha = 1;
                float backgroundIterp = saturate(Remap(0.05, 1, 0, 1, length(float2(castPosition.z/size, castPosition.y/size))));
                color = lerp(backgroundColor1, backgroundColor2, backgroundIterp);
                break;
            }
        }
    }
    
}