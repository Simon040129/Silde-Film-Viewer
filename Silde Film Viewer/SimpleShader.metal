#include <metal_stdlib>
using namespace metal;
struct VertexOut { float4 position [[position]]; };
vertex VertexOut simpleVertexShader(uint index [[vertex_id]], constant float4 &transform [[buffer(1)]]) {
    const float2 vertices[] = {float2(-0.5,-0.5), float2(0.5,-0.5), float2(-0.5,0.5),
                              float2(-0.5,0.5), float2(0.5,-0.5), float2(0.5,0.5)};
    VertexOut out;
    out.position = float4(vertices[index] * transform.zw + transform.xy, 0, 1);
    return out;
}
fragment float4 simpleFragmentShader(constant float4 &color [[buffer(2)]]) { return color; }
