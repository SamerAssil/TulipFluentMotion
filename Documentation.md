[🇺🇸 English Version](Documentation.md) | [🇸🇦 النسخة العربية](Documentation.ar.md)

# TulipFluentMotion Developer Reference Manual
### The Definitive Operational Guide for Delphi 13 (VER370) FireMonkey & Skia

---

## 📑 Table of Contents

1. [Technical Prerequisites & Initialization](#1-technical-prerequisites--initialization)
2. [Declarative Fluent Builder & Helpers](#2-declarative-fluent-builder--helpers)
3. [Event Handling & Micro-Interactions](#3-event-handling--micro-interactions)
4. [Geometric Transforms & Spatial Geometry](#4-geometric-transforms--spatial-geometry)
5. [Opacity, Color Transitions & Hardware Filters](#5-opacity-color-transitions--hardware-filters)
6. [Micro-Interactions & Quick Transitions](#6-micro-interactions--quick-transitions)
7. [SkSL Runtime GPU Shaders Catalog](#7-sksl-runtime-gpu-shaders-catalog)
8. [Typography, Complex Arabic Text & KPI Counters](#8-typography-complex-arabic-text--kpi-counters)
9. [Window & OS Form Motion](#9-window--os-form-motion)
10. [Analytical Spring Physics & Easing Curves](#10-analytical-spring-physics--easing-curves)
11. [Motion Pipelines, Sequencing & Runtime Controls](#11-motion-pipelines-sequencing--runtime-controls)
12. [Memory Management & High-Performance Best Practices](#12-memory-management--high-performance-best-practices)

---

## 1. Technical Prerequisites & Initialization

**TulipFluentMotion** targets **Delphi 13 Athens (`VER370`)** and subsequent releases across all four major FireMonkey operating systems:
- **Windows** (32-bit & 64-bit)
- **Android** (32-bit & 64-bit ARM)
- **iOS** (64-bit ARM & Simulator)
- **macOS** (Intel & Apple Silicon ARM64)

### A. Global Skia Initialization
Advanced graphics effects (such as `LiquidGlass` live refraction, chromatic dispersion, and text contour sheen) dispatch draw commands directly to the GPU via Skia. To enable the hardware pipeline and prevent black/opaque rectangular visual artifacts, you must initialize Skia globally in your application's main `.dpr` file before initializing the application:

```pascal
program YourApplication;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia, // <--- Mandatory Skia FireMonkey unit
  UnitMain in 'UnitMain.pas' {MainForm};

{$R *.res}

begin
  GlobalUseSkia := True; // <--- Must be set before Application.Initialize
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
```

### B. Single Uses Clause
In all forms, frames, or view units throughout your application, include the main facade:
```pascal
uses
  Tulip.FluentMotion;
```
This unit automatically re-exports all core interfaces (`IMotionBuilder`), configuration types (`TFluentEase`, `TFluentSpring`, `TMotionAnchor`), effects, and class helpers (`TControl.Motion` and `TCommonCustomForm`).

---

## 2. Declarative Fluent Builder & Helpers

The framework provides two interchangeable programming patterns:

<!-- IMAGE_PLACEHOLDER: Fluent API Chaining Diagram / Code Editor Screenshot -->
![Fluent API Usage](docs/images/fluent-api-guide.png)

### A. Instant One-Liners
Via `TFluentMotionControlHelper`, which extends every `TControl` instance:
```pascal
// Instantly triggers the effect using tuned physics presets
BtnLogin.PopIn(250);
EditPassword.Shake(12.0, 400);
CardOffer.Pulse(1.10, 200);
PanelNotification.FadeIn(300);
```

### B. Declarative Method Chaining
By invoking the `.Motion` property, which yields an `IMotionBuilder` contract:
```pascal
CardProduct.Motion
  .Anchor(TMotionAnchor.Center)
  .Scale(0.9, 1.0, 300)
  .WithSpring(TFluentSpring.Bouncy)
  .Start;
```

---

## 3. Event Handling & Micro-Interactions

Trigger fluid feedback in response to user inputs within standard FMX event handlers:

<!-- IMAGE_PLACEHOLDER: Interactive Micro-Interactions in action (Hover, Press, Ripple, Shake) -->
![Event Handling Demo](docs/images/event-handling.gif)

### A. Mouse Hover (OnMouseEnter / OnMouseLeave)
Elevate cards or buttons on hover and settle back smoothly on leave:
```pascal
procedure TMainForm.CardMouseEnter(Sender: TObject);
begin
  TControl(Sender).Motion
    .Scale(1.05, 180)
    .WithSpring(TFluentSpring.Snappy)
    .Start;
end;

procedure TMainForm.CardMouseLeave(Sender: TObject);
begin
  TControl(Sender).Motion
    .Scale(1.0, 180)
    .WithEase(TFluentEase.OutQuad)
    .Start;
end;
```

### B. Touch & Button Press Feedback (OnMouseDown / OnMouseUp)
Replicate iOS and macOS physical button depression:
```pascal
procedure TMainForm.BtnSubmitMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    TControl(Sender).Motion.Scale(0.95, 100).WithEase(TFluentEase.OutQuad).Start;
end;

procedure TMainForm.BtnSubmitMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    TControl(Sender).Motion.Scale(1.0, 250).WithSpring(TFluentSpring.Bouncy).Start;
end;
```

### C. Touch Ripple Shockwave
Spawn an authentic water shockwave expanding outward from the precise tap coordinate:
```pascal
procedure TMainForm.PanelSurfaceClick(Sender: TObject);
var
  LocalPos: TPointF;
  Ctrl: TControl;
begin
  Ctrl := Sender as TControl;
  // Convert screen mouse coordinates to local control space:
  LocalPos := Ctrl.ScreenToLocal(Screen.MousePos);

  Ctrl.Motion
    .RippleDistortion(LocalPos, $8000BFFF, 24.0, 500)
    .Start;
end;
```

### D. Input Validation Shake
Indicate incorrect passwords, PIN codes, or form errors:
```pascal
procedure TMainForm.ValidateLogin;
begin
  if EditPIN.Text <> '1234' then
  begin
    EditPIN.Shake(10.0, 350);
    LblError.FadeIn(200);
  end;
end;
```

### E. Interactive Gesture Scrubbing (.Seek)
Directly couple animation progress (`0.0 .. 1.0`) with gestures, scroll offsets, or sliders without starting the ticker loop:
```pascal
procedure TMainForm.TrackBarProgressChange(Sender: TObject);
begin
  // Scrub motion timeline proportionally
  CardDrawer.Motion
    .MoveX(280, 400)
    .Fade(0.2, 1.0, 400)
    .Seek(TrackBarProgress.Value / 100.0);
end;
```

---

## 4. Geometric Transforms & Spatial Geometry

<!-- IMAGE_PLACEHOLDER: Geometric Transforms Showcase (Scale, Move, Rotate, Flip3D, ResizeTo) -->
![Transforms Showcase](docs/images/transforms-guide.png)

### A. Scaling Modifiers
```pascal
// Uniform scaling across X and Y
function Scale(const ATargetScale: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder; overload;
// Explicit start and target scale factors
function Scale(const AFromScale, ATargetScale: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder; overload;
// Independent horizontal scale
function ScaleX(const ATargetScaleX: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
// Independent vertical scale
function ScaleY(const ATargetScaleY: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
```

### B. Coordinate Translation
```pascal
// Relative delta displacement
function Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function Move(const ADeltaX, ADeltaY: Single; const AAnchor: TMotionAnchor): IMotionBuilder; overload;
function Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder; overload;
function MoveX(const ADeltaX: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.TopLeft): IMotionBuilder;
function MoveY(const ADeltaY: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.TopLeft): IMotionBuilder;
// Absolute coordinate positioning inside container
function MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function MoveTo(const ATargetX, ATargetY: Single; const AAnchor: TMotionAnchor): IMotionBuilder; overload;
function MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder; overload;
```

### C. 2D Rotation & 3D Perspective Card Flips
```pascal
function Rotate(const ATargetAngleDeg: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
function RotateBy(const ADeltaAngleDeg: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;

// 3D perspective rotation around horizontal or vertical axes
function Flip3D(const ATargetAngleDeg: Single; const AAxis: TFlipAxis = TFlipAxis.Horizontal; const ADurationMs: Cardinal = 350; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
function FlipHorizontal(const ATargetAngleDeg: Single = 180.0; const ADurationMs: Cardinal = 350; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
function FlipVertical(const ATargetAngleDeg: Single = 180.0; const ADurationMs: Cardinal = 350; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
```

### D. Dynamic Bounds Resizing
Directly interpolates actual control `Width` and `Height` for accordion containers and expandable drawers:
```pascal
function ResizeTo(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
function ResizeWidth(const ATargetWidth: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
function ResizeHeight(const ATargetHeight: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
```

### E. Transform Anchors (`TMotionAnchor`)
Configures the pivot point for scaling, rotation, and dynamic resizing:
```pascal
type
  TMotionAnchor = (
    TopLeft,      // (0.0, 0.0)
    TopCenter,    // (0.5, 0.0)
    TopRight,     // (1.0, 0.0)
    CenterLeft,   // (0.0, 0.5)
    Center,       // (0.5, 0.5) [Default]
    CenterRight,  // (1.0, 0.5)
    BottomLeft,   // (0.0, 1.0)
    BottomCenter, // (0.5, 1.0)
    BottomRight,  // (1.0, 1.0)
    Custom        // User-defined point
  );

// Usage (either inline as the trailing parameter, or via .Anchor):
MyControl.Motion
  .ScaleY(1.5, 300, TMotionAnchor.TopCenter)
  .Start;

// Or chain .Anchor for custom normalized point:
MyControl.Motion
  .Anchor(PointF(0.2, 0.8))
  .Rotate(45.0, 400)
  .Start;
```

---

## 5. Opacity, Color Transitions & Hardware Filters

<!-- IMAGE_PLACEHOLDER: Opacity, Color Tints, Shadows and Glow Effects GIF -->
![Colors and Filters Demo](docs/images/colors-filters.gif)

### A. Smart Opacity & Fades
Evaluates current visibility state: if `FadeIn` is called on a hidden (`Visible = False`) or opaque (`1.0`) control, it resets opacity to `0.0`, enables visibility, and smoothly interpolates to `1.0`:
```pascal
function Fade(const ATargetOpacity: Single; const ADurationMs: Cardinal = 200): IMotionBuilder; overload;
function Fade(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal = 200): IMotionBuilder; overload;
function FadeIn(const ADurationMs: Cardinal = 200): IMotionBuilder;
function FadeOut(const ADurationMs: Cardinal = 200): IMotionBuilder;
```

### B. Color Transitions & Tinting
Smoothly transitions fill colors on `TShape` controls and text colors on `TTextControl`:
```pascal
function ColorTo(const ATargetColor: TAlphaColor; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function ColorTo(const AFromColor, ATargetColor: TAlphaColor; const ADurationMs: Cardinal): IMotionBuilder; overload;
function ColorFromTo(const AFromColor, ATargetColor: TAlphaColor; const ADurationMs: Cardinal = 250): IMotionBuilder;
function Tint(const ATintColor: TAlphaColor; const ADurationMs: Cardinal = 250): IMotionBuilder;
```

### C. Grayscale & Hue Rotation
```pascal
function Grayscale(const ATargetAmount: Single = 1.0; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function Grayscale(const AFromAmount, ATargetAmount: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function GrayscaleIn(const ADurationMs: Cardinal = 250): IMotionBuilder;
function GrayscaleOut(const ADurationMs: Cardinal = 250): IMotionBuilder;

// Cycles color spectrum in degrees via GPU shader
function HueRotation(const ATargetAngleDeg: Single = 360.0; const ADurationMs: Cardinal = 500): IMotionBuilder;
```

### D. Blur, Elevation & Glow
```pascal
// Hardware-accelerated gaussian blur
function Blur(const ATargetSoftness: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function BlurIn(const AMaxSoftness: Single = 4.0; const ADurationMs: Cardinal = 250): IMotionBuilder;
function BlurOut(const ADurationMs: Cardinal = 250): IMotionBuilder;

// Material / SwiftUI elevation shadow
function Shadow(const ADistance: Single; const ASoftness: Single = 0.3; const AOpacity: Single = 0.5; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
function Elevation(const AElevationLevel: Single; const ADurationMs: Cardinal = 250): IMotionBuilder;

// Ambient glowing outline
function Glow(const AColor: TAlphaColor = $8000A0FF; const ASoftness: Single = 0.5; const AOpacity: Single = 0.8; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
```

---

## 6. Micro-Interactions & Quick Transitions

<!-- IMAGE_PLACEHOLDER: Micro-Interactions Showcase (Shake, Pulse, Bounce, Wiggle, Slide, Pop) -->
![Micro-Interactions Showcase](docs/images/micro-actions.gif)

```pascal
// Damped harmonic shake for form validation errors
function Shake(const AIntensity: Single = 8.0; const ADurationMs: Cardinal = 350): IMotionBuilder;

// Snappy expanding scale pulse
function Pulse(const AScalePeak: Single = 1.12; const ADurationMs: Cardinal = 280; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;

// Playful vertical rebound bounce
function Bounce(const AHeight: Single = 16.0; const ADurationMs: Cardinal = 320): IMotionBuilder;

// Tactical oscillation resembling iOS home screen edit mode
function Wiggle(const AIntensityDeg: Single = 2.5; const ADurationMs: Cardinal = 350; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;

// Edge slides with synchronized opacity fading
function SlideIn(const ADirection: TTransitionDirection = TTransitionDirection.FromLeft; const ADistance: Single = 0; const ADurationMs: Cardinal = 300): IMotionBuilder;
function SlideOut(const ADirection: TTransitionDirection = TTransitionDirection.FromRight; const ADistance: Single = 0; const ADurationMs: Cardinal = 300): IMotionBuilder;

// Bouncy spring zoom-in from zero to full scale or vice versa
function PopIn(const ADurationMs: Cardinal = 350; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
function PopOut(const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
```

---

## 7. SkSL Runtime GPU Shaders Catalog

Compiled directly to GPU bytecode using Skia Shading Language (`SkSL`):

<!-- IMAGE_PLACEHOLDER: All 9 SkSL Shaders Showcase GIF Matrix -->
![SkSL Shaders Matrix](docs/images/sksl-matrix.gif)

### 1. Liquid Glass (`LiquidGlass`)
Emulates modern frosted acrylic and Apple visionOS glass by sampling and refracting underlying pixels (`Backdrop Refraction`), separating chromatic RGB spectrums, applying gaussian surface blur, and projecting rim specular reflections:

```pascal
// A. Using visual presets:
function LiquidGlass(const AStyle: TFluentGlassStyle; const ADurationMs: Cardinal = 2000): IMotionBuilder; overload;

// B. Precise physical optical configuration:
function LiquidGlass(
  const ARefrMagnitude: Single = 14.0; // Refraction displacement intensity
  const AAberration: Single = 0.08;   // Lateral chromatic dispersion (RGB Split)
  const ABlurRadius: Single = 0.8;    // Frosted sampling radius
  const AGlowIntensity: Single = 0.40; // Specular rim reflection intensity
  const ADurationMs: Cardinal = 2000
): IMotionBuilder; overload;
```

#### Available Styles (`TFluentGlassStyle`):
- `ClearLiquid`: Pure optical liquid glass (Shadertoy 3cdXDX model).
- `Frosted`: Classic iOS / macOS frosted matte glass.
- `DynamicIsland`: Highly-polished reflective lens.
- `HeavyPrism`: Thick crystal prism with pronounced rainbow dispersion.

---

### 2. Mesh Gradient (`MeshGradient`)
4-point generative color mesh undulating smoothly across time:
```pascal
function MeshGradient(
  const AColor1, AColor2, AColor3, AColor4: TAlphaColor;
  const ADurationMs: Cardinal = 3000
): IMotionBuilder;
```
```pascal
BackgroundPanel.Motion
  .MeshGradient($FF4F46E5, $FF06B6D4, $FFEC4899, $FF8B5CF6, 3500)
  .RepeatForever(True)
  .Start;
```

---

### 3. Laser Border Beam (`BorderBeam`)
Continuous light runner traversing the perimeter of cards or buttons:
```pascal
function BorderBeam(
  const AColorFrom, AColorTo: TAlphaColor;
  const ABorderWidth: Single = 3.0;
  const ABeamLength: Single = 0.25;
  const ADurationMs: Cardinal = 2000
): IMotionBuilder; overload;

function BorderBeam(
  const AColor: TAlphaColor;
  const ABorderWidth: Single = 3.0;
  const ADurationMs: Cardinal = 2000
): IMotionBuilder; overload;
```

---

### 4. Sinuous Fluid Wave (`LiquidWave`)
Realistic animated liquid body with wave crest highlight:
```pascal
function LiquidWave(
  const ATargetLevel: Single; // Target fill level (0.0 .. 1.0)
  const AColor: TAlphaColor = $CC007ACC;
  const ACrestColor: TAlphaColor = $FFFFFFFF;
  const ADurationMs: Cardinal = 1000
): IMotionBuilder; overload;

function LiquidWave(
  const AFromLevel, ATargetLevel: Single;
  const AColor: TAlphaColor = $CC007ACC;
  const ACrestColor: TAlphaColor = $FFFFFFFF;
  const ADurationMs: Cardinal = 1000
): IMotionBuilder; overload;
```

---

### 5. Water Ripple Distortion (`RippleDistortion`)
Circular refractive shockwave radiating from touch coordinates:
```pascal
function RippleDistortion(
  const ACenter: TPointF;
  const ARippleColor: TAlphaColor = $8000BFFF;
  const AWaveWidth: Single = 24.0;
  const ADurationMs: Cardinal = 600
): IMotionBuilder; overload;
```

---

### 6. Particle Dissolve Burn (`DissolveBurn`)
Noise-driven ember dissolution transition:
```pascal
function DissolveBurn(
  const AEmberColor: TAlphaColor = $FFFF4500;
  const AEmberWidth: Single = 0.08;
  const ANoiseScale: Single = 8.0;
  const ADurationMs: Cardinal = 1500
): IMotionBuilder;
```

---

### 7. Pulsing Neon Glow (`NeonGlow`)
Multi-layered ambient neon outline:
```pascal
function NeonGlow(
  const AGlowColor: TAlphaColor = $FF00FFCC;
  const AGlowRadius: Single = 16.0;
  const APulseSpeed: Single = 4.0;
  const ADurationMs: Cardinal = 1500
): IMotionBuilder;
```

---

### 8. Gooey Fluid Metaballs (`GooeyMetaball`)
Organic fluid droplets merging and separating dynamically:
```pascal
function GooeyMetaball(
  const ABlobColor: TAlphaColor = $DDFF007F;
  const ASpeed: Single = 2.0;
  const ADurationMs: Cardinal = 3000
): IMotionBuilder;
```

---

### 9. Custom SkSL Shader (`CustomShader`)
Inject arbitrary SkSL source code and supply dynamic runtime uniforms:
```pascal
function CustomShader(
  const ASkSL: string;
  const ADurationMs: Cardinal = 1000;
  const ADrawMode: TShaderDrawMode = TShaderDrawMode.Overlay
): IMotionBuilder;

// Uniform chaining:
function Uniform(const AName: string; const AValue: Single): IMotionBuilder; overload;
function Uniform(const AName: string; const AValue: TPointF): IMotionBuilder; overload;
function Uniform(const AName: string; const AValue: TAlphaColor): IMotionBuilder; overload;
function Uniform(const AName: string; const AValue: TArray<Single>): IMotionBuilder; overload;
```

---

## 8. Typography, Complex Arabic Text & KPI Counters

Engineered specifically to overcome text animation limitations in FireMonkey:

<!-- IMAGE_PLACEHOLDER: Typography Demo (Arabic Typewriter with cursor, Numeric Counter, ShimmerText) -->
![Typography & Arabic Motion Demo](docs/images/typography-showcase.gif)

### A. Ligature-Safe Arabic Typewriter (`Typewriter`)
Utilizes `TFluentGraphemeHelper` to preserve Unicode Arabic ligatures and combining marks (Harakat, Tashkeel, Tanween, Shadda), preventing disconnected glyphs or crashes during incremental reveals:
```pascal
function Typewriter(
  const ATargetText: string;
  const ACharDelayMs: Cardinal = 40;
  const ABlinkingCursor: Boolean = True;
  const ACursorChar: Char = '|'
): IMotionBuilder;
```
```pascal
LblWelcome.Motion
  .Typewriter('مَرْحَباً بِكُمْ فِي مَنْظُومَةِ تُولِيبْ...', 45, True, '|')
  .Start;
```

### B. Rolling KPI Numeric Counter (`CountTo`)
Odometer-style smooth number interpolation with currency and percentage formatting:
```pascal
function CountTo(const ATargetValue: Double; const AFormatStr: string = '%0.2f'; const ADurationMs: Cardinal = 1500): IMotionBuilder; overload;
function CountTo(const AFromValue, ATargetValue: Double; const AFormatStr: string = '%0.2f'; const ADurationMs: Cardinal = 1500): IMotionBuilder; overload;
```
```pascal
LblBalance.Motion
  .CountTo(0.0, 1250000.75, '$%0.2f', 1600)
  .WithEase(TFluentEase.OutCubic)
  .Start;
```

### C. Vector Glyph Text Shimmer (`ShimmerText`)
Clips gradient sweeps strictly inside vector font glyph contours, eliminating opaque bounding-box leaks over transparent backgrounds:
```pascal
function ShimmerText(
  const ADurationMs: Cardinal = 1000;
  const ADirection: TShimmerDirection = TShimmerDirection.LeftToRight;
  const AAngleDeg: Single = 20.0
): IMotionBuilder; overload;

function ShimmerText(
  const AHighlightColor: TAlphaColor;
  const ADurationMs: Cardinal;
  const ADirection: TShimmerDirection = TShimmerDirection.LeftToRight;
  const AAngleDeg: Single = 20.0
): IMotionBuilder; overload;
```
```pascal
// Natural right-to-left golden shimmer for Arabic typography:
LblVipTitle.Motion
  .ShimmerText($FFFFD700, 1400, TShimmerDirection.RightToLeft, 20.0)
  .RepeatForever(False)
  .Start;
```

---

## 9. Window & OS Form Motion

Directly animate the operating system window (`TCommonCustomForm`) using `TFluentMotionFormHelper`:

<!-- IMAGE_PLACEHOLDER: Form Motion GIF (Shake Window on error, FadeIn Form, SlideIn Form) -->
![Form Motion Demo](docs/images/form-motion-demo.gif)

```pascal
procedure TLoginForm.OnPasswordFailed;
begin
  // Shake entire OS window with 14px displacement
  Self.Shake(14.0, 380);
end;

procedure TNoticeForm.FormShow(Sender: TObject);
begin
  // Smoothly fade window from transparent to opaque
  Self.FadeIn(300);
end;

procedure TNoticeForm.BtnCloseClick(Sender: TObject);
begin
  // Slide window downwards off-screen and hide
  Self.SlideOut(TTransitionDirection.FromBottom, 250);
end;
```

---

## 10. Analytical Spring Physics & Easing Curves

<!-- IMAGE_PLACEHOLDER: Spring Curves Diagram / Visual Comparison Graph -->
![Spring Physics Comparison](docs/images/spring-curves.png)

### A. Analytical Damped Springs (`TFluentSpring`)
Solves second-order harmonic oscillator differential equations analytically without numerical approximation errors:
```pascal
type
  TFluentSpring = record
    Response: Single;         // Approximate duration in seconds
    DampingFraction: Single;  // Damping ratio (0.0: undamped, 1.0: critical damping)
    Mass: Single;             // Virtual mass (default 1.0)
    
    class function Smooth: TFluentSpring; static;       // (0.45, 0.82, 1.0)
    class function Bouncy: TFluentSpring; static;       // (0.38, 0.52, 1.0)
    class function Snappy: TFluentSpring; static;       // (0.25, 0.90, 1.0)
    class function Interactive: TFluentSpring; static;  // (0.15, 0.86, 1.0)
    constructor Create(const AResponse: Single; const ADampingFraction: Single; const AMass: Single = 1.0);
  end;
```

#### Usage:
```pascal
// 1. Using tuned presets:
CardView.Motion
  .Scale(1.15)
  .WithSpring(TFluentSpring.Bouncy)
  .Start;

// 2. Custom physical tuning:
CardView.Motion
  .Scale(1.15)
  .WithSpring(TFluentSpring.Create(0.30, 0.65, 1.0))
  .Start;
```

### B. Mathematical Easing Curves (`TFluentEase`)
31 standard Penner and Bezier evaluators applied via `.WithEase(TFluentEase.XXX)`:
- `Linear`: Constant velocity.
- `InQuad`, `OutQuad`, `InOutQuad`: Quadratic acceleration/deceleration.
- `InCubic`, `OutCubic`, `InOutCubic`: Cubic curve ideal for view transitions.
- `InQuart`, `OutQuart`, `InOutQuart`: 4th-order polynomial curve.
- `InQuint`, `OutQuint`, `InOutQuint`: 5th-order steep curve.
- `InSine`, `OutSine`, `InOutSine`: Gentle sinusoidal curves for breathing loops.
- `InExpo`, `OutExpo`, `InOutExpo`: Exponential curve.
- `InCirc`, `OutCirc`, `InOutCirc`: Circular arc curve.
- `InBack`, `OutBack`, `InOutBack`: Anticipation retraction and settling overshoot.
- `InElastic`, `OutElastic`, `InOutElastic`: Oscillating elastic string simulation.
- `InBounce`, `OutBounce`, `InOutBounce`: Decaying gravitational bounce.

---

## 11. Motion Pipelines, Sequencing & Runtime Controls

<!-- IMAGE_PLACEHOLDER: Sequencing Pipeline Diagram (Phase 1 -> Wait -> Phase 2 -> OnComplete) -->
![Motion Pipeline Diagram](docs/images/pipeline-diagram.png)

### A. Phase Sequencing (`.&Then` and `.Wait`)
The `.&Then` operator finalizes the active concurrent phase barrier and begins a subsequent phase:
```pascal
DialogCard.Motion
  // Phase 1: Concurrently scale and fade in
  .Scale(0.8, 1.0, 300).WithSpring(TFluentSpring.Bouncy)
  .FadeIn(250)
  .&Then
  // Non-blocking 300ms pause
  .Wait(300)
  .&Then
  // Phase 2: Laser perimeter sweep
  .BorderBeam($FF00E5FF, $FF9D4EDD, 3.0, 0.25, 1500)
  .&Then
  // Phase 3: Typewriter greeting
  .Typewriter('Authentication successful!', 35)
  .OnComplete(procedure
    begin
      ShowMessage('All sequence phases completed!');
    end)
  .Start;
```

### B. Callbacks
- `OnProgress(reference to procedure(const AProgress: Single))`: Receives normalized progress `(0.0 .. 1.0)` on every frame tick.
- `OnComplete(reference to procedure)`: Dispatched when all phases complete and the driver stops.

### C. Runtime Playback Controls
- `Speed(Value)`: Dynamic speed multiplier (e.g. `2.0` for 2x, `0.5` for half-speed).
- `Pause` / `Resume`: Freezes execution at current frame with 0% CPU consumption and resumes without timing drift.
- `Seek(Progress)`: Instant scrubbing to normalized timeline position.
- `Stop`: Stops motion at current state.
- `Reset`: Halts motion and restores pre-animation control properties.
- `RepeatCount(N)`: Cycles exact $N$ iterations.
- `RepeatForever(Autoreverse)`: Infinite loop with smooth ping-pong reversal.

---

## 12. Memory Management & High-Performance Best Practices

<!-- IMAGE_PLACEHOLDER: Memory Leaks Verification Proof (0 Leaks / DUnitX) Screenshot -->
![Zero Leaks Proof](docs/images/zero-leaks.png)

1. **Never Call `.Free` on `IMotionBuilder` Instances:**
   Builders are reference-counted interfaces. The singleton engine (`TFluentMotionEngine`) cleans up effects automatically upon completion with 0 memory leaks (`Tests Leaked : 0`).

2. **Prefer `TRectangle` over `TButton` for Liquid Glass Cards:**
   Standard `TButton` controls use opaque stylesheets that can obscure background pixels. For purest glass refraction, use a `TRectangle` with `HitTest := True`, `Cursor := crHandPoint`, and embed a transparent `TLabel`.

3. **Mobile Battery Conservation:**
   `TFluentMotionEngine` integrates with `IFMXApplicationEventService`. When an app moves to background (`EnteredBackground`) on Android or iOS, the ticker suspends immediately to conserve battery and avoid OS watchdog termination, automatically resuming when the app re-enters foreground.
