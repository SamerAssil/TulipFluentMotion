{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Ripple
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Ripple;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  System.Math,
  FMX.Controls,
  FMX.Graphics,
  System.Skia,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Ripple Effect (Skia and FMX-rendered expanding circular water wave) }
  TFluentRippleEffect = class(TFluentMotionEffectBase, ISkiaPaintEffect)
  private
    FConfig: TFluentRippleConfig;
    FCurrentProgress: Single;
  protected
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
  public
    constructor Create(const ADurationMs: Cardinal = 450); reintroduce; overload;
    constructor Create(const AConfig: TFluentRippleConfig; const ADurationMs: Cardinal = 450); reintroduce; overload;

    { ISkiaPaintEffect Implementation }
    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
    procedure PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
    function NeedsRepaint: Boolean;

    function Clone: IMotionEffect; override;

    property Config: TFluentRippleConfig read FConfig write FConfig;
  end;

implementation

{ TFluentRippleEffect }

constructor TFluentRippleEffect.Create(const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FConfig := TFluentRippleConfig.Default;
  FEase := TFluentEase.OutCubic;
  FCurrentProgress := 0.0;
end;

constructor TFluentRippleEffect.Create(const AConfig: TFluentRippleConfig; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FConfig := AConfig;
  FEase := TFluentEase.OutCubic;
  FCurrentProgress := 0.0;
end;

procedure TFluentRippleEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  FCurrentProgress := AProgress;
  if Assigned(FControl) then
    FControl.Repaint;
end;

function TFluentRippleEffect.NeedsRepaint: Boolean;
begin
  Result := (not FIsFinished) and (FCurrentProgress > 0.0) and (FCurrentProgress < 1.0);
end;

procedure TFluentRippleEffect.Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
var
  LPaint: ISkPaint;
  LCenter, AnchorPt: TPointF;
  LMaxRadius, LCurrentRadius, LFadeAlpha: Single;
begin
  if not Assigned(ACanvas) or (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  if FIsFinished or (FCurrentProgress <= 0.0) or (FCurrentProgress >= 1.0) then
    Exit;

  if (FAnchor <> TMotionAnchor.Center) then
  begin
    AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
    LCenter := PointF(ARect.Left + (ARect.Width * AnchorPt.X), ARect.Top + (ARect.Height * AnchorPt.Y));
  end
  else if FConfig.AutoCenter then
    LCenter := PointF(ARect.Left + (ARect.Width * 0.5), ARect.Top + (ARect.Height * 0.5))
  else
    LCenter := PointF(ARect.Left + FConfig.Origin.X, ARect.Top + FConfig.Origin.Y);

  LMaxRadius := Max(ARect.Width, ARect.Height) * FConfig.MaxRadiusFraction;
  LCurrentRadius := LMaxRadius * FCurrentProgress;

  LFadeAlpha := (1.0 - FCurrentProgress) * AOpacity;

  LPaint := TSkPaint.Create;
  LPaint.Color := FConfig.RippleColor;
  LPaint.AlphaF := EnsureRange(LFadeAlpha, 0.0, 1.0);
  LPaint.AntiAlias := True;

  ACanvas.Save;
  try
    ACanvas.ClipRect(ARect, TSkClipOp.Intersect, True);
    ACanvas.DrawCircle(LCenter, LCurrentRadius, LPaint);
  finally
    ACanvas.Restore;
  end;
end;

procedure TFluentRippleEffect.PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
var
  LState: TCanvasSaveState;
  LCenter, AnchorPt: TPointF;
  LMaxRadius, LCurrentRadius, LFadeAlpha: Single;
  R: TRectF;
begin
  if not Assigned(ACanvas) or (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  if FIsFinished or (FCurrentProgress <= 0.0) or (FCurrentProgress >= 1.0) then
    Exit;

  if (FAnchor <> TMotionAnchor.Center) then
  begin
    AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
    LCenter := PointF(ARect.Left + (ARect.Width * AnchorPt.X), ARect.Top + (ARect.Height * AnchorPt.Y));
  end
  else if FConfig.AutoCenter then
    LCenter := PointF(ARect.Left + (ARect.Width * 0.5), ARect.Top + (ARect.Height * 0.5))
  else
    LCenter := PointF(ARect.Left + FConfig.Origin.X, ARect.Top + FConfig.Origin.Y);

  LMaxRadius := Max(ARect.Width, ARect.Height) * FConfig.MaxRadiusFraction;
  LCurrentRadius := LMaxRadius * FCurrentProgress;
  LFadeAlpha := (1.0 - FCurrentProgress) * AOpacity;

  R := TRectF.Create(LCenter.X - LCurrentRadius, LCenter.Y - LCurrentRadius,
                     LCenter.X + LCurrentRadius, LCenter.Y + LCurrentRadius);

  LState := ACanvas.SaveState;
  try
    ACanvas.IntersectClipRect(ARect);
    ACanvas.Fill.Kind := TBrushKind.Solid;
    ACanvas.Fill.Color := FConfig.RippleColor;
    ACanvas.FillEllipse(R, EnsureRange(LFadeAlpha, 0.0, 1.0));
  finally
    ACanvas.RestoreState(LState);
  end;
end;

function TFluentRippleEffect.Clone: IMotionEffect;
var
  Res: TFluentRippleEffect;
begin
  Res := TFluentRippleEffect.Create(FConfig, FDurationMs);
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Res.FAnchor := FAnchor;
  Res.FCustomAnchorPoint := FCustomAnchorPoint;
  Result := Res;
end;

end.
