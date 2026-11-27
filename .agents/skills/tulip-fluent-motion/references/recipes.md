# TulipFluentMotion: Production UI Recipes

Complete, copy-paste ready Delphi FMX implementations for real-world UI patterns.

---

## Recipe 1: Modern Login Dialog with Error Shake & Success Pop

```pascal
unit UnitLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Edit, FMX.StdCtrls,
  Tulip.FluentMotion; // <--- Single required unit

type
  TLoginForm = class(TForm)
    CardPanel: TRectangle;
    EditUsername: TEdit;
    EditPassword: TEdit;
    BtnLogin: TButton;
    LabelTitle: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure BtnLoginClick(Sender: TObject);
  private
    procedure HandleLoginFailed;
    procedure HandleLoginSuccess;
  end;

implementation

{$R *.fmx}

procedure TLoginForm.FormCreate(Sender: TObject);
begin
  // 1. Initial entrance animation
  CardPanel.Opacity := 0.0;
  CardPanel.Motion
    .Anchor(TMotionAnchor.Center)
    .Scale(0.85, 1.0, 350)
    .FadeIn(300)
    .WithSpring(TFluentSpring.Bouncy)
    .Start;
end;

procedure TLoginForm.BtnLoginClick(Sender: TObject);
begin
  if (EditPassword.Text <> 'correct_password') then
    HandleLoginFailed
  else
    HandleLoginSuccess;
end;

procedure TLoginForm.HandleLoginFailed;
begin
  // Error feedback: Shake the password edit and tint border
  EditPassword.Motion
    .Shake(12.0, 380)
    .&Then
    .ColorTo(TAlphaColors.Red, 150)
    .&Then
    .ColorTo(TAlphaColors.Black, 300)
    .Start;

  // Also shake the entire window slightly on desktop
  Shake(8.0, 350);
end;

procedure TLoginForm.HandleLoginSuccess;
begin
  // Success feedback: Pulse button, then pop out card and transition
  BtnLogin.Motion
    .Pulse(1.15, 200)
    .&Then
    .Wait(100)
    .&Then
    .FadeOut(250)
    .Start;

  CardPanel.Motion
    .Delay(150)
    .PopOut(250)
    .OnComplete(procedure
      begin
        // Open dashboard or next screen here
      end)
    .Start;
end;

end.
```

---

## Recipe 2: Financial KPI Metric Card with Number Counting & Shimmer

```pascal
unit UnitKpiCard;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Objects, FMX.StdCtrls,
  Tulip.FluentMotion;

type
  TKpiCard = class(TFrame)
    BackgroundRect: TRectangle;
    LabelMetricTitle: TLabel;
    LabelValue: TLabel;
    LabelChange: TLabel;
    procedure FrameMouseEnter(Sender: TObject);
    procedure FrameMouseLeave(Sender: TObject);
  public
    procedure AnimateData(const ATargetAmount: Double; const APercentChange: Double);
  end;

implementation

{$R *.fmx}

procedure TKpiCard.AnimateData(const ATargetAmount: Double; const APercentChange: Double);
begin
  // 1. Animate financial metric from 0 to target
  LabelValue.Motion
    .CountTo(0.0, ATargetAmount, '$%0.2f', 1600)
    .WithEase(TFluentEase.OutExpo)
    .Start;

  // 2. Animate percentage badge
  LabelChange.Motion
    .CountTo(0.0, APercentChange, '%+0.1f%%', 1400)
    .WithEase(TFluentEase.OutCubic)
    .Start;

  // 3. Ambient border laser runner
  BackgroundRect.Motion
    .BorderBeam(TAlphaColors.Dodgerblue, TAlphaColors.Deepskyblue, 2.5, 0.25, 2500)
    .RepeatForever(False)
    .Start;
end;

procedure TKpiCard.FrameMouseEnter(Sender: TObject);
begin
  // Elevation lift on hover
  BackgroundRect.Motion
    .MoveY(-4.0, 180)
    .Shadow(12.0, 0.45, 0.35, 180)
    .WithSpring(TFluentSpring.Snappy)
    .Start;
end;

procedure TKpiCard.FrameMouseLeave(Sender: TObject);
begin
  // Return to baseline
  BackgroundRect.Motion
    .MoveY(0.0, 200)
    .Shadow(4.0, 0.25, 0.20, 200)
    .WithEase(TFluentEase.OutQuad)
    .Start;
end;

end.
```

---

## Recipe 3: Windows 11 Fluent App Frame with Mica and Title Bar Extension

```pascal
unit UnitMainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Objects, FMX.Layouts,
  Tulip.FluentMotion;

type
  TMainForm = class(TForm)
    LayoutTitleBar: TLayout;
    LayoutContent: TLayout;
    PanelSidebar: TRectangle;
    procedure FormCreate(Sender: TObject);
  end;

implementation

{$R *.fmx}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // 1. Apply native Windows 11 Mica backdrop
  Mica(False); // Or Acrylic($60181818) for frosted acrylic

  // 2. Seamlessly extend client area into custom title bar
  HideTitleBar;

  // 3. Smooth entrance of main content
  LayoutContent.Opacity := 0.0;
  LayoutContent.Motion
    .SlideIn(TTransitionDirection.FromBottom, 25, 350)
    .FadeIn(300)
    .WithSpring(TFluentSpring.Smooth)
    .Start;
end;

end.
```

---

## Recipe 4: Expandable Floating Action Button (FAB) Speed-Dial

```pascal
procedure TMainForm.ToggleFabMenu(const AOpen: Boolean);
var
  Buttons: array[0..2] of TControl;
  I: Integer;
begin
  Buttons[0] := BtnActionShare;
  Buttons[1] := BtnActionEdit;
  Buttons[2] := BtnActionDelete;

  // Rotate main FAB plus icon to an 'X'
  BtnMainFab.Motion
    .Rotate(IfThen(AOpen, 45.0, 0.0), 250)
    .WithSpring(TFluentSpring.Bouncy)
    .Start;

  for I := 0 to High(Buttons) do
  begin
    if AOpen then
    begin
      Buttons[I].Visible := True;
      Buttons[I].Motion
        .Delay(I * 40)
        .Anchor(TMotionAnchor.Center)
        .MoveY(-(I + 1) * 56.0, 260)
        .Scale(0.3, 1.0, 260)
        .FadeIn(200)
        .WithSpring(TFluentSpring.Bouncy)
        .Start;
    end
    else
    begin
      Buttons[I].Motion
        .Delay((High(Buttons) - I) * 30)
        .MoveY(0.0, 200)
        .Scale(0.3, 200)
        .FadeOut(180)
        .OnComplete(procedure
          begin
            Buttons[I].Visible := False;
          end)
        .Start;
    end;
  end;
end;
```
