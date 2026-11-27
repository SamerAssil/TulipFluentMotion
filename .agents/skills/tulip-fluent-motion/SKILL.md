---
name: tulip-fluent-motion
description: Use when building animations, micro-interactions, physics motion, Skia runtime shaders, typography effects, or Windows 11 Fluent backdrops (Mica/Acrylic) in Delphi FireMonkey (FMX) applications using the TulipFluentMotion library.
---

# TulipFluentMotion: Delphi FMX & Skia Motion Engine

`TulipFluentMotion` is a declarative, hardware-accelerated motion and UI physics engine for **Delphi 13 Athens (`VER370`+)** FireMonkey (FMX) and Skia. It provides SwiftUI-parity declarative syntax, spring physics, Skia runtime shaders (SkSL), typography animations (Arabic cluster-aware), and native Windows 11 Fluent backdrops (Mica & Acrylic).

---

## 1. Mental Model & Architecture

Understanding how `TulipFluentMotion` works guarantees correct and idiomatic code:

```
[ Your TControl or Form ]
         │
         ├── Attached Driver (Companion Pattern)
         │     ├── TFluentMotionDriver (for TControl: Align=Contents, HitTest=False, Locked=True)
         │     └── TFluentMotionFormDriver (for TCommonCustomForm: Windows DWM & Form transforms)
         │
         ├── Heartbeat Engine (TFluentMotionEngine Singleton)
         │     ├── 60 FPS (~16ms) High-precision timer via TStopwatch
         │     ├── Auto-suspends on mobile backgrounding (EnteredBackground)
         │     └── Snapshot execution with crash-isolation
         │
         └── Phase System (IMotionPhase)
               ├── Single Phase = Concurrent/Parallel execution of all chained effects
               └── .&Then = Sequential phase boundary (Phase 1 finishes ➔ Phase 2 starts)
```

### Key Principles
1. **Zero Component Dropping**: No components need to be placed at design-time on forms or data modules. Everything is invoked via code.
2. **Companion Driver**: Calling `.Motion` or any one-liner automatically attaches an invisible, lightweight driver control to the target.
3. **ARC Interface Lifetime**: Builders (`IMotionBuilder`), phases (`IMotionPhase`), and effects (`IMotionEffect`) are ref-counted interfaces. Never attempt to manually free them.
4. **Layout Alignment Safety**: If a control has `Align <> TAlignLayout.None`, the library automatically freezes and overrides layout constraints during translation/resizing, restoring alignment when complete.

---

## 2. Setup & DPR Initialization

### Project File (`.dpr`) Setup
For full hardware acceleration, Skia runtime shaders, and backdrop refraction, enable Skia **before** `Application.Initialize`:

```pascal
program MyProject;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,             // <--- Required for Skia
  UnitMain in 'UnitMain.pas' {MainForm};

{$R *.res}

begin
  GlobalUseSkia := True; // <--- MUST be before Application.Initialize
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
```

### Unit Uses Clause
In any form or frame unit where animations are used, include a single unit:

```pascal
uses
  Tulip.FluentMotion;
```
*Note: `Tulip.FluentMotion` re-exports all core interfaces, types, enums, shaders, and class helpers for `TControl` and `TCommonCustomForm`.*

---

## 3. Core API Styles: One-Liners vs. Fluent Builder

### Style A: Instant One-Liners (Micro-Interactions)
Every `TControl` has built-in helper methods that start immediately:

```pascal
// Instant feedback
ButtonSubmit.PopIn(250);
EditPassword.Shake(10.0, 350);
CardNotification.Pulse(1.10, 250);
PanelOverlay.FadeIn(200);
BadgeCount.Bounce(14.0, 300);
IconSetting.Wiggle(3.0, 350);

// Visual filters & one-liners
CardSurface.Shadow(6.0, 0.35, 0.45, 250);
CardSurface.Elevation(2.0, 200); // Level 0..4
PanelGlass.FrostedGlass($40FFFFFF, 0.8, 500);
CardModern.LiquidGlass(TFluentGlassStyle.Frosted, 2000);
```

### Style B: Declarative Fluent Builder (`.Motion`)
For customized timing, physics, anchors, callbacks, and multi-stage sequences:

```pascal
ButtonOrder.Motion
  .Anchor(TMotionAnchor.Center)
  .Scale(0.92, 120)
  .WithEase(TFluentEase.OutQuad)
  .&Then                             // <--- Switch to next phase (Sequential)
  .Scale(1.0, 300)
  .WithSpring(TFluentSpring.Bouncy)
  .OnComplete(procedure
    begin
      ShowMessage('Order processed!');
    end)
  .Start;
```

---

## 4. Parallel vs. Sequential Execution

This is the most critical rule of the fluent builder:

* **Effects chained together run in PARALLEL (Concurrent Phase):**
  ```pascal
  // Scale and Fade happen at the same time:
  Card.Motion
    .Scale(1.05, 300)
    .Fade(0.85, 300)
    .Start;
  ```

* **Use `.&Then` to separate SEQUENTIAL Phases:**
  ```pascal
  // Step 1: Slide in and fade in
  // Step 2: Pause 500ms
  // Step 3: Fade out and slide away
  Banner.Motion
    .SlideIn(TTransitionDirection.FromTop, 0, 350)
    .FadeIn(350)
    .&Then
    .Wait(500)
    .&Then
    .SlideOut(TTransitionDirection.FromTop, 0, 300)
    .FadeOut(300)
    .Start;
  ```

---

## 5. Springs Physics & Easing Curves

### SwiftUI-Parity Spring Physics
Use `.WithSpring(...)` for natural, organic motion:

```pascal
// Pre-tuned factory presets:
.WithSpring(TFluentSpring.Smooth)      // Gentle, minimal overshoot (response: 0.45, damping: 0.82)
.WithSpring(TFluentSpring.Bouncy)      // Dynamic, fun overshoot (response: 0.38, damping: 0.52)
.WithSpring(TFluentSpring.Snappy)      // Quick, responsive UI feel (response: 0.25, damping: 0.90)
.WithSpring(TFluentSpring.Interactive) // Ultra-fast direct touch tracking (response: 0.15, damping: 0.86)

// Custom physics:
.WithSpring(TFluentSpring.Create(AResponseSec, ADampingFraction, AMass));
```

### Standard Easing Curves (`TFluentEase`)
Use `.WithEase(...)` for mathematical interpolation:

```pascal
TFluentEase = (
  Linear,
  InQuad, OutQuad, InOutQuad,
  InCubic, OutCubic, InOutCubic,
  InQuart, OutQuart, InOutQuart,
  InQuint, OutQuint, InOutQuint,
  InSine, OutSine, InOutSine,
  InExpo, OutExpo, InOutExpo,
  InCirc, OutCirc, InOutCirc,
  InBack, OutBack, InOutBack,       // Overshoot curves
  InElastic, OutElastic, InOutElastic,
  InBounce, OutBounce, InOutBounce  // Ground bounce curves
);
```

---

## 6. Motion Anchors (`TMotionAnchor`)

Anchors determine the fixed origin point around which transformations (Scale, Rotate, Resize, Flip3D, Pulse, Wiggle, Pop, Ripple) take place:

```
TopLeft    (0.0, 0.0) ─── TopCenter    (0.5, 0.0) ─── TopRight    (1.0, 0.0)
      │                                                     │
CenterLeft (0.0, 0.5) ─── Center       (0.5, 0.5) ─── CenterRight (1.0, 0.5)  <-- Default
      │                                                     │
BottomLeft (0.0, 1.0) ─── BottomCenter (0.5, 1.0) ─── BottomRight (1.0, 1.0)
```

Example: Scaling a dropdown or popup from its top-right corner:
```pascal
PopupMenu.Motion
  .Anchor(TMotionAnchor.TopRight)
  .Scale(0.0, 1.0, 250)
  .FadeIn(200)
  .WithSpring(TFluentSpring.Snappy)
  .Start;
```

---

## 7. Skia Runtime Shaders & GPU Presets

TulipFluentMotion includes built-in hardware-accelerated SkSL runtime shaders:

| Preset | Method | Visual Effect |
| :--- | :--- | :--- |
| **Liquid Glass** | `.LiquidGlass(style, duration)` | iOS 18 / macOS dynamic optical refraction with chromatic dispersion & blur |
| **Border Beam** | `.BorderBeam(colorFrom, colorTo, width, length, duration)` | High-tech moving laser beam tracing around rounded borders |
| **Frosted Glass** | `.FrostedGlass(tintColor, borderLight, duration)` | Modern semi-transparent acrylic/frosted glass surface |
| **Liquid Wave** | `.LiquidWave(targetLevel, color, crestColor, duration)` | Animated fluid water level filling up a container |
| **Neon Glow** | `.NeonGlow(glowColor, radius, pulseSpeed, duration)` | Pulsating cyberpunk neon outer aura |
| **Mesh Gradient** | `.MeshGradient(c1, c2, c3, c4, duration)` | Flowing 4-point generative color gradient |
| **Dissolve Burn** | `.DissolveBurn(emberColor, emberWidth, noiseScale, duration)` | Sci-fi burn away / disintegration with glowing embers |
| **Ripple Distortion** | `.RippleDistortion(center, rippleColor, waveWidth, duration)` | Optical water refraction shockwave |
| **Gooey Metaball** | `.GooeyMetaball(blobColor, speed, duration)` | Organic fluid blobs merging and separating |

### Liquid Glass Styles (`TFluentGlassStyle`)
- `TFluentGlassStyle.ClearLiquid`: Ultra-clear optical liquid lens.
- `TFluentGlassStyle.Frosted`: iOS / macOS frosted matte glass.
- `TFluentGlassStyle.DynamicIsland`: High-specular polished lens.
- `TFluentGlassStyle.HeavyPrism`: Heavy crystal prism with rainbow chromatic aberration.

### Custom SkSL Shader Example:
```pascal
PanelCustom.Motion
  .CustomShader(MY_SKSL_CODE, 2000, TShaderDrawMode.Overlay)
  .Uniform('uSpeed', 1.5)
  .Uniform('uCenter', PointF(0.5, 0.5))
  .Uniform('uHighlight', $FFFF0080)
  .Start;
```

---

## 8. Typography & Arabic Motion

### 1. Numeric Counter (`CountTo`)
Animates numbers, currencies, and percentages smoothly on `TText`, `TLabel`, `TSkLabel`, or any control exposing a `Text` property:
```pascal
// Automatically reads current value from text and animates to 15450.75
LabelBalance.Motion
  .CountTo(15450.75, '$%0.2f', 2000)
  .WithEase(TFluentEase.OutExpo)
  .Start;

// Or explicitly from-to:
LabelCounter.CountTo(0, 100, '%0.0f%%', 1200);
```

### 2. Arabic Cluster-Safe Typewriter (`Typewriter`)
Standard substring typing breaks Arabic connected letters and Tashkeel (diacritics). TulipFluentMotion uses `TFluentGraphemeHelper.SplitGraphemes` to guarantee valid Arabic glyph shaping and connected letters:
```pascal
LabelGreeting.Motion
  .Typewriter('مرحباً بك في نظام Tulip Fluent Motion الفائق!', 35, True, '|')
  .WithEase(TFluentEase.Linear)
  .Start;
```

### 3. Text Shimmer (`ShimmerText`)
Sweeps a light gradient masked strictly to the text contours (not the whole bounding box):
```pascal
LabelTitle.Motion
  .ShimmerText(TShimmerDirection.LeftToRight, 1200, 20.0)
  .RepeatForever(True)
  .Start;
```

---

## 9. Form Motion & Windows 11 Fluent Backdrops

`TCommonCustomForm` has its own dedicated driver `TFluentMotionFormDriver` accessible directly via class helper methods:

```pascal
// 1. Windows 11 Backdrops (Mica & Acrylic)
FormMain.Mica(False);         // Standard Mica (subtle desktop wallpaper blend)
FormMain.Mica(True);          // Mica Alt (tabbed style, higher contrast)
FormMain.Acrylic($60202020);  // Acrylic Blur Behind with custom dark tint
FormMain.HideTitleBar;        // Extends client area into title bar with smooth caption dragging

// 2. Window Shake (Error / Password rejected)
FormMain.Shake(12.0, 380);

// 3. Window Transitions
FormLogin.FadeIn(250);
FormDialog.PopIn(350);
FormDialog.SlideIn(TTransitionDirection.FromBottom, 300);

// 4. Smooth Animated Form Close
procedure TMainForm.BtnCloseClick(Sender: TObject);
begin
  FadeOut(250, procedure
    begin
      Close;
    end);
end;
```

---

## 10. Common UI Interaction Patterns (Recipes)

### Recipe 1: Modern Button Hover & Press (iOS / macOS Feel)
```pascal
procedure TForm1.BtnActionMouseEnter(Sender: TObject);
begin
  TControl(Sender).Motion
    .Scale(1.04, 160)
    .WithSpring(TFluentSpring.Snappy)
    .Start;
end;

procedure TForm1.BtnActionMouseLeave(Sender: TObject);
begin
  TControl(Sender).Motion
    .Scale(1.0, 180)
    .WithEase(TFluentEase.OutQuad)
    .Start;
end;

procedure TForm1.BtnActionMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    TControl(Sender).Motion.Scale(0.96, 90).WithEase(TFluentEase.OutQuad).Start;
end;

procedure TForm1.BtnActionMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    TControl(Sender).Motion.Scale(1.04, 200).WithSpring(TFluentSpring.Bouncy).Start;
end;
```

### Recipe 2: Touch / Click Water Ripple
```pascal
procedure TForm1.CardSurfaceClick(Sender: TObject);
var
  LocalPos: TPointF;
  Ctrl: TControl;
  RConfig: TFluentRippleConfig;
begin
  Ctrl := Sender as TControl;
  LocalPos := Ctrl.ScreenToLocal(Screen.MousePos);

  RConfig := TFluentRippleConfig.Default;
  RConfig.Origin := LocalPos;
  RConfig.AutoCenter := False;
  RConfig.RippleColor := $40007ACC; // Fluent blue with alpha

  Ctrl.Motion.Ripple(RConfig, 400).Start;
end;
```

### Recipe 3: Staggered List Entrance (Fly-In)
When opening a form or loading data, stagger items smoothly:
```pascal
procedure TForm1.AnimateListItems;
var
  I: Integer;
  Item: TControl;
begin
  for I := 0 to VertScrollBox1.Content.ChildrenCount - 1 do
  begin
    if VertScrollBox1.Content.Children[I] is TControl then
    begin
      Item := TControl(VertScrollBox1.Content.Children[I]);
      Item.Opacity := 0.0;
      Item.Motion
        .Delay(I * 45) // <--- Stagger delay per item
        .SlideIn(TTransitionDirection.FromBottom, 40, 300)
        .FadeIn(250)
        .WithSpring(TFluentSpring.Snappy)
        .Start;
    end;
  end;
end;
```

---

## 11. Golden Rules & Pitfalls for AI Agents

1. **NEVER use standard `TTimer` for UI animations**:
   Always use `TulipFluentMotion`. The library coordinates everything with a single 60 FPS heartbeat and sub-pixel interpolation.
2. **NEVER chain multiple `.Start` calls for sequencing**:
   Do NOT write:
   ```pascal
   // WRONG!
   Card.Motion.Scale(1.2).Start;
   Sleep(200); // Or timer
   Card.Motion.Scale(1.0).Start;
   ```
   Instead, use `.&Then`:
   ```pascal
   // CORRECT
   Card.Motion.Scale(1.2, 200).&Then.Scale(1.0, 200).Start;
   ```
3. **NEVER manually free `IMotionBuilder` or drivers**:
   `IMotionBuilder` is an ARC interface. Assigning or chaining it cleans itself up automatically.
4. **DO NOT fight the FMX Alignment Engine**:
   When using `.Move(...)` or `.ResizeTo(...)` on a control with `Align = Client` or `Align = Top`, `TulipFluentMotion` automatically detaches and manages the layout override during motion. Do not write manual position hacks.
5. **Remember `GlobalUseSkia := True`**:
   Before initializing the application in the `.dpr`, ensure `GlobalUseSkia := True;` is present so SkSL shaders and Skia paint effects compile and render properly.
6. **Cancellation**:
   To immediately stop an in-flight animation on any control, call:
   ```pascal
   MyControl.StopMotion;
   // Or reset back to baseline:
   MyControl.ResetMotion;
   ```

---

## 12. Reference Files

For in-depth APIs and advanced shader creation, see:
- [API Reference](references/api-reference.md) — Comprehensive method signatures and parameters.
- [Recipes & UI Patterns](references/recipes.md) — Full copy-paste ready Delphi FMX forms and components.
- [Shader Guide](references/shader-guide.md) — SkSL authoring, uniform binding, and custom shaders.
