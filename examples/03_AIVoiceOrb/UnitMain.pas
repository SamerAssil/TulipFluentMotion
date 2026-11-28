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
    LabelStatus: TLabel;
    LayoutOrbContainer: TLayout;
    RectOrb: TRectangle;
    LabelOrb: TLabel;
    RectAnswerCard: TRectangle;
    LabelResponse: TLabel;
    LayoutInput: TLayout;
    BtnSend: TRectangle;
    LabelSend: TLabel;
    EditPrompt: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure RectOrbClick(Sender: TObject);
    procedure BtnSendClick(Sender: TObject);
  private
    FResponseIndex: Integer;
    procedure RunAIResponse(const ACustomPrompt: string);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

const
  AI_RESPONSES: array[0..2] of string = (
    'تم تحليل طلبك بنجاح! تعتمد هذه الواجهة على محرك TulipFluentMotion لعرض الحروف العربية المتصلة والتشكيل بسلاسة تامة دون تقطيع.',
    'نصيحة ذكية: يمكنك دمج تأثير BorderBeam مع GooeyMetaball لخلق إحساس حي بأن المساعد يستمع ويفكر في الوقت الفعلي.',
    'كل الحركات هنا تعمل على 60 إطاراً في الثانية بعتاد GPU عبر Skia دون أي مؤقتات تقليدية أو استهلاك زائد للمعالج.'
  );

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FResponseIndex := 0;

  RectOrb.Motion
    .GooeyMetaball($DD7C3AED, 1.8, 3500)
    .NeonGlow($FF8B5CF6, 18.0, 3.0, 2000)
    .RepeatForever(True)
    .Start;
end;

procedure TMainForm.RectOrbClick(Sender: TObject);
begin
  RunAIResponse('');
end;

procedure TMainForm.BtnSendClick(Sender: TObject);
begin
  if Trim(EditPrompt.Text) = '' then
  begin
    EditPrompt.Shake(10.0, 320);
    Exit;
  end;

  BtnSend.Motion
    .Scale(0.92, 90)
    .&Then
    .Scale(1.0, 220)
    .WithSpring(TFluentSpring.Snappy)
    .Start;

  RunAIResponse(Trim(EditPrompt.Text));
  EditPrompt.Text := '';
end;

procedure TMainForm.RunAIResponse(const ACustomPrompt: string);
var
  AnswerText: string;
begin
  if ACustomPrompt <> '' then
    AnswerText := Format('سؤالك: "%s"' + sLineBreak + sLineBreak + '%s',
      [ACustomPrompt, AI_RESPONSES[FResponseIndex]])
  else
    AnswerText := AI_RESPONSES[FResponseIndex];

  FResponseIndex := (FResponseIndex + 1) mod Length(AI_RESPONSES);

  LabelStatus.Text := 'جاري التفكير وتوليد الإجابة...';
  LabelStatus.Motion
    .ShimmerText(900, TShimmerDirection.LeftToRight, 20.0)
    .RepeatForever(True)
    .Start;

  RectOrb.Motion
    .Scale(1.12, 260)
    .WithSpring(TFluentSpring.Bouncy)
    .&Then
    .Scale(1.0, 320)
    .WithSpring(TFluentSpring.Smooth)
    .Start;

  RectAnswerCard.Motion
    .BorderBeam($FF38BDF8, $FFA855F7, 3.0, 0.28, 1800)
    .Start;

  LabelResponse.StopMotion;
  LabelResponse.Motion
    .Typewriter(AnswerText, 28, True, '|')
    .WithEase(TFluentEase.Linear)
    .OnComplete(procedure
      begin
        LabelStatus.StopMotion;
        LabelStatus.Text := 'جاهز — اضغط على الكرة لسؤال جديد';
      end)
    .Start;
end;

end.
