{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Wiggle
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MIT (SPDX-License-Identifier: MIT)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Wiggle;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.Math,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Wiggle Effect: iOS Home Screen App Edit Mode continuous tactile jiggle with Anchor Point }
  TFluentWiggleEffect = class(TFluentMotionEffectBase, ITransformEffect)
  private
    FIntensityDeg: Single;
    FInitialAngle: Single;
    FInitialRotationCenter: TPointF;
    FFrequency: Single;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const AIntensityDeg: Single = 2.5; const ADurationMs: Cardinal = 350); reintroduce;

    { ITransformEffect Implementation }
    procedure CaptureInitialState;
    procedure RestoreInitialState;

    function Clone: IMotionEffect; override;

    property IntensityDeg: Single read FIntensityDeg write FIntensityDeg;
    property Frequency: Single read FFrequency write FFrequency;
  end;

implementation

type
  TControlAccess = class(TControl);

{ TFluentWiggleEffect }

constructor TFluentWiggleEffect.Create(const AIntensityDeg: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FIntensityDeg := AIntensityDeg;
  FFrequency := 24.0; // Rapid gentle oscillations (~4Hz)
  FEase := TFluentEase.Linear;
end;

procedure TFluentWiggleEffect.CaptureInitialState;
begin
  if Assigned(FControl) then
  begin
    FInitialAngle := TControlAccess(FControl).RotationAngle;
    FInitialRotationCenter := TControlAccess(FControl).RotationCenter.Point;
  end;
end;

procedure TFluentWiggleEffect.RestoreInitialState;
begin
  if Assigned(FControl) then
  begin
    TControlAccess(FControl).RotationCenter.Point := FInitialRotationCenter;
    TControlAccess(FControl).RotationAngle := FInitialAngle;
  end;
end;

procedure TFluentWiggleEffect.DoAttach;
begin
  CaptureInitialState;
end;

procedure TFluentWiggleEffect.DoStart;
begin
  if Assigned(FControl) then
    TControlAccess(FControl).RotationCenter.Point := FAnchor.ToPointF(FCustomAnchorPoint);
  CaptureInitialState;
end;

procedure TFluentWiggleEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurDeltaAngle: Single;
  Envelope: Single;
begin
  if not Assigned(FControl) then
    Exit;

  // Damping envelope at the very end to smoothly settle
  if AProgress > 0.85 then
    Envelope := (1.0 - AProgress) / 0.15
  else
    Envelope := 1.0;

  CurDeltaAngle := FIntensityDeg * Envelope * Sin(AElapsedTimeSec * FFrequency);
  TControlAccess(FControl).RotationAngle := FInitialAngle + CurDeltaAngle;
end;

procedure TFluentWiggleEffect.DoFinish;
begin
  RestoreInitialState;
end;

procedure TFluentWiggleEffect.DoReset;
begin
  RestoreInitialState;
end;

function TFluentWiggleEffect.Clone: IMotionEffect;
var
  Res: TFluentWiggleEffect;
begin
  Res := TFluentWiggleEffect.Create(FIntensityDeg, FDurationMs);
  Res.FFrequency := FFrequency;
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Res.FAnchor := FAnchor;
  Res.FCustomAnchorPoint := FCustomAnchorPoint;
  Result := Res;
end;

end.
