# TulipFluentMotion: Full API Reference

Comprehensive reference of all interfaces, classes, helpers, records, and enums provided by `TulipFluentMotion`.

---

## 1. Core Interfaces

### `IMotionBuilder`
The primary fluent interface returned by `TControl.Motion`.

#### Timing, Physics & State
```pascal
function Duration(const ADurationMs: Cardinal): IMotionBuilder;
function Delay(const ADelayMs: Cardinal): IMotionBuilder;
function Speed(const ASpeed: Single): IMotionBuilder; // 1.0 = normal, 2.0 = double speed, 0.5 = half speed
function WithEase(const AEase: TFluentEase): IMotionBuilder;
function WithSpring(const ASpring: TFluentSpring): IMotionBuilder;
function WithAngle(const AAngleDeg: Single): IMotionBuilder;
function RepeatCount(const ACount: Integer): IMotionBuilder; // -1 = infinite, N = repeat N times
function RepeatForever(const AAutoreverse: Boolean = True): IMotionBuilder;
function Autoreverse(const AEnabled: Boolean = True): IMotionBuilder;
function Anchor(const AAnchor: TMotionAnchor): IMotionBuilder; overload;
function Anchor(const ACustomPoint: TPointF): IMotionBuilder; overload;
```

#### Physical Transforms (Parallel by default within same phase)
```pascal
function Scale(const ATargetScale: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function Scale(const AFromScale, ATargetScale: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function ScaleX(const ATargetScaleX: Single; const ADurationMs: Cardinal = 250): IMotionBuilder;
function ScaleY(const ATargetScaleY: Single; const ADurationMs: Cardinal = 250): IMotionBuilder;

function Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function Move(const ADeltaX, ADeltaY: Single; const AAnchor: TMotionAnchor): IMotionBuilder; overload;
function Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder; overload;
function MoveX(const ADeltaX: Single; const ADurationMs: Cardinal = 250): IMotionBuilder;
function MoveY(const ADeltaY: Single; const ADurationMs: Cardinal = 250): IMotionBuilder;
function MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function MoveTo(const ATargetX, ATargetY: Single; const AAnchor: TMotionAnchor): IMotionBuilder; overload;
function MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder; overload;

function Rotate(const ATargetAngleDeg: Single; const ADurationMs: Cardinal = 250): IMotionBuilder;
function RotateBy(const ADeltaAngleDeg: Single; const ADurationMs: Cardinal = 250): IMotionBuilder;

function Flip3D(const ATargetAngleDeg: Single; const AAxis: TFlipAxis = TFlipAxis.Horizontal; const ADurationMs: Cardinal = 350): IMotionBuilder;
function FlipHorizontal(const ATargetAngleDeg: Single = 180.0; const ADurationMs: Cardinal = 350): IMotionBuilder;
function FlipVertical(const ATargetAngleDeg: Single = 180.0; const ADurationMs: Cardinal = 350): IMotionBuilder;
```

#### Opacity, Colors & Filters
```pascal
function Fade(const ATargetOpacity: Single; const ADurationMs: Cardinal = 200): IMotionBuilder; overload;
function Fade(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal = 200): IMotionBuilder; overload;
function FadeIn(const ADurationMs: Cardinal = 200): IMotionBuilder;
function FadeOut(const ADurationMs: Cardinal = 200): IMotionBuilder;

function ColorTo(const ATargetColor: TAlphaColor; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function ColorTo(const AFromColor, ATargetColor: TAlphaColor; const ADurationMs: Cardinal): IMotionBuilder; overload;
function ColorFromTo(const AFromColor, ATargetColor: TAlphaColor; const ADurationMs: Cardinal = 250): IMotionBuilder;
function Tint(const ATintColor: TAlphaColor; const ADurationMs: Cardinal = 250): IMotionBuilder;

function Grayscale(const ATargetAmount: Single = 1.0; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function Grayscale(const AFromAmount, ATargetAmount: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function GrayscaleIn(const ADurationMs: Cardinal = 250): IMotionBuilder;
function GrayscaleOut(const ADurationMs: Cardinal = 250): IMotionBuilder;

function Shadow(const ADistance: Single; const ASoftness: Single = 0.3; const AOpacity: Single = 0.5; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function Shadow(const AFromDistance, ATargetDistance, AFromSoftness, ATargetSoftness, AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function Elevation(const AElevationLevel: Single; const ADurationMs: Cardinal = 250): IMotionBuilder;

function Blur(const ATargetSoftness: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function Blur(const AFromSoftness, ATargetSoftness: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function BlurIn(const AMaxSoftness: Single = 4.0; const ADurationMs: Cardinal = 250): IMotionBuilder;
function BlurOut(const ADurationMs: Cardinal = 250): IMotionBuilder;

function Glow(const AColor: TAlphaColor = $8000A0FF; const ASoftness: Single = 0.5; const AOpacity: Single = 0.8; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function Glow(const ATargetOpacity: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function HueRotation(const ATargetAngleDeg: Single = 360.0; const ADurationMs: Cardinal = 500): IMotionBuilder;
```

#### Micro-Interactions & Transitions
```pascal
function Shake(const AIntensity: Single = 8.0; const ADurationMs: Cardinal = 350): IMotionBuilder;
function Pulse(const AScalePeak: Single = 1.12; const ADurationMs: Cardinal = 280): IMotionBuilder;
function Bounce(const AHeight: Single = 16.0; const ADurationMs: Cardinal = 320): IMotionBuilder;
function Wiggle(const AIntensityDeg: Single = 2.5; const ADurationMs: Cardinal = 350): IMotionBuilder;

function SlideIn(const ADirection: TTransitionDirection = TTransitionDirection.FromLeft; const ADistance: Single = 0; const ADurationMs: Cardinal = 300): IMotionBuilder;
function SlideOut(const ADirection: TTransitionDirection = TTransitionDirection.FromRight; const ADistance: Single = 0; const ADurationMs: Cardinal = 300): IMotionBuilder;
function PopIn(const ADurationMs: Cardinal = 350): IMotionBuilder;
function PopOut(const ADurationMs: Cardinal = 250): IMotionBuilder;

function ResizeTo(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal = 250; const AAnchor: TResizeAnchor = TResizeAnchor.Center): IMotionBuilder;
function ResizeWidth(const ATargetWidth: Single; const ADurationMs: Cardinal = 250; const AAnchor: TResizeAnchor = TResizeAnchor.Center): IMotionBuilder;
function ResizeHeight(const ATargetHeight: Single; const ADurationMs: Cardinal = 250; const AAnchor: TResizeAnchor = TResizeAnchor.Center): IMotionBuilder;
```

#### Typography & Skia Shimmer/Ripple
```pascal
function CountTo(const ATargetValue: Double; const AFormatStr: string = '%0.2f'; const ADurationMs: Cardinal = 1500): IMotionBuilder; overload;
function CountTo(const AFromValue, ATargetValue: Double; const AFormatStr: string = '%0.2f'; const ADurationMs: Cardinal = 1500): IMotionBuilder; overload;
function Typewriter(const ATargetText: string; const ACharDelayMs: Cardinal = 40; const ABlinkingCursor: Boolean = True; const ACursorChar: Char = '|'): IMotionBuilder;
function ShimmerText(const ADurationMs: Cardinal = 1000; const ADirection: TShimmerDirection = TShimmerDirection.LeftToRight; const AAngleDeg: Single = 20.0): IMotionBuilder; overload;

function Shimmer(const ADurationMs: Cardinal = 1000; const ADirection: TShimmerDirection = TShimmerDirection.LeftToRight; const AAngleDeg: Single = 20.0): IMotionBuilder; overload;
function Shimmer(const AConfig: TFluentShimmerConfig; const ADurationMs: Cardinal = 1000): IMotionBuilder; overload;
function Ripple(const ADurationMs: Cardinal = 450): IMotionBuilder; overload;
function Ripple(const AConfig: TFluentRippleConfig; const ADurationMs: Cardinal = 450): IMotionBuilder; overload;
```

#### Skia Runtime Shaders & Presets
```pascal
function CustomShader(const ASkSL: string; const ADurationMs: Cardinal = 1000; const ADrawMode: TShaderDrawMode = TShaderDrawMode.Overlay): IMotionBuilder;
function BorderBeam(const AColorFrom, AColorTo: TAlphaColor; const ABorderWidth: Single = 3.0; const ABeamLength: Single = 0.25; const ADurationMs: Cardinal = 2000): IMotionBuilder; overload;
function BorderBeam(const AColor: TAlphaColor; const ABorderWidth: Single = 3.0; const ADurationMs: Cardinal = 2000): IMotionBuilder; overload;
function LiquidWave(const ATargetLevel: Single; const AColor: TAlphaColor = $CC007ACC; const ACrestColor: TAlphaColor = $FFFFFFFF; const ADurationMs: Cardinal = 1000): IMotionBuilder; overload;
function FrostedGlass(const ATintColor: TAlphaColor = $40FFFFFF; const ABorderLight: Single = 0.8; const ADurationMs: Cardinal = 500): IMotionBuilder;
function MeshGradient(const AColor1, AColor2, AColor3, AColor4: TAlphaColor; const ADurationMs: Cardinal = 3000): IMotionBuilder;
function DissolveBurn(const AEmberColor: TAlphaColor = $FFFF4500; const AEmberWidth: Single = 0.08; const ANoiseScale: Single = 8.0; const ADurationMs: Cardinal = 1500): IMotionBuilder;
function RippleDistortion(const ARippleColor: TAlphaColor = $8000BFFF; const AWaveWidth: Single = 24.0; const ADurationMs: Cardinal = 600): IMotionBuilder; overload;
function NeonGlow(const AGlowColor: TAlphaColor = $FF00FFCC; const AGlowRadius: Single = 16.0; const APulseSpeed: Single = 4.0; const ADurationMs: Cardinal = 1500): IMotionBuilder;
function GooeyMetaball(const ABlobColor: TAlphaColor = $DDFF007F; const ASpeed: Single = 2.0; const ADurationMs: Cardinal = 3000): IMotionBuilder;
function LiquidGlass(const AStyle: TFluentGlassStyle; const ADurationMs: Cardinal = 2000): IMotionBuilder; overload;
function LiquidGlass(const ARefrMagnitude: Single = 14.0; const AAberration: Single = 0.08; const ABlurRadius: Single = 0.8; const AGlowIntensity: Single = 0.40; const ADurationMs: Cardinal = 2000): IMotionBuilder; overload;

// Uniform Configuration
function Uniform(const AName: string; const AValue: Single): IMotionBuilder; overload;
function Uniform(const AName: string; const AValue: TPointF): IMotionBuilder; overload;
function Uniform(const AName: string; const AValue: TAlphaColor): IMotionBuilder; overload;
function Uniform(const AName: string; const AValue: TArray<Single>): IMotionBuilder; overload;
function DrawMode(const ADrawMode: TShaderDrawMode): IMotionBuilder;
```

#### Phasing & Execution Lifecycle
```pascal
function Wait(const AWaitMs: Cardinal): IMotionBuilder;
function &Then: IMotionBuilder; // Marks end of current parallel phase and begins next sequential phase
function OnProgress(const ACallback: TMotionProgressCallback): IMotionBuilder;
function OnComplete(const ACallback: TMotionCallback): IMotionBuilder;

function Start: IMotionBuilder;
function Stop: IMotionBuilder;
function Reset: IMotionBuilder;
function Pause: IMotionBuilder;
function Resume: IMotionBuilder;
function Seek(const AProgress: Single): IMotionBuilder; // 0.0 .. 1.0
```

---

## 2. Enums and Records

### `TFluentEase`
31 easing curves covering all standard CSS/Penner curves:
`Linear`, `InQuad`, `OutQuad`, `InOutQuad`, `InCubic`, `OutCubic`, `InOutCubic`, `InQuart`, `OutQuart`, `InOutQuart`, `InQuint`, `OutQuint`, `InOutQuint`, `InSine`, `OutSine`, `InOutSine`, `InExpo`, `OutExpo`, `InOutExpo`, `InCirc`, `OutCirc`, `InOutCirc`, `InBack`, `OutBack`, `InOutBack`, `InElastic`, `OutElastic`, `InOutElastic`, `InBounce`, `OutBounce`, `InOutBounce`.

### `TFluentSpring`
SwiftUI-compatible spring physics record:
```pascal
constructor Create(const AResponse: Single; const ADampingFraction: Single; const AMass: Single = 1.0);
class function Smooth: TFluentSpring; static;      // (0.45, 0.82, 1.0)
class function Bouncy: TFluentSpring; static;      // (0.38, 0.52, 1.0)
class function Snappy: TFluentSpring; static;      // (0.25, 0.90, 1.0)
class function Interactive: TFluentSpring; static; // (0.15, 0.86, 1.0)
```

### `TMotionAnchor`
Transformation origin anchors:
`TopLeft`, `TopCenter`, `TopRight`, `CenterLeft`, `Center`, `CenterRight`, `BottomLeft`, `BottomCenter`, `BottomRight`, `Custom`.

### `TFluentGlassStyle`
Liquid glass visual presets:
- `ClearLiquid`: Ultra-clear optical refraction.
- `Frosted`: Apple macOS / iOS style matte frosted glass.
- `DynamicIsland`: High-gloss lens with subtle dispersion.
- `HeavyPrism`: Strong crystal prism with noticeable rainbow chromatic aberration.

### `TShaderDrawMode`
- `Overlay`: Rendered on top of the host control.
- `Background`: Rendered underneath the host control.
- `Filter`: Acts as an image filtering pass.

### `TTransitionDirection`
`FromLeft`, `FromRight`, `FromTop`, `FromBottom`.

---

## 3. Form Driver (`TCommonCustomForm` Helper)

Direct methods available on any `TCommonCustomForm` (e.g. `FormMain.Mica()`):

```pascal
procedure Shake(const AIntensity: Single = 12.0; const ADurationMs: Cardinal = 380);
procedure Fade(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal = 250); overload;
procedure Fade(const ATargetOpacity: Single; const ADurationMs: Cardinal = 250); overload;
procedure FadeIn(const ADurationMs: Cardinal = 250);
procedure FadeOut(const ADurationMs: Cardinal = 250; const AOnComplete: TMotionCallback = nil);
procedure MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.TopLeft);
procedure MoveBy(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal = 250);
procedure ResizeTo(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal = 250);
procedure SlideIn(const ADirection: TTransitionDirection = TTransitionDirection.FromBottom; const ADurationMs: Cardinal = 300);
procedure SlideOut(const ADirection: TTransitionDirection = TTransitionDirection.FromBottom; const ADurationMs: Cardinal = 250);
procedure PopIn(const ADurationMs: Cardinal = 350);
procedure PopOut(const ADurationMs: Cardinal = 250);

// Windows 11 Fluent Backdrops
procedure Acrylic(const ATintColor: TAlphaColor = $60202020; const AKeepActive: Boolean = True);
procedure Mica(const AAltTabbed: Boolean = False; const AKeepActive: Boolean = True);
procedure DisableBackdrop;
procedure HideTitleBar;
```
