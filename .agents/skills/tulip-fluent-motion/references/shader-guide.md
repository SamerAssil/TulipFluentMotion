# TulipFluentMotion: Skia Runtime Shaders & SkSL Guide

A comprehensive guide for authoring, binding, and controlling Skia Runtime Shaders (SkSL) in Delphi FMX using `TulipFluentMotion`.

---

## 1. Built-in Automatic Uniforms

When `TulipFluentMotion` compiles and renders any SkSL runtime effect, it automatically provides standard uniforms so you do not need to calculate or supply them manually:

| Uniform Name | Type | Description |
| :--- | :--- | :--- |
| `iResolution` | `uniform vec2` | Width and height of the host control in physical pixels. |
| `iTime` | `uniform float` | Continuous elapsed time in seconds (monotonically increasing). |
| `iCornerRadius` | `uniform float` | Extracted corner radius of the host control (if `TRectangle`). |

---

## 2. Built-In Preset Directory

### 1. Liquid Glass (`.LiquidGlass`)
Simulates realistic refractive glass optics inspired by Apple iOS 18 glass cards.
- **Preset Styles (`TFluentGlassStyle`)**:
  - `TFluentGlassStyle.ClearLiquid`: High clarity, sharp refraction, minimal chromatic dispersion.
  - `TFluentGlassStyle.Frosted`: Balanced frosted blur with subtle highlight borders.
  - `TFluentGlassStyle.DynamicIsland`: Deep obsidian gloss with strong specular edge reflections.
  - `TFluentGlassStyle.HeavyPrism`: Strong RGB split (chromatic aberration) along edges.
- **Custom Parametric Call**:
  ```pascal
  Card.Motion.LiquidGlass(
    ARefrMagnitude, // e.g. 14.0 (refraction strength)
    AAberration,    // e.g. 0.08 (chromatic aberration offset)
    ABlurRadius,    // e.g. 0.8 (inner blur diffusion)
    AGlowIntensity, // e.g. 0.40 (ambient specular glow)
    2000            // Duration in ms
  ).Start;
  ```

### 2. Border Beam (`.BorderBeam`)
Draws a high-tech laser beam traveling around the rounded border contour of any control:
```pascal
Card.Motion
  .BorderBeam(
    TAlphaColors.Cyan,       // Start color
    TAlphaColors.Magenta,    // End color
    3.0,                     // Border width in pixels
    0.30,                    // Beam length fraction (0.1 .. 0.5)
    2000                     // Loop cycle duration in ms
  )
  .RepeatForever(False)
  .Start;
```

### 3. Liquid Wave Fill (`.LiquidWave`)
Renders an undulating organic water or fluid fill rising to a target level:
```pascal
// Fill container up to 75% height
WaveContainer.Motion
  .LiquidWave(
    0.75,                     // Target fill level (0.0 .. 1.0)
    $CC007ACC,                // Main water body color
    $FFFFFFFF,                // Wave foam / crest highlight color
    1500                      // Duration to reach level
  )
  .Start;
```
*Note: Once the water level reaches target, the ambient fluid ripples continue undulating smoothly in the background because `TulipFluentMotion` marks it as a continuous effect.*

### 4. Neon Glow (`.NeonGlow`)
Creates a pulsating neon outer illumination:
```pascal
IconGlow.Motion
  .NeonGlow(
    $FF00FFCC,  // Neon teal glow color
    20.0,       // Glow radius in pixels
    4.0,        // Pulse frequency speed
    1500        // Duration
  )
  .RepeatForever(True)
  .Start;
```

### 5. Mesh Gradient (`.MeshGradient`)
Generates a smooth, organic 4-point color mesh that flows gently over time:
```pascal
BackgroundRect.Motion
  .MeshGradient(
    $FF4158D0,
    $FFC850C0,
    $FFFFCC70,
    $FF0093E9,
    4000
  )
  .RepeatForever(True)
  .Start;
```

---

## 3. Authoring Custom SkSL Shaders

You can provide raw SkSL code directly to `.CustomShader(...)`.

### Custom SkSL Template
```pascal
const
  MY_CUSTOM_SKSL =
    'uniform vec2 iResolution;' + sLineBreak +
    'uniform float iTime;' + sLineBreak +
    'uniform float uSpeed;' + sLineBreak +
    'uniform vec4 uBaseColor;' + sLineBreak +
    'half4 main(vec2 fragCoord) {' + sLineBreak +
    '    vec2 uv = fragCoord / iResolution;' + sLineBreak +
    '    float wave = sin(uv.x * 10.0 + iTime * uSpeed) * 0.5 + 0.5;' + sLineBreak +
    '    return half4(uBaseColor.rgb * wave, uBaseColor.a * wave);' + sLineBreak +
    '}';

procedure TMainForm.ApplyMyShader;
begin
  PanelVisual.Motion
    .CustomShader(MY_CUSTOM_SKSL, 2000, TShaderDrawMode.Overlay)
    .Uniform('uSpeed', 3.0)
    .Uniform('uBaseColor', TAlphaColors.Deepskyblue)
    .RepeatForever(False)
    .Start;
end;
```

### Supported Uniform Types
- **Single Float**: `.Uniform('uFloat', 1.25)`
- **2D Vector / Point**: `.Uniform('uCenter', PointF(0.5, 0.5))`
- **Color (`TAlphaColor`)**: `.Uniform('uTint', $80FF0000)` *(Automatically converted to normalized `vec4(r, g, b, a)`)*
- **Float Array**: `.Uniform('uWeights', [0.1, 0.5, 0.9])`

### Draw Modes (`TShaderDrawMode`)
- `TShaderDrawMode.Overlay`: Paints on top of the host control's children.
- `TShaderDrawMode.Background`: Paints behind the host control (`SendToBack`).
- `TShaderDrawMode.Filter`: Applied as a raster effect pass.
