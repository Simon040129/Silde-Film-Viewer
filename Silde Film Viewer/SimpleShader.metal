//
//  SimpleShader.metal
//  Silde Film Viewer
//
//  Created by 卫奕铭 on 2025/3/21.
//

#include <metal_stdlib>
using namespace metal;

// 顶点数据结构
struct VertexIn {
    float2 position [[attribute(0)]];
};

// 顶点着色器输出
struct VertexOut {
    float4 position [[position]];
};

// 顶点着色器：将传入坐标变成屏幕坐标
vertex VertexOut simpleVertexShader(VertexIn in [[stage_in]],
                                    constant float2 &offset [[buffer(1)]]) {
    VertexOut out;
    // in.position 范围是NDC( -1~1 ), 需要加上 offset
    // 这里 offset 是你传进来的移动量，用来让矩形随 highlightPosition 移动
    out.position = float4(in.position + offset, 0.0, 1.0);
    return out;
}

// 片元着色器：返回一个超亮白色
fragment float4 simpleFragmentShader() {
    // 值大于1.0 (这里设10.0) 表示EDR高亮
    return float4(10.0, 10.0, 10.0, 1.0);
}
