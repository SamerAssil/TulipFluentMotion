unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  Tulip.FluentMotion, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls;

type
  TForm1 = class(TForm)
    Circle1: TCircle;
    Rectangle1: TRectangle;
    Circle2: TCircle;
    procedure Circle1Click(Sender: TObject);
    procedure Circle2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FOriginalX, FOriginalY: Single;
    FIsAnimating: Boolean;
    procedure RevealWithCircle(const AExpandCircle, AShrinkCircle: TCircle;
      const AExpandAnchor, AShrinkAnchor: TMotionAnchor);
  public
  end;

var
  Form1: TForm1;

const
  MAX_SCALE            = 5000.0;
  SCALE_DURATION_MS    = 1200;
  MOVE_DURATION_MS     = 500;
  BOTTOM_QUARTER_RATIO = 0.85;
  EASE_EXPAND          = TFluentEase.InCubic;
  EASE_SHRINK          = TFluentEase.OutCubic;

implementation

{$R *.fmx}

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

  FIsAnimating := False;
end;

procedure TForm1.RevealWithCircle(const AExpandCircle, AShrinkCircle: TCircle;
  const AExpandAnchor, AShrinkAnchor: TMotionAnchor);
var
  ExpandTargetX, ShrinkStartX: Single;
begin
  if FIsAnimating then
    Exit;
  FIsAnimating := True;

  if AExpandAnchor = TMotionAnchor.CenterRight then
    ExpandTargetX := FOriginalX
  else
    ExpandTargetX := FOriginalX + AExpandCircle.Width;

  if AShrinkAnchor = TMotionAnchor.CenterRight then
    ShrinkStartX := FOriginalX - (AShrinkCircle.Width * (MAX_SCALE - 1.0))
  else
    ShrinkStartX := FOriginalX;

  AExpandCircle.BringToFront;
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

        AShrinkCircle.Scale.Point := PointF(MAX_SCALE, MAX_SCALE);
        AShrinkCircle.Position.Point := PointF(
          ShrinkStartX,
          FOriginalY - (AShrinkCircle.Height * (MAX_SCALE - 1.0) * 0.5));
        AShrinkCircle.BringToFront;
        AShrinkCircle.Visible := True;

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
  RevealWithCircle(Circle1, Circle2, TMotionAnchor.CenterRight, TMotionAnchor.CenterLeft);
end;

procedure TForm1.Circle2Click(Sender: TObject);
begin
  RevealWithCircle(Circle2, Circle1, TMotionAnchor.CenterLeft, TMotionAnchor.CenterRight);
end;

end.
