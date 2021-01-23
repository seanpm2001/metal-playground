#include <metal_stdlib>
using namespace metal;
#include "../ShaderHeaders.h"

struct VertexIn {
    vector_float2 pos;
};

struct FragmentUniforms {
    float time;
    float screen_width;
    float screen_height;
    float screen_scale;
};

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

vertex VertexOut liveCodeVertexShader(const device VertexIn *vertices [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    VertexOut in;
    in.pos = {vertices[vid].pos.x, vertices[vid].pos.y, 0, 1};
    return in;
}

float sdArc( float2 p, float2 sca, float2 scb, float ra, float rb ) {
    p *= float2x2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float4 stemF(float2 uv, float progress) {
    float4 col = 0;
    float4 stemCol = float4(0.8,0.8, 0.6, 1);
    float4 budCol = float4(0.4, 0.4, 0.1, 1);

    float r1 = 1.2;
    float2 arcCenterOffset = {-1.1,-.3};

    uv -= arcCenterOffset;

    float a2Variant = lerp(progress, 0, 1, 0.33, 1);
//    a2Variant = 0.3;
    float a1 = 0.0;
    float a2 = M_PI_F/1.8 * a2Variant;
    uv = rotate(-M_PI_F/2.5) * uv;

    // stem
    float tStem = arc(uv, r1, a1, a2, 0.01);
    col = mix(col, stemCol, tStem);

    // bud
    float circleR = 0.04;
    float tBud = circle(uv-float2(r1*cos(a2), r1*sin(a2)) , circleR);
    col = mix(col, budCol, tBud);

    return col;
}

float4 flower(float2 uv, float yOverX, float progress) {
    uv.x /= yOverX;
    float4 col = 0;
    float4 bg = {0.8, 0.4, 0.51, 1};
    float4 stem = stemF(uv, progress);
    col = mix(bg, stem, stem.a);

    return col;
}

// ----- NOISE experiments

float noiseMove(float2 uv, float time) {
    float x = time * 3;

    // -- multiples
//    uv *= 20;
//    uv = fract(uv);

    float i = floor(x);
    float f = fract(x);
    float t = mix(random(i), random(i+1), smoothstep(0., 1., f));


//    uv.x -= t - 0.0;
//    uv.y -= t - 0.0;

    uv -= 0.5;
    uv = rotate(t) * uv;

    float rs = .2;
    float c = rectangle(uv, {-rs,rs,rs,-rs});

    return c;
}

float noiseCreature(float2 uv, float time) {
    float2 uvN = uv * 10;
    float m = uvN.x;
    float f = fract(m+time/10);
    float i = floor(m);

    float t = mix(random(i), random(i+1), smoothstep(0., 1., f));
    uv.y -= t/10;
    float rec = rectangle(uv-0.5, {-.2,.2,.2,-.2});
    return rec;
}


float noiseSmoothToSharpAnimated(float2 uv, float time) {
    float x = uv.x * 10;
    float i = floor(x);
    float f = fract(x);
    float y = random(i);
    f += 1-fract(time/12);
    y = mix(random(i), random(i+1), f);
    y = mix(random(i), random(i+1), smoothstep(0., 1., f));

    // Draw
    float t = smoothstep(y, y-0.001, uv.y + 0.98);
    return t;
}

// -END- NOISE experiments

fragment float4 liveCodeFragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    float2 uv = {interpolated.pos.x / uniforms.screen_width, 1 - interpolated.pos.y/uniforms.screen_height};
    float2 st = uv;
    st -= 0.5;
    st *= 2;

    float yOverX = uniforms.screen_height / uniforms.screen_width;

    float time = uniforms.time;

    time /= 10;

    float progress = fract(time);

//    float3  color = noiseCreature(uv, time);
    float4 color = flower(st, yOverX, progress);

    return color;
}
