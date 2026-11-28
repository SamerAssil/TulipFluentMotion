unit UnitMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Layouts, FMX.StdCtrls, FMX.Controls.Presentation,
  Tulip.FluentMotion;

type
  TMainForm = class(TForm)
    RectMeshBg: TRectangle;
    LayoutRoot: TLayout;
    LabelTitle: TLabel;
    LabelCycles: TLabel;
    LayoutOrbHost: TLayout;
    RectBreathOrb: TRectangle;
    LabelPhase: TLabel;
    BtnToggle: TRectangle;
    LabelToggle: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure BtnToggleClick(Sender: TObject);
  private
    FIsRunning: Boolean;
    FCycleCount: Integer;
    procedure StartInhalePhase;
    procedure StartHoldPhase;
    procedure StartExhalePhase;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FIsRunning := False;
  FCycleCount := 0;

  RectMeshBg.Motion
    .MeshGradient($FF06202A, $FF0E4D64, $FF134E4A, $FF0F172A, 6000)
    .DrawMode(TShaderDrawMode.Background)
    .RepeatForever(True)
    .Start;

  RectBreathOrb.Motion
    .LiquidGlass(TFluentGlassStyle.DynamicIsland, 0)
    .DrawMode(TShaderDrawMode.Background)
    .Start;
end;

procedure TMainForm.BtnToggleClick(Sender: TObject);
begin
  BtnToggle.Motion
    .Scale(0.93, 90)
    .&Then
    .Scale(1.0, 220)
    .WithSpring(TFluentSpring.Snappy)
    .Start;

  FIsRunning := not FIsRunning;
  if FIsRunning then
  begin
    LabelToggle.Text := 'إيقاف الجلسة';
    BtnToggle.Fill.Color := $FFEF4444;
    StartInhalePhase;
  end
  else
  begin
    RectBreathOrb.StopMotion;
    RectBreathOrb.Motion.Scale(1.0, 350).WithSpring(TFluentSpring.Smooth).Start;
    LabelPhase.Text := 'استعد';
    LabelToggle.Text := 'ابدأ جلسة التنفس';
    BtnToggle.Fill.Color := $FF14B8A6;
  end;
end;

procedure TMainForm.StartInhalePhase;
begin
  if not FIsRunning then Exit;

  LabelPhase.Text := 'اشهق بعمق...';
  LabelPhase.FadeIn(300);

  RectBreathOrb.Motion
    .Anchor(TMotionAnchor.Center)
    .Scale(1.0, 1.48, 4000)
    .WithEase(TFluentEase.InOutSine)
    .OnComplete(procedure
      begin
        StartHoldPhase;
      end)
    .Start;
end;

procedure TMainForm.StartHoldPhase;
begin
  if not FIsRunning then Exit;

  LabelPhase.Text := 'احبس النفس...';
  LabelPhase.FadeIn(250);

  RectBreathOrb.Motion
    .Wait(2000)
    .OnComplete(procedure
      begin
        StartExhalePhase;
      end)
    .Start;
end;

procedure TMainForm.StartExhalePhase;
begin
  if not FIsRunning then Exit;

  LabelPhase.Text := 'أخرج الزفير...';
  LabelPhase.FadeIn(300);

  RectBreathOrb.Motion
    .Anchor(TMotionAnchor.Center)
    .Scale(1.48, 1.0, 4000)
    .WithEase(TFluentEase.InOutSine)
    .OnComplete(procedure
      begin
        if not FIsRunning then Exit;
        Inc(FCycleCount);
        LabelCycles.Text := Format('الدورات المكتملة: %d', [FCycleCount]);
        LayoutOrbHost.Motion
          .RippleDistortion(PointF(0.5, 0.5), $705EEAD4, 28.0, 900)
          .Start;
        StartInhalePhase;
      end)
    .Start;
end;

end.
