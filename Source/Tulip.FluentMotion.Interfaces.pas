{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Interfaces
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Interfaces;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  FMX.Controls,
  FMX.Graphics,
  System.Skia,
  Tulip.FluentMotion.Types;

type
  { Forward declarations }
  IMotionEffect = interface;
  ITransformEffect = interface;
  ISkiaPaintEffect = interface;
  IMotionPhase = interface;
  IMotionDriver = interface;
  IMotionBuilder = interface;

  { Callback types }
  TMotionCallback = reference to procedure;
  TMotionProgressCallback = reference to procedure(const AProgress: Single);

  { Base Motion Effect Interface (Open/Closed Principle) }
  IMotionEffect = interface
    ['{8A2B9C01-4F5E-4D3C-B1A2-9E8D7C6B5A4F}']
    procedure Attach(const AControl: TControl);
    procedure Detach;
    procedure Start;
    procedure Update(const AProgress: Single; const AElapsedTimeSec: Single);
    procedure Finish;
    procedure Reset;
    function GetDurationMs: Cardinal;
    function GetDelayMs: Cardinal;
    function IsFinished: Boolean;
    function Clone: IMotionEffect;
  end;

  { Transform Effect Interface (Position, Scale, Rotation, Opacity) }
  ITransformEffect = interface(IMotionEffect)
    ['{9B3C0D12-5E6F-4A4B-C2B3-0F9E8D7C6B50}']
    procedure CaptureInitialState;
    procedure RestoreInitialState;
  end;

  { Anchorable Effect Interface (Scale, Rotate, Resize, Flip3D, Pulse, Wiggle, Pop, Ripple) }
  IAnchorableEffect = interface
    ['{B8E2A740-1D45-4E7B-89A0-3C4D5E6F7A8B}']
    procedure SetAnchor(const AAnchor: TMotionAnchor; const ACustomPoint: TPointF);
    function GetAnchor: TMotionAnchor;
    function GetAnchorPoint: TPointF;
  end;

  { Skia-rendered Paint Effect Interface (Shimmer, Ripple, Glow) }
  ISkiaPaintEffect = interface(IMotionEffect)
    ['{AC4D1E23-6F70-4B5C-D3C4-1EA09E8D7C61}']
    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
    procedure PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
    function NeedsRepaint: Boolean;
  end;

  { Motion Phase Interface: Groups concurrent (parallel) effects }
  IMotionPhase = interface
    ['{BD5E2F34-7081-4C6D-E4D5-2FB1AF9E8D72}']
    procedure AddEffect(const AEffect: IMotionEffect);
    procedure Start;
    procedure Update(const ADeltaTimeSec: Single);
    function IsFinished: Boolean;
    procedure Reset;
    procedure Finish;
    function GetTotalDurationMs: Cardinal;
    function GetEffectsCount: Integer;
    function GetEffect(const Index: Integer): IMotionEffect;
    procedure SetReversed(const AReversed: Boolean);
    function IsReversed: Boolean;
    procedure Restart;
    procedure Seek(const AProgress: Single);
  end;

  { Motion Driver Interface: Attached to TControl }
  IMotionDriver = interface
    ['{CE6F3045-8192-4D7E-F5E6-30C2B0AF9E83}']
    function GetControl: TControl;
    procedure AddPhase(const APhase: IMotionPhase);
    procedure ClearPhases;
    procedure Start;
    procedure Stop;
    procedure Reset;
    procedure Pause;
    procedure Resume;
    function IsRunning: Boolean;
    function IsPaused: Boolean;
    procedure Tick(const ADeltaTimeSec: Single);
    procedure RegisterPaintEffect(const AEffect: ISkiaPaintEffect);
    procedure UnregisterPaintEffect(const AEffect: ISkiaPaintEffect);
    procedure RequestRepaint;
    procedure SetRepeatCount(const ACount: Integer);
    procedure SetAutoreverse(const AEnabled: Boolean);
    procedure SetSpeed(const ASpeed: Single);
    function GetSpeed: Single;
    procedure Seek(const AProgress: Single);
  end;

  { Fluent Builder Interface (SwiftUI-Style Declarative API) }
  IMotionBuilder = interface
    ['{DF704156-92A3-4E8F-06F7-41D3C1BAAF94}']
    { Easing & Timing Configuration }
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

    { Physical Transformations (Parallel by default) }
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

    { Skia Canvas Shaders }
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

    { Silence & Phasing }
    function Wait(const AWaitMs: Cardinal): IMotionBuilder;
    function &Then: IMotionBuilder;
    function ThenDo(const ACallback: TMotionCallback): IMotionBuilder;

    { Callbacks }
    function OnProgress(const ACallback: TMotionProgressCallback): IMotionBuilder;
    function OnComplete(const ACallback: TMotionCallback): IMotionBuilder;

    { Execution Lifecycle }
    function Start: IMotionBuilder;
    function Stop: IMotionBuilder;
    function Reset: IMotionBuilder;
    function Pause: IMotionBuilder;
    function Resume: IMotionBuilder;
    function Seek(const AProgress: Single): IMotionBuilder;
  end;

implementation

end.
