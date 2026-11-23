unit Tulip.FluentMotion.Effect.Shader;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  System.Math,
  System.Generics.Collections,
  System.Diagnostics,
  System.Skia,
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  FMX.Graphics,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Uniform Value Storage }
  TShaderUniformKind = (sukSingle, sukPointF, sukColor, sukSingleArray);

  TShaderUniform = record
    Kind: TShaderUniformKind;
    SingleVal: Single;
    PointVal: TPointF;
    ColorVal: TAlphaColor;
    SingleArrayVal: TArray<Single>;
    class function MakeSingle(const AVal: Single): TShaderUniform; static;
    class function MakePointF(const AVal: TPointF): TShaderUniform; static;
    class function MakeColor(const AVal: TAlphaColor): TShaderUniform; static;
    class function MakeSingleArray(const AVal: TArray<Single>): TShaderUniform; static;
  end;

  { Base SkSL Runtime Shader Effect }
  TFluentShaderEffect = class(TFluentMotionEffectBase, ISkiaPaintEffect)
  private
    class var FEffectCache: TDictionary<string, ISkRuntimeEffect>;
    class var FGlobalClock: TStopwatch;
    class constructor CreateClass;
    class destructor DestroyClass;
  protected
    FSkSL: string;
    FEffect: ISkRuntimeEffect;
    FUniforms: TDictionary<string, TShaderUniform>;
    FDrawMode: TShaderDrawMode;
    FCompileError: string;

    function GetOrCreateEffect(const ASkSL: string): ISkRuntimeEffect;
    procedure ApplyUniforms(const ABuilder: ISkRuntimeShaderBuilder; const ARect: TRectF; const AOpacity: Single); virtual;
    function ExtractCornerRadius: Single;
    procedure DoAttach; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
  public
    constructor Create(const ASkSL: string; const ADurationMs: Cardinal = 1000; const ADrawMode: TShaderDrawMode = TShaderDrawMode.Overlay); reintroduce; virtual;
    destructor Destroy; override;

    { Uniform Configuration }
    function SetUniform(const AName: string; const AValue: Single): TFluentShaderEffect; overload;
    function SetUniform(const AName: string; const AValue: TPointF): TFluentShaderEffect; overload;
    function SetUniform(const AName: string; const AValue: TAlphaColor): TFluentShaderEffect; overload;
    function SetUniform(const AName: string; const AValue: TArray<Single>): TFluentShaderEffect; overload;

    { DrawMode Configuration }
    function SetDrawMode(const ADrawMode: TShaderDrawMode): TFluentShaderEffect;

    { ISkiaPaintEffect Implementation }
    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single); virtual;
    procedure PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single); virtual;
    function NeedsRepaint: Boolean; virtual;

    function Clone: IMotionEffect; override;

    property SkSL: string read FSkSL;
    property DrawMode: TShaderDrawMode read FDrawMode write FDrawMode;
    property CompileError: string read FCompileError;
  end;

  { Preset 1: Border Beam (Laser runner along control border) }
  TFluentBorderBeamEffect = class(TFluentShaderEffect)
  private
    const BORDER_BEAM_SKSL =
      'uniform vec2 iResolution;' + sLineBreak +
      'uniform float iTime;' + sLineBreak +
      'uniform float iCornerRadius;' + sLineBreak +
      'uniform float uBorderWidth;' + sLineBreak +
      'uniform float uBeamLength;' + sLineBreak +
      'uniform vec4 uColorFrom;' + sLineBreak +
      'uniform vec4 uColorTo;' + sLineBreak +
      'float roundedBoxSDF(vec2 p, vec2 b, float r) {' + sLineBreak +
      '    vec2 q = abs(p) - b + r;' + sLineBreak +
      '    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;' + sLineBreak +
      '}' + sLineBreak +
      'half4 main(vec2 fragCoord) {' + sLineBreak +
      '    vec2 halfRes = iResolution * 0.5;' + sLineBreak +
      '    vec2 p = fragCoord - halfRes;' + sLineBreak +
      '    float r = min(iCornerRadius, min(halfRes.x, halfRes.y));' + sLineBreak +
      '    float d = roundedBoxSDF(p, halfRes, r);' + sLineBreak +
      '    float stroke = 1.0 - smoothstep(0.0, 1.5, abs(d + uBorderWidth * 0.5) - uBorderWidth * 0.5);' + sLineBreak +
      '    if (stroke <= 0.0) return half4(0.0);' + sLineBreak +
      '    float angle = (atan(p.y, p.x) / 6.2831853) + 0.5;' + sLineBreak +
      '    float beamPos = fract(iTime * 0.5);' + sLineBreak +
      '    float dist = fract(angle - beamPos);' + sLineBreak +
      '    float intensity = smoothstep(1.0 - uBeamLength, 1.0, 1.0 - dist);' + sLineBreak +
      '    vec4 col = mix(uColorFrom, uColorTo, dist / max(0.001, uBeamLength));' + sLineBreak +
      '    return half4(col.rgb * col.a * intensity * stroke, col.a * intensity * stroke);' + sLineBreak +
      '}';
  public
    constructor Create(const AColorFrom, AColorTo: TAlphaColor; const ABorderWidth: Single = 3.0; const ABeamLength: Single = 0.25; const ADurationMs: Cardinal = 2000); reintroduce;
  end;

  { Preset 2: Liquid Wave (Dynamic fluid level fill) }
  TFluentLiquidWaveEffect = class(TFluentShaderEffect)
  private
    const LIQUID_WAVE_SKSL =
      'uniform vec2 iResolution;' + sLineBreak +
      'uniform float iTime;' + sLineBreak +
      'uniform float iProgress;' + sLineBreak +
      'uniform float uFromLevel;' + sLineBreak +
      'uniform float uToLevel;' + sLineBreak +
      'uniform vec4 uColor;' + sLineBreak +
      'uniform vec4 uCrestColor;' + sLineBreak +
      'half4 main(vec2 fragCoord) {' + sLineBreak +
      '    vec2 uv = fragCoord / iResolution;' + sLineBreak +
      '    float currentLevel = mix(uFromLevel, uToLevel, iProgress);' + sLineBreak +
      '    float yTarget = 1.0 - currentLevel;' + sLineBreak +
      '    float wave1 = sin(uv.x * 12.0 + iTime * 4.0) * 0.025;' + sLineBreak +
      '    float wave2 = cos(uv.x * 8.0 - iTime * 2.5) * 0.015;' + sLineBreak +
      '    float waveY = yTarget + wave1 + wave2;' + sLineBreak +
      '    if (uv.y < waveY) return half4(0.0);' + sLineBreak +
      '    float crestDist = abs(uv.y - waveY);' + sLineBreak +
      '    float crest = smoothstep(0.02, 0.0, crestDist);' + sLineBreak +
      '    vec4 col = mix(uColor, uCrestColor, crest);' + sLineBreak +
      '    return half4(col.rgb * col.a, col.a);' + sLineBreak +
      '}';
  private
    class var FControlLevels: TDictionary<TControl, Single>;
    class constructor CreateClass;
    class destructor DestroyClass;
  protected
    FFromLevel: Single;
    FToLevel: Single;
    FCurrentLevel: Single;
    FExplicitFrom: Boolean;
    procedure DoAttach; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure ApplyUniforms(const ABuilder: ISkRuntimeShaderBuilder; const ARect: TRectF; const AOpacity: Single); override;
  public
    constructor Create(const ATargetLevel: Single; const AColor: TAlphaColor = $CC007ACC; const ACrestColor: TAlphaColor = $FFFFFFFF; const ADurationMs: Cardinal = 1000); reintroduce; overload;
    constructor Create(const AFromLevel, ATargetLevel: Single; const AColor: TAlphaColor = $CC007ACC; const ACrestColor: TAlphaColor = $FFFFFFFF; const ADurationMs: Cardinal = 1000); reintroduce; overload;
    function Clone: IMotionEffect; override;
    function NeedsRepaint: Boolean; override;
    class function GetCurrentLevel(const AControl: TControl): Single; static;
  end;

  { Preset 3: Frosted Glass (Reflective acrylic material) }
  TFluentFrostedGlassEffect = class(TFluentShaderEffect)
  private
    FTintColor: TAlphaColor;
    FBorderLight: Single;
    const FROSTED_GLASS_SKSL =
      'uniform vec2 iResolution;' + sLineBreak +
      'uniform float iTime;' + sLineBreak +
      'uniform vec4 uTint;' + sLineBreak +
      'uniform float uBorderLight;' + sLineBreak +
      'half4 main(vec2 fragCoord) {' + sLineBreak +
      '    vec2 uv = fragCoord / iResolution;' + sLineBreak +
      '    float edge = smoothstep(0.05, 0.0, uv.x) + smoothstep(0.05, 0.0, uv.y);' + sLineBreak +
      '    float light = clamp(edge * uBorderLight, 0.0, 1.0);' + sLineBreak +
      '    vec4 col = uTint;' + sLineBreak +
      '    col.rgb += light * 0.25;' + sLineBreak +
      '    col.a = clamp(col.a + light * 0.15, 0.0, 1.0);' + sLineBreak +
      '    return half4(col.rgb * col.a, col.a);' + sLineBreak +
      '}';
  public
    constructor Create(const ATintColor: TAlphaColor = $40FFFFFF; const ABorderLight: Single = 0.8; const ADurationMs: Cardinal = 500); reintroduce;
    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single); override;
  end;

  { Preset 4: Mesh Gradient (Ambient animated aurora background) }
  TFluentMeshGradientEffect = class(TFluentShaderEffect)
  private
    const MESH_GRADIENT_SKSL =
      'uniform vec2 iResolution;' + sLineBreak +
      'uniform float iTime;' + sLineBreak +
      'uniform vec4 uColor1;' + sLineBreak +
      'uniform vec4 uColor2;' + sLineBreak +
      'uniform vec4 uColor3;' + sLineBreak +
      'uniform vec4 uColor4;' + sLineBreak +
      'half4 main(vec2 fragCoord) {' + sLineBreak +
      '    vec2 uv = fragCoord / iResolution;' + sLineBreak +
      '    vec2 p1 = vec2(0.2 + 0.15 * sin(iTime * 0.8), 0.2 + 0.15 * cos(iTime * 0.6));' + sLineBreak +
      '    vec2 p2 = vec2(0.8 + 0.12 * cos(iTime * 0.7), 0.25 + 0.18 * sin(iTime * 0.9));' + sLineBreak +
      '    vec2 p3 = vec2(0.25 + 0.18 * cos(iTime * 0.5), 0.8 + 0.12 * sin(iTime * 0.7));' + sLineBreak +
      '    vec2 p4 = vec2(0.75 + 0.14 * sin(iTime * 0.6), 0.75 + 0.14 * cos(iTime * 0.8));' + sLineBreak +
      '    float d1 = 1.0 / (distance(uv, p1) + 0.001);' + sLineBreak +
      '    float d2 = 1.0 / (distance(uv, p2) + 0.001);' + sLineBreak +
      '    float d3 = 1.0 / (distance(uv, p3) + 0.001);' + sLineBreak +
      '    float d4 = 1.0 / (distance(uv, p4) + 0.001);' + sLineBreak +
      '    float total = d1 + d2 + d3 + d4;' + sLineBreak +
      '    vec4 col = (uColor1 * d1 + uColor2 * d2 + uColor3 * d3 + uColor4 * d4) / total;' + sLineBreak +
      '    return half4(col.rgb * col.a, col.a);' + sLineBreak +
      '}';
  public
    constructor Create(const AColor1, AColor2, AColor3, AColor4: TAlphaColor; const ADurationMs: Cardinal = 3000); reintroduce;
  end;

  { Preset 5: Dissolve Burn (Noise-driven burn & ember dissolution) }
  TFluentDissolveBurnEffect = class(TFluentShaderEffect)
  private
    const DISSOLVE_BURN_SKSL =
      'uniform vec2 iResolution;' + sLineBreak +
      'uniform float iTime;' + sLineBreak +
      'uniform float iProgress;' + sLineBreak +
      'uniform vec4 uEmberColor;' + sLineBreak +
      'uniform float uNoiseScale;' + sLineBreak +
      'uniform float uEmberWidth;' + sLineBreak +
      'float hash(vec2 p) {' + sLineBreak +
      '    p = fract(p * vec2(123.34, 456.21));' + sLineBreak +
      '    p += dot(p, p + 45.32);' + sLineBreak +
      '    return fract(p.x * p.y);' + sLineBreak +
      '}' + sLineBreak +
      'float noise(vec2 p) {' + sLineBreak +
      '    vec2 i = floor(p);' + sLineBreak +
      '    vec2 f = fract(p);' + sLineBreak +
      '    f = f * f * (3.0 - 2.0 * f);' + sLineBreak +
      '    float a = hash(i);' + sLineBreak +
      '    float b = hash(i + vec2(1.0, 0.0));' + sLineBreak +
      '    float c = hash(i + vec2(0.0, 1.0));' + sLineBreak +
      '    float d = hash(i + vec2(1.0, 1.0));' + sLineBreak +
      '    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);' + sLineBreak +
      '}' + sLineBreak +
      'half4 main(vec2 fragCoord) {' + sLineBreak +
      '    vec2 uv = fragCoord / iResolution;' + sLineBreak +
      '    float n = noise(uv * uNoiseScale) * 0.7 + noise(uv * uNoiseScale * 2.0) * 0.3;' + sLineBreak +
      '    float threshold = iProgress;' + sLineBreak +
      '    if (n < threshold) {' + sLineBreak +
      '        float diff = threshold - n;' + sLineBreak +
      '        if (diff < uEmberWidth) {' + sLineBreak +
      '            float intensity = 1.0 - (diff / max(0.001, uEmberWidth));' + sLineBreak +
      '            vec4 col = uEmberColor;' + sLineBreak +
      '            col.rgb += intensity * 0.5;' + sLineBreak +
      '            return half4(col.rgb * col.a * intensity, col.a * intensity);' + sLineBreak +
      '        }' + sLineBreak +
      '        return half4(0.0);' + sLineBreak +
      '    }' + sLineBreak +
      '    return half4(0.0);' + sLineBreak +
      '}';
  public
    constructor Create(const AEmberColor: TAlphaColor = $FFFF4500; const AEmberWidth: Single = 0.08; const ANoiseScale: Single = 8.0; const ADurationMs: Cardinal = 1500); reintroduce;
  end;

  { Preset 6: Ripple Distortion (Refractive outward expanding water wave) }
  TFluentRippleDistortionEffect = class(TFluentShaderEffect)
  private
    const RIPPLE_DISTORTION_SKSL =
      'uniform vec2 iResolution;' + sLineBreak +
      'uniform float iTime;' + sLineBreak +
      'uniform float iProgress;' + sLineBreak +
      'uniform vec2 uCenter;' + sLineBreak +
      'uniform float uWaveWidth;' + sLineBreak +
      'uniform vec4 uRippleColor;' + sLineBreak +
      'half4 main(vec2 fragCoord) {' + sLineBreak +
      '    vec2 p = fragCoord - uCenter;' + sLineBreak +
      '    float dist = length(p);' + sLineBreak +
      '    float maxDist = length(iResolution);' + sLineBreak +
      '    float currentRadius = iProgress * maxDist * 0.75;' + sLineBreak +
      '    float waveDist = abs(dist - currentRadius);' + sLineBreak +
      '    if (waveDist > uWaveWidth) return half4(0.0);' + sLineBreak +
      '    float factor = cos((waveDist / max(0.001, uWaveWidth)) * 3.1415926 * 0.5);' + sLineBreak +
      '    factor = clamp(factor, 0.0, 1.0);' + sLineBreak +
      '    float fade = 1.0 - iProgress;' + sLineBreak +
      '    float alpha = factor * fade;' + sLineBreak +
      '    vec4 col = uRippleColor;' + sLineBreak +
      '    return half4(col.rgb * col.a * alpha, col.a * alpha);' + sLineBreak +
      '}';
  protected
    procedure ApplyUniforms(const ABuilder: ISkRuntimeShaderBuilder; const ARect: TRectF; const AOpacity: Single); override;
  public
    constructor Create(const ARippleColor: TAlphaColor = $8000BFFF; const AWaveWidth: Single = 24.0; const ADurationMs: Cardinal = 600); reintroduce;
  end;

  { Preset 7: Neon Glow (Pulsing multi-layer SDF neon aura) }
  TFluentNeonGlowEffect = class(TFluentShaderEffect)
  private
    const NEON_GLOW_SKSL =
      'uniform vec2 iResolution;' + sLineBreak +
      'uniform float iTime;' + sLineBreak +
      'uniform float iCornerRadius;' + sLineBreak +
      'uniform vec4 uGlowColor;' + sLineBreak +
      'uniform float uGlowRadius;' + sLineBreak +
      'uniform float uPulseSpeed;' + sLineBreak +
      'float roundedBoxSDF(vec2 p, vec2 b, float r) {' + sLineBreak +
      '    vec2 q = abs(p) - b + r;' + sLineBreak +
      '    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;' + sLineBreak +
      '}' + sLineBreak +
      'half4 main(vec2 fragCoord) {' + sLineBreak +
      '    vec2 halfRes = iResolution * 0.5;' + sLineBreak +
      '    vec2 p = fragCoord - halfRes;' + sLineBreak +
      '    float r = min(iCornerRadius, min(halfRes.x, halfRes.y));' + sLineBreak +
      '    float d = roundedBoxSDF(p, halfRes, r);' + sLineBreak +
      '    float pulse = 0.85 + 0.15 * sin(iTime * uPulseSpeed);' + sLineBreak +
      '    float glow = exp(-max(0.0, abs(d)) / max(0.001, uGlowRadius * pulse));' + sLineBreak +
      '    float inner = smoothstep(1.0, -1.0, d);' + sLineBreak +
      '    glow = mix(glow, 1.0, inner * 0.5);' + sLineBreak +
      '    vec4 col = uGlowColor;' + sLineBreak +
      '    return half4(col.rgb * col.a * glow, col.a * glow);' + sLineBreak +
      '}';
  public
    constructor Create(const AGlowColor: TAlphaColor = $FF00FFCC; const AGlowRadius: Single = 16.0; const APulseSpeed: Single = 4.0; const ADurationMs: Cardinal = 1500); reintroduce;
  end;

  { Preset 8: Gooey Metaball (Dynamic fusing organic fluid blobs) }
  TFluentGooeyMetaballEffect = class(TFluentShaderEffect)
  private
    const GOOEY_METABALL_SKSL =
      'uniform vec2 iResolution;' + sLineBreak +
      'uniform float iTime;' + sLineBreak +
      'uniform vec4 uBlobColor;' + sLineBreak +
      'uniform float uSpeed;' + sLineBreak +
      'half4 main(vec2 fragCoord) {' + sLineBreak +
      '    vec2 uv = fragCoord / iResolution;' + sLineBreak +
      '    vec2 b1 = vec2(0.5 + 0.25 * sin(iTime * uSpeed), 0.5 + 0.2 * cos(iTime * uSpeed * 1.2));' + sLineBreak +
      '    vec2 b2 = vec2(0.5 + 0.2 * cos(iTime * uSpeed * 0.8), 0.5 + 0.25 * sin(iTime * uSpeed * 1.1));' + sLineBreak +
      '    vec2 b3 = vec2(0.5 + 0.22 * sin(iTime * uSpeed * 1.4 + 1.5), 0.5 + 0.18 * cos(iTime * uSpeed * 0.9));' + sLineBreak +
      '    float f1 = 0.04 / (distance(uv, b1) + 0.0001);' + sLineBreak +
      '    float f2 = 0.04 / (distance(uv, b2) + 0.0001);' + sLineBreak +
      '    float f3 = 0.035 / (distance(uv, b3) + 0.0001);' + sLineBreak +
      '    float sum = f1 + f2 + f3;' + sLineBreak +
      '    float blobAlpha = smoothstep(0.48, 0.52, sum);' + sLineBreak +
      '    if (blobAlpha <= 0.0) return half4(0.0);' + sLineBreak +
      '    vec4 col = uBlobColor;' + sLineBreak +
      '    return half4(col.rgb * col.a * blobAlpha, col.a * blobAlpha);' + sLineBreak +
      '}';
  public
    constructor Create(const ABlobColor: TAlphaColor = $DDFF007F; const ASpeed: Single = 2.0; const ADurationMs: Cardinal = 3000); reintroduce;
  end;

  { Preset 9: Liquid Glass (macOS / Dynamic Island optics: Back-surface Refraction, Gaussian Blur & Chromatic Aberration) }
  TFluentLiquidGlassEffect = class(TFluentShaderEffect)
  private
    FBlurRadius: Single;
    FGlowIntensity: Single;
    const LIQUID_GLASS_SKSL =
      'const float GLOW_SPREAD = 0.1;' + sLineBreak +
      'const vec3  GLOW_COLOR = vec3(0.0, 0.0, 0.0);' + sLineBreak +
      'uniform shader image;' + sLineBreak +
      'uniform float time;' + sLineBreak +
      'uniform vec2 resolution;' + sLineBreak +
      'uniform vec2 u_offset;' + sLineBreak +
      'uniform vec2 u_mouse;' + sLineBreak +
      'uniform float iCornerRadius;' + sLineBreak +
      'uniform float uRefrMagnitude;' + sLineBreak +
      'uniform float uAberration;' + sLineBreak +
      'uniform float uBlurRadius;' + sLineBreak +
      'uniform float uGlowIntensity;' + sLineBreak +
      'float sdRoundedBox(vec2 p, vec2 b, float r) {' + sLineBreak +
      '  vec2 d = abs(p) - b;' + sLineBreak +
      '  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;' + sLineBreak +
      '}' + sLineBreak +
      'vec3 sampleFrostedGlass(vec2 centerCoord, float blurRadius) {' + sLineBreak +
      '  vec3 acc = vec3(0.0);' + sLineBreak +
      '  float totalWeight = 0.0;' + sLineBreak +
      '  for(float x = -2.0; x <= 2.0; x += 1.0) {' + sLineBreak +
      '    for(float y = -2.0; y <= 2.0; y += 1.0) {' + sLineBreak +
      '      vec2 offset = vec2(x, y) * (blurRadius * 0.5);' + sLineBreak +
      '      float w = exp(-(x*x + y*y) * 0.25);' + sLineBreak +
      '      acc += image.eval(centerCoord + offset).rgb * w;' + sLineBreak +
      '      totalWeight += w;' + sLineBreak +
      '    }' + sLineBreak +
      '  }' + sLineBreak +
      '  return acc / totalWeight;' + sLineBreak +
      '}' + sLineBreak +
      'vec4 main(vec2 coord) {' + sLineBreak +
      '  vec2 halfRes = resolution * 0.5;' + sLineBreak +
      '  vec2 p = coord - halfRes;' + sLineBreak +
      '  float r = min(iCornerRadius, min(halfRes.x, halfRes.y));' + sLineBreak +
      '  float d = sdRoundedBox(p, halfRes, r);' + sLineBreak +
      '  vec2 globalCoord = coord + u_offset;' + sLineBreak +
      '  vec4 bg = image.eval(globalCoord);' + sLineBreak +
      '  float aa = smoothstep(-1.2, 1.2, d);' + sLineBreak +
      '  if (d > 0.0) {' + sLineBreak +
      '    float glowMask = exp(-d * GLOW_SPREAD) * smoothstep(20.0, 0.0, d) * uGlowIntensity;' + sLineBreak +
      '    vec3 glowingBg = mix(bg.rgb, GLOW_COLOR, glowMask);' + sLineBreak +
      '    return mix(bg, vec4(glowingBg, bg.a), 1.0 - aa);' + sLineBreak +
      '  }' + sLineBreak +
      '  vec2 center = halfRes;' + sLineBreak +
      '  vec2 toCenter = normalize((globalCoord - u_offset) - center + vec2(0.0001));' + sLineBreak +
      '  float maxEdgeDist = min(halfRes.x, halfRes.y);' + sLineBreak +
      '  float interiorDepth = -d;' + sLineBreak +
      '  float normalizedDist = clamp(interiorDepth / max(1.0, maxEdgeDist), 0.0, 1.0);' + sLineBreak +
      '  float smoothLens = smoothstep(0.0, 1.0, normalizedDist);' + sLineBreak +
      '  vec2 offset = toCenter * uRefrMagnitude * (1.0 - smoothLens);' + sLineBreak +
      '  vec2 coordR = globalCoord + offset * (1.0 + uAberration);' + sLineBreak +
      '  vec2 coordG = globalCoord + offset;' + sLineBreak +
      '  vec2 coordB = globalCoord + offset * (1.0 - uAberration);' + sLineBreak +
      '  float rChan = sampleFrostedGlass(coordR, uBlurRadius).r;' + sLineBreak +
      '  float gChan = sampleFrostedGlass(coordG, uBlurRadius).g;' + sLineBreak +
      '  float bChan = sampleFrostedGlass(coordB, uBlurRadius).b;' + sLineBreak +
      '  vec3 glassColor = vec3(rChan, gChan, bChan);' + sLineBreak +
      '  glassColor = mix(glassColor, vec3(1.0), (1.0 - smoothstep(0.0, 4.0, interiorDepth)) * 0.35);' + sLineBreak +
      '  return mix(vec4(glassColor, 1.0), bg, aa);' + sLineBreak +
      '}';
  public
    constructor Create(const AStyle: TFluentGlassStyle; const ADurationMs: Cardinal = 2000); reintroduce; overload;
    constructor Create(const ARefrMagnitude: Single = 14.0; const AAberration: Single = 0.08; const ABlurRadius: Single = 0.8; const AGlowIntensity: Single = 0.40; const ADurationMs: Cardinal = 2000); reintroduce; overload;
    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single); override;
  end;

implementation

{ TShaderUniform }

class function TShaderUniform.MakeSingle(const AVal: Single): TShaderUniform;
begin
  Result.Kind := TShaderUniformKind.sukSingle;
  Result.SingleVal := AVal;
  Result.PointVal := PointF(0, 0);
  Result.ColorVal := 0;
  Result.SingleArrayVal := nil;
end;

class function TShaderUniform.MakePointF(const AVal: TPointF): TShaderUniform;
begin
  Result.Kind := TShaderUniformKind.sukPointF;
  Result.SingleVal := 0;
  Result.PointVal := AVal;
  Result.ColorVal := 0;
  Result.SingleArrayVal := nil;
end;

class function TShaderUniform.MakeColor(const AVal: TAlphaColor): TShaderUniform;
begin
  Result.Kind := TShaderUniformKind.sukColor;
  Result.SingleVal := 0;
  Result.PointVal := PointF(0, 0);
  Result.ColorVal := AVal;
  Result.SingleArrayVal := nil;
end;

class function TShaderUniform.MakeSingleArray(const AVal: TArray<Single>): TShaderUniform;
begin
  Result.Kind := TShaderUniformKind.sukSingleArray;
  Result.SingleVal := 0;
  Result.PointVal := PointF(0, 0);
  Result.ColorVal := 0;
  Result.SingleArrayVal := AVal;
end;

{ TFluentShaderEffect }

class constructor TFluentShaderEffect.CreateClass;
begin
  FEffectCache := TDictionary<string, ISkRuntimeEffect>.Create;
  FGlobalClock := TStopwatch.StartNew;
end;

class destructor TFluentShaderEffect.DestroyClass;
begin
  FreeAndNil(FEffectCache);
end;

constructor TFluentShaderEffect.Create(const ASkSL: string; const ADurationMs: Cardinal; const ADrawMode: TShaderDrawMode);
begin
  inherited Create(ADurationMs);
  FSkSL := ASkSL;
  FDrawMode := ADrawMode;
  FUniforms := TDictionary<string, TShaderUniform>.Create;
  FCompileError := '';
  FEffect := GetOrCreateEffect(FSkSL);
end;

destructor TFluentShaderEffect.Destroy;
begin
  FreeAndNil(FUniforms);
  FEffect := nil;
  inherited Destroy;
end;

function TFluentShaderEffect.GetOrCreateEffect(const ASkSL: string): ISkRuntimeEffect;
var
  ErrText: string;
begin
  Result := nil;
  if ASkSL = '' then
    Exit;

  if FEffectCache.TryGetValue(ASkSL, Result) then
    Exit;

  Result := TSkRuntimeEffect.MakeForShader(ASkSL, ErrText);
  if Assigned(Result) then
    FEffectCache.Add(ASkSL, Result)
  else
    FCompileError := ErrText;
end;

procedure TFluentShaderEffect.DoAttach;
begin
  inherited DoAttach;
  // If effect has background mode, notify companion driver control to send to back
  if (FDrawMode = TShaderDrawMode.Background) and Assigned(FControl) then
  begin
    // Driver companion control will position itself appropriately
  end;
end;

procedure TFluentShaderEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  // Shader state evolves over time and progress during Paint
end;

function TFluentShaderEffect.SetUniform(const AName: string; const AValue: Single): TFluentShaderEffect;
begin
  FUniforms.AddOrSetValue(AName, TShaderUniform.MakeSingle(AValue));
  Result := Self;
end;

function TFluentShaderEffect.SetUniform(const AName: string; const AValue: TPointF): TFluentShaderEffect;
begin
  FUniforms.AddOrSetValue(AName, TShaderUniform.MakePointF(AValue));
  Result := Self;
end;

function TFluentShaderEffect.SetUniform(const AName: string; const AValue: TAlphaColor): TFluentShaderEffect;
begin
  FUniforms.AddOrSetValue(AName, TShaderUniform.MakeColor(AValue));
  Result := Self;
end;

function TFluentShaderEffect.SetUniform(const AName: string; const AValue: TArray<Single>): TFluentShaderEffect;
begin
  FUniforms.AddOrSetValue(AName, TShaderUniform.MakeSingleArray(AValue));
  Result := Self;
end;

function TFluentShaderEffect.SetDrawMode(const ADrawMode: TShaderDrawMode): TFluentShaderEffect;
begin
  FDrawMode := ADrawMode;
  Result := Self;
end;

function TFluentShaderEffect.ExtractCornerRadius: Single;
begin
  Result := 0.0;
  if not Assigned(FControl) then
    Exit;

  if FControl is TRectangle then
    Result := Max(TRectangle(FControl).XRadius, TRectangle(FControl).YRadius)
  else if FControl is TCircle then
    Result := Min(FControl.Width, FControl.Height) * 0.5;
end;

procedure TFluentShaderEffect.ApplyUniforms(const ABuilder: ISkRuntimeShaderBuilder; const ARect: TRectF; const AOpacity: Single);
var
  Pair: TPair<string, TShaderUniform>;
begin
  if not Assigned(ABuilder) then
    Exit;

  // 1. Standard Auto-Injected Uniforms (both naming conventions)
  if FEffect.IndexOfUniform('iResolution') >= 0 then
    ABuilder.SetUniform('iResolution', PointF(ARect.Width, ARect.Height));
  if FEffect.IndexOfUniform('resolution') >= 0 then
    ABuilder.SetUniform('resolution', PointF(ARect.Width, ARect.Height));

  if FEffect.IndexOfUniform('iTime') >= 0 then
    ABuilder.SetUniform('iTime', Single(FGlobalClock.Elapsed.TotalSeconds));
  if FEffect.IndexOfUniform('time') >= 0 then
    ABuilder.SetUniform('time', Single(FGlobalClock.Elapsed.TotalSeconds));

  if FEffect.IndexOfUniform('iProgress') >= 0 then
    ABuilder.SetUniform('iProgress', CalculateProgress(FElapsedTimeSec));

  if FEffect.IndexOfUniform('iOpacity') >= 0 then
    ABuilder.SetUniform('iOpacity', AOpacity);

  if FEffect.IndexOfUniform('iCornerRadius') >= 0 then
    ABuilder.SetUniform('iCornerRadius', ExtractCornerRadius);

  if FEffect.IndexOfUniform('u_offset') >= 0 then
    ABuilder.SetUniform('u_offset', PointF(0, 0));

  if (FEffect.IndexOfUniform('u_mouse') >= 0) and (not FUniforms.ContainsKey('u_mouse')) then
    ABuilder.SetUniform('u_mouse', PointF(ARect.Width * 0.5, ARect.Height * 0.5));

  // 2. Custom Uniforms
  for Pair in FUniforms do
  begin
    if FEffect.IndexOfUniform(Pair.Key) >= 0 then
    begin
      case Pair.Value.Kind of
        TShaderUniformKind.sukSingle:
          ABuilder.SetUniform(Pair.Key, Pair.Value.SingleVal);
        TShaderUniformKind.sukPointF:
          ABuilder.SetUniform(Pair.Key, Pair.Value.PointVal);
        TShaderUniformKind.sukColor:
          ABuilder.SetUniform(Pair.Key, TAlphaColorF.Create(Pair.Value.ColorVal));
        TShaderUniformKind.sukSingleArray:
          ABuilder.SetUniform(Pair.Key, Pair.Value.SingleArrayVal);
      end;
    end;
  end;
end;

procedure TFluentShaderEffect.Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
var
  CornerRadius: Single;
  Builder: ISkRuntimeShaderBuilder;
  PaintObj: ISkPaint;
  ShaderObj: ISkShader;
  BackdropFilter: ISkImageFilter;
  SaveCount: Integer;
  ChildName: string;
begin
  if not Assigned(FEffect) then
    Exit;

  CornerRadius := ExtractCornerRadius;
  SaveCount := ACanvas.Save;
  try
    // Smart shape clipping
    if CornerRadius > 0.5 then
      ACanvas.ClipRoundRect(TSkRoundRect.Create(ARect, CornerRadius, CornerRadius), TSkClipOp.Intersect, True)
    else if Assigned(FControl) and (FControl is TCircle) then
      ACanvas.ClipRoundRect(TSkRoundRect.Create(ARect, ARect.Width * 0.5, ARect.Height * 0.5), TSkClipOp.Intersect, True)
    else
      ACanvas.ClipRect(ARect, TSkClipOp.Intersect, True);

    // Build shader instance
    Builder := TSkRuntimeShaderBuilder.Create(FEffect);
    ApplyUniforms(Builder, ARect, AOpacity);

    // Automatic Backdrop Sampling if shader declares 'uniform shader image' or 'uniform shader iChannel0'
    ChildName := '';
    if FEffect.ChildExists('image') then
      ChildName := 'image'
    else if FEffect.ChildExists('iChannel0') then
      ChildName := 'iChannel0';

    if ChildName <> '' then
    begin
      BackdropFilter := TSkImageFilter.MakeRuntimeShader(Builder, ChildName, nil);
      if Assigned(BackdropFilter) then
      begin
        PaintObj := TSkPaint.Create;
        PaintObj.AlphaF := AOpacity;
        ACanvas.SaveLayer(ARect, PaintObj, BackdropFilter);
        ACanvas.Restore;
      end;
      Exit;
    end;

    // Normal non-backdrop shader
    ShaderObj := Builder.MakeShader;
    if Assigned(ShaderObj) then
    begin
      PaintObj := TSkPaint.Create;
      PaintObj.Shader := ShaderObj;
      PaintObj.AlphaF := AOpacity;
      ACanvas.DrawRect(ARect, PaintObj);
    end;
  finally
    ACanvas.RestoreToCount(SaveCount);
  end;
end;

procedure TFluentShaderEffect.PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
begin
  // Safe Graceful Fallback for non-Skia environments:
  // Render nothing or subtle outline to prevent visual anomalies
end;

function TFluentShaderEffect.NeedsRepaint: Boolean;
begin
  Result := (not FIsFinished) or (FDurationMs = 0);
end;

function TFluentShaderEffect.Clone: IMotionEffect;
var
  Res: TFluentShaderEffect;
  Pair: TPair<string, TShaderUniform>;
begin
  Res := TFluentShaderEffect.Create(FSkSL, FDurationMs, FDrawMode);
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  for Pair in FUniforms do
    Res.FUniforms.Add(Pair.Key, Pair.Value);
  Result := Res;
end;

{ TFluentBorderBeamEffect }

constructor TFluentBorderBeamEffect.Create(const AColorFrom, AColorTo: TAlphaColor; const ABorderWidth: Single; const ABeamLength: Single; const ADurationMs: Cardinal);
begin
  inherited Create(BORDER_BEAM_SKSL, ADurationMs, TShaderDrawMode.Overlay);
  SetUniform('uBorderWidth', ABorderWidth);
  SetUniform('uBeamLength', ABeamLength);
  SetUniform('uColorFrom', AColorFrom);
  SetUniform('uColorTo', AColorTo);
end;

{ TFluentLiquidWaveEffect }

class constructor TFluentLiquidWaveEffect.CreateClass;
begin
  FControlLevels := TDictionary<TControl, Single>.Create;
end;

class destructor TFluentLiquidWaveEffect.DestroyClass;
begin
  FControlLevels.Free;
end;

constructor TFluentLiquidWaveEffect.Create(const ATargetLevel: Single; const AColor, ACrestColor: TAlphaColor; const ADurationMs: Cardinal);
begin
  inherited Create(LIQUID_WAVE_SKSL, ADurationMs, TShaderDrawMode.Background);
  FFromLevel := 0.0;
  FToLevel := EnsureRange(ATargetLevel, 0.0, 1.0);
  FCurrentLevel := 0.0;
  FExplicitFrom := False;
  SetUniform('uFromLevel', 0.0);
  SetUniform('uToLevel', FToLevel);
  SetUniform('uColor', AColor);
  SetUniform('uCrestColor', ACrestColor);
end;

constructor TFluentLiquidWaveEffect.Create(const AFromLevel, ATargetLevel: Single; const AColor, ACrestColor: TAlphaColor; const ADurationMs: Cardinal);
begin
  inherited Create(LIQUID_WAVE_SKSL, ADurationMs, TShaderDrawMode.Background);
  FFromLevel := EnsureRange(AFromLevel, 0.0, 1.0);
  FToLevel := EnsureRange(ATargetLevel, 0.0, 1.0);
  FCurrentLevel := FFromLevel;
  FExplicitFrom := True;
  SetUniform('uFromLevel', FFromLevel);
  SetUniform('uToLevel', FToLevel);
  SetUniform('uColor', AColor);
  SetUniform('uCrestColor', ACrestColor);
end;

procedure TFluentLiquidWaveEffect.DoAttach;
begin
  inherited DoAttach;
  if not FExplicitFrom then
  begin
    if Assigned(FControl) and FControlLevels.TryGetValue(FControl, FFromLevel) then
      FCurrentLevel := FFromLevel
    else
    begin
      FFromLevel := 0.0;
      FCurrentLevel := 0.0;
    end;
    SetUniform('uFromLevel', FFromLevel);
    SetUniform('uToLevel', FToLevel);
  end;
end;

procedure TFluentLiquidWaveEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  inherited DoUpdate(AProgress, AElapsedTimeSec);
  FCurrentLevel := FFromLevel + (FToLevel - FFromLevel) * AProgress;
  if Assigned(FControl) then
    FControlLevels.AddOrSetValue(FControl, FCurrentLevel);
end;

procedure TFluentLiquidWaveEffect.DoFinish;
begin
  inherited DoFinish;
  FFromLevel := FToLevel;
  FCurrentLevel := FToLevel;
  SetUniform('uFromLevel', FToLevel);
  SetUniform('uToLevel', FToLevel);
  if Assigned(FControl) then
    FControlLevels.AddOrSetValue(FControl, FToLevel);
end;

procedure TFluentLiquidWaveEffect.ApplyUniforms(const ABuilder: ISkRuntimeShaderBuilder; const ARect: TRectF; const AOpacity: Single);
begin
  inherited ApplyUniforms(ABuilder, ARect, AOpacity);
  if FEffect.IndexOfUniform('uFromLevel') >= 0 then
    ABuilder.SetUniform('uFromLevel', FFromLevel);
  if FEffect.IndexOfUniform('uToLevel') >= 0 then
    ABuilder.SetUniform('uToLevel', FToLevel);
  if IsFinished and (FEffect.IndexOfUniform('iProgress') >= 0) then
    ABuilder.SetUniform('iProgress', 1.0);
end;

function TFluentLiquidWaveEffect.NeedsRepaint: Boolean;
begin
  Result := True;
end;

function TFluentLiquidWaveEffect.Clone: IMotionEffect;
var
  Res: TFluentLiquidWaveEffect;
begin
  Res := TFluentLiquidWaveEffect.Create(FFromLevel, FToLevel, FUniforms['uColor'].ColorVal, FUniforms['uCrestColor'].ColorVal, FDurationMs);
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Res.FExplicitFrom := FExplicitFrom;
  Result := Res;
end;

class function TFluentLiquidWaveEffect.GetCurrentLevel(const AControl: TControl): Single;
begin
  if Assigned(AControl) and FControlLevels.TryGetValue(AControl, Result) then
    Exit;
  Result := 0.0;
end;

{ TFluentFrostedGlassEffect }

constructor TFluentFrostedGlassEffect.Create(const ATintColor: TAlphaColor; const ABorderLight: Single; const ADurationMs: Cardinal);
begin
  inherited Create(FROSTED_GLASS_SKSL, ADurationMs, TShaderDrawMode.Filter);
  FTintColor := ATintColor;
  FBorderLight := ABorderLight;
  SetUniform('uTint', ATintColor);
  SetUniform('uBorderLight', ABorderLight);
end;

procedure TFluentFrostedGlassEffect.Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
var
  Backdrop: ISkImageFilter;
  TintPaint: ISkPaint;
  BorderPaint: ISkPaint;
  LSaveCount: Integer;
begin
  if not Assigned(ACanvas) then
    Exit;

  // 1. Create Gaussian Blur Backdrop filter from underlying scene pixels
  Backdrop := TSkImageFilter.MakeBlur(15.0, 15.0, nil, TSkTileMode.Clamp);

  // 2. SaveLayer with backdrop filter
  LSaveCount := ACanvas.SaveLayer(ARect, nil, Backdrop);
  try
    // 3. Draw frosted tint overlay
    TintPaint := TSkPaint.Create;
    TintPaint.Color := FTintColor;
    TintPaint.AlphaF := AOpacity * (TAlphaColorRec(FTintColor).A / 255.0);
    ACanvas.DrawRect(ARect, TintPaint);

    // 4. Draw glass border light
    if FBorderLight > 0.0 then
    begin
      BorderPaint := TSkPaint.Create;
      BorderPaint.Style := TSkPaintStyle.Stroke;
      BorderPaint.StrokeWidth := 1.0;
      BorderPaint.Color := $40FFFFFF;
      BorderPaint.AlphaF := AOpacity * FBorderLight * 0.5;
      ACanvas.DrawRect(ARect, BorderPaint);
    end;
  finally
    ACanvas.RestoreToCount(LSaveCount);
  end;
end;

{ TFluentMeshGradientEffect }

constructor TFluentMeshGradientEffect.Create(const AColor1, AColor2, AColor3, AColor4: TAlphaColor; const ADurationMs: Cardinal);
begin
  inherited Create(MESH_GRADIENT_SKSL, ADurationMs, TShaderDrawMode.Background);
  SetUniform('uColor1', AColor1);
  SetUniform('uColor2', AColor2);
  SetUniform('uColor3', AColor3);
  SetUniform('uColor4', AColor4);
end;

{ TFluentDissolveBurnEffect }

constructor TFluentDissolveBurnEffect.Create(const AEmberColor: TAlphaColor; const AEmberWidth, ANoiseScale: Single; const ADurationMs: Cardinal);
begin
  inherited Create(DISSOLVE_BURN_SKSL, ADurationMs, TShaderDrawMode.Overlay);
  SetUniform('uEmberColor', AEmberColor);
  SetUniform('uEmberWidth', AEmberWidth);
  SetUniform('uNoiseScale', ANoiseScale);
end;

{ TFluentRippleDistortionEffect }

constructor TFluentRippleDistortionEffect.Create(const ARippleColor: TAlphaColor; const AWaveWidth: Single; const ADurationMs: Cardinal);
begin
  inherited Create(RIPPLE_DISTORTION_SKSL, ADurationMs, TShaderDrawMode.Overlay);
  SetUniform('uRippleColor', ARippleColor);
  SetUniform('uWaveWidth', AWaveWidth);
end;

procedure TFluentRippleDistortionEffect.ApplyUniforms(const ABuilder: ISkRuntimeShaderBuilder; const ARect: TRectF; const AOpacity: Single);
begin
  inherited ApplyUniforms(ABuilder, ARect, AOpacity);
  // Default ripple center to middle of the control if not explicitly supplied
  if not FUniforms.ContainsKey('uCenter') then
  begin
    if FEffect.IndexOfUniform('uCenter') >= 0 then
      ABuilder.SetUniform('uCenter', PointF(ARect.Width * 0.5, ARect.Height * 0.5));
  end;
end;

{ TFluentNeonGlowEffect }

constructor TFluentNeonGlowEffect.Create(const AGlowColor: TAlphaColor; const AGlowRadius, APulseSpeed: Single; const ADurationMs: Cardinal);
begin
  inherited Create(NEON_GLOW_SKSL, ADurationMs, TShaderDrawMode.Overlay);
  SetUniform('uGlowColor', AGlowColor);
  SetUniform('uGlowRadius', AGlowRadius);
  SetUniform('uPulseSpeed', APulseSpeed);
end;

{ TFluentGooeyMetaballEffect }

constructor TFluentGooeyMetaballEffect.Create(const ABlobColor: TAlphaColor; const ASpeed: Single; const ADurationMs: Cardinal);
begin
  inherited Create(GOOEY_METABALL_SKSL, ADurationMs, TShaderDrawMode.Background);
  SetUniform('uBlobColor', ABlobColor);
  SetUniform('uSpeed', ASpeed);
end;

{ TFluentLiquidGlassEffect }

constructor TFluentLiquidGlassEffect.Create(const AStyle: TFluentGlassStyle; const ADurationMs: Cardinal);
var
  LRefr, LAberr, LBlur, LGlow: Single;
begin
  case AStyle of
    TFluentGlassStyle.ClearLiquid:
      begin
        LRefr := 14.0;
        LAberr := 0.08;
        LBlur := 0.8;
        LGlow := 0.40;
      end;
    TFluentGlassStyle.Frosted:
      begin
        LRefr := 18.0;
        LAberr := 0.12;
        LBlur := 2.5;
        LGlow := 0.25;
      end;
    TFluentGlassStyle.DynamicIsland:
      begin
        LRefr := 10.0;
        LAberr := 0.05;
        LBlur := 0.3;
        LGlow := 0.50;
      end;
    TFluentGlassStyle.HeavyPrism:
      begin
        LRefr := 24.0;
        LAberr := 0.25;
        LBlur := 1.2;
        LGlow := 0.35;
      end;
  else
    begin
      LRefr := 14.0;
      LAberr := 0.08;
      LBlur := 0.8;
      LGlow := 0.40;
    end;
  end;

  Create(LRefr, LAberr, LBlur, LGlow, ADurationMs);
end;

constructor TFluentLiquidGlassEffect.Create(const ARefrMagnitude, AAberration, ABlurRadius, AGlowIntensity: Single; const ADurationMs: Cardinal);
begin
  inherited Create(LIQUID_GLASS_SKSL, ADurationMs, TShaderDrawMode.Overlay);
  FBlurRadius := ABlurRadius;
  FGlowIntensity := AGlowIntensity;
  SetUniform('uRefrMagnitude', ARefrMagnitude);
  SetUniform('uAberration', AAberration);
  SetUniform('uBlurRadius', ABlurRadius);
  SetUniform('uGlowIntensity', AGlowIntensity);
end;

procedure TFluentLiquidGlassEffect.Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
var
  Backdrop: ISkImageFilter;
  TintPaint: ISkPaint;
  BorderPaint: ISkPaint;
  LSaveCount: Integer;
begin
  if not Assigned(ACanvas) then
    Exit;

  // 1. Hardware Gaussian Blur Backdrop filter from underlying scene pixels
  Backdrop := TSkImageFilter.MakeBlur(FBlurRadius * 12.0, FBlurRadius * 12.0, nil, TSkTileMode.Clamp);

  // 2. SaveLayer with backdrop filter
  LSaveCount := ACanvas.SaveLayer(ARect, nil, Backdrop);
  try
    // 3. Draw glass highlight
    TintPaint := TSkPaint.Create;
    TintPaint.Color := $20FFFFFF;
    TintPaint.AlphaF := AOpacity;
    ACanvas.DrawRect(ARect, TintPaint);

    // 4. Glow / Refractive edge light
    if FGlowIntensity > 0.0 then
    begin
      BorderPaint := TSkPaint.Create;
      BorderPaint.Style := TSkPaintStyle.Stroke;
      BorderPaint.StrokeWidth := 1.2;
      BorderPaint.Color := $60FFFFFF;
      BorderPaint.AlphaF := AOpacity * FGlowIntensity;
      ACanvas.DrawRect(ARect, BorderPaint);
    end;
  finally
    ACanvas.RestoreToCount(LSaveCount);
  end;
end;

end.
