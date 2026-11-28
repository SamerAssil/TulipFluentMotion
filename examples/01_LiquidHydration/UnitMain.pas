unit UnitMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Layouts, FMX.StdCtrls, FMX.Controls.Presentation,
  Tulip.FluentMotion;

type
  TMainForm = class(TForm)
    LayoutRoot: TLayout;
    LayoutHeader: TLayout;
    LabelTitle: TLabel;
    LabelSubtitle: TLabel;
    RectTank: TRectangle;
    RectWaveLayer: TRectangle;
    LayoutCenterText: TLayout;
    LabelMl: TLabel;
    LabelPercent: TLabel;
    LabelStatus: TLabel;
    LayoutActions: TLayout;
    RectMetaballBg: TRectangle;
    GridButtons: TGridPanelLayout;
    BtnAdd150: TRectangle;
    LabelBtn150: TLabel;
    BtnAdd250: TRectangle;
    LabelBtn250: TLabel;
    BtnAdd500: TRectangle;
    LabelBtn500: TLabel;
    BtnReset: TRectangle;
    LabelReset: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure BtnAddWaterClick(Sender: TObject);
    procedure BtnResetClick(Sender: TObject);
  private
    FCurrentMl: Integer;
    FGoalMl: Integer;
    FCurrentLevel: Single;
    procedure UpdateTankVisuals(const AOldMl, ANewMl: Integer; const AOldLevel, ANewLevel: Single);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FGoalMl := 2000;
  FCurrentMl := 400;
  FCurrentLevel := FCurrentMl / FGoalMl;

  // Entrance animations
  RectTank.Opacity := 0;
  RectTank.Motion
    .Scale(0.92, 1.0, 450)
    .FadeIn(400)
    .WithSpring(TFluentSpring.Smooth)
    .Start;

  LabelTitle.Motion
    .ShimmerText(1800, TShimmerDirection.LeftToRight, 20.0)
    .RepeatForever(True)
    .Start;

  // Organic metaball accent above action buttons
  RectMetaballBg.Motion
    .GooeyMetaball($AA38BDF8, 1.8, 4000)
    .RepeatForever(True)
    .Start;

  UpdateTankVisuals(0, FCurrentMl, 0.0, FCurrentLevel);
end;

procedure TMainForm.BtnAddWaterClick(Sender: TObject);
var
  Btn: TRectangle;
  AddAmount: Integer;
  OldMl: Integer;
  OldLevel: Single;
begin
  if not (Sender is TRectangle) then
    Exit;

  Btn := TRectangle(Sender);
  AddAmount := Btn.Tag;

  // Tactile spring press feedback
  Btn.Motion
    .Anchor(TMotionAnchor.Center)
    .Scale(0.90, 90)
    .WithEase(TFluentEase.OutQuad)
    .&Then
    .Scale(1.0, 260)
    .WithSpring(TFluentSpring.Bouncy)
    .Start;

  if FCurrentMl >= FGoalMl then
  begin
    RectTank.Shake(8.0, 300);
    Exit;
  end;

  OldMl := FCurrentMl;
  OldLevel := FCurrentLevel;
  FCurrentMl := Min(FGoalMl, FCurrentMl + AddAmount);
  FCurrentLevel := FCurrentMl / FGoalMl;

  // Optical water ripple distortion on tank
  RectTank.Motion
    .RippleDistortion(PointF(0.5, 0.85), $807DD3FC, 26.0, 650)
    .Start;

  UpdateTankVisuals(OldMl, FCurrentMl, OldLevel, FCurrentLevel);
end;

procedure TMainForm.BtnResetClick(Sender: TObject);
var
  OldMl: Integer;
  OldLevel: Single;
begin
  BtnReset.Motion
    .Scale(0.94, 80)
    .&Then
    .Scale(1.0, 200)
    .WithSpring(TFluentSpring.Snappy)
    .Start;

  OldMl := FCurrentMl;
  OldLevel := FCurrentLevel;
  FCurrentMl := 0;
  FCurrentLevel := 0.0;

  UpdateTankVisuals(OldMl, FCurrentMl, OldLevel, FCurrentLevel);
end;

procedure TMainForm.UpdateTankVisuals(const AOldMl, ANewMl: Integer; const AOldLevel, ANewLevel: Single);
var
  OldPct, NewPct: Double;
begin
  OldPct := (AOldMl / FGoalMl) * 100.0;
  NewPct := (ANewMl / FGoalMl) * 100.0;

  RectWaveLayer.StopMotion;
  RectWaveLayer.Motion
    .LiquidWave(AOldLevel, ANewLevel, $CC0284C7, $FFBAE6FD, 1100)
    .DrawMode(TShaderDrawMode.Background)
    .WithEase(TFluentEase.OutCubic)
    .Start;

  LabelMl.Motion
    .CountTo(AOldMl, ANewMl, '%0.0f مل', 900)
    .WithEase(TFluentEase.OutExpo)
    .Start;

  LabelPercent.Motion
    .CountTo(OldPct, NewPct, '%0.0f%%', 900)
    .WithEase(TFluentEase.OutExpo)
    .Start;

  if ANewMl >= FGoalMl then
  begin
    LabelStatus.Text := 'أحسنت! وصلت لهدفك اليومي';
    RectTank.Motion
      .Pulse(1.03, 300)
      .NeonGlow($FF38BDF8, 18.0, 3.5, 2200)
      .Start;
  end
  else if ANewMl = 0 then
    LabelStatus.Text := 'ابدأ يومك بأول كوب ماء'
  else
    LabelStatus.Text := Format('المتبقي %d مل للوصول للهدف', [FGoalMl - ANewMl]);
end;

end.
