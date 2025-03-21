#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
};

struct TransformData {
    float2 offset;
    float2 scale;
};

struct VertexOut {
    float4 position [[position]];
};

// 顶点着色器
vertex VertexOut simpleVertexShader(VertexIn vin [[stage_in]],
                                    constant TransformData &td [[buffer(1)]])
{
    VertexOut out;
    
    // vin.position ∈ [-0.5..0.5], 乘以 scale => [-0.5..0.5]*scale = [-scale/2..scale/2]
    float2 scaledPos = vin.position * td.scale;
    // 再加 offset => 最终NDC
    out.position = float4(scaledPos + td.offset, 0.0, 1.0);
    return out;
}

// 片元着色器
fragment float4 simpleFragmentShader() {
    // EDR 高亮
    return float4(10.0, 10.0, 10.0, 1.0);
}
