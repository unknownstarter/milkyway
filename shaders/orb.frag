#version 460 core
#include <flutter/runtime_effect.glsl>

// 진화 은하 오브. 밤하늘 유리구 안에 은하가 돌고(회전 레이어),
// 유리 반사/프레넬 림은 광원 고정, 바깥은 부드러운 안개.
// 설계: docs/design/06-ORB_RENDERING.md · 프로토타입: marketing/orb_shader_preview.html
precision highp float;

uniform vec2 uSize;    // 위젯 픽셀 크기
uniform float uTime;   // 회전/트윙클(초, 래핑됨)
uniform float uGlow;   // 0..1 안개/글로우 호흡
uniform vec3 uTier;    // 티어 액센트색
uniform vec3 uCore;    // 코어색
uniform float uArms;   // 나선팔 수(0=성운, 2~4)
uniform float uDensity;// 별/성운 밀도
uniform float uSeed;   // 티어별 변주

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p), f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash21(i);
  float b = hash21(i + vec2(1.0, 0.0));
  float c = hash21(i + vec2(0.0, 1.0));
  float d = hash21(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
  float v = 0.0, a = 0.5;
  for (int i = 0; i < 5; i++) {
    v += a * noise(p);
    p *= 2.0;
    a *= 0.5;
  }
  return v;
}

mat2 rot(float a) {
  float s = sin(a), c = cos(a);
  return mat2(c, -s, s, c);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  // 중심화. WebGL은 y가 위, Flutter는 아래 -> y 뒤집어 프로토타입과 광원 방향 일치.
  // 0.84로 나눠 오브를 정사각 캔버스보다 작게 -> 안개/글로우가 박스 모서리에
  // 닿기 전에 사라질 여백 확보(희미한 보라 사각형 seam 방지).
  vec2 p = (uv - 0.5) * 2.0 / 0.84;
  p.y = -p.y;
  float r = length(p);

  vec3 col = vec3(0.0);
  float alpha = 0.0;

  // 안개(구 바깥으로 번지는 방사형 haze)
  float fog = exp(-max(r - 0.6, 0.0) * 3.0) * (0.10 + 0.12 * uGlow);
  col += uTier * fog;
  alpha = max(alpha, fog * 1.5);

  if (r < 1.0) {
    float z = sqrt(max(1.0 - r * r, 0.0));
    vec3 N = vec3(p, z);

    // 회전 은하
    float rotAng = uTime * 0.26 + uSeed;
    vec2 g = rot(rotAng) * p;
    float ang = atan(g.y, g.x);
    float rad = r;

    vec2 nu = g * (1.6 + uDensity * 0.4);
    float neb = pow(fbm(nu + uSeed * 7.0), 1.6);

    float arms = 0.0;
    if (uArms > 0.5) {
      arms = 0.5 + 0.5 * cos(ang * uArms + rad * 6.0);
      arms = pow(arms, 2.2) * (1.0 - rad * 0.35) * smoothstep(0.10, 0.55, rad);
    }

    float core = smoothstep(0.24, 0.0, rad);

    vec3 galaxy = mix(vec3(0.02, 0.015, 0.04), uTier, neb * 0.6);
    galaxy += uTier * arms * 0.38;
    galaxy += uCore * core * 0.45;

    float grid = 90.0 + uDensity * 60.0;
    float star = hash21(floor(g * grid) + uSeed);
    float starOn = step(0.987 - uDensity * 0.005, star);
    float twk = 0.6 + 0.4 * sin(uTime * 2.0 + star * 30.0);
    galaxy += vec3(1.0) * starOn * twk * (0.4 + 0.5 * (1.0 - rad));

    galaxy *= mix(1.0, 0.28, smoothstep(0.35, 1.0, rad)); // 3D 깊이(가장자리 어둠)
    galaxy *= 0.92;

    // 유리(고정 광원)
    vec3 L = normalize(vec3(-0.42, 0.5, 0.82));
    vec3 V = vec3(0.0, 0.0, 1.0);
    float fres = pow(1.0 - z, 3.2);
    vec3 H = normalize(L + V);
    float nh = max(dot(N, H), 0.0);
    float specSharp = pow(nh, 60.0);
    float specSoft = pow(nh, 6.0);

    vec3 glass = vec3(0.0);
    glass += vec3(0.85, 0.9, 1.0) * (specSharp * 1.0 + specSoft * 0.14);
    glass += uTier * fres * 0.42;
    // 유리구 반사(좌상단 소프트 오벌 하이라이트)
    float hl = smoothstep(0.40, 0.0, length((p - vec2(-0.33, 0.42)) * vec2(1.0, 1.35)));
    glass += vec3(0.95, 0.97, 1.0) * hl * hl * 0.55;
    // 하단-우측 은은한 반대편 반사
    float hl2 = smoothstep(0.5, 0.0, length((p - vec2(0.3, -0.42)) * vec2(1.0, 1.2)));
    glass += uTier * hl2 * 0.12;

    vec3 orb = galaxy + glass;
    float edge = smoothstep(1.0, 0.984, r);
    col = mix(col, orb, edge);
    alpha = max(alpha, edge);
  }

  // 박스 경계 전에 색/알파를 완전히 0으로 -> 캔버스 사각형 seam 제거.
  // 오브(r<=1.0)와 그 바깥 얇은 글로우 링만 남기고 나머지는 투명.
  float vign = 1.0 - smoothstep(1.0, 1.17, r);
  col *= vign;
  alpha *= vign;

  fragColor = vec4(col, clamp(alpha, 0.0, 1.0));
}
