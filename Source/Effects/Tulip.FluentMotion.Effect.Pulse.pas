{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Pulse
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MIT (SPDX-License-Identifier: MIT)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Pulse;

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
  { Pulse Effect (Scale up to peak and return to normal using Anchor Point) }
  TFluentPulseEffect = class(TFluentMotionEffectBase, ITransformEffect)
  private
    FScalePeak: Single;
    FInitialScaleX: Single;
    FInitialScaleY: Single;
    FInitialPosX: Single;
    FInitialPosY: Single;
    FStartPosX: Single;
    FStartPosY: Single;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const AScalePeak: Single = 1.12; const ADurationMs: Cardinal = 280); reintroduce;

    { ITransformEffect Implementation }
    procedure CaptureInitialState;
    procedure RestoreInitialState;

    function Clone: IMotionEffect; override;

    property ScalePeak: Single read FScalePeak write FScalePeak;
  end;

implementation

type
  TControlAccess = class(TControl);

{ TFluentPulseEffect }

constructor TFluentPulseEffect.Create(const AScalePeak: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FScalePeak := AScalePeak;
  FEase := TFluentEase.InOutSine;
end;

procedure TFluentPulseEffect.CaptureInitialState;
begin
  if Assigned(FControl) then
  begin
    FInitialScaleX := TControlAccess(FControl).Scale.X;
    FInitialScaleY := TControlAccess(FControl).Scale.Y;
    FInitialPosX := FControl.Position.X;
    FInitialPosY := FControl.Position.Y;
  end;
end;

procedure TFluentPulseEffect.RestoreInitialState;
begin
  if Assigned(FControl) then
  begin
    FControl.Position.X := FInitialPosX;
    FControl.Position.Y := FInitialPosY;
    TControlAccess(FControl).Scale.X := FInitialScaleX;
    TControlAccess(FControl).Scale.Y := FInitialScaleY;
  end;
end;

procedure TFluentPulseEffect.DoAttach;
begin
  CaptureInitialState;
end;

procedure TFluentPulseEffect.DoStart;
begin
  PrepareLayoutOverride;
  CaptureInitialState;
  if Assigned(FControl) then
  begin
    FStartPosX := FControl.Position.X;
    FStartPosY := FControl.Position.Y;
  end;
end;

procedure TFluentPulseEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurrentScale, HalfProg: Single;
  AnchorPt: TPointF;
  DeltaW, DeltaH: Single;
begin
  if not Assigned(FControl) then
    Exit;

  // First half [0.0 .. 0.5]: scale from 1.0 to Peak
  // Second half [0.5 .. 1.0]: scale from Peak to 1.0
  if AProgress < 0.5 then
  begin
    HalfProg := AProgress * 2.0;
    CurrentScale := FInitialScaleX + (FScalePeak - FInitialScaleX) * TFluentEaseEvaluator.Evaluate(TFluentEase.OutQuad, HalfProg);
  end
  else
  begin
    HalfProg := (AProgress - 0.5) * 2.0;
    CurrentScale := FScalePeak + (FInitialScaleX - FScalePeak) * TFluentEaseEvaluator.Evaluate(TFluentEase.OutQuad, HalfProg);
  end;

  AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
  DeltaW := FControl.Width * (CurrentScale - FInitialScaleX);
  DeltaH := FControl.Height * (CurrentScale - FInitialScaleY);

  FControl.Position.X := FStartPosX - (DeltaW * AnchorPt.X);
  FControl.Position.Y := FStartPosY - (DeltaH * AnchorPt.Y);

  TControlAccess(FControl).Scale.X := CurrentScale;
  TControlAccess(FControl).Scale.Y := CurrentScale;
end;

procedure TFluentPulseEffect.DoFinish;
begin
  RestoreInitialState;
  RestoreLayoutOverride;
end;

procedure TFluentPulseEffect.DoReset;
begin
  RestoreInitialState;
  RestoreLayoutOverride;
end;

function TFluentPulseEffect.Clone: IMotionEffect;
var
  Res: TFluentPulseEffect;
begin
  Res := TFluentPulseEffect.Create(FScalePeak, FDurationMs);
  Res.FDelayMs := FDelayMs;
  Res.FAnchor := FAnchor;
  Res.FCustomAnchorPoint := FCustomAnchorPoint;
  Result := Res;
end;

end.
