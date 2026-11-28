{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.ColorTransition
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MIT (SPDX-License-Identifier: MIT)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.ColorTransition;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  FMX.Controls,
  FMX.Graphics,
  FMX.Objects,
  System.Skia,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Color Transition Effect: Animates Fill / FontColor or paints smooth tint overlay }
  TFluentColorTransitionEffect = class(TFluentMotionEffectBase, ISkiaPaintEffect)
  private
    FFromColor: TAlphaColor;
    FTargetColor: TAlphaColor;
    FStartColor: TAlphaColor;
    FInitialColor: TAlphaColor;
    FCurrentColor: TAlphaColor;
    FAutoCaptureFrom: Boolean;
    FTintOverlay: Boolean;
    FCurrentProgress: Single;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetColor: TAlphaColor; const ADurationMs: Cardinal = 250); reintroduce; overload;
    constructor Create(const AFromColor, ATargetColor: TAlphaColor; const ADurationMs: Cardinal = 250); reintroduce; overload;

    class function MakeTint(const ATintColor: TAlphaColor; const ADurationMs: Cardinal = 250): TFluentColorTransitionEffect; static;

    { ISkiaPaintEffect Implementation }
    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
    procedure PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
    function NeedsRepaint: Boolean;

    function Clone: IMotionEffect; override;

    property TargetColor: TAlphaColor read FTargetColor write FTargetColor;
    property FromColor: TAlphaColor read FFromColor write FFromColor;
    property TintOverlay: Boolean read FTintOverlay write FTintOverlay;
    property CurrentColor: TAlphaColor read FCurrentColor;
  end;

implementation

{ TFluentColorTransitionEffect }

constructor TFluentColorTransitionEffect.Create(const ATargetColor: TAlphaColor; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FTargetColor := ATargetColor;
  FFromColor := $00000000;
  FStartColor := $00000000;
  FInitialColor := $00000000;
  FCurrentColor := $00000000;
  FAutoCaptureFrom := True;
  FTintOverlay := False;
  FCurrentProgress := 0.0;
  FEase := TFluentEase.OutCubic;
end;

constructor TFluentColorTransitionEffect.Create(const AFromColor, ATargetColor: TAlphaColor; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FFromColor := AFromColor;
  FTargetColor := ATargetColor;
  FStartColor := AFromColor;
  FInitialColor := AFromColor;
  FCurrentColor := AFromColor;
  FAutoCaptureFrom := False;
  FTintOverlay := False;
  FCurrentProgress := 0.0;
  FEase := TFluentEase.OutCubic;
end;

class function TFluentColorTransitionEffect.MakeTint(const ATintColor: TAlphaColor; const ADurationMs: Cardinal): TFluentColorTransitionEffect;
begin
  Result := TFluentColorTransitionEffect.Create(ATintColor, ADurationMs);
  Result.FTintOverlay := True;
end;

procedure TFluentColorTransitionEffect.DoAttach;
begin
  if Assigned(FControl) then
  begin
    if FControl is TShape then
      FInitialColor := TShape(FControl).Fill.Color
    else if FControl is TTextControl then
      FInitialColor := TTextControl(FControl).FontColor
    else
    begin
      FInitialColor := $00000000;
      FTintOverlay := True;
    end;

    if FAutoCaptureFrom then
      FFromColor := FInitialColor;
  end;
end;

procedure TFluentColorTransitionEffect.DoStart;
begin
  if FAutoCaptureFrom then
  begin
    if Assigned(FControl) then
    begin
      if FControl is TShape then
        FStartColor := TShape(FControl).Fill.Color
      else if FControl is TTextControl then
        FStartColor := TTextControl(FControl).FontColor
      else
        FStartColor := FFromColor;
    end
    else
      FStartColor := FFromColor;
  end
  else
    FStartColor := FFromColor;

  FCurrentColor := FStartColor;
  FCurrentProgress := 0.0;
end;

procedure TFluentColorTransitionEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  FCurrentProgress := AProgress;
  FCurrentColor := TFluentColorHelper.Lerp(FStartColor, FTargetColor, AProgress);

  if Assigned(FControl) then
  begin
    if FControl is TShape then
      TShape(FControl).Fill.Color := FCurrentColor
    else if FControl is TTextControl then
      TTextControl(FControl).FontColor := FCurrentColor;

    if FTintOverlay then
      FControl.Repaint;
  end;
end;

procedure TFluentColorTransitionEffect.DoFinish;
begin
  FCurrentProgress := 1.0;
  FCurrentColor := FTargetColor;

  if Assigned(FControl) then
  begin
    if FControl is TShape then
      TShape(FControl).Fill.Color := FTargetColor
    else if FControl is TTextControl then
      TTextControl(FControl).FontColor := FTargetColor;

    if FTintOverlay then
      FControl.Repaint;
  end;
end;

procedure TFluentColorTransitionEffect.DoReset;
begin
  FCurrentProgress := 0.0;
  FCurrentColor := FInitialColor;

  if Assigned(FControl) then
  begin
    if FControl is TShape then
      TShape(FControl).Fill.Color := FInitialColor
    else if FControl is TTextControl then
      TTextControl(FControl).FontColor := FInitialColor;

    if FTintOverlay then
      FControl.Repaint;
  end;
end;

function TFluentColorTransitionEffect.NeedsRepaint: Boolean;
begin
  Result := FTintOverlay and (not FIsFinished);
end;

procedure TFluentColorTransitionEffect.Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
var
  LPaint: ISkPaint;
  ColRec: TAlphaColorRec;
begin
  if not FTintOverlay then
    Exit;
  if not Assigned(ACanvas) or (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  ColRec := TAlphaColorRec(FCurrentColor);
  ColRec.A := Round(ColRec.A * AOpacity);

  LPaint := TSkPaint.Create;
  LPaint.Color := TAlphaColor(ColRec);
  LPaint.Blender := TSkBlender.MakeMode(TSkBlendMode.SrcATop);
  ACanvas.DrawRect(ARect, LPaint);
end;

procedure TFluentColorTransitionEffect.PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
var
  ColRec: TAlphaColorRec;
begin
  if not FTintOverlay then
    Exit;
  if not Assigned(ACanvas) or (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  ColRec := TAlphaColorRec(FCurrentColor);
  ColRec.A := Round(ColRec.A * AOpacity);

  ACanvas.Fill.Color := TAlphaColor(ColRec);
  ACanvas.Fill.Kind := TBrushKind.Solid;
  ACanvas.FillRect(ARect, 0, 0, [], 1.0);
end;

function TFluentColorTransitionEffect.Clone: IMotionEffect;
var
  Res: TFluentColorTransitionEffect;
begin
  if FAutoCaptureFrom then
    Res := TFluentColorTransitionEffect.Create(FTargetColor, FDurationMs)
  else
    Res := TFluentColorTransitionEffect.Create(FFromColor, FTargetColor, FDurationMs);

  Res.FTintOverlay := FTintOverlay;
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

end.
