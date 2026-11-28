{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Resize
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MIT (SPDX-License-Identifier: MIT)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Resize;

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
  { Resize Effect: Smoothly animates actual Width and Height dimensions with Anchor Point }
  TFluentResizeEffect = class(TFluentMotionEffectBase, ITransformEffect)
  private
    FFromWidth: Single;
    FTargetWidth: Single;
    FFromHeight: Single;
    FTargetHeight: Single;
    FStartWidth: Single;
    FStartHeight: Single;
    FInitialWidth: Single;
    FInitialHeight: Single;
    FStartPosX: Single;
    FStartPosY: Single;
    FInitialPosX: Single;
    FInitialPosY: Single;
    FAutoCapture: Boolean;
    FAnimateWidth: Boolean;
    FAnimateHeight: Boolean;
    FSuppressPositionUpdate: Boolean;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center); reintroduce; overload;
    constructor Create(const AFromWidth, ATargetWidth, AFromHeight, ATargetHeight: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center); reintroduce; overload;

    class function MakeWidth(const ATargetWidth: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): TFluentResizeEffect; static;
    class function MakeHeight(const ATargetHeight: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.Center): TFluentResizeEffect; static;

    { ITransformEffect Implementation }
    procedure CaptureInitialState;
    procedure RestoreInitialState;

    function Clone: IMotionEffect; override;

    property TargetWidth: Single read FTargetWidth write FTargetWidth;
    property TargetHeight: Single read FTargetHeight write FTargetHeight;
    property SuppressPositionUpdate: Boolean read FSuppressPositionUpdate write FSuppressPositionUpdate;
  end;

implementation

{ TFluentResizeEffect }

constructor TFluentResizeEffect.Create(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor);
begin
  inherited Create(ADurationMs);
  FTargetWidth := Max(0.0, ATargetWidth);
  FTargetHeight := Max(0.0, ATargetHeight);
  FFromWidth := 0.0;
  FFromHeight := 0.0;
  FAutoCapture := True;
  FAnimateWidth := True;
  FAnimateHeight := True;
  FAnchor := AAnchor;
  FEase := TFluentEase.OutCubic;
end;

constructor TFluentResizeEffect.Create(const AFromWidth, ATargetWidth, AFromHeight, ATargetHeight: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor);
begin
  inherited Create(ADurationMs);
  FFromWidth := Max(0.0, AFromWidth);
  FTargetWidth := Max(0.0, ATargetWidth);
  FFromHeight := Max(0.0, AFromHeight);
  FTargetHeight := Max(0.0, ATargetHeight);
  FAutoCapture := False;
  FAnimateWidth := True;
  FAnimateHeight := True;
  FAnchor := AAnchor;
  FEase := TFluentEase.OutCubic;
end;

class function TFluentResizeEffect.MakeWidth(const ATargetWidth: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): TFluentResizeEffect;
begin
  Result := TFluentResizeEffect.Create(ATargetWidth, 0.0, ADurationMs, AAnchor);
  Result.FAnimateHeight := False;
end;

class function TFluentResizeEffect.MakeHeight(const ATargetHeight: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): TFluentResizeEffect;
begin
  Result := TFluentResizeEffect.Create(0.0, ATargetHeight, ADurationMs, AAnchor);
  Result.FAnimateWidth := False;
end;

procedure TFluentResizeEffect.CaptureInitialState;
begin
  if Assigned(FControl) then
  begin
    FInitialWidth := FControl.Width;
    FInitialHeight := FControl.Height;
    FInitialPosX := FControl.Position.X;
    FInitialPosY := FControl.Position.Y;
    if FAutoCapture then
    begin
      FFromWidth := FInitialWidth;
      FFromHeight := FInitialHeight;
    end;
  end;
end;

procedure TFluentResizeEffect.RestoreInitialState;
begin
  if Assigned(FControl) then
  begin
    FControl.Position.X := FInitialPosX;
    FControl.Position.Y := FInitialPosY;
    if FAnimateWidth then
      FControl.Width := FInitialWidth;
    if FAnimateHeight then
      FControl.Height := FInitialHeight;
  end;
end;

procedure TFluentResizeEffect.DoAttach;
begin
  CaptureInitialState;
end;

procedure TFluentResizeEffect.DoStart;
begin
  PrepareLayoutOverride;
  CaptureInitialState;
  if FAutoCapture then
  begin
    FStartWidth := FInitialWidth;
    FStartHeight := FInitialHeight;
  end
  else
  begin
    FStartWidth := FFromWidth;
    FStartHeight := FFromHeight;
  end;

  if Assigned(FControl) then
  begin
    FStartPosX := FControl.Position.X;
    FStartPosY := FControl.Position.Y;
  end
  else
  begin
    FStartPosX := 0.0;
    FStartPosY := 0.0;
  end;
end;

procedure TFluentResizeEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurW, CurH, DeltaW, DeltaH: Single;
  AnchorPt: TPointF;
begin
  if not Assigned(FControl) then
    Exit;

  if FAnimateWidth then
    CurW := Max(0.0, FStartWidth + (FTargetWidth - FStartWidth) * AProgress)
  else
    CurW := FStartWidth;

  if FAnimateHeight then
    CurH := Max(0.0, FStartHeight + (FTargetHeight - FStartHeight) * AProgress)
  else
    CurH := FStartHeight;

  DeltaW := CurW - FStartWidth;
  DeltaH := CurH - FStartHeight;

  if not FSuppressPositionUpdate then
  begin
    AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
    if (AnchorPt.X <> 0) or (AnchorPt.Y <> 0) then
    begin
      FControl.Position.X := FStartPosX - (DeltaW * AnchorPt.X);
      FControl.Position.Y := FStartPosY - (DeltaH * AnchorPt.Y);
    end;
  end;

  if FAnimateWidth then
    FControl.Width := CurW;
  if FAnimateHeight then
    FControl.Height := CurH;
end;

procedure TFluentResizeEffect.DoFinish;
var
  FinalW, FinalH, DeltaW, DeltaH: Single;
  AnchorPt: TPointF;
begin
  if not Assigned(FControl) then
    Exit;

  if FAnimateWidth then
    FinalW := FTargetWidth
  else
    FinalW := FStartWidth;

  if FAnimateHeight then
    FinalH := FTargetHeight
  else
    FinalH := FStartHeight;

  DeltaW := FinalW - FStartWidth;
  DeltaH := FinalH - FStartHeight;

  if not FSuppressPositionUpdate then
  begin
    AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
    if (AnchorPt.X <> 0) or (AnchorPt.Y <> 0) then
    begin
      FControl.Position.X := FStartPosX - (DeltaW * AnchorPt.X);
      FControl.Position.Y := FStartPosY - (DeltaH * AnchorPt.Y);
    end;
  end;

  if FAnimateWidth then
    FControl.Width := FinalW;
  if FAnimateHeight then
    FControl.Height := FinalH;

  RestoreLayoutOverride;
end;

procedure TFluentResizeEffect.DoReset;
begin
  RestoreInitialState;
  RestoreLayoutOverride;
end;

function TFluentResizeEffect.Clone: IMotionEffect;
var
  Res: TFluentResizeEffect;
begin
  Res := TFluentResizeEffect.Create(FFromWidth, FTargetWidth, FFromHeight, FTargetHeight, FDurationMs, FAnchor);
  Res.FAnimateWidth := FAnimateWidth;
  Res.FAnimateHeight := FAnimateHeight;
  Res.FAutoCapture := FAutoCapture;
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Res.FCustomAnchorPoint := FCustomAnchorPoint;
  Res.FSuppressPositionUpdate := FSuppressPositionUpdate;
  Result := Res;
end;

end.
