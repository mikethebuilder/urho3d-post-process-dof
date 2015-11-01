#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"

varying vec2 vScreenPos;

float focalDistance = 10;
float focalNearDistance = 10;
float focalFarDistance = 10;

float focalRange = 0.5;

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vScreenPos = GetScreenPosPreDiv(gl_Position);
}

#ifdef COMPILEPS
float Linearize(float depth)
{
	return -cFarClipPS * cNearClipPS / (depth * (cFarClipPS - cNearClipPS) - cFarClipPS);
}

float DepthToAlpha(float depth, float centerDepth) 
{
    float f;
    vec4 vDofParams;
    
    //cNearClipPS 0.1 
    //cFarClipPS 1000
    
    float invFullField = 1.0f / (cFarClipPS - cNearClipPS); // 0.001 
    float focal = invFullField * focalDistance;
        
    // x = near blur depth    
    vDofParams.x = centerDepth - (invFullField * focalNearDistance);
    
    // y = focal plane depth 
    vDofParams.y = centerDepth;
    
    // z = far blur depth
    vDofParams.z = centerDepth + (invFullField * focalFarDistance); 
    
    // w = blurriness cutoff constant for objects behind the focal plane
    vDofParams.w = 1.0;
    
    
    if (depth < vDofParams.y)
    {
        //[-1, 0] range
        f = (depth - vDofParams.y) / (vDofParams.y - vDofParams.x);
    }
    else 
    {
        f = (depth - vDofParams.y) / (vDofParams.z - vDofParams.x);
        f = clamp(f, 0, vDofParams.w);
    }
    
    //f = clamp(abs(-depth - focalDistance) / focalRange, 0.0, 1.0);
 
    return f * 0.5f + 0.5f;
}

void PS()
{
    float depth = ReconstructDepth(texture2D(sNormalMap, vScreenPos).r);
    float centerDepth = ReconstructDepth(texture2D(sNormalMap, vec2(0.5, 0.5)).r);
    
    float a = DepthToAlpha(depth, centerDepth);
    vec4 color = texture2D(sDiffMap, vScreenPos);
    gl_FragColor = vec4(vec3(color.xyz), a);
}
#endif
