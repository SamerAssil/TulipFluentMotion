{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Shake
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Shake;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Shake Effect (Damped harmonic oscillation for error indication) }
  TFluentShakeEffect = class(TFluentMotionEffectBase, ITransformEffect)
  private
    FIntensity: Single;      // Maximum displacement in pixels
    FFrequency: Single;     // Number of full oscillations
    FInitialX: Single;
    FInitialY: Single;
    FLastOffsetX: Single;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const AIntensity: Single = 8.0; const ADurationMs: Cardinal = 350; const AFrequency: Single = 3.5); reintroduce;

    { ITransformEffect Implementation }
    procedure CaptureInitialState;
    procedure RestoreInitialState;

    function Clone: IMotionEffect; override;

    property Intensity: Single read FIntensity write FIntensity;
    property Frequency: Single read FFrequency write FFrequency;
  end;

implementation

{ TFluentShakeEffect }

constructor TFluentShakeEffect.Create(const AIntensity: Single; const ADurationMs: Cardinal; const AFrequency: Single);
begin
  inherited Create(ADurationMs);
  FIntensity := AIntensity;
  FFrequency := Max(1.0, AFrequency);
  FEase := TFluentEase.Linear; // Linear progress, oscillation handled internally
end;

procedure TFluentShakeEffect.CaptureInitialState;
begin
  if Assigned(FControl) then
  begin
    FInitialX := FControl.Position.X;
    FInitialY := FControl.Position.Y;
  end;
end;

procedure TFluentShakeEffect.RestoreInitialState;
begin
  if Assigned(FControl) then
  begin
    FControl.Position.X := FInitialX;
    FControl.Position.Y := FInitialY;
  end;
end;

procedure TFluentShakeEffect.DoAttach;
begin
  CaptureInitialState;
end;

procedure TFluentShakeEffect.DoStart;
begin
  PrepareLayoutOverride;
  CaptureInitialState;
  FLastOffsetX := 0.0;
end;

procedure TFluentShakeEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  Decay, Offset: Single;
begin
  if not Assigned(FControl) then
    Exit;

  // Exponential decay envelope from 1.0 down to 0.0
  Decay := 1.0 - AProgress;
  // Damped sinusoidal wave
  Offset := FIntensity * Decay * Sin(AProgress * (2.0 * Pi * FFrequency));

  FControl.Position.X := FControl.Position.X + (Offset - FLastOffsetX);
  FLastOffsetX := Offset;
end;

procedure TFluentShakeEffect.DoFinish;
begin
  if Assigned(FControl) and (FLastOffsetX <> 0.0) then
  begin
    FControl.Position.X := FControl.Position.X - FLastOffsetX;
    FLastOffsetX := 0.0;
  end;
  RestoreLayoutOverride;
end;

procedure TFluentShakeEffect.DoReset;
begin
  if Assigned(FControl) and (FLastOffsetX <> 0.0) then
  begin
    FControl.Position.X := FControl.Position.X - FLastOffsetX;
    FLastOffsetX := 0.0;
  end;
  RestoreLayoutOverride;
end;

function TFluentShakeEffect.Clone: IMotionEffect;
var
  Res: TFluentShakeEffect;
begin
  Res := TFluentShakeEffect.Create(FIntensity, FDurationMs, FFrequency);
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

end.
