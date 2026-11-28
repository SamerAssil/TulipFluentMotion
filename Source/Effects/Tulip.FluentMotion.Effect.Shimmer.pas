{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Shimmer
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Shimmer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  System.Math,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  FMX.Objects,
  FMX.StdCtrls,
  FMX.TextLayout,
  System.Skia,
  FMX.Skia,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Shimmer Effect (Crisp sweeping light beam across control or glyph path with Skia and FMX fallback) }
  TFluentShimmerEffect = class(TFluentMotionEffectBase, ISkiaPaintEffect)
  private
    FConfig: TFluentShimmerConfig;
    FCurrentProgress: Single;
    FTextPath: TPathData;
    procedure CalculateGeometry(const ARect: TRectF; out APt1, APt2: TPointF; out ABandPx: Single);
    procedure EnsureTextPath(const ARect: TRectF);
  protected
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
  public
    constructor Create(const ADurationMs: Cardinal = 850); reintroduce; overload;
    constructor Create(const AConfig: TFluentShimmerConfig; const ADurationMs: Cardinal = 850); reintroduce; overload;
    destructor Destroy; override;

    { ISkiaPaintEffect Implementation }
    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
    procedure PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
    function NeedsRepaint: Boolean;

    function Clone: IMotionEffect; override;

    property Config: TFluentShimmerConfig read FConfig write FConfig;
    property AngleDeg: Single read FConfig.AngleDeg write FConfig.AngleDeg;
    property Direction: TShimmerDirection read FConfig.Direction write FConfig.Direction;
  end;

implementation

uses
  Tulip.FluentMotion.Effect.Text;

{ TFluentShimmerEffect }

constructor TFluentShimmerEffect.Create(const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FConfig := TFluentShimmerConfig.Default;
  FEase := TFluentEase.Linear; // Linear constant sweep velocity
  FCurrentProgress := 0.0;
  FTextPath := nil;
end;

constructor TFluentShimmerEffect.Create(const AConfig: TFluentShimmerConfig; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FConfig := AConfig;
  FEase := TFluentEase.Linear;
  FCurrentProgress := 0.0;
  FTextPath := nil;
end;

destructor TFluentShimmerEffect.Destroy;
begin
  FreeAndNil(FTextPath);
  inherited Destroy;
end;

procedure TFluentShimmerEffect.EnsureTextPath(const ARect: TRectF);
var
  Layout: TTextLayout;
  LText: string;
  LFont: TFont;
  LWordWrap: Boolean;
  LHorzAlign, LVertAlign: TTextAlign;
begin
  if not FConfig.MaskToText then
    Exit;

  if Assigned(FTextPath) then
    Exit;

  if not Assigned(FControl) then
    Exit;

  LFont := nil;
  LWordWrap := False;
  LHorzAlign := TTextAlign.Center;
  LVertAlign := TTextAlign.Center;

  if FControl is TText then
  begin
    LText := TText(FControl).Text;
    LFont := TText(FControl).Font;
    LWordWrap := TText(FControl).WordWrap;
    LHorzAlign := TText(FControl).HorzTextAlign;
    LVertAlign := TText(FControl).VertTextAlign;
  end
  else if FControl is TLabel then
  begin
    LText := TLabel(FControl).Text;
    LFont := TLabel(FControl).Font;
    LWordWrap := TLabel(FControl).WordWrap;
    LHorzAlign := TLabel(FControl).TextAlign;
    LVertAlign := TLabel(FControl).VertTextAlign;
  end
  else
  begin
    LText := TFluentTextHelper.GetText(FControl);
  end;

  if LText = '' then
    Exit;

  FTextPath := TPathData.Create;
  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.BeginUpdate;
    try
      Layout.TopLeft := ARect.TopLeft;
      Layout.MaxSize := PointF(ARect.Width, ARect.Height);
      Layout.Text := LText;
      Layout.WordWrap := LWordWrap;
      Layout.HorizontalAlign := LHorzAlign;
      Layout.VerticalAlign := LVertAlign;
      if Assigned(LFont) then
        Layout.Font := LFont;
    finally
      Layout.EndUpdate;
    end;
    Layout.ConvertToPath(FTextPath);
  finally
    Layout.Free;
  end;
end;

procedure TFluentShimmerEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  FCurrentProgress := AProgress;
  if Assigned(FControl) then
    FControl.Repaint;
end;

function TFluentShimmerEffect.NeedsRepaint: Boolean;
begin
  Result := (not FIsFinished) and (FCurrentProgress > 0.0) and (FCurrentProgress < 1.0);
end;

procedure TFluentShimmerEffect.CalculateGeometry(const ARect: TRectF; out APt1, APt2: TPointF; out ABandPx: Single);
var
  Rad, TanA, CosA, SinA, BandHalf, TiltOffset, TotalTravel: Single;
  StartX, StartY, CenterX, CenterY: Single;
begin
  Rad := DegToRad(FConfig.AngleDeg);
  CosA := Cos(Rad);
  SinA := Sin(Rad);
  TanA := Tan(Rad);

  case FConfig.Direction of
    TShimmerDirection.LeftToRight:
    begin
      ABandPx := EnsureRange(ARect.Width * FConfig.BandWidth, 25.0, Max(35.0, ARect.Width * 0.35));
      BandHalf := ABandPx * 0.5;
      TiltOffset := Abs(ARect.Height * TanA);
      TotalTravel := ARect.Width + TiltOffset + (ABandPx * 2.0);

      StartX := ARect.Left - BandHalf - (TiltOffset * 0.5);
      CenterX := StartX + (TotalTravel * FCurrentProgress);
      CenterY := ARect.Top + (ARect.Height * 0.5);

      APt1 := PointF(CenterX - BandHalf * CosA, CenterY - BandHalf * SinA);
      APt2 := PointF(CenterX + BandHalf * CosA, CenterY + BandHalf * SinA);
    end;

    TShimmerDirection.RightToLeft:
    begin
      ABandPx := EnsureRange(ARect.Width * FConfig.BandWidth, 25.0, Max(35.0, ARect.Width * 0.35));
      BandHalf := ABandPx * 0.5;
      TiltOffset := Abs(ARect.Height * TanA);
      TotalTravel := ARect.Width + TiltOffset + (ABandPx * 2.0);

      // Start completely outside Right, travel to Left
      StartX := ARect.Right + BandHalf + (TiltOffset * 0.5);
      CenterX := StartX - (TotalTravel * FCurrentProgress);
      CenterY := ARect.Top + (ARect.Height * 0.5);

      // Gradient vector along the beam
      APt1 := PointF(CenterX + BandHalf * CosA, CenterY - BandHalf * SinA);
      APt2 := PointF(CenterX - BandHalf * CosA, CenterY + BandHalf * SinA);
    end;

    TShimmerDirection.TopToBottom:
    begin
      ABandPx := EnsureRange(ARect.Height * FConfig.BandWidth, 25.0, Max(35.0, ARect.Height * 0.35));
      BandHalf := ABandPx * 0.5;
      TiltOffset := Abs(ARect.Width * TanA);
      TotalTravel := ARect.Height + TiltOffset + (ABandPx * 2.0);

      StartY := ARect.Top - BandHalf - (TiltOffset * 0.5);
      CenterY := StartY + (TotalTravel * FCurrentProgress);
      CenterX := ARect.Left + (ARect.Width * 0.5);

      APt1 := PointF(CenterX - BandHalf * SinA, CenterY - BandHalf * CosA);
      APt2 := PointF(CenterX + BandHalf * SinA, CenterY + BandHalf * CosA);
    end;

    TShimmerDirection.BottomToTop:
    begin
      ABandPx := EnsureRange(ARect.Height * FConfig.BandWidth, 25.0, Max(35.0, ARect.Height * 0.35));
      BandHalf := ABandPx * 0.5;
      TiltOffset := Abs(ARect.Width * TanA);
      TotalTravel := ARect.Height + TiltOffset + (ABandPx * 2.0);

      StartY := ARect.Bottom + BandHalf + (TiltOffset * 0.5);
      CenterY := StartY - (TotalTravel * FCurrentProgress);
      CenterX := ARect.Left + (ARect.Width * 0.5);

      APt1 := PointF(CenterX - BandHalf * SinA, CenterY + BandHalf * CosA);
      APt2 := PointF(CenterX + BandHalf * SinA, CenterY - BandHalf * CosA);
    end;
  end;
end;

procedure TFluentShimmerEffect.Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
var
  LPaint: ISkPaint;
  LShader: ISkShader;
  Pt1, Pt2: TPointF;
  BandPx: Single;
  LColors: TArray<TAlphaColor>;
  LPositions: TArray<Single>;
begin
  if not Assigned(ACanvas) or (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  if FIsFinished or (FCurrentProgress <= 0.0) or (FCurrentProgress >= 1.0) then
    Exit;

  EnsureTextPath(ARect);

  if FConfig.MaskToText then
  begin
    if (FTextPath = nil) or (FTextPath.Count = 0) then
      Exit;
  end;

  CalculateGeometry(ARect, Pt1, Pt2, BandPx);

  SetLength(LColors, 5);
  LColors[0] := FConfig.BaseColor;
  LColors[1] := FConfig.BaseColor;
  LColors[2] := FConfig.HighlightColor;
  LColors[3] := FConfig.BaseColor;
  LColors[4] := FConfig.BaseColor;

  SetLength(LPositions, 5);
  LPositions[0] := 0.0;
  LPositions[1] := 0.25;
  LPositions[2] := 0.50;
  LPositions[3] := 0.75;
  LPositions[4] := 1.0;

  LShader := TSkShader.MakeGradientLinear(Pt1, Pt2, LColors, LPositions, TSkTileMode.Clamp);
  if not Assigned(LShader) then
    Exit;

  LPaint := TSkPaint.Create;
  LPaint.AntiAlias := True;
  LPaint.Shader := LShader;
  LPaint.Blender := TSkBlender.MakeMode(TSkBlendMode.SrcOver);
  LPaint.AlphaF := EnsureRange(AOpacity, 0.0, 1.0);

  ACanvas.Save;
  try
    if FConfig.MaskToText and Assigned(FTextPath) then
    begin
      // Draw shader exclusively within the text glyph contours
      ACanvas.DrawPath(FTextPath.ToSkPath, LPaint);
    end
    else
    begin
      ACanvas.ClipRect(ARect, TSkClipOp.Intersect, True);
      ACanvas.DrawRect(ARect, LPaint);
    end;
  finally
    ACanvas.Restore;
  end;
end;

procedure TFluentShimmerEffect.PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
var
  LState: TCanvasSaveState;
  Pt1, Pt2: TPointF;
  BandPx: Single;
  P0, P1, P2, P3, P4: TGradientPoint;
  NormStart, NormStop: TPointF;
begin
  if not Assigned(ACanvas) or (ARect.Width <= 1.0) or (ARect.Height <= 1.0) then
    Exit;

  if FIsFinished or (FCurrentProgress <= 0.0) or (FCurrentProgress >= 1.0) then
    Exit;

  EnsureTextPath(ARect);

  if FConfig.MaskToText then
  begin
    if (FTextPath = nil) or (FTextPath.Count = 0) then
      Exit;
  end;

  CalculateGeometry(ARect, Pt1, Pt2, BandPx);

  // Normalize pixel coordinates to [0..1] range for FMX TGradient
  NormStart := PointF((Pt1.X - ARect.Left) / ARect.Width, (Pt1.Y - ARect.Top) / ARect.Height);
  NormStop := PointF((Pt2.X - ARect.Left) / ARect.Width, (Pt2.Y - ARect.Top) / ARect.Height);

  LState := ACanvas.SaveState;
  try
    ACanvas.Fill.Kind := TBrushKind.Gradient;
    ACanvas.Fill.Gradient.Points.Clear;

    P0 := TGradientPoint(ACanvas.Fill.Gradient.Points.Add);
    P0.Color := FConfig.BaseColor;
    P0.Offset := 0.0;

    P1 := TGradientPoint(ACanvas.Fill.Gradient.Points.Add);
    P1.Color := FConfig.BaseColor;
    P1.Offset := 0.25;

    P2 := TGradientPoint(ACanvas.Fill.Gradient.Points.Add);
    P2.Color := FConfig.HighlightColor;
    P2.Offset := 0.50;

    P3 := TGradientPoint(ACanvas.Fill.Gradient.Points.Add);
    P3.Color := FConfig.BaseColor;
    P3.Offset := 0.75;

    P4 := TGradientPoint(ACanvas.Fill.Gradient.Points.Add);
    P4.Color := FConfig.BaseColor;
    P4.Offset := 1.0;

    ACanvas.Fill.Gradient.StartPosition.Point := NormStart;
    ACanvas.Fill.Gradient.StopPosition.Point := NormStop;

    if FConfig.MaskToText and Assigned(FTextPath) then
    begin
      // Fallback: fill text path directly with gradient
      ACanvas.FillPath(FTextPath, EnsureRange(AOpacity, 0.0, 1.0));
    end
    else
    begin
      ACanvas.IntersectClipRect(ARect);
      ACanvas.FillRect(ARect, 0, 0, [], EnsureRange(AOpacity, 0.0, 1.0));
    end;
  finally
    ACanvas.RestoreState(LState);
  end;
end;

function TFluentShimmerEffect.Clone: IMotionEffect;
var
  Res: TFluentShimmerEffect;
begin
  Res := TFluentShimmerEffect.Create(FConfig, FDurationMs);
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

end.
