{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Builder
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Builder;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Types,
  System.Generics.Collections,
  System.UITypes,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Phase,
  Tulip.FluentMotion.Driver,
  Tulip.FluentMotion.Effect.Base,
  Tulip.FluentMotion.Effect.Scale,
  Tulip.FluentMotion.Effect.Translate,
  Tulip.FluentMotion.Effect.Fade,
  Tulip.FluentMotion.Effect.Rotate,
  Tulip.FluentMotion.Effect.Flip3D,
  Tulip.FluentMotion.Effect.ColorTransition,
  Tulip.FluentMotion.Effect.Grayscale,
  Tulip.FluentMotion.Effect.Shadow,
  Tulip.FluentMotion.Effect.Shake,
  Tulip.FluentMotion.Effect.Pulse,
  Tulip.FluentMotion.Effect.Wait,
  Tulip.FluentMotion.Effect.Blur,
  Tulip.FluentMotion.Effect.Shimmer,
  Tulip.FluentMotion.Effect.Ripple,
  Tulip.FluentMotion.Effect.Transition,
  Tulip.FluentMotion.Effect.Glow,
  Tulip.FluentMotion.Effect.HueRotation,
  Tulip.FluentMotion.Effect.Wiggle,
  Tulip.FluentMotion.Effect.Resize,
  Tulip.FluentMotion.Effect.Shader,
  Tulip.FluentMotion.Effect.Text;

type
  { Fluent Motion Builder: Implements SwiftUI-style chaining }
  TFluentMotionBuilder = class(TInterfacedObject, IMotionBuilder)
  private
    FControl: TControl;
    FCurrentPhase: IMotionPhase;
    FPhases: TList<IMotionPhase>;
    FCurrentDurationMs: Cardinal;
    FCurrentDelayMs: Cardinal;
    FCurrentEase: TFluentEase;
    FCurrentSpring: TFluentSpring;
    FUseSpring: Boolean;
    FRepeatCount: Integer;
    FAutoreverse: Boolean;
    FSpeed: Single;
    FCurrentAnchor: TMotionAnchor;
    FCurrentCustomAnchorPoint: TPointF;
    FAnchorExplicitlySet: Boolean;
    FDurationExplicitlySet: Boolean;
    FLastShaderEffect: TFluentShaderEffect;
    FOnCompleteCallback: TMotionCallback;
    FOnProgressCallback: TMotionProgressCallback;

    procedure EnsureCurrentPhase;
    procedure AddConfiguredEffect(const AEffect: TFluentMotionEffectBase);
    procedure ApplyStepAnchor(const AEffect: TFluentMotionEffectBase; const AAnchor: TMotionAnchor);
    procedure SetPhaseDuration(const ADurationMs: Cardinal);
    function EffectiveDuration(const ADurationMs: Cardinal; const ADefaultMs: Cardinal = 250): Cardinal;
  public
    constructor Create(const AControl: TControl);
    destructor Destroy; override;

    { Timing & Easing }
    function Duration(const ADurationMs: Cardinal): IMotionBuilder;
    function Delay(const ADelayMs: Cardinal): IMotionBuilder;
    function Speed(const ASpeed: Single): IMotionBuilder;
    function WithEase(const AEase: TFluentEase): IMotionBuilder;
    function WithSpring(const ASpring: TFluentSpring): IMotionBuilder;
    function PhaseEase(const AEase: TFluentEase): IMotionBuilder;
    function PhaseSpring(const ASpring: TFluentSpring): IMotionBuilder;
    function WithAngle(const AAngleDeg: Single): IMotionBuilder;
    function RepeatCount(const ACount: Integer): IMotionBuilder;
    function RepeatForever(const AAutoreverse: Boolean = True): IMotionBuilder;
    function Autoreverse(const AEnabled: Boolean = True): IMotionBuilder;
    function Anchor(const AAnchor: TMotionAnchor): IMotionBuilder; overload;
    function Anchor(const ACustomPoint: TPointF): IMotionBuilder; overload;

    { Physical Transformations }
    function Scale(const ATargetScale: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder; overload;
    function Scale(const AFromScale, ATargetScale: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder; overload;
    function ScaleX(const ATargetScaleX: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
    function ScaleY(const ATargetScaleY: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;

    function Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
    function Move(const ADeltaX, ADeltaY: Single; const AAnchor: TMotionAnchor): IMotionBuilder; overload;
    function Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder; overload;
    function MoveX(const ADeltaX: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.TopLeft): IMotionBuilder;
    function MoveY(const ADeltaY: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.TopLeft): IMotionBuilder;
    function MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
    function MoveTo(const ATargetX, ATargetY: Single; const AAnchor: TMotionAnchor): IMotionBuilder; overload;
    function MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder; overload;

    function Rotate(const ATargetAngleDeg: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
    function RotateBy(const ADeltaAngleDeg: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;

    { 3D Flip (SwiftUI rotation3DEffect) }
    function Flip3D(const ATargetAngleDeg: Single; const AAxis: TFlipAxis = TFlipAxis.Horizontal; const ADurationMs: Cardinal = 350; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
    function FlipHorizontal(const ATargetAngleDeg: Single = 180.0; const ADurationMs: Cardinal = 350; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
    function FlipVertical(const ATargetAngleDeg: Single = 180.0; const ADurationMs: Cardinal = 350; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;

    function Fade(const ATargetOpacity: Single; const ADurationMs: Cardinal = 200): IMotionBuilder; overload;
    function Fade(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal = 200): IMotionBuilder; overload;
    function FadeIn(const ADurationMs: Cardinal = 200): IMotionBuilder;
    function FadeOut(const ADurationMs: Cardinal = 200): IMotionBuilder;

    { Color Transition & Tint (SwiftUI tint / foregroundStyle) }
    function ColorTo(const ATargetColor: TAlphaColor; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
    function ColorTo(const AFromColor, ATargetColor: TAlphaColor; const ADurationMs: Cardinal): IMotionBuilder; overload;
    function ColorFromTo(const AFromColor, ATargetColor: TAlphaColor; const ADurationMs: Cardinal = 250): IMotionBuilder;
    function Tint(const ATintColor: TAlphaColor; const ADurationMs: Cardinal = 250): IMotionBuilder;

    { Grayscale & Desaturation (SwiftUI grayscale) }
    function Grayscale(const ATargetAmount: Single = 1.0; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
    function Grayscale(const AFromAmount, ATargetAmount: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
    function GrayscaleIn(const ADurationMs: Cardinal = 250): IMotionBuilder;
    function GrayscaleOut(const ADurationMs: Cardinal = 250): IMotionBuilder;

    { Shadow & Elevation (SwiftUI shadow) }
    function Shadow(const ADistance: Single; const ASoftness: Single = 0.3; const AOpacity: Single = 0.5; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
    function Shadow(const AFromDistance, ATargetDistance, AFromSoftness, ATargetSoftness, AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
    function Elevation(const AElevationLevel: Single; const ADurationMs: Cardinal = 250): IMotionBuilder;

    { Blur Filter }
    function Blur(const ATargetSoftness: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
    function Blur(const AFromSoftness, ATargetSoftness: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
    function BlurIn(const AMaxSoftness: Single = 4.0; const ADurationMs: Cardinal = 250): IMotionBuilder;
    function BlurOut(const ADurationMs: Cardinal = 250): IMotionBuilder;

    { Micro-interactions }
    function Shake(const AIntensity: Single = 8.0; const ADurationMs: Cardinal = 350): IMotionBuilder;
    function Pulse(const AScalePeak: Single = 1.12; const ADurationMs: Cardinal = 280; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
    function Bounce(const AHeight: Single = 16.0; const ADurationMs: Cardinal = 320): IMotionBuilder;
    function Wiggle(const AIntensityDeg: Single = 2.5; const ADurationMs: Cardinal = 350; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;

    { Transitions (SwiftUI transitions) }
    function SlideIn(const ADirection: TTransitionDirection = TTransitionDirection.FromLeft; const ADistance: Single = 0; const ADurationMs: Cardinal = 300): IMotionBuilder;
    function SlideOut(const ADirection: TTransitionDirection = TTransitionDirection.FromRight; const ADistance: Single = 0; const ADurationMs: Cardinal = 300): IMotionBuilder;
    function PopIn(const ADurationMs: Cardinal = 350; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;
    function PopOut(const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder;

    { Advanced Effects (Glow, HueRotation, Resize) }
    function Glow(const AColor: TAlphaColor = $8000A0FF; const ASoftness: Single = 0.5; const AOpacity: Single = 0.8; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
    function Glow(const ATargetOpacity: Single; const ADurationMs: Cardinal = 250): IMotionBuilder; overload;
    function HueRotation(const ATargetAngleDeg: Single = 360.0; const ADurationMs: Cardinal = 500): IMotionBuilder;
    function ResizeTo(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal = 250; const AAnchor: TResizeAnchor = TResizeAnchor.Center): IMotionBuilder;
    function ResizeWidth(const ATargetWidth: Single; const ADurationMs: Cardinal = 250; const AAnchor: TResizeAnchor = TResizeAnchor.Center): IMotionBuilder;
    function ResizeHeight(const ATargetHeight: Single; const ADurationMs: Cardinal = 250; const AAnchor: TResizeAnchor = TResizeAnchor.Center): IMotionBuilder;

    { Text Typography Animations }
    function CountTo(const ATargetValue: Double; const AFormatStr: string = '%0.2f'; const ADurationMs: Cardinal = 1500): IMotionBuilder; overload;
    function CountTo(const AFromValue, ATargetValue: Double; const AFormatStr: string = '%0.2f'; const ADurationMs: Cardinal = 1500): IMotionBuilder; overload;
    function Typewriter(const ATargetText: string; const ACharDelayMs: Cardinal = 40; const ABlinkingCursor: Boolean = True; const ACursorChar: Char = '|'): IMotionBuilder;
    function ShimmerText(const ADurationMs: Cardinal = 1000; const ADirection: TShimmerDirection = TShimmerDirection.LeftToRight; const AAngleDeg: Single = 20.0): IMotionBuilder; overload;
    function ShimmerText(const ADirection: TShimmerDirection; const ADurationMs: Cardinal = 1000; const AAngleDeg: Single = 20.0): IMotionBuilder; overload;
    function ShimmerText(const AHighlightColor: TAlphaColor; const ADurationMs: Cardinal; const ADirection: TShimmerDirection = TShimmerDirection.LeftToRight; const AAngleDeg: Single = 20.0): IMotionBuilder; overload;

    { Skia Shaders }
    function Shimmer(const ADurationMs: Cardinal = 1000; const ADirection: TShimmerDirection = TShimmerDirection.LeftToRight; const AAngleDeg: Single = 20.0): IMotionBuilder; overload;
    function Shimmer(const ADirection: TShimmerDirection; const ADurationMs: Cardinal = 1000; const AAngleDeg: Single = 20.0): IMotionBuilder; overload;
    function Shimmer(const AConfig: TFluentShimmerConfig; const ADurationMs: Cardinal = 1000): IMotionBuilder; overload;
    function Ripple(const ADurationMs: Cardinal = 450; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder; overload;
    function Ripple(const AConfig: TFluentRippleConfig; const ADurationMs: Cardinal = 450; const AAnchor: TMotionAnchor = TMotionAnchor.Center): IMotionBuilder; overload;

    { Skia Runtime Shaders & Presets }
    function CustomShader(const ASkSL: string; const ADurationMs: Cardinal = 1000; const ADrawMode: TShaderDrawMode = TShaderDrawMode.Overlay): IMotionBuilder;
    function BorderBeam(const AColorFrom: TAlphaColor; const AColorTo: TAlphaColor; const ABorderWidth: Single = 3.0; const ABeamLength: Single = 0.25; const ADurationMs: Cardinal = 2000): IMotionBuilder; overload;
    function BorderBeam(const AColor: TAlphaColor; const ABorderWidth: Single = 3.0; const ADurationMs: Cardinal = 2000): IMotionBuilder; overload;
    function LiquidWave(const ATargetLevel: Single; const AColor: TAlphaColor = $CC007ACC; const ACrestColor: TAlphaColor = $FFFFFFFF; const ADurationMs: Cardinal = 1000): IMotionBuilder; overload;
    function LiquidWave(const AFromLevel, ATargetLevel: Single; const AColor: TAlphaColor = $CC007ACC; const ACrestColor: TAlphaColor = $FFFFFFFF; const ADurationMs: Cardinal = 1000): IMotionBuilder; overload;
    function FrostedGlass(const ATintColor: TAlphaColor = $40FFFFFF; const ABorderLight: Single = 0.8; const ADurationMs: Cardinal = 500): IMotionBuilder;
    function MeshGradient(const AColor1, AColor2, AColor3, AColor4: TAlphaColor; const ADurationMs: Cardinal = 3000): IMotionBuilder;
    function DissolveBurn(const AEmberColor: TAlphaColor = $FFFF4500; const AEmberWidth: Single = 0.08; const ANoiseScale: Single = 8.0; const ADurationMs: Cardinal = 1500): IMotionBuilder;
    function RippleDistortion(const ARippleColor: TAlphaColor = $8000BFFF; const AWaveWidth: Single = 24.0; const ADurationMs: Cardinal = 600): IMotionBuilder; overload;
    function RippleDistortion(const ACenter: TPointF; const ARippleColor: TAlphaColor = $8000BFFF; const AWaveWidth: Single = 24.0; const ADurationMs: Cardinal = 600): IMotionBuilder; overload;
    function NeonGlow(const AGlowColor: TAlphaColor = $FF00FFCC; const AGlowRadius: Single = 16.0; const APulseSpeed: Single = 4.0; const ADurationMs: Cardinal = 1500): IMotionBuilder;
    function GooeyMetaball(const ABlobColor: TAlphaColor = $DDFF007F; const ASpeed: Single = 2.0; const ADurationMs: Cardinal = 3000): IMotionBuilder;
    function Glass(const AStyle: TFluentGlassStyle; const ADurationMs: Cardinal = 2000): IMotionBuilder; overload;
    function Glass(const ARefrMagnitude: Single = 14.0; const AAberration: Single = 0.08; const ABlurRadius: Single = 0.8; const AGlowIntensity: Single = 0.40; const ADurationMs: Cardinal = 2000): IMotionBuilder; overload;
    function LiquidGlass(const AStyle: TFluentGlassStyle; const ADurationMs: Cardinal = 0): IMotionBuilder; overload;
    function LiquidGlass(const ARefrMagnitude: Single = 14.0; const AAberration: Single = 0.08; const ABlurRadius: Single = 0.8; const AGlowIntensity: Single = 0.40; const ADurationMs: Cardinal = 0): IMotionBuilder; overload;
    function LiquidGlassGroup(const ATargets: TArray<TControl>; const AStyle: TFluentGlassStyle = TFluentGlassStyle.Frosted; const ASmoothness: Single = 18.0; const ADurationMs: Cardinal = 0): IMotionBuilder; overload;
    function LiquidGlassGroup(const ATargets: TArray<TControl>; const ASmoothness, ARefrMagnitude, AAberration, ABlurRadius, AGlowIntensity: Single; const ADurationMs: Cardinal = 0): IMotionBuilder; overload;

    { Shader Configuration Chaining }
    function Uniform(const AName: string; const AValue: Single): IMotionBuilder; overload;
    function Uniform(const AName: string; const AValue: TPointF): IMotionBuilder; overload;
    function Uniform(const AName: string; const AValue: TAlphaColor): IMotionBuilder; overload;
    function Uniform(const AName: string; const AValue: TArray<Single>): IMotionBuilder; overload;
    function DrawMode(const ADrawMode: TShaderDrawMode): IMotionBuilder;

    { Phasing & Delays }
    function Wait(const AWaitMs: Cardinal): IMotionBuilder;
    function &Then: IMotionBuilder;
    function ThenDo(const ACallback: TMotionCallback): IMotionBuilder;

    { Callbacks }
    function OnProgress(const ACallback: TMotionProgressCallback): IMotionBuilder;
    function OnComplete(const ACallback: TMotionCallback): IMotionBuilder;

    { Lifecycle Execution }
    function Start: IMotionBuilder;
    function Stop: IMotionBuilder;
    function Reset: IMotionBuilder;
    function Pause: IMotionBuilder;
    function Resume: IMotionBuilder;
    function Seek(const AProgress: Single): IMotionBuilder;
  end;

implementation

{ TFluentMotionBuilder }

constructor TFluentMotionBuilder.Create(const AControl: TControl);
begin
  inherited Create;
  FControl := AControl;
  FPhases := TList<IMotionPhase>.Create;
  FCurrentPhase := nil;
  FCurrentDurationMs := 250;
  FCurrentDelayMs := 0;
  FCurrentEase := TFluentEase.OutCubic;
  FCurrentSpring := TFluentSpring.Smooth;
  FUseSpring := False;
  FRepeatCount := 0;
  FAutoreverse := False;
  FSpeed := 1.0;
  FCurrentAnchor := TMotionAnchor.Center;
  FCurrentCustomAnchorPoint := PointF(0.5, 0.5);
  FAnchorExplicitlySet := False;
  FDurationExplicitlySet := False;
  FLastShaderEffect := nil;
end;

destructor TFluentMotionBuilder.Destroy;
begin
  FPhases.Free;
  inherited Destroy;
end;

procedure TFluentMotionBuilder.EnsureCurrentPhase;
begin
  if not Assigned(FCurrentPhase) then
  begin
    FCurrentPhase := TFluentMotionPhase.Create;
    FPhases.Add(FCurrentPhase);
  end;
end;

procedure TFluentMotionBuilder.AddConfiguredEffect(const AEffect: TFluentMotionEffectBase);
begin
  if not Assigned(AEffect) then
    Exit;

  EnsureCurrentPhase;

  if FUseSpring then
    AEffect.SetSpring(FCurrentSpring)
  else
    AEffect.SetEase(FCurrentEase);

  if FCurrentDelayMs > 0 then
    AEffect.SetDelay(FCurrentDelayMs);

  AEffect.SetAnchor(FCurrentAnchor, FCurrentCustomAnchorPoint);
  AEffect.Attach(FControl);
  FCurrentPhase.AddEffect(AEffect);

  if AEffect is TFluentShaderEffect then
    FLastShaderEffect := TFluentShaderEffect(AEffect)
  else
    FLastShaderEffect := nil;

  // Reset transient per-step delay
  FCurrentDelayMs := 0;
end;

procedure TFluentMotionBuilder.ApplyStepAnchor(const AEffect: TFluentMotionEffectBase; const AAnchor: TMotionAnchor);
var
  EffectiveAnchor: TMotionAnchor;
  EffectiveCustomPoint: TPointF;
begin
  if not Assigned(AEffect) then
    Exit;

  if FAnchorExplicitlySet then
  begin
    EffectiveAnchor := FCurrentAnchor;
    EffectiveCustomPoint := FCurrentCustomAnchorPoint;
  end
  else
  begin
    EffectiveAnchor := AAnchor;
    EffectiveCustomPoint := AAnchor.ToPointF(PointF(0.5, 0.5));
  end;

  AEffect.SetAnchor(EffectiveAnchor, EffectiveCustomPoint);
end;

procedure TFluentMotionBuilder.SetPhaseDuration(const ADurationMs: Cardinal);
var
  I: Integer;
  Eff: IMotionEffect;
begin
  FCurrentDurationMs := ADurationMs;
  FDurationExplicitlySet := True;
  if Assigned(FCurrentPhase) then
  begin
    for I := 0 to FCurrentPhase.GetEffectsCount - 1 do
    begin
      Eff := FCurrentPhase.GetEffect(I);
      if Eff is TFluentMotionEffectBase then
      begin
        // If the prior effect had a default duration, sync it to the new phase duration
        if (Eff.GetDurationMs = 250) or (Eff.GetDurationMs = 200) then
          TFluentMotionEffectBase(Eff).SetDuration(ADurationMs);
      end;
    end;
  end;
end;

function TFluentMotionBuilder.EffectiveDuration(const ADurationMs: Cardinal; const ADefaultMs: Cardinal): Cardinal;
begin
  if ADurationMs <> ADefaultMs then
  begin
    SetPhaseDuration(ADurationMs);
    Result := ADurationMs;
  end
  else if FDurationExplicitlySet then
    Result := FCurrentDurationMs
  else
    Result := ADefaultMs;
end;

function TFluentMotionBuilder.Duration(const ADurationMs: Cardinal): IMotionBuilder;
begin
  SetPhaseDuration(ADurationMs);
  Result := Self;
end;

function TFluentMotionBuilder.Delay(const ADelayMs: Cardinal): IMotionBuilder;
begin
  FCurrentDelayMs := ADelayMs;
  Result := Self;
end;

function TFluentMotionBuilder.Speed(const ASpeed: Single): IMotionBuilder;
begin
  FSpeed := Max(0.0, ASpeed);
  Result := Self;
end;

function TFluentMotionBuilder.WithEase(const AEase: TFluentEase): IMotionBuilder;
var
  Eff: IMotionEffect;
begin
  if Assigned(FCurrentPhase) and (FCurrentPhase.GetEffectsCount > 0) then
  begin
    Eff := FCurrentPhase.GetEffect(FCurrentPhase.GetEffectsCount - 1);
    if Eff is TFluentMotionEffectBase then
      TFluentMotionEffectBase(Eff).SetEase(AEase);
  end
  else
  begin
    FCurrentEase := AEase;
    FUseSpring := False;
  end;
  Result := Self;
end;

function TFluentMotionBuilder.WithSpring(const ASpring: TFluentSpring): IMotionBuilder;
var
  Eff: IMotionEffect;
begin
  if Assigned(FCurrentPhase) and (FCurrentPhase.GetEffectsCount > 0) then
  begin
    Eff := FCurrentPhase.GetEffect(FCurrentPhase.GetEffectsCount - 1);
    if Eff is TFluentMotionEffectBase then
      TFluentMotionEffectBase(Eff).SetSpring(ASpring);
  end
  else
  begin
    FCurrentSpring := ASpring;
    FUseSpring := True;
  end;
  Result := Self;
end;

function TFluentMotionBuilder.PhaseEase(const AEase: TFluentEase): IMotionBuilder;
var
  I: Integer;
  Eff: IMotionEffect;
begin
  FCurrentEase := AEase;
  FUseSpring := False;
  if Assigned(FCurrentPhase) then
  begin
    for I := 0 to FCurrentPhase.GetEffectsCount - 1 do
    begin
      Eff := FCurrentPhase.GetEffect(I);
      if Eff is TFluentMotionEffectBase then
        TFluentMotionEffectBase(Eff).SetEase(AEase);
    end;
  end;
  Result := Self;
end;

function TFluentMotionBuilder.PhaseSpring(const ASpring: TFluentSpring): IMotionBuilder;
var
  I: Integer;
  Eff: IMotionEffect;
begin
  FCurrentSpring := ASpring;
  FUseSpring := True;
  if Assigned(FCurrentPhase) then
  begin
    for I := 0 to FCurrentPhase.GetEffectsCount - 1 do
    begin
      Eff := FCurrentPhase.GetEffect(I);
      if Eff is TFluentMotionEffectBase then
        TFluentMotionEffectBase(Eff).SetSpring(ASpring);
    end;
  end;
  Result := Self;
end;

function TFluentMotionBuilder.WithAngle(const AAngleDeg: Single): IMotionBuilder;
var
  I: Integer;
  Eff: IMotionEffect;
begin
  if Assigned(FCurrentPhase) then
  begin
    for I := 0 to FCurrentPhase.GetEffectsCount - 1 do
    begin
      Eff := FCurrentPhase.GetEffect(I);
      if Eff is TFluentShimmerEffect then
        TFluentShimmerEffect(Eff).AngleDeg := AAngleDeg;
    end;
  end;
  Result := Self;
end;

function TFluentMotionBuilder.RepeatCount(const ACount: Integer): IMotionBuilder;
begin
  FRepeatCount := ACount;
  Result := Self;
end;

function TFluentMotionBuilder.RepeatForever(const AAutoreverse: Boolean): IMotionBuilder;
begin
  FRepeatCount := -1;
  FAutoreverse := AAutoreverse;
  Result := Self;
end;

function TFluentMotionBuilder.Autoreverse(const AEnabled: Boolean): IMotionBuilder;
begin
  FAutoreverse := AEnabled;
  Result := Self;
end;

function TFluentMotionBuilder.Anchor(const AAnchor: TMotionAnchor): IMotionBuilder;
var
  I: Integer;
  Eff: IMotionEffect;
  AnchorEff: IAnchorableEffect;
begin
  FCurrentAnchor := AAnchor;
  FCurrentCustomAnchorPoint := AAnchor.ToPointF(PointF(0.5, 0.5));
  FAnchorExplicitlySet := True;
  if Assigned(FCurrentPhase) then
  begin
    for I := 0 to FCurrentPhase.GetEffectsCount - 1 do
    begin
      Eff := FCurrentPhase.GetEffect(I);
      if Supports(Eff, IAnchorableEffect, AnchorEff) then
        AnchorEff.SetAnchor(AAnchor, FCurrentCustomAnchorPoint);
    end;
  end;
  Result := Self;
end;

function TFluentMotionBuilder.Anchor(const ACustomPoint: TPointF): IMotionBuilder;
var
  I: Integer;
  Eff: IMotionEffect;
  AnchorEff: IAnchorableEffect;
begin
  FCurrentAnchor := TMotionAnchor.Custom;
  FCurrentCustomAnchorPoint := ACustomPoint;
  FAnchorExplicitlySet := True;
  if Assigned(FCurrentPhase) then
  begin
    for I := 0 to FCurrentPhase.GetEffectsCount - 1 do
    begin
      Eff := FCurrentPhase.GetEffect(I);
      if Supports(Eff, IAnchorableEffect, AnchorEff) then
        AnchorEff.SetAnchor(TMotionAnchor.Custom, ACustomPoint);
    end;
  end;
  Result := Self;
end;

function TFluentMotionBuilder.Scale(const ATargetScale: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentScaleEffect;
begin
  Eff := TFluentScaleEffect.Create(ATargetScale, EffectiveDuration(ADurationMs, 250));
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.Scale(const AFromScale, ATargetScale: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentScaleEffect;
begin
  Eff := TFluentScaleEffect.Create(AFromScale, ATargetScale, EffectiveDuration(ADurationMs, 250));
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.ScaleX(const ATargetScaleX: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentScaleEffect;
begin
  Eff := TFluentScaleEffect.MakeXY(ATargetScaleX, 1.0, EffectiveDuration(ADurationMs, 250));
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.ScaleY(const ATargetScaleY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentScaleEffect;
begin
  Eff := TFluentScaleEffect.MakeXY(1.0, ATargetScaleY, EffectiveDuration(ADurationMs, 250));
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentTranslateEffect;
begin
  Eff := TFluentTranslateEffect.CreateRelative(ADeltaX, ADeltaY, EffectiveDuration(ADurationMs, 250));
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Move(const ADeltaX, ADeltaY: Single; const AAnchor: TMotionAnchor): IMotionBuilder;
begin
  Result := Move(ADeltaX, ADeltaY, EffectiveDuration(250, 250), AAnchor);
end;

function TFluentMotionBuilder.Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentTranslateEffect;
  Dur: Cardinal;
begin
  FCurrentAnchor := AAnchor;
  FCurrentCustomAnchorPoint := AAnchor.ToPointF(PointF(0.0, 0.0));
  FAnchorExplicitlySet := True;
  Dur := EffectiveDuration(ADurationMs, 250);
  Eff := TFluentTranslateEffect.CreateRelative(ADeltaX, ADeltaY, Dur);
  Eff.SetAnchor(AAnchor, FCurrentCustomAnchorPoint);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.MoveX(const ADeltaX: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentTranslateEffect;
begin
  Eff := TFluentTranslateEffect.CreateRelative(ADeltaX, 0, EffectiveDuration(ADurationMs, 250));
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.MoveY(const ADeltaY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentTranslateEffect;
begin
  Eff := TFluentTranslateEffect.CreateRelative(0, ADeltaY, EffectiveDuration(ADurationMs, 250));
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  EffectiveAnchor: TMotionAnchor;
begin
  if FAnchorExplicitlySet then
    EffectiveAnchor := FCurrentAnchor
  else
    EffectiveAnchor := TMotionAnchor.TopLeft;

  Result := MoveTo(ATargetX, ATargetY, EffectiveDuration(ADurationMs, 250), EffectiveAnchor);
end;

function TFluentMotionBuilder.MoveTo(const ATargetX, ATargetY: Single; const AAnchor: TMotionAnchor): IMotionBuilder;
begin
  Result := MoveTo(ATargetX, ATargetY, EffectiveDuration(250, 250), AAnchor);
end;

function TFluentMotionBuilder.MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentTranslateEffect;
  Dur: Cardinal;
begin
  FCurrentAnchor := AAnchor;
  FCurrentCustomAnchorPoint := AAnchor.ToPointF(PointF(0.0, 0.0));
  FAnchorExplicitlySet := True;
  Dur := EffectiveDuration(ADurationMs, 250);
  Eff := TFluentTranslateEffect.MakeAbsolute(ATargetX, ATargetY, Dur, AAnchor);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Rotate(const ATargetAngleDeg: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentRotateEffect;
begin
  Eff := TFluentRotateEffect.Create(ATargetAngleDeg, EffectiveDuration(ADurationMs, 250));
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.RotateBy(const ADeltaAngleDeg: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentRotateEffect;
begin
  Eff := TFluentRotateEffect.MakeRelative(ADeltaAngleDeg, EffectiveDuration(ADurationMs, 250));
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.Flip3D(const ATargetAngleDeg: Single; const AAxis: TFlipAxis; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentFlip3DEffect;
begin
  Eff := TFluentFlip3DEffect.Create(ATargetAngleDeg, AAxis, ADurationMs);
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.FlipHorizontal(const ATargetAngleDeg: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
begin
  Result := Flip3D(ATargetAngleDeg, TFlipAxis.Horizontal, ADurationMs, AAnchor);
end;

function TFluentMotionBuilder.FlipVertical(const ATargetAngleDeg: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
begin
  Result := Flip3D(ATargetAngleDeg, TFlipAxis.Vertical, ADurationMs, AAnchor);
end;

function TFluentMotionBuilder.Fade(const ATargetOpacity: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentFadeEffect;
begin
  Eff := TFluentFadeEffect.Create(ATargetOpacity, EffectiveDuration(ADurationMs, 200));
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Fade(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentFadeEffect;
begin
  Eff := TFluentFadeEffect.Create(AFromOpacity, ATargetOpacity, EffectiveDuration(ADurationMs, 200));
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.FadeIn(const ADurationMs: Cardinal): IMotionBuilder;
begin
  Result := Fade(1.0, EffectiveDuration(ADurationMs, 200));
end;

function TFluentMotionBuilder.FadeOut(const ADurationMs: Cardinal): IMotionBuilder;
begin
  Result := Fade(0.0, EffectiveDuration(ADurationMs, 200));
end;

function TFluentMotionBuilder.ColorTo(const ATargetColor: TAlphaColor; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentColorTransitionEffect;
begin
  Eff := TFluentColorTransitionEffect.Create(ATargetColor, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.ColorTo(const AFromColor, ATargetColor: TAlphaColor; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentColorTransitionEffect;
begin
  Eff := TFluentColorTransitionEffect.Create(AFromColor, ATargetColor, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.ColorFromTo(const AFromColor, ATargetColor: TAlphaColor; const ADurationMs: Cardinal): IMotionBuilder;
begin
  Result := ColorTo(AFromColor, ATargetColor, ADurationMs);
end;

function TFluentMotionBuilder.Tint(const ATintColor: TAlphaColor; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentColorTransitionEffect;
begin
  Eff := TFluentColorTransitionEffect.MakeTint(ATintColor, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Grayscale(const ATargetAmount: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentGrayscaleEffect;
begin
  Eff := TFluentGrayscaleEffect.Create(ATargetAmount, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Grayscale(const AFromAmount, ATargetAmount: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentGrayscaleEffect;
begin
  Eff := TFluentGrayscaleEffect.Create(AFromAmount, ATargetAmount, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.GrayscaleIn(const ADurationMs: Cardinal): IMotionBuilder;
begin
  Result := Grayscale(0.0, 1.0, ADurationMs);
end;

function TFluentMotionBuilder.GrayscaleOut(const ADurationMs: Cardinal): IMotionBuilder;
begin
  Result := Grayscale(1.0, 0.0, ADurationMs);
end;

function TFluentMotionBuilder.Shadow(const ADistance: Single; const ASoftness: Single; const AOpacity: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentShadowEffect;
begin
  Eff := TFluentShadowEffect.Create(ADistance, ASoftness, AOpacity, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Shadow(const AFromDistance, ATargetDistance, AFromSoftness, ATargetSoftness, AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentShadowEffect;
begin
  Eff := TFluentShadowEffect.Create(AFromDistance, ATargetDistance, AFromSoftness, ATargetSoftness, AFromOpacity, ATargetOpacity, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Elevation(const AElevationLevel: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentShadowEffect;
begin
  Eff := TFluentShadowEffect.MakeElevation(AElevationLevel, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Blur(const ATargetSoftness: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentBlurEffect;
begin
  Eff := TFluentBlurEffect.Create(ATargetSoftness, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Blur(const AFromSoftness, ATargetSoftness: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentBlurEffect;
begin
  Eff := TFluentBlurEffect.Create(AFromSoftness, ATargetSoftness, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.BlurIn(const AMaxSoftness: Single; const ADurationMs: Cardinal): IMotionBuilder;
begin
  Result := Blur(0.0, AMaxSoftness, ADurationMs);
end;

function TFluentMotionBuilder.BlurOut(const ADurationMs: Cardinal): IMotionBuilder;
begin
  Result := Blur(0.0, ADurationMs);
end;

function TFluentMotionBuilder.Shake(const AIntensity: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentShakeEffect;
begin
  Eff := TFluentShakeEffect.Create(AIntensity, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Pulse(const AScalePeak: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentPulseEffect;
begin
  Eff := TFluentPulseEffect.Create(AScalePeak, ADurationMs);
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.Bounce(const AHeight: Single; const ADurationMs: Cardinal): IMotionBuilder;
begin
  // Move up then spring down via relative translation
  Result := MoveY(-AHeight, ADurationMs div 2)
    .&Then
    .MoveY(AHeight, ADurationMs div 2)
    .WithEase(TFluentEase.OutBounce);
end;

function TFluentMotionBuilder.Wiggle(const AIntensityDeg: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentWiggleEffect;
begin
  Eff := TFluentWiggleEffect.Create(AIntensityDeg, ADurationMs);
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.SlideIn(const ADirection: TTransitionDirection; const ADistance: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentSlideEffect;
begin
  Eff := TFluentSlideEffect.Create(ADirection, True, ADistance, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.SlideOut(const ADirection: TTransitionDirection; const ADistance: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentSlideEffect;
begin
  Eff := TFluentSlideEffect.Create(ADirection, False, ADistance, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.PopIn(const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentPopEffect;
begin
  Eff := TFluentPopEffect.Create(True, ADurationMs);
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.PopOut(const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentPopEffect;
begin
  Eff := TFluentPopEffect.Create(False, ADurationMs);
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.Glow(const AColor: TAlphaColor; const ASoftness, AOpacity: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentGlowEffect;
begin
  Eff := TFluentGlowEffect.Create(AColor, ASoftness, AOpacity, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Glow(const ATargetOpacity: Single; const ADurationMs: Cardinal): IMotionBuilder;
begin
  Result := Glow($8000A0FF, 0.5, ATargetOpacity, ADurationMs);
end;

function TFluentMotionBuilder.HueRotation(const ATargetAngleDeg: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentHueRotationEffect;
begin
  Eff := TFluentHueRotationEffect.Create(ATargetAngleDeg, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.ResizeTo(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal; const AAnchor: TResizeAnchor): IMotionBuilder;
var
  Eff: TFluentResizeEffect;
  EffectiveAnchor: TMotionAnchor;
  Dur: Cardinal;
begin
  if FAnchorExplicitlySet then
    EffectiveAnchor := FCurrentAnchor
  else
    EffectiveAnchor := AAnchor;

  FCurrentAnchor := EffectiveAnchor;
  FCurrentCustomAnchorPoint := EffectiveAnchor.ToPointF(PointF(0.5, 0.5));
  Dur := EffectiveDuration(ADurationMs, 250);
  Eff := TFluentResizeEffect.Create(ATargetWidth, ATargetHeight, Dur, EffectiveAnchor);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.ResizeWidth(const ATargetWidth: Single; const ADurationMs: Cardinal; const AAnchor: TResizeAnchor): IMotionBuilder;
var
  Eff: TFluentResizeEffect;
  EffectiveAnchor: TMotionAnchor;
  Dur: Cardinal;
begin
  if FAnchorExplicitlySet then
    EffectiveAnchor := FCurrentAnchor
  else
    EffectiveAnchor := AAnchor;

  FCurrentAnchor := EffectiveAnchor;
  FCurrentCustomAnchorPoint := EffectiveAnchor.ToPointF(PointF(0.5, 0.5));
  Dur := EffectiveDuration(ADurationMs, 250);
  Eff := TFluentResizeEffect.MakeWidth(ATargetWidth, Dur, EffectiveAnchor);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.ResizeHeight(const ATargetHeight: Single; const ADurationMs: Cardinal; const AAnchor: TResizeAnchor): IMotionBuilder;
var
  Eff: TFluentResizeEffect;
  EffectiveAnchor: TMotionAnchor;
  Dur: Cardinal;
begin
  if FAnchorExplicitlySet then
    EffectiveAnchor := FCurrentAnchor
  else
    EffectiveAnchor := AAnchor;

  FCurrentAnchor := EffectiveAnchor;
  FCurrentCustomAnchorPoint := EffectiveAnchor.ToPointF(PointF(0.5, 0.5));
  Dur := EffectiveDuration(ADurationMs, 250);
  Eff := TFluentResizeEffect.MakeHeight(ATargetHeight, Dur, EffectiveAnchor);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Shimmer(const ADurationMs: Cardinal; const ADirection: TShimmerDirection; const AAngleDeg: Single): IMotionBuilder;
var
  LConfig: TFluentShimmerConfig;
begin
  LConfig := TFluentShimmerConfig.Default;
  LConfig.Direction := ADirection;
  LConfig.AngleDeg := AAngleDeg;
  Result := Shimmer(LConfig, ADurationMs);
end;

function TFluentMotionBuilder.Shimmer(const ADirection: TShimmerDirection; const ADurationMs: Cardinal; const AAngleDeg: Single): IMotionBuilder;
begin
  Result := Shimmer(ADurationMs, ADirection, AAngleDeg);
end;

function TFluentMotionBuilder.Shimmer(const AConfig: TFluentShimmerConfig; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentShimmerEffect;
begin
  Eff := TFluentShimmerEffect.Create(AConfig, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.CountTo(const ATargetValue: Double; const AFormatStr: string; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentCountEffect;
begin
  Eff := TFluentCountEffect.Create(ATargetValue, AFormatStr, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.CountTo(const AFromValue, ATargetValue: Double; const AFormatStr: string; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentCountEffect;
begin
  Eff := TFluentCountEffect.Create(AFromValue, ATargetValue, AFormatStr, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Typewriter(const ATargetText: string; const ACharDelayMs: Cardinal; const ABlinkingCursor: Boolean; const ACursorChar: Char): IMotionBuilder;
var
  Eff: TFluentTypewriterEffect;
begin
  Eff := TFluentTypewriterEffect.Create(ATargetText, ACharDelayMs, ABlinkingCursor, ACursorChar);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.ShimmerText(const ADurationMs: Cardinal; const ADirection: TShimmerDirection; const AAngleDeg: Single): IMotionBuilder;
var
  LConfig: TFluentShimmerConfig;
begin
  LConfig := TFluentShimmerConfig.TextDefault;
  LConfig.Direction := ADirection;
  LConfig.AngleDeg := AAngleDeg;
  Result := Shimmer(LConfig, ADurationMs);
end;

function TFluentMotionBuilder.ShimmerText(const ADirection: TShimmerDirection; const ADurationMs: Cardinal; const AAngleDeg: Single): IMotionBuilder;
begin
  Result := ShimmerText(ADurationMs, ADirection, AAngleDeg);
end;

function TFluentMotionBuilder.ShimmerText(const AHighlightColor: TAlphaColor; const ADurationMs: Cardinal; const ADirection: TShimmerDirection; const AAngleDeg: Single): IMotionBuilder;
var
  LConfig: TFluentShimmerConfig;
begin
  LConfig := TFluentShimmerConfig.TextDefault;
  LConfig.HighlightColor := AHighlightColor;
  LConfig.Direction := ADirection;
  LConfig.AngleDeg := AAngleDeg;
  Result := Shimmer(LConfig, ADurationMs);
end;

function TFluentMotionBuilder.Ripple(const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentRippleEffect;
begin
  Eff := TFluentRippleEffect.Create(ADurationMs);
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.Ripple(const AConfig: TFluentRippleConfig; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): IMotionBuilder;
var
  Eff: TFluentRippleEffect;
begin
  Eff := TFluentRippleEffect.Create(AConfig, ADurationMs);
  AddConfiguredEffect(Eff);
  ApplyStepAnchor(Eff, AAnchor);
  Result := Self;
end;

function TFluentMotionBuilder.CustomShader(const ASkSL: string; const ADurationMs: Cardinal; const ADrawMode: TShaderDrawMode): IMotionBuilder;
var
  Eff: TFluentShaderEffect;
begin
  Eff := TFluentShaderEffect.Create(ASkSL, ADurationMs, ADrawMode);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.BorderBeam(const AColorFrom, AColorTo: TAlphaColor; const ABorderWidth, ABeamLength: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentBorderBeamEffect;
begin
  Eff := TFluentBorderBeamEffect.Create(AColorFrom, AColorTo, ABorderWidth, ABeamLength, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.BorderBeam(const AColor: TAlphaColor; const ABorderWidth: Single; const ADurationMs: Cardinal): IMotionBuilder;
begin
  Result := BorderBeam(AColor, AColor, ABorderWidth, 0.25, ADurationMs);
end;

function TFluentMotionBuilder.LiquidWave(const ATargetLevel: Single; const AColor, ACrestColor: TAlphaColor; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentLiquidWaveEffect;
begin
  Eff := TFluentLiquidWaveEffect.Create(ATargetLevel, AColor, ACrestColor, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.LiquidWave(const AFromLevel, ATargetLevel: Single; const AColor, ACrestColor: TAlphaColor; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentLiquidWaveEffect;
begin
  Eff := TFluentLiquidWaveEffect.Create(AFromLevel, ATargetLevel, AColor, ACrestColor, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.FrostedGlass(const ATintColor: TAlphaColor; const ABorderLight: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentFrostedGlassEffect;
begin
  Eff := TFluentFrostedGlassEffect.Create(ATintColor, ABorderLight, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.MeshGradient(const AColor1, AColor2, AColor3, AColor4: TAlphaColor; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentMeshGradientEffect;
begin
  Eff := TFluentMeshGradientEffect.Create(AColor1, AColor2, AColor3, AColor4, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.DissolveBurn(const AEmberColor: TAlphaColor; const AEmberWidth, ANoiseScale: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentDissolveBurnEffect;
begin
  Eff := TFluentDissolveBurnEffect.Create(AEmberColor, AEmberWidth, ANoiseScale, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.RippleDistortion(const ARippleColor: TAlphaColor; const AWaveWidth: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentRippleDistortionEffect;
begin
  Eff := TFluentRippleDistortionEffect.Create(ARippleColor, AWaveWidth, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.RippleDistortion(const ACenter: TPointF; const ARippleColor: TAlphaColor; const AWaveWidth: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentRippleDistortionEffect;
begin
  Eff := TFluentRippleDistortionEffect.Create(ARippleColor, AWaveWidth, ADurationMs);
  Eff.SetUniform('uCenter', ACenter);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.NeonGlow(const AGlowColor: TAlphaColor; const AGlowRadius, APulseSpeed: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentNeonGlowEffect;
begin
  Eff := TFluentNeonGlowEffect.Create(AGlowColor, AGlowRadius, APulseSpeed, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.GooeyMetaball(const ABlobColor: TAlphaColor; const ASpeed: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentGooeyMetaballEffect;
begin
  Eff := TFluentGooeyMetaballEffect.Create(ABlobColor, ASpeed, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Glass(const AStyle: TFluentGlassStyle; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentGlassEffect;
begin
  Eff := TFluentGlassEffect.Create(AStyle, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Glass(const ARefrMagnitude, AAberration, ABlurRadius, AGlowIntensity: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentGlassEffect;
begin
  Eff := TFluentGlassEffect.Create(ARefrMagnitude, AAberration, ABlurRadius, AGlowIntensity, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.LiquidGlass(const AStyle: TFluentGlassStyle; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentLiquidGlassEffect;
begin
  Eff := TFluentLiquidGlassEffect.Create(AStyle, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.LiquidGlass(const ARefrMagnitude, AAberration, ABlurRadius, AGlowIntensity: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentLiquidGlassEffect;
begin
  Eff := TFluentLiquidGlassEffect.Create(ARefrMagnitude, AAberration, ABlurRadius, AGlowIntensity, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.LiquidGlassGroup(const ATargets: TArray<TControl>; const AStyle: TFluentGlassStyle; const ASmoothness: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentLiquidGlassGroupEffect;
begin
  Eff := TFluentLiquidGlassGroupEffect.Create(ATargets, AStyle, ASmoothness, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.LiquidGlassGroup(const ATargets: TArray<TControl>; const ASmoothness, ARefrMagnitude, AAberration, ABlurRadius, AGlowIntensity: Single; const ADurationMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentLiquidGlassGroupEffect;
begin
  Eff := TFluentLiquidGlassGroupEffect.Create(ATargets, ASmoothness, ARefrMagnitude, AAberration, ABlurRadius, AGlowIntensity, ADurationMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.Uniform(const AName: string; const AValue: Single): IMotionBuilder;
begin
  if Assigned(FLastShaderEffect) then
    FLastShaderEffect.SetUniform(AName, AValue);
  Result := Self;
end;

function TFluentMotionBuilder.Uniform(const AName: string; const AValue: TPointF): IMotionBuilder;
begin
  if Assigned(FLastShaderEffect) then
    FLastShaderEffect.SetUniform(AName, AValue);
  Result := Self;
end;

function TFluentMotionBuilder.Uniform(const AName: string; const AValue: TAlphaColor): IMotionBuilder;
begin
  if Assigned(FLastShaderEffect) then
    FLastShaderEffect.SetUniform(AName, AValue);
  Result := Self;
end;

function TFluentMotionBuilder.Uniform(const AName: string; const AValue: TArray<Single>): IMotionBuilder;
begin
  if Assigned(FLastShaderEffect) then
    FLastShaderEffect.SetUniform(AName, AValue);
  Result := Self;
end;

function TFluentMotionBuilder.DrawMode(const ADrawMode: TShaderDrawMode): IMotionBuilder;
begin
  if Assigned(FLastShaderEffect) then
    FLastShaderEffect.SetDrawMode(ADrawMode);
  Result := Self;
end;

function TFluentMotionBuilder.Wait(const AWaitMs: Cardinal): IMotionBuilder;
var
  Eff: TFluentWaitEffect;
begin
  Eff := TFluentWaitEffect.Create(AWaitMs);
  AddConfiguredEffect(Eff);
  Result := Self;
end;

function TFluentMotionBuilder.&Then: IMotionBuilder;
begin
  // Finalize current phase and start a new phase on next effect call
  FCurrentPhase := nil;
  FDurationExplicitlySet := False;
  FCurrentDurationMs := 250;
  FAnchorExplicitlySet := False;
  Result := Self;
end;

function TFluentMotionBuilder.ThenDo(const ACallback: TMotionCallback): IMotionBuilder;
var
  Eff: TFluentActionEffect;
begin
  if Assigned(FCurrentPhase) and (FCurrentPhase.GetEffectsCount > 0) then
    &Then;

  Eff := TFluentActionEffect.Create(ACallback);
  AddConfiguredEffect(Eff);

  // Advance to a fresh phase so subsequent effects run after the callback
  Result := &Then;
end;

function TFluentMotionBuilder.OnProgress(const ACallback: TMotionProgressCallback): IMotionBuilder;
begin
  FOnProgressCallback := ACallback;
  Result := Self;
end;

function TFluentMotionBuilder.OnComplete(const ACallback: TMotionCallback): IMotionBuilder;
begin
  FOnCompleteCallback := ACallback;
  Result := Self;
end;

function TFluentMotionBuilder.Start: IMotionBuilder;
var
  Driver: TFluentMotionDriver;
  Phase: IMotionPhase;
begin
  if not Assigned(FControl) then
    Exit(Self);

  Driver := TFluentMotionDriver.GetOrCreate(FControl);
  Driver.ClearPhases;

  for Phase in FPhases do
    Driver.AddPhase(Phase);

  Driver.OnComplete := FOnCompleteCallback;
  Driver.OnProgress := FOnProgressCallback;
  Driver.SetRepeatCount(FRepeatCount);
  Driver.SetAutoreverse(FAutoreverse);
  Driver.SetSpeed(FSpeed);

  Driver.Start;
  Result := Self;
end;

function TFluentMotionBuilder.Stop: IMotionBuilder;
var
  Driver: TFluentMotionDriver;
begin
  if Assigned(FControl) then
  begin
    Driver := TFluentMotionDriver.FindDriver(FControl);
    if Assigned(Driver) then
      Driver.Stop;
  end;
  Result := Self;
end;

function TFluentMotionBuilder.Reset: IMotionBuilder;
var
  Driver: TFluentMotionDriver;
begin
  if Assigned(FControl) then
  begin
    Driver := TFluentMotionDriver.FindDriver(FControl);
    if Assigned(Driver) then
      Driver.Reset;
  end;
  Result := Self;
end;

function TFluentMotionBuilder.Pause: IMotionBuilder;
var
  Driver: TFluentMotionDriver;
begin
  if Assigned(FControl) then
  begin
    Driver := TFluentMotionDriver.FindDriver(FControl);
    if Assigned(Driver) then
      Driver.Pause;
  end;
  Result := Self;
end;

function TFluentMotionBuilder.Resume: IMotionBuilder;
var
  Driver: TFluentMotionDriver;
begin
  if Assigned(FControl) then
  begin
    Driver := TFluentMotionDriver.FindDriver(FControl);
    if Assigned(Driver) then
      Driver.Resume;
  end;
  Result := Self;
end;

function TFluentMotionBuilder.Seek(const AProgress: Single): IMotionBuilder;
var
  Driver: TFluentMotionDriver;
  Phase: IMotionPhase;
begin
  if not Assigned(FControl) then
    Exit(Self);

  Driver := TFluentMotionDriver.GetOrCreate(FControl);
  Driver.ClearPhases;
  for Phase in FPhases do
    Driver.AddPhase(Phase);

  Driver.Seek(AProgress);
  Result := Self;
end;

end.
