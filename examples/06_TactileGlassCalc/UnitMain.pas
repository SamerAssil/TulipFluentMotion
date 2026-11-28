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
    RectDisplay: TRectangle;
    LabelExpr: TLabel;
    LabelResult: TLabel;
    GridKeypad: TGridPanelLayout;
    procedure FormCreate(Sender: TObject);
  private
    FAccumulator: Double;
    FCurrentInput: string;
    FPendingOp: string;
    FResetOnNextDigit: Boolean;
    procedure BuildKeypad;
    procedure KeyClick(Sender: TObject);
    procedure KeyMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure KeyMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure AnimateResult(const ANewValue: Double);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

const
  KEY_LABELS: array[0..15] of string = (
    '7', '8', '9', '÷',
    '4', '5', '6', '×',
    '1', '2', '3', '-',
    'C', '0', '=', '+'
  );

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FAccumulator := 0;
  FCurrentInput := '0';
  FPendingOp := '';
  FResetOnNextDigit := False;

  RectMeshBg.Motion
    .MeshGradient($FF111827, $FF1E3A8A, $FF312E81, $FF0F172A, 6000)
    .DrawMode(TShaderDrawMode.Background)
    .RepeatForever(True)
    .Start;

  RectDisplay.Motion
    .FrostedGlass($35FFFFFF, 0.9, 0)
    .DrawMode(TShaderDrawMode.Background)
    .Start;

  BuildKeypad;
end;

procedure TMainForm.BuildKeypad;
var
  I: Integer;
  Btn: TRectangle;
  Lbl: TLabel;
  Cap: string;
begin
  for I := 0 to High(KEY_LABELS) do
  begin
    Cap := KEY_LABELS[I];
    Btn := TRectangle.Create(GridKeypad);
    Btn.Parent := GridKeypad;
    Btn.Align := TAlignLayout.Client;
    Btn.Margins.Rect := RectF(5, 5, 5, 5);
    Btn.XRadius := 22;
    Btn.YRadius := 22;
    Btn.Cursor := crHandPoint;
    Btn.Tag := I;
    Btn.TagString := Cap;
    Btn.Stroke.Color := $40FFFFFF;
    Btn.Stroke.Thickness := 1.0;

    if Cap = '=' then
      Btn.Fill.Color := $FF2563EB
    else if (Cap = 'C') then
      Btn.Fill.Color := $40EF4444
    else if (Cap = '+') or (Cap = '-') or (Cap = '×') or (Cap = '÷') then
      Btn.Fill.Color := $406366F1
    else
      Btn.Fill.Color := $24FFFFFF;

    Btn.OnClick := KeyClick;
    Btn.OnMouseDown := KeyMouseDown;
    Btn.OnMouseUp := KeyMouseUp;

    Lbl := TLabel.Create(Btn);
    Lbl.Parent := Btn;
    Lbl.Align := TAlignLayout.Client;
    Lbl.HitTest := False;
    Lbl.StyledSettings := [];
    Lbl.TextSettings.Font.Size := 24;
    Lbl.TextSettings.Font.Style := [TFontStyle.fsBold];
    Lbl.TextSettings.FontColor := TAlphaColors.White;
    Lbl.TextSettings.HorzAlign := TTextAlign.Center;
    Lbl.Text := Cap;

    Btn.Motion
      .FrostedGlass($22FFFFFF, 0.7, 0)
      .DrawMode(TShaderDrawMode.Background)
      .Start;
  end;
end;

procedure TMainForm.KeyMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Sender is TControl then
    TControl(Sender).Motion
      .Scale(0.90, 80)
      .WithEase(TFluentEase.OutQuad)
      .Start;
end;

procedure TMainForm.KeyMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Sender is TControl then
    TControl(Sender).Motion
      .Scale(1.0, 220)
      .WithSpring(TFluentSpring.Interactive)
      .Start;
end;

procedure TMainForm.KeyClick(Sender: TObject);
var
  Btn: TRectangle;
  Key: string;
  Val, Res: Double;
begin
  if not (Sender is TRectangle) then Exit;
  Btn := TRectangle(Sender);
  Key := Btn.TagString;

  Btn.Motion.Ripple(360).Start;

  if Key = 'C' then
  begin
    FAccumulator := 0;
    FCurrentInput := '0';
    FPendingOp := '';
    LabelExpr.Text := '';
    AnimateResult(0);
    Exit;
  end;

  if (Key >= '0') and (Key <= '9') then
  begin
    if FResetOnNextDigit or (FCurrentInput = '0') then
      FCurrentInput := Key
    else if Length(FCurrentInput) < 10 then
      FCurrentInput := FCurrentInput + Key;
    FResetOnNextDigit := False;
    LabelResult.Text := FCurrentInput;
    Exit;
  end;

  Val := StrToFloatDef(FCurrentInput, 0);
  if Key = '=' then
  begin
    if FPendingOp = '' then Exit;
    Res := Val;
    if FPendingOp = '+' then Res := FAccumulator + Val
    else if FPendingOp = '-' then Res := FAccumulator - Val
    else if FPendingOp = '×' then Res := FAccumulator * Val
    else if FPendingOp = '÷' then
    begin
      if Val = 0 then
      begin
        RectDisplay.Shake(10.0, 320);
        Exit;
      end;
      Res := FAccumulator / Val;
    end;

    LabelExpr.Text := Format('%g %s %g =', [FAccumulator, FPendingOp, Val]);
    FAccumulator := Res;
    FCurrentInput := FloatToStr(Res);
    FPendingOp := '';
    FResetOnNextDigit := True;
    AnimateResult(Res);
  end
  else
  begin
    FAccumulator := Val;
    FPendingOp := Key;
    LabelExpr.Text := Format('%g %s', [FAccumulator, FPendingOp]);
    FResetOnNextDigit := True;
  end;
end;

procedure TMainForm.AnimateResult(const ANewValue: Double);
var
  OldVal: Double;
begin
  OldVal := StrToFloatDef(LabelResult.Text, 0);
  if Frac(ANewValue) = 0 then
    LabelResult.Motion
      .CountTo(OldVal, ANewValue, '%0.0f', 420)
      .WithEase(TFluentEase.OutExpo)
      .Start
  else
    LabelResult.Motion
      .CountTo(OldVal, ANewValue, '%0.2f', 420)
      .WithEase(TFluentEase.OutExpo)
      .Start;
end;

end.
