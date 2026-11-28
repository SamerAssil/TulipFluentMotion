unit UnitMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Layouts, FMX.StdCtrls, FMX.Controls.Presentation,
  Tulip.FluentMotion;

type
  TMainForm = class(TForm)
    LayoutRoot: TLayout;
    GridDhikr: TGridPanelLayout;
    BtnDhikr1: TRectangle;
    LabelD1: TLabel;
    BtnDhikr2: TRectangle;
    LabelD2: TLabel;
    BtnDhikr3: TRectangle;
    LabelD3: TLabel;
    LabelDhikr: TLabel;
    LayoutRingHost: TLayout;
    RectRing: TRectangle;
    RectWave: TRectangle;
    LabelCount: TLabel;
    LabelTotal: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure RectRingClick(Sender: TObject);
    procedure BtnDhikrClick(Sender: TObject);
  private
    FCount: Integer;
    FTotal: Integer;
    procedure UpdateDhikrText(const AIndex: Integer);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

const
  CYCLE_TARGET = 33;
  DHIKR_TEXTS: array[0..2] of string = (
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    'اللَّهُ أَكْبَرُ كَبِيراً'
  );

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCount := 0;
  FTotal := 0;

  UpdateDhikrText(0);
  LabelDhikr.Motion
    .ShimmerText(2000, TShimmerDirection.LeftToRight, 20.0)
    .RepeatForever(True)
    .Start;
end;

procedure TMainForm.BtnDhikrClick(Sender: TObject);
var
  Btn: TRectangle;
begin
  if not (Sender is TRectangle) then Exit;
  Btn := TRectangle(Sender);

  BtnDhikr1.Fill.Color := $20FFFFFF;
  BtnDhikr2.Fill.Color := $20FFFFFF;
  BtnDhikr3.Fill.Color := $20FFFFFF;
  Btn.Fill.Color := $FF059669;

  Btn.Motion
    .Scale(0.92, 80)
    .&Then
    .Scale(1.0, 220)
    .WithSpring(TFluentSpring.Bouncy)
    .Start;

  UpdateDhikrText(Btn.Tag);
end;

procedure TMainForm.UpdateDhikrText(const AIndex: Integer);
begin
  LabelDhikr.StopMotion;
  LabelDhikr.Motion
    .Typewriter(DHIKR_TEXTS[AIndex], 45, False, '|')
    .WithEase(TFluentEase.Linear)
    .OnComplete(procedure
      begin
        LabelDhikr.Motion
          .ShimmerText(2000, TShimmerDirection.LeftToRight, 20.0)
          .RepeatForever(True)
          .Start;
      end)
    .Start;
end;

procedure TMainForm.RectRingClick(Sender: TObject);
var
  OldLevel, NewLevel: Single;
begin
  OldLevel := FCount / CYCLE_TARGET;
  Inc(FCount);
  Inc(FTotal);

  if FCount > CYCLE_TARGET then
    FCount := 1;

  NewLevel := FCount / CYCLE_TARGET;

  LabelCount.Text := IntToStr(FCount);
  LabelTotal.Text := Format('المجموع الكلي: %d  |  الدورة: %d', [FTotal, CYCLE_TARGET]);

  RectRing.Motion
    .Scale(0.94, 70)
    .&Then
    .Scale(1.0, 240)
    .WithSpring(TFluentSpring.Bouncy)
    .Start;

  LayoutRingHost.Motion
    .RippleDistortion(PointF(0.5, 0.5), $7034D399, 22.0, 520)
    .Start;

  RectWave.StopMotion;
  RectWave.Motion
    .LiquidWave(OldLevel, NewLevel, $CC059669, $FFA7F3D0, 420)
    .DrawMode(TShaderDrawMode.Background)
    .WithEase(TFluentEase.OutCubic)
    .Start;

  if FCount = CYCLE_TARGET then
  begin
    RectRing.Motion
      .NeonGlow($FF10B981, 22.0, 4.0, 1600)
      .Start;
  end;
end;

end.
