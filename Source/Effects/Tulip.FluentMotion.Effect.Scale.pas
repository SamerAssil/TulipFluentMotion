{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Scale
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Scale;

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
  { Scale Effect (Transforms Scale.X and Scale.Y with Anchor Point compensation) }
  TFluentScaleEffect = class(TFluentMotionEffectBase, ITransformEffect)
  private
    FFromScaleX: Single;
    FFromScaleY: Single;
    FTargetScaleX: Single;
    FTargetScaleY: Single;
    FInitialScaleX: Single;
    FInitialScaleY: Single;
    FInitialPosX: Single;
    FInitialPosY: Single;
    FBasePosX: Single;
    FBasePosY: Single;
    FLastAnchorOffsetX: Single;
    FLastAnchorOffsetY: Single;
    FAutoCaptureFrom: Boolean;
    FSuppressPositionUpdate: Boolean;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetScale: Single; const ADurationMs: Cardinal = 250); reintroduce; overload;
    constructor Create(const AFromScale, ATargetScale: Single; const ADurationMs: Cardinal = 250); reintroduce; overload;
    class function MakeXY(const ATargetScaleX, ATargetScaleY: Single; const ADurationMs: Cardinal = 250): TFluentScaleEffect; static;

    { ITransformEffect Implementation }
    procedure CaptureInitialState;
    procedure RestoreInitialState;

    function Clone: IMotionEffect; override;

    property TargetScaleX: Single read FTargetScaleX write FTargetScaleX;
    property TargetScaleY: Single read FTargetScaleY write FTargetScaleY;
    property SuppressPositionUpdate: Boolean read FSuppressPositionUpdate write FSuppressPositionUpdate;
  end;

implementation

type
  TControlAccess = class(TControl);

{ TFluentScaleEffect }

constructor TFluentScaleEffect.Create(const ATargetScale: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FTargetScaleX := ATargetScale;
  FTargetScaleY := ATargetScale;
  FFromScaleX := 1.0;
  FFromScaleY := 1.0;
  FAutoCaptureFrom := True;
end;

constructor TFluentScaleEffect.Create(const AFromScale, ATargetScale: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FFromScaleX := AFromScale;
  FFromScaleY := AFromScale;
  FTargetScaleX := ATargetScale;
  FTargetScaleY := ATargetScale;
  FAutoCaptureFrom := False;
end;

class function TFluentScaleEffect.MakeXY(const ATargetScaleX, ATargetScaleY: Single; const ADurationMs: Cardinal): TFluentScaleEffect;
begin
  Result := TFluentScaleEffect.Create(ATargetScaleX, ADurationMs);
  Result.FTargetScaleY := ATargetScaleY;
  Result.FFromScaleX := 1.0;
  Result.FFromScaleY := 1.0;
  Result.FAutoCaptureFrom := True;
end;

procedure TFluentScaleEffect.CaptureInitialState;
var
  AnchorPt: TPointF;
  CurScaleX, CurScaleY: Single;
begin
  if Assigned(FControl) then
  begin
    AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
    CurScaleX := TControlAccess(FControl).Scale.X;
    CurScaleY := TControlAccess(FControl).Scale.Y;

    if SameValue(CurScaleX, FTargetScaleX, 0.001) then
      FInitialScaleX := 1.0
    else
      FInitialScaleX := CurScaleX;

    if SameValue(CurScaleY, FTargetScaleY, 0.001) then
      FInitialScaleY := 1.0
    else
      FInitialScaleY := CurScaleY;

    // Calculate unscaled base position
    FInitialPosX := FControl.Position.X + (FControl.Width * (CurScaleX - 1.0) * AnchorPt.X);
    FInitialPosY := FControl.Position.Y + (FControl.Height * (CurScaleY - 1.0) * AnchorPt.Y);

    if FAutoCaptureFrom then
    begin
      FFromScaleX := FInitialScaleX;
      FFromScaleY := FInitialScaleY;
    end;
  end;
end;

procedure TFluentScaleEffect.RestoreInitialState;
begin
  if Assigned(FControl) then
  begin
    FControl.Position.X := FInitialPosX;
    FControl.Position.Y := FInitialPosY;
    if FAutoCaptureFrom then
    begin
      TControlAccess(FControl).Scale.X := FInitialScaleX;
      TControlAccess(FControl).Scale.Y := FInitialScaleY;
    end
    else
    begin
      TControlAccess(FControl).Scale.X := FFromScaleX;
      TControlAccess(FControl).Scale.Y := FFromScaleY;
    end;
  end;
end;

procedure TFluentScaleEffect.DoAttach;
begin
  CaptureInitialState;
end;

procedure TFluentScaleEffect.DoStart;
var
  AnchorPt: TPointF;
  CurScaleX, CurScaleY: Single;
begin
  PrepareLayoutOverride;
  if Assigned(FControl) then
  begin
    AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
    CurScaleX := TControlAccess(FControl).Scale.X;
    CurScaleY := TControlAccess(FControl).Scale.Y;

    // Calculate unscaled base position (used by RestoreInitialState)
    FBasePosX := FControl.Position.X + (FControl.Width * (CurScaleX - 1.0) * AnchorPt.X);
    FBasePosY := FControl.Position.Y + (FControl.Height * (CurScaleY - 1.0) * AnchorPt.Y);
    FLastAnchorOffsetX := 0.0;
    FLastAnchorOffsetY := 0.0;

    if FIsReversed then
      Exit;

    if FAutoCaptureFrom then
    begin
      if SameValue(CurScaleX, FTargetScaleX, 0.001) then
      begin
        FFromScaleX := 1.0;
        TControlAccess(FControl).Scale.X := 1.0;
      end
      else
        FFromScaleX := CurScaleX;

      if SameValue(CurScaleY, FTargetScaleY, 0.001) then
      begin
        FFromScaleY := 1.0;
        TControlAccess(FControl).Scale.Y := 1.0;
      end
      else
        FFromScaleY := CurScaleY;

      if not FSuppressPositionUpdate and ((AnchorPt.X <> 0) or (AnchorPt.Y <> 0)) then
      begin
        if not SameValue(TControlAccess(FControl).Scale.X, CurScaleX, 0.0001) then
          FControl.Position.X := FControl.Position.X - (FControl.Width * (TControlAccess(FControl).Scale.X - CurScaleX) * AnchorPt.X);
        if not SameValue(TControlAccess(FControl).Scale.Y, CurScaleY, 0.0001) then
          FControl.Position.Y := FControl.Position.Y - (FControl.Height * (TControlAccess(FControl).Scale.Y - CurScaleY) * AnchorPt.Y);
      end;
    end
    else
    begin
      TControlAccess(FControl).Scale.X := FFromScaleX;
      TControlAccess(FControl).Scale.Y := FFromScaleY;
      if not FSuppressPositionUpdate and ((AnchorPt.X <> 0) or (AnchorPt.Y <> 0)) then
      begin
        if not SameValue(FFromScaleX, CurScaleX, 0.0001) then
          FControl.Position.X := FControl.Position.X - (FControl.Width * (FFromScaleX - CurScaleX) * AnchorPt.X);
        if not SameValue(FFromScaleY, CurScaleY, 0.0001) then
          FControl.Position.Y := FControl.Position.Y - (FControl.Height * (FFromScaleY - CurScaleY) * AnchorPt.Y);
      end;
    end;
  end;
end;

procedure TFluentScaleEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurX, CurY: Single;
  NewOffsetX, NewOffsetY: Single;
  AnchorPt: TPointF;
begin
  if not Assigned(FControl) then
    Exit;

  CurX := FFromScaleX + (FTargetScaleX - FFromScaleX) * AProgress;
  CurY := FFromScaleY + (FTargetScaleY - FFromScaleY) * AProgress;

  if not FSuppressPositionUpdate then
  begin
    AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
    if (AnchorPt.X <> 0) or (AnchorPt.Y <> 0) then
    begin
      NewOffsetX := -FControl.Width * (CurX - FFromScaleX) * AnchorPt.X;
      NewOffsetY := -FControl.Height * (CurY - FFromScaleY) * AnchorPt.Y;
      if not SameValue(NewOffsetX, FLastAnchorOffsetX, 0.0) then
        FControl.Position.X := FControl.Position.X + (NewOffsetX - FLastAnchorOffsetX);
      if not SameValue(NewOffsetY, FLastAnchorOffsetY, 0.0) then
        FControl.Position.Y := FControl.Position.Y + (NewOffsetY - FLastAnchorOffsetY);
      FLastAnchorOffsetX := NewOffsetX;
      FLastAnchorOffsetY := NewOffsetY;
    end;
  end;

  TControlAccess(FControl).Scale.X := CurX;
  TControlAccess(FControl).Scale.Y := CurY;
end;

procedure TFluentScaleEffect.DoFinish;
begin
  if Assigned(FControl) then
  begin
    if SameValue(TControlAccess(FControl).Scale.X, FInitialScaleX, 0.01) and
       SameValue(TControlAccess(FControl).Scale.Y, FInitialScaleY, 0.01) then
      RestoreLayoutOverride;
  end;
end;

procedure TFluentScaleEffect.DoReset;
begin
  RestoreInitialState;
  RestoreLayoutOverride;
end;

function TFluentScaleEffect.Clone: IMotionEffect;
var
  Res: TFluentScaleEffect;
begin
  Res := TFluentScaleEffect.MakeXY(FTargetScaleX, FTargetScaleY, FDurationMs);
  Res.FFromScaleX := FFromScaleX;
  Res.FFromScaleY := FFromScaleY;
  Res.FAutoCaptureFrom := FAutoCaptureFrom;
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Res.FAnchor := FAnchor;
  Res.FCustomAnchorPoint := FCustomAnchorPoint;
  Res.FSuppressPositionUpdate := FSuppressPositionUpdate;
  Result := Res;
end;

end.
