{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Flip3D
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Flip3D;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Types,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Flip 3D Effect: Simulates 3D perspective card flip around X or Y axis with Anchor Point }
  TFluentFlip3DEffect = class(TFluentMotionEffectBase, ITransformEffect)
  private
    FAxis: TFlipAxis;
    FFromAngleDeg: Single;
    FTargetAngleDeg: Single;
    FStartAngleDeg: Single;
    FInitialScaleX: Single;
    FInitialScaleY: Single;
    FInitialPosX: Single;
    FInitialPosY: Single;
    FStartPosX: Single;
    FStartPosY: Single;
    FAutoCaptureFrom: Boolean;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetAngleDeg: Single; const AAxis: TFlipAxis = TFlipAxis.Horizontal; const ADurationMs: Cardinal = 350); reintroduce; overload;
    constructor Create(const AFromAngleDeg, ATargetAngleDeg: Single; const AAxis: TFlipAxis = TFlipAxis.Horizontal; const ADurationMs: Cardinal = 350); reintroduce; overload;

    { ITransformEffect Implementation }
    procedure CaptureInitialState;
    procedure RestoreInitialState;

    function Clone: IMotionEffect; override;

    property Axis: TFlipAxis read FAxis write FAxis;
    property TargetAngleDeg: Single read FTargetAngleDeg write FTargetAngleDeg;
    property FromAngleDeg: Single read FFromAngleDeg write FFromAngleDeg;
  end;

implementation

type
  TControlAccess = class(TControl);

{ TFluentFlip3DEffect }

constructor TFluentFlip3DEffect.Create(const ATargetAngleDeg: Single; const AAxis: TFlipAxis; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FAxis := AAxis;
  FTargetAngleDeg := ATargetAngleDeg;
  FFromAngleDeg := 0.0;
  FAutoCaptureFrom := True;
  FEase := TFluentEase.InOutCubic;
end;

constructor TFluentFlip3DEffect.Create(const AFromAngleDeg, ATargetAngleDeg: Single; const AAxis: TFlipAxis; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FAxis := AAxis;
  FFromAngleDeg := AFromAngleDeg;
  FTargetAngleDeg := ATargetAngleDeg;
  FAutoCaptureFrom := False;
  FEase := TFluentEase.InOutCubic;
end;

procedure TFluentFlip3DEffect.CaptureInitialState;
begin
  if Assigned(FControl) then
  begin
    FInitialScaleX := TControlAccess(FControl).Scale.X;
    FInitialScaleY := TControlAccess(FControl).Scale.Y;
    FInitialPosX := FControl.Position.X;
    FInitialPosY := FControl.Position.Y;
  end;
end;

procedure TFluentFlip3DEffect.RestoreInitialState;
begin
  if Assigned(FControl) then
  begin
    FControl.Position.X := FInitialPosX;
    FControl.Position.Y := FInitialPosY;
    TControlAccess(FControl).Scale.X := FInitialScaleX;
    TControlAccess(FControl).Scale.Y := FInitialScaleY;
  end;
end;

procedure TFluentFlip3DEffect.DoAttach;
begin
  CaptureInitialState;
  if FAutoCaptureFrom then
    FFromAngleDeg := 0.0;
end;

procedure TFluentFlip3DEffect.DoStart;
begin
  PrepareLayoutOverride;
  CaptureInitialState;
  if Assigned(FControl) then
  begin
    FStartPosX := FControl.Position.X;
    FStartPosY := FControl.Position.Y;
  end;

  if FAutoCaptureFrom then
    FStartAngleDeg := 0.0
  else
    FStartAngleDeg := FFromAngleDeg;
end;

procedure TFluentFlip3DEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurAngleDeg: Single;
  Rad, CosVal: Single;
  AnchorPt: TPointF;
  DeltaW, DeltaH: Single;
begin
  if not Assigned(FControl) then
    Exit;

  CurAngleDeg := FStartAngleDeg + (FTargetAngleDeg - FStartAngleDeg) * AProgress;
  Rad := DegToRad(CurAngleDeg);
  CosVal := Cos(Rad);
  AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);

  if FAxis = TFlipAxis.Horizontal then
  begin
    DeltaW := FControl.Width * (CosVal - 1.0) * FInitialScaleX;
    FControl.Position.X := FStartPosX - (DeltaW * AnchorPt.X);
    TControlAccess(FControl).Scale.X := FInitialScaleX * CosVal;
  end
  else
  begin
    DeltaH := FControl.Height * (CosVal - 1.0) * FInitialScaleY;
    FControl.Position.Y := FStartPosY - (DeltaH * AnchorPt.Y);
    TControlAccess(FControl).Scale.Y := FInitialScaleY * CosVal;
  end;
end;

procedure TFluentFlip3DEffect.DoFinish;
var
  Rad, CosVal: Single;
  AnchorPt: TPointF;
  DeltaW, DeltaH: Single;
begin
  if Assigned(FControl) then
  begin
    Rad := DegToRad(FTargetAngleDeg);
    CosVal := Cos(Rad);
    AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);

    if FAxis = TFlipAxis.Horizontal then
    begin
      DeltaW := FControl.Width * (CosVal - 1.0) * FInitialScaleX;
      FControl.Position.X := FStartPosX - (DeltaW * AnchorPt.X);
      TControlAccess(FControl).Scale.X := FInitialScaleX * CosVal;
    end
    else
    begin
      DeltaH := FControl.Height * (CosVal - 1.0) * FInitialScaleY;
      FControl.Position.Y := FStartPosY - (DeltaH * AnchorPt.Y);
      TControlAccess(FControl).Scale.Y := FInitialScaleY * CosVal;
    end;

    if SameValue(CosVal, 1.0, 0.01) then
      RestoreLayoutOverride;
  end;
end;

procedure TFluentFlip3DEffect.DoReset;
begin
  RestoreInitialState;
  RestoreLayoutOverride;
end;

function TFluentFlip3DEffect.Clone: IMotionEffect;
var
  Res: TFluentFlip3DEffect;
begin
  if FAutoCaptureFrom then
    Res := TFluentFlip3DEffect.Create(FTargetAngleDeg, FAxis, FDurationMs)
  else
    Res := TFluentFlip3DEffect.Create(FFromAngleDeg, FTargetAngleDeg, FAxis, FDurationMs);

  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Res.FAnchor := FAnchor;
  Res.FCustomAnchorPoint := FCustomAnchorPoint;
  Result := Res;
end;

end.
