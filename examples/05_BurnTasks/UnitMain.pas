unit UnitMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Layouts, FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation,
  Tulip.FluentMotion;

type
  TMainForm = class(TForm)
    LayoutRoot: TLayout;
    LabelTitle: TLabel;
    LabelHint: TLabel;
    LayoutInput: TLayout;
    BtnAdd: TRectangle;
    LabelAdd: TLabel;
    EditTask: TEdit;
    ScrollTasks: TVertScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
  private
    procedure AddTaskCard(const ATaskText: string; const ADelayMs: Cardinal = 0);
    procedure TaskCardClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  AddTaskCard('مراجعة تصميم الواجهة الرئيسية', 0);
  AddTaskCard('إرسال التقرير اليومي للفريق', 90);
  AddTaskCard('تحديث مكتبة TulipFluentMotion للأندرويد', 180);
  AddTaskCard('تجربة تأثير الاحتراق DissolveBurn', 270);
end;

procedure TMainForm.BtnAddClick(Sender: TObject);
var
  TaskText: string;
begin
  TaskText := Trim(EditTask.Text);
  if TaskText = '' then
  begin
    EditTask.Shake(10.0, 320);
    Exit;
  end;

  BtnAdd.Motion
    .Scale(0.92, 90)
    .&Then
    .Scale(1.0, 220)
    .WithSpring(TFluentSpring.Bouncy)
    .Start;

  AddTaskCard(TaskText, 0);
  EditTask.Text := '';
end;

procedure TMainForm.AddTaskCard(const ATaskText: string; const ADelayMs: Cardinal);
var
  Card: TRectangle;
  Lbl: TLabel;
begin
  Card := TRectangle.Create(ScrollTasks);
  Card.Parent := ScrollTasks;
  Card.Align := TAlignLayout.Top;
  Card.Height := 72;
  Card.Margins.Bottom := 12;
  Card.Padding.Left := 18;
  Card.Padding.Right := 18;
  Card.XRadius := 18;
  Card.YRadius := 18;
  Card.Fill.Color := $FF1F1616;
  Card.Stroke.Color := $40F97316;
  Card.Stroke.Thickness := 1.2;
  Card.Cursor := crHandPoint;
  Card.OnClick := TaskCardClick;

  Lbl := TLabel.Create(Card);
  Lbl.Parent := Card;
  Lbl.Align := TAlignLayout.Client;
  Lbl.HitTest := False;
  Lbl.StyledSettings := [];
  Lbl.TextSettings.Font.Size := 16;
  Lbl.TextSettings.FontColor := $FFF8FAFC;
  Lbl.TextSettings.HorzAlign := TTextAlign.Trailing;
  Lbl.Text := ATaskText;

  Card.Opacity := 0;
  Card.Motion
    .Delay(ADelayMs)
    .PopIn(340)
    .WithSpring(TFluentSpring.Bouncy)
    .Start;
end;

procedure TMainForm.TaskCardClick(Sender: TObject);
var
  Card: TRectangle;
begin
  if not (Sender is TRectangle) then Exit;
  Card := TRectangle(Sender);
  Card.HitTest := False;

  Card.Motion
    .DissolveBurn($FFFF4500, 0.09, 8.0, 1100)
    .FadeOut(1100)
    .OnComplete(procedure
      begin
        Card.Visible := False;
        Card.Parent := nil;
      end)
    .Start;
end;

end.
