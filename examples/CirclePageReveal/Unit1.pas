{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Unit1
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  Tulip.FluentMotion, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  System.Skia, FMX.Skia;

type
  TForm1 = class(TForm)
    Circle1: TCircle;
    Rectangle1: TRectangle;
    Circle2: TCircle;
    SkSvg1: TSkSvg;
    SkSvg2: TSkSvg;
    Layout1: TLayout;
    Painting1: TRectangle;
    Painting2: TRectangle;
    Text1: TText;
    procedure Circle1Click(Sender: TObject);
    procedure Circle2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FOriginalX, FOriginalY: Single;
    FIsAnimating: Boolean;
    function GetSvgCenterPos(const ASvg: TSkSvg; const AOffsetX: Single = 0.0): TPointF;
    function GetPaintingCenterPos(const APainting: TRectangle; const AOffsetX: Single = 0.0): TPointF;
    procedure RevealWithCircle(const AExpandCircle, AShrinkCircle: TCircle;
      const AExpandSvg, AShrinkSvg: TSkSvg;
      const AExpandPainting, AShrinkPainting: TRectangle;
      const AExpandAnchor, AShrinkAnchor: TMotionAnchor);
  public
  end;

var
  Form1: TForm1;

const
  MAX_SCALE               = 3000.0;
  SCALE_DURATION_MS       = 1000;
  MOVE_DURATION_MS        = 250;
  SVG_DURATION_MS         = 240;
  SVG_SHIFT_DISTANCE      = 44.0;
  PAINTING_DURATION_MS    = 450;
  PAINTING_FADE_MS        = 220;
  PAINTING_SHIFT_DISTANCE = 130.0;
  BOTTOM_QUARTER_RATIO    = 0.85;
  EASE_EXPAND             = TFluentEase.InCubic;
  EASE_SHRINK             = TFluentEase.OutCubic;

implementation

{$R *.fmx}

function TForm1.GetSvgCenterPos(const ASvg: TSkSvg; const AOffsetX: Single): TPointF;
begin
  Result.X := FOriginalX + ((Circle1.Width - ASvg.Width) * 0.5) + AOffsetX;
  Result.Y := FOriginalY + ((Circle1.Height - ASvg.Height) * 0.5);
end;

function TForm1.GetPaintingCenterPos(const APainting: TRectangle; const AOffsetX: Single): TPointF;
begin
  Result.X := ((Layout1.Width - APainting.Width) * 0.5) + AOffsetX;
  Result.Y := (Layout1.Height - APainting.Height) * 0.5;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  FOriginalX := (ClientWidth - Circle1.Width) * 0.5;
  FOriginalY := (ClientHeight * BOTTOM_QUARTER_RATIO) - (Circle1.Height * 0.5);

  Circle1.Position.Point := PointF(FOriginalX, FOriginalY);
  Circle1.Scale.Point := PointF(1, 1);
  Circle1.Visible := True;

  Circle2.Position.Point := PointF(FOriginalX, FOriginalY);
  Circle2.Scale.Point := PointF(1, 1);
  Circle2.Visible := False;

  SkSvg1.Position.Point := GetSvgCenterPos(SkSvg1);
  SkSvg1.Opacity := 1.0;
  SkSvg1.BringToFront;

  SkSvg2.Position.Point := GetSvgCenterPos(SkSvg2);
  SkSvg2.Opacity := 0.0;

  Layout1.Align := TAlignLayout.None;
  Layout1.Position.X := (ClientWidth - Layout1.Width) * 0.5;
  Layout1.Position.Y := (FOriginalY - Layout1.Height) * 0.5;

  Painting1.Align := TAlignLayout.None;
  Painting1.Position.Point := GetPaintingCenterPos(Painting1);
  Painting1.Opacity := 1.0;
  Painting1.Elevation(1);
  Painting1.BringToFront;

  Painting2.Align := TAlignLayout.None;
  Painting2.Position.Point := GetPaintingCenterPos(Painting2);
  Painting2.Opacity := 0.0;
  Painting2.Elevation(1);

  FIsAnimating := False;
end;

procedure TForm1.RevealWithCircle(const AExpandCircle, AShrinkCircle: TCircle;
  const AExpandSvg, AShrinkSvg: TSkSvg;
  const AExpandPainting, AShrinkPainting: TRectangle;
  const AExpandAnchor, AShrinkAnchor: TMotionAnchor);
var
  ExpandTargetX, ShrinkStartX: Single;
  ExitSvgShift, EnterSvgShift: Single;
  ExitPaintingShift, EnterPaintingShift: Single;
begin
  if FIsAnimating then
    Exit;
  FIsAnimating := True;

  if AExpandAnchor = TMotionAnchor.CenterRight then
  begin
    ExpandTargetX := FOriginalX;
    ExitSvgShift := SVG_SHIFT_DISTANCE;
    ExitPaintingShift := PAINTING_SHIFT_DISTANCE;
  end
  else
  begin
    ExpandTargetX := FOriginalX + AExpandCircle.Width;
    ExitSvgShift := -SVG_SHIFT_DISTANCE;
    ExitPaintingShift := -PAINTING_SHIFT_DISTANCE;
  end;

  if AShrinkAnchor = TMotionAnchor.CenterRight then
  begin
    ShrinkStartX := FOriginalX - (AShrinkCircle.Width * (MAX_SCALE - 1.0));
    EnterSvgShift := -SVG_SHIFT_DISTANCE;
    EnterPaintingShift := -PAINTING_SHIFT_DISTANCE;
  end
  else
  begin
    ShrinkStartX := FOriginalX;
    EnterSvgShift := SVG_SHIFT_DISTANCE;
    EnterPaintingShift := SVG_SHIFT_DISTANCE;
  end;

  AExpandCircle.BringToFront;
  AExpandSvg.Position.Point := GetSvgCenterPos(AExpandSvg);
  AExpandSvg.BringToFront;

  // Slide out and fade the outgoing icon opposite to the circle expansion (unscaled)
  AExpandSvg.Motion
    .WithEase(TFluentEase.OutQuad)
    .FadeOut(SVG_DURATION_MS)
    .MoveX(ExitSvgShift, SVG_DURATION_MS)
    .Start;

  // Slide out and fade the outgoing page illustration opposite to the circle expansion
  AExpandPainting.Position.Point := GetPaintingCenterPos(AExpandPainting);
  AExpandPainting.Motion
    .Elevation(1, 0)
    .WithEase(TFluentEase.OutCubic)
    .FadeOut(PAINTING_FADE_MS)
    .MoveX(ExitPaintingShift, PAINTING_DURATION_MS)
    .Start;

  AExpandCircle.Motion
    .Scale(1, MAX_SCALE, SCALE_DURATION_MS, AExpandAnchor)
    .WithEase(EASE_EXPAND)
    .MoveTo(ExpandTargetX, FOriginalY + (AExpandCircle.Height * 0.5), MOVE_DURATION_MS, AExpandAnchor)
    .OnComplete(
      procedure
      begin
        Rectangle1.Fill.Color := AExpandCircle.Fill.Color;

        AExpandCircle.Visible := False;
        AExpandCircle.Scale.Point := PointF(1, 1);
        AExpandCircle.Position.Point := PointF(FOriginalX, FOriginalY);
        AExpandSvg.Opacity := 0.0;
        AExpandPainting.Opacity := 0.0;

        AShrinkCircle.Scale.Point := PointF(MAX_SCALE, MAX_SCALE);
        AShrinkCircle.Position.Point := PointF(
          ShrinkStartX,
          FOriginalY - (AShrinkCircle.Height * (MAX_SCALE - 1.0) * 0.5));
        AShrinkCircle.BringToFront;
        AShrinkCircle.Visible := True;

        // Slide in the incoming icon at constant size as the new circle settles
        AShrinkSvg.Opacity := 0.0;
        AShrinkSvg.Position.Point := GetSvgCenterPos(AShrinkSvg, -EnterSvgShift);
        AShrinkSvg.BringToFront;
        AShrinkSvg.Motion
          .Delay(SCALE_DURATION_MS - SVG_DURATION_MS)
          .WithEase(TFluentEase.OutCubic)
          .FadeIn(SVG_DURATION_MS)
          .MoveX(EnterSvgShift, SVG_DURATION_MS)
          .Start;

        // Slide in the incoming page illustration as the new circle settles
        AShrinkPainting.Opacity := 0.0;
        AShrinkPainting.Position.Point := GetPaintingCenterPos(AShrinkPainting, -EnterPaintingShift);
        AShrinkPainting.BringToFront;
        AShrinkPainting.Motion
          .Elevation(1, 0)
          .Delay(SCALE_DURATION_MS - PAINTING_DURATION_MS)
          .WithEase(TFluentEase.OutCubic)
          .FadeIn(PAINTING_FADE_MS)
          .MoveX(EnterPaintingShift, PAINTING_DURATION_MS)
          .Start;

        AShrinkCircle.Motion
          .Scale(MAX_SCALE, 1, SCALE_DURATION_MS, AShrinkAnchor)
          .WithEase(EASE_SHRINK)
          .OnComplete(
            procedure
            begin
              FIsAnimating := False;
            end)
          .Start;
      end)
    .Start;
end;

procedure TForm1.Circle1Click(Sender: TObject);
begin
  RevealWithCircle(Circle1, Circle2, SkSvg1, SkSvg2, Painting1, Painting2,
    TMotionAnchor.CenterRight, TMotionAnchor.CenterLeft);
end;

procedure TForm1.Circle2Click(Sender: TObject);
begin
  RevealWithCircle(Circle2, Circle1, SkSvg2, SkSvg1, Painting2, Painting1,
    TMotionAnchor.CenterLeft, TMotionAnchor.CenterRight);
end;

end.
