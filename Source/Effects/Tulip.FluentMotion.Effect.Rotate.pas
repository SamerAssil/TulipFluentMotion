{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Rotate
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Rotate;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  TRotateMode = (AbsoluteAngle, RelativeAngle);

  { Rotate Effect (Transforms TControl.RotationAngle using Anchor Point) }
  TFluentRotateEffect = class(TFluentMotionEffectBase, ITransformEffect)
  private
    FTargetAngle: Single;
    FDeltaAngle: Single;
    FStartAngle: Single;
    FInitialAngle: Single;
    FInitialRotationCenter: TPointF;
    FMode: TRotateMode;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetAngleDeg: Single; const ADurationMs: Cardinal = 250); reintroduce;
    class function MakeRelative(const ADeltaAngleDeg: Single; const ADurationMs: Cardinal = 250): TFluentRotateEffect; static;

    { ITransformEffect Implementation }
    procedure CaptureInitialState;
    procedure RestoreInitialState;

    function Clone: IMotionEffect; override;

    property TargetAngle: Single read FTargetAngle write FTargetAngle;
  end;

implementation

type
  TControlAccess = class(TControl);

{ TFluentRotateEffect }

constructor TFluentRotateEffect.Create(const ATargetAngleDeg: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FMode := TRotateMode.AbsoluteAngle;
  FTargetAngle := ATargetAngleDeg;
  FDeltaAngle := 0.0;
end;

class function TFluentRotateEffect.MakeRelative(const ADeltaAngleDeg: Single; const ADurationMs: Cardinal): TFluentRotateEffect;
begin
  Result := TFluentRotateEffect.Create(0, ADurationMs);
  Result.FMode := TRotateMode.RelativeAngle;
  Result.FDeltaAngle := ADeltaAngleDeg;
end;

procedure TFluentRotateEffect.CaptureInitialState;
begin
  if Assigned(FControl) then
  begin
    FInitialAngle := TControlAccess(FControl).RotationAngle;
    FInitialRotationCenter := TControlAccess(FControl).RotationCenter.Point;
  end;
end;

procedure TFluentRotateEffect.RestoreInitialState;
begin
  if Assigned(FControl) then
  begin
    TControlAccess(FControl).RotationCenter.Point := FInitialRotationCenter;
    TControlAccess(FControl).RotationAngle := FInitialAngle;
  end;
end;

procedure TFluentRotateEffect.DoAttach;
begin
  CaptureInitialState;
end;

procedure TFluentRotateEffect.DoStart;
begin
  if Assigned(FControl) then
  begin
    TControlAccess(FControl).RotationCenter.Point := FAnchor.ToPointF(FCustomAnchorPoint);
    FStartAngle := TControlAccess(FControl).RotationAngle;
    if FMode = TRotateMode.RelativeAngle then
      FTargetAngle := FStartAngle + FDeltaAngle;
  end;
end;

procedure TFluentRotateEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurAngle: Single;
begin
  if not Assigned(FControl) then
    Exit;

  CurAngle := FStartAngle + (FTargetAngle - FStartAngle) * AProgress;
  TControlAccess(FControl).RotationAngle := CurAngle;
end;

procedure TFluentRotateEffect.DoReset;
begin
  RestoreInitialState;
end;

function TFluentRotateEffect.Clone: IMotionEffect;
var
  Res: TFluentRotateEffect;
begin
  if FMode = TRotateMode.RelativeAngle then
    Res := TFluentRotateEffect.MakeRelative(FDeltaAngle, FDurationMs)
  else
    Res := TFluentRotateEffect.Create(FTargetAngle, FDurationMs);

  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Res.FAnchor := FAnchor;
  Res.FCustomAnchorPoint := FCustomAnchorPoint;
  Result := Res;
end;

end.
