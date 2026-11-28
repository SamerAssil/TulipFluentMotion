{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Types
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MIT (SPDX-License-Identifier: MIT)
*******************************************************************************}
unit Tulip.FluentMotion.Types;

interface

uses
  System.SysUtils,
  System.Math,
  System.Types,
  System.UITypes;

type
  { Easing Curve Types }
  TFluentEase = (
    Linear,
    InQuad,
    OutQuad,
    InOutQuad,
    InCubic,
    OutCubic,
    InOutCubic,
    InQuart,
    OutQuart,
    InOutQuart,
    InQuint,
    OutQuint,
    InOutQuint,
    InSine,
    OutSine,
    InOutSine,
    InExpo,
    OutExpo,
    InOutExpo,
    InCirc,
    OutCirc,
    InOutCirc,
    InBack,
    OutBack,
    InOutBack,
    InElastic,
    OutElastic,
    InOutElastic,
    InBounce,
    OutBounce,
    InOutBounce
  );

  { Spring Physics Configuration (SwiftUI-compatible response & dampingFraction) }
  TFluentSpring = record
  private
    FResponse: Single;         // Approximate duration of the spring motion in seconds
    FDampingFraction: Single; // 0.0: undamped (infinite oscillations), 1.0: critically damped (no overshoot)
    FStiffness: Single;       // Angular frequency squared
    FDamping: Single;         // Damping coefficient
    FMass: Single;
  public
    constructor Create(const AResponse: Single; const ADampingFraction: Single; const AMass: Single = 1.0);

    class function Smooth: TFluentSpring; static;
    class function Bouncy: TFluentSpring; static;
    class function Snappy: TFluentSpring; static;
    class function Interactive: TFluentSpring; static;

    { Solves the spring position at elapsed time t (seconds) from 0.0 to 1.0 target }
    function Solve(const AElapsedTimeSec: Single): Single;

    property Response: Single read FResponse;
    property DampingFraction: Single read FDampingFraction;
    property Stiffness: Single read FStiffness;
    property Damping: Single read FDamping;
    property Mass: Single read FMass;
  end;

  { Easing Evaluator Function }
  TFluentEaseEvaluator = class
  public
    class function Evaluate(const AEase: TFluentEase; const T: Single): Single; static;
  end;

  { Shimmer Flow Direction }
  TShimmerDirection = (
    LeftToRight,
    RightToLeft,
    TopToBottom,
    BottomToTop
  );

  { Shimmer Color Configuration }
  TFluentShimmerConfig = record
    HighlightColor: TAlphaColor;
    BaseColor: TAlphaColor;
    BandWidth: Single; // Fraction of control width (e.g. 0.4)
    AngleDeg: Single;  // Tilt angle (e.g. 25.0)
    Direction: TShimmerDirection;
    MaskToText: Boolean;
    class function Default: TFluentShimmerConfig; static;
    class function TextDefault: TFluentShimmerConfig; static;
  end;

  { Ripple Configuration }
  TFluentRippleConfig = record
    RippleColor: TAlphaColor;
    Origin: TPointF;
    AutoCenter: Boolean;
    MaxRadiusFraction: Single; // Multiplier of max(width, height)
    class function Default: TFluentRippleConfig; static;
  end;

  { Flip 3D Axis }
  TFlipAxis = (Horizontal, Vertical);

  { Transition Direction }
  TTransitionDirection = (FromLeft, FromRight, FromTop, FromBottom);

  { Motion Anchor Point (9 standard points + Custom) }
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
    Custom        // Custom user-defined point
  );

  { Backward compatibility alias }
  TResizeAnchor = TMotionAnchor;

  { Helper for TMotionAnchor }
  TMotionAnchorHelper = record helper for TMotionAnchor
  public
    function ToPointF: TPointF; overload;
    function ToPointF(const ACustomPoint: TPointF): TPointF; overload;
  end;

  { Color Interpolation Helper }
  TFluentColorHelper = record
  public
    class function Lerp(const AFromColor, AToColor: TAlphaColor; const T: Single): TAlphaColor; static;
  end;

  { Shader Drawing / Compositing Mode }
  TShaderDrawMode = (Overlay, Background, Filter);

  { Shader Preset Types }
  TShaderPreset = (
    BorderBeam,
    LiquidWave,
    FrostedGlass,
    MeshGradient,
    DissolveBurn,
    RippleDistortion,
    NeonGlow,
    GooeyMetaball,
    Glass,
    LiquidGlass,
    LiquidGlassGroup
  );

  { Liquid Glass Visual Preset Styles }
  TFluentGlassStyle = (
    ClearLiquid,    // Shadertoy 3cdXDX ultra-clear liquid optics (Refr: 14.0, Aberr: 0.08, Blur: 0.8, Glow: 0.40)
    Frosted,        // iOS / macOS Frosted matte glass (Refr: 18.0, Aberr: 0.12, Blur: 2.5, Glow: 0.25)
    DynamicIsland,  // High-specular polished lens (Refr: 10.0, Aberr: 0.05, Blur: 0.3, Glow: 0.50)
    HeavyPrism      // Crystal prism with chromatic dispersion (Refr: 24.0, Aberr: 0.25, Blur: 1.2, Glow: 0.35)
  );

implementation

{ TFluentSpring }

constructor TFluentSpring.Create(const AResponse: Single; const ADampingFraction: Single; const AMass: Single);
var
  W0: Single;
begin
  FMass := Max(0.01, AMass);
  FResponse := Max(0.05, AResponse);
  FDampingFraction := Max(0.0, ADampingFraction);

  // Angular frequency (w0 = 2 * pi / response)
  W0 := (2.0 * Pi) / FResponse;
  // Stiffness (k = m * w0^2)
  FStiffness := FMass * Sqr(W0);
  // Damping (c = 2 * m * dampingFraction * w0)
  FDamping := 2.0 * FMass * FDampingFraction * W0;
end;

class function TFluentSpring.Smooth: TFluentSpring;
begin
  Result := TFluentSpring.Create(0.45, 0.82, 1.0);
end;

class function TFluentSpring.Bouncy: TFluentSpring;
begin
  Result := TFluentSpring.Create(0.38, 0.52, 1.0);
end;

class function TFluentSpring.Snappy: TFluentSpring;
begin
  Result := TFluentSpring.Create(0.25, 0.90, 1.0);
end;

class function TFluentSpring.Interactive: TFluentSpring;
begin
  Result := TFluentSpring.Create(0.15, 0.86, 1.0);
end;

function TFluentSpring.Solve(const AElapsedTimeSec: Single): Single;
var
  T, W0, DampedW, Decay, CosTerm, SinTerm: Single;
begin
  if AElapsedTimeSec <= 0.0 then
    Exit(0.0);

  T := AElapsedTimeSec;
  W0 := Sqrt(FStiffness / FMass);

  if FDampingFraction < 1.0 then
  begin
    // Under-damped (harmonic oscillation with decay)
    DampedW := W0 * Sqrt(1.0 - Sqr(FDampingFraction));
    Decay := Exp(-FDampingFraction * W0 * T);
    CosTerm := Cos(DampedW * T);
    SinTerm := Sin(DampedW * T);
    // Position from 0 to 1
    Result := 1.0 - Decay * (CosTerm + ((FDampingFraction * W0) / DampedW) * SinTerm);
  end
  else if SameValue(FDampingFraction, 1.0, 0.001) then
  begin
    // Critically damped (fastest return without oscillation)
    Decay := Exp(-W0 * T);
    Result := 1.0 - Decay * (1.0 + W0 * T);
  end
  else
  begin
    // Over-damped (no oscillation, slower return)
    DampedW := W0 * Sqrt(Sqr(FDampingFraction) - 1.0);
    Decay := Exp(-FDampingFraction * W0 * T);
    Result := 1.0 - Decay * (Cosh(DampedW * T) + ((FDampingFraction * W0) / DampedW) * Sinh(DampedW * T));
  end;
end;

{ TFluentEaseEvaluator }

class function TFluentEaseEvaluator.Evaluate(const AEase: TFluentEase; const T: Single): Single;
var
  ClampedT, P, S: Single;
begin
  ClampedT := EnsureRange(T, 0.0, 1.0);

  case AEase of
    Linear:
      Result := ClampedT;

    InQuad:
      Result := Sqr(ClampedT);

    OutQuad:
      Result := ClampedT * (2.0 - ClampedT);

    InOutQuad:
      if ClampedT < 0.5 then
        Result := 2.0 * Sqr(ClampedT)
      else
        Result := -1.0 + (4.0 - 2.0 * ClampedT) * ClampedT;

    InCubic:
      Result := ClampedT * ClampedT * ClampedT;

    OutCubic:
      begin
        P := ClampedT - 1.0;
        Result := P * P * P + 1.0;
      end;

    InOutCubic:
      if ClampedT < 0.5 then
        Result := 4.0 * ClampedT * ClampedT * ClampedT
      else
      begin
        P := 2.0 * ClampedT - 2.0;
        Result := 0.5 * P * P * P + 1.0;
      end;

    InQuart:
      Result := Sqr(Sqr(ClampedT));

    OutQuart:
      begin
        P := ClampedT - 1.0;
        Result := 1.0 - Sqr(Sqr(P));
      end;

    InOutQuart:
      if ClampedT < 0.5 then
        Result := 8.0 * Sqr(Sqr(ClampedT))
      else
      begin
        P := ClampedT - 1.0;
        Result := 1.0 - 8.0 * Sqr(Sqr(P));
      end;

    InQuint:
      Result := ClampedT * Sqr(Sqr(ClampedT));

    OutQuint:
      begin
        P := ClampedT - 1.0;
        Result := 1.0 + P * Sqr(Sqr(P));
      end;

    InOutQuint:
      if ClampedT < 0.5 then
        Result := 16.0 * ClampedT * Sqr(Sqr(ClampedT))
      else
      begin
        P := 2.0 * ClampedT - 2.0;
        Result := 0.5 * P * Sqr(Sqr(P)) + 1.0;
      end;

    InSine:
      Result := 1.0 - Cos(ClampedT * (Pi * 0.5));

    OutSine:
      Result := Sin(ClampedT * (Pi * 0.5));

    InOutSine:
      Result := 0.5 * (1.0 - Cos(Pi * ClampedT));

    InExpo:
      if SameValue(ClampedT, 0.0) then
        Result := 0.0
      else
        Result := Power(2.0, 10.0 * (ClampedT - 1.0));

    OutExpo:
      if SameValue(ClampedT, 1.0) then
        Result := 1.0
      else
        Result := 1.0 - Power(2.0, -10.0 * ClampedT);

    InOutExpo:
      if SameValue(ClampedT, 0.0) then
        Result := 0.0
      else if SameValue(ClampedT, 1.0) then
        Result := 1.0
      else if ClampedT < 0.5 then
        Result := 0.5 * Power(2.0, 20.0 * ClampedT - 10.0)
      else
        Result := 1.0 - 0.5 * Power(2.0, -20.0 * ClampedT + 10.0);

    InCirc:
      Result := 1.0 - Sqrt(Max(0.0, 1.0 - Sqr(ClampedT)));

    OutCirc:
      Result := Sqrt(Max(0.0, 1.0 - Sqr(ClampedT - 1.0)));

    InOutCirc:
      if ClampedT < 0.5 then
        Result := 0.5 * (1.0 - Sqrt(Max(0.0, 1.0 - 4.0 * Sqr(ClampedT))))
      else
        Result := 0.5 * (Sqrt(Max(0.0, 1.0 - Sqr(-2.0 * ClampedT + 2.0))) + 1.0);

    InBack:
      begin
        S := 1.70158;
        Result := ClampedT * ClampedT * ((S + 1.0) * ClampedT - S);
      end;

    OutBack:
      begin
        S := 1.70158;
        P := ClampedT - 1.0;
        Result := P * P * ((S + 1.0) * P + S) + 1.0;
      end;

    InOutBack:
      begin
        S := 1.70158 * 1.525;
        if ClampedT < 0.5 then
          Result := 0.5 * (4.0 * Sqr(ClampedT) * ((S + 1.0) * 2.0 * ClampedT - S))
        else
        begin
          P := 2.0 * ClampedT - 2.0;
          Result := 0.5 * (P * P * ((S + 1.0) * P + S) + 2.0);
        end;
      end;

    InElastic:
      if SameValue(ClampedT, 0.0) then
        Result := 0.0
      else if SameValue(ClampedT, 1.0) then
        Result := 1.0
      else
      begin
        P := 0.3;
        S := P / 4.0;
        Result := -Power(2.0, 10.0 * (ClampedT - 1.0)) * Sin((ClampedT - 1.0 - S) * (2.0 * Pi) / P);
      end;

    OutElastic:
      if SameValue(ClampedT, 0.0) then
        Result := 0.0
      else if SameValue(ClampedT, 1.0) then
        Result := 1.0
      else
      begin
        P := 0.3;
        S := P / 4.0;
        Result := Power(2.0, -10.0 * ClampedT) * Sin((ClampedT - S) * (2.0 * Pi) / P) + 1.0;
      end;

    InOutElastic:
      if SameValue(ClampedT, 0.0) then
        Result := 0.0
      else if SameValue(ClampedT, 1.0) then
        Result := 1.0
      else
      begin
        P := 0.45;
        S := P / 4.0;
        if ClampedT < 0.5 then
          Result := -0.5 * Power(2.0, 20.0 * ClampedT - 10.0) * Sin((2.0 * ClampedT - 1.0 - S) * (2.0 * Pi) / P)
        else
          Result := Power(2.0, -20.0 * ClampedT + 10.0) * Sin((2.0 * ClampedT - 1.0 - S) * (2.0 * Pi) / P) * 0.5 + 1.0;
      end;

    InBounce:
      Result := 1.0 - TFluentEaseEvaluator.Evaluate(OutBounce, 1.0 - ClampedT);

    OutBounce:
      begin
        if ClampedT < (1.0 / 2.75) then
          Result := 7.5625 * Sqr(ClampedT)
        else if ClampedT < (2.0 / 2.75) then
        begin
          P := ClampedT - (1.5 / 2.75);
          Result := 7.5625 * Sqr(P) + 0.75;
        end
        else if ClampedT < (2.5 / 2.75) then
        begin
          P := ClampedT - (2.25 / 2.75);
          Result := 7.5625 * Sqr(P) + 0.9375;
        end
        else
        begin
          P := ClampedT - (2.625 / 2.75);
          Result := 7.5625 * Sqr(P) + 0.984375;
        end;
      end;

    InOutBounce:
      if ClampedT < 0.5 then
        Result := TFluentEaseEvaluator.Evaluate(InBounce, ClampedT * 2.0) * 0.5
      else
        Result := TFluentEaseEvaluator.Evaluate(OutBounce, ClampedT * 2.0 - 1.0) * 0.5 + 0.5;
  else
    Result := ClampedT;
  end;
end;

{ TFluentShimmerConfig }

class function TFluentShimmerConfig.Default: TFluentShimmerConfig;
begin
  Result.HighlightColor := $E0FFFFFF; // Bright crisp white shine beam
  Result.BaseColor := $00FFFFFF;      // 100% Transparent
  Result.BandWidth := 0.22;           // Crisp 22% band width
  Result.AngleDeg := 20.0;            // Elegant 20 degree tilt
  Result.Direction := TShimmerDirection.LeftToRight;
  Result.MaskToText := False;
end;

class function TFluentShimmerConfig.TextDefault: TFluentShimmerConfig;
begin
  Result.HighlightColor := $E0FFFFFF;
  Result.BaseColor := $00FFFFFF;
  Result.BandWidth := 0.35;
  Result.AngleDeg := 20.0;
  Result.Direction := TShimmerDirection.LeftToRight;
  Result.MaskToText := True;
end;

{ TFluentRippleConfig }

class function TFluentRippleConfig.Default: TFluentRippleConfig;
begin
  Result.RippleColor := $40FFFFFF;    // Soft light ripple
  Result.Origin := PointF(0, 0);
  Result.AutoCenter := True;
  Result.MaxRadiusFraction := 1.2;
end;

{ TFluentColorHelper }

class function TFluentColorHelper.Lerp(const AFromColor, AToColor: TAlphaColor; const T: Single): TAlphaColor;
var
  ClampedT: Single;
  C1, C2: TAlphaColorRec;
  R: TAlphaColorRec;
begin
  ClampedT := EnsureRange(T, 0.0, 1.0);
  C1 := TAlphaColorRec(AFromColor);
  C2 := TAlphaColorRec(AToColor);
  R.A := Round(C1.A + (C2.A - C1.A) * ClampedT);
  R.R := Round(C1.R + (C2.R - C1.R) * ClampedT);
  R.G := Round(C1.G + (C2.G - C1.G) * ClampedT);
  R.B := Round(C1.B + (C2.B - C1.B) * ClampedT);
  Result := TAlphaColor(R);
end;

{ TMotionAnchorHelper }

function TMotionAnchorHelper.ToPointF: TPointF;
begin
  Result := ToPointF(PointF(0.5, 0.5));
end;

function TMotionAnchorHelper.ToPointF(const ACustomPoint: TPointF): TPointF;
begin
  case Self of
    TMotionAnchor.TopLeft:      Result := PointF(0.0, 0.0);
    TMotionAnchor.TopCenter:    Result := PointF(0.5, 0.0);
    TMotionAnchor.TopRight:     Result := PointF(1.0, 0.0);
    TMotionAnchor.CenterLeft:   Result := PointF(0.0, 0.5);
    TMotionAnchor.Center:       Result := PointF(0.5, 0.5);
    TMotionAnchor.CenterRight:  Result := PointF(1.0, 0.5);
    TMotionAnchor.BottomLeft:   Result := PointF(0.0, 1.0);
    TMotionAnchor.BottomCenter: Result := PointF(0.5, 1.0);
    TMotionAnchor.BottomRight:  Result := PointF(1.0, 1.0);
    TMotionAnchor.Custom:       Result := ACustomPoint;
  else
    Result := PointF(0.5, 0.5);
  end;
end;

end.
