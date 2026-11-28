unit UnitMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Layouts, FMX.StdCtrls, FMX.Controls.Presentation,
  Tulip.FluentMotion;

type
  TMainForm = class(TForm)
    RectMeshBg: TRectangle;
    LayoutRoot: TLayout;
    LabelHeader: TLabel;
    RectCard: TRectangle;
    LayoutCardFront: TLayout;
    LabelTier: TLabel;
    LabelBalanceTitle: TLabel;
    LabelBalance: TLabel;
    LabelCardNum: TLabel;
    LayoutCardBack: TLayout;
    LabelBackTitle: TLabel;
    LabelCVV: TLabel;
    LabelBackHint: TLabel;
    GridActions: TGridPanelLayout;
    BtnDeposit: TRectangle;
    LabelDeposit: TLabel;
    BtnPay: TRectangle;
    LabelPay: TLabel;
    LabelTxTitle: TLabel;
    LayoutTxList: TLayout;
    RectTx1: TRectangle;
    LabelTx1: TLabel;
    RectTx2: TRectangle;
    LabelTx2: TLabel;
    RectTx3: TRectangle;
    LabelTx3: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure RectCardClick(Sender: TObject);
    procedure BtnDepositClick(Sender: TObject);
    procedure BtnPayClick(Sender: TObject);
  private
    FBalance: Double;
    FIsFlipped: Boolean;
    procedure AnimateBalance(const AOldValue, ANewValue: Double);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

procedure TMainForm.FormCreate(Sender: TObject);
var
  I: Integer;
  Item: TControl;
begin
  FBalance := 4850.00;
  FIsFlipped := False;

  // Generative 4-point mesh gradient background
  RectMeshBg.Motion
    .MeshGradient($FF0F172A, $FF1E1B4B, $FF312E81, $FF0C4A6E, 5000)
    .DrawMode(TShaderDrawMode.Background)
    .RepeatForever(True)
    .Start;

  // HeavyPrism liquid glass card
  RectCard.Motion
    .LiquidGlass(TFluentGlassStyle.HeavyPrism, 0)
    .DrawMode(TShaderDrawMode.Background)
    .Start;

  LabelTier.Motion
    .ShimmerText(1600, TShimmerDirection.LeftToRight, 20.0)
    .RepeatForever(True)
    .Start;

  // Staggered transaction list entrance
  for I := 0 to LayoutTxList.ChildrenCount - 1 do
  begin
    if LayoutTxList.Children[I] is TControl then
    begin
      Item := TControl(LayoutTxList.Children[I]);
      Item.Opacity := 0.0;
      Item.Motion
        .Delay(I * 80)
        .SlideIn(TTransitionDirection.FromBottom, 36, 320)
        .FadeIn(280)
        .WithSpring(TFluentSpring.Snappy)
        .Start;
    end;
  end;
end;

procedure TMainForm.RectCardClick(Sender: TObject);
begin
  FIsFlipped := not FIsFlipped;

  RectCard.Motion
    .Flip3D(90.0, TFlipAxis.Horizontal, 180)
    .WithEase(TFluentEase.InQuad)
    .OnComplete(procedure
      begin
        LayoutCardFront.Visible := not FIsFlipped;
        LayoutCardBack.Visible := FIsFlipped;
        RectCard.Motion
          .Flip3D(0.0, TFlipAxis.Horizontal, 240)
          .WithSpring(TFluentSpring.Snappy)
          .Start;
      end)
    .Start;
end;

procedure TMainForm.BtnDepositClick(Sender: TObject);
var
  OldVal: Double;
begin
  BtnDeposit.Motion
    .Scale(0.92, 90)
    .&Then
    .Scale(1.0, 240)
    .WithSpring(TFluentSpring.Bouncy)
    .Start;

  OldVal := FBalance;
  FBalance := FBalance + 250.0;
  AnimateBalance(OldVal, FBalance);
end;

procedure TMainForm.BtnPayClick(Sender: TObject);
var
  OldVal: Double;
begin
  BtnPay.Motion
    .Scale(0.92, 90)
    .&Then
    .Scale(1.0, 240)
    .WithSpring(TFluentSpring.Bouncy)
    .Start;

  if FBalance < 120.0 then
  begin
    RectCard.Shake(10.0, 320);
    Exit;
  end;

  OldVal := FBalance;
  FBalance := FBalance - 120.0;
  AnimateBalance(OldVal, FBalance);
end;

procedure TMainForm.AnimateBalance(const AOldValue, ANewValue: Double);
begin
  LabelBalance.Motion
    .CountTo(AOldValue, ANewValue, '$%0.2f', 850)
    .WithEase(TFluentEase.OutExpo)
    .Start;

  RectCard.Motion
    .Pulse(1.03, 240)
    .Start;
end;

end.
