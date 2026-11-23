unit Tulip.FluentMotion.Effect.Grayscale;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  FMX.Types,
  FMX.Controls,
  FMX.Filter.Effects,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Grayscale Effect: Animates monochrome desaturation using FMX TMonochromeEffect }
  TFluentGrayscaleEffect = class(TFluentMotionEffectBase)
  private
    FMonochromeComponent: TMonochromeEffect;
    FFromAmount: Single;
    FTargetAmount: Single;
    FStartAmount: Single;
    FInitialAmount: Single;
    FCurrentAmount: Single;
    FAutoCapture: Boolean;
    function GetOrCreateMonochromeComponent: TMonochromeEffect;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetAmount: Single = 1.0; const ADurationMs: Cardinal = 250); reintroduce; overload;
    constructor Create(const AFromAmount, ATargetAmount: Single; const ADurationMs: Cardinal = 250); reintroduce; overload;

    function Clone: IMotionEffect; override;

    property TargetAmount: Single read FTargetAmount write FTargetAmount;
    property CurrentAmount: Single read FCurrentAmount;
  end;

implementation

{ TFluentGrayscaleEffect }

constructor TFluentGrayscaleEffect.Create(const ATargetAmount: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FTargetAmount := EnsureRange(ATargetAmount, 0.0, 1.0);
  FFromAmount := 0.0;
  FStartAmount := 0.0;
  FInitialAmount := 0.0;
  FCurrentAmount := 0.0;
  FAutoCapture := True;
  FEase := TFluentEase.OutCubic;
end;

constructor TFluentGrayscaleEffect.Create(const AFromAmount, ATargetAmount: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FFromAmount := EnsureRange(AFromAmount, 0.0, 1.0);
  FTargetAmount := EnsureRange(ATargetAmount, 0.0, 1.0);
  FStartAmount := FFromAmount;
  FInitialAmount := FFromAmount;
  FCurrentAmount := FFromAmount;
  FAutoCapture := False;
  FEase := TFluentEase.OutCubic;
end;

function TFluentGrayscaleEffect.GetOrCreateMonochromeComponent: TMonochromeEffect;
var
  I: Integer;
begin
  if not Assigned(FControl) then
    Exit(nil);

  for I := 0 to FControl.ChildrenCount - 1 do
  begin
    if FControl.Children[I] is TMonochromeEffect then
    begin
      FMonochromeComponent := TMonochromeEffect(FControl.Children[I]);
      Exit(FMonochromeComponent);
    end;
  end;

  FMonochromeComponent := TMonochromeEffect.Create(FControl);
  FMonochromeComponent.Stored := False;
  FMonochromeComponent.Parent := FControl;
  FMonochromeComponent.Enabled := False;
  Result := FMonochromeComponent;
end;

procedure TFluentGrayscaleEffect.DoAttach;
begin
  GetOrCreateMonochromeComponent;
  if Assigned(FMonochromeComponent) then
  begin
    if FMonochromeComponent.Enabled then
      FInitialAmount := 1.0
    else
      FInitialAmount := 0.0;

    if FAutoCapture then
      FFromAmount := FInitialAmount;
  end;
end;

procedure TFluentGrayscaleEffect.DoStart;
begin
  GetOrCreateMonochromeComponent;
  if Assigned(FMonochromeComponent) then
  begin
    if FAutoCapture then
    begin
      if FMonochromeComponent.Enabled then
        FStartAmount := 1.0
      else
        FStartAmount := 0.0;
    end
    else
      FStartAmount := FFromAmount;

    FCurrentAmount := FStartAmount;
    FMonochromeComponent.Enabled := (FCurrentAmount >= 0.5) or (FTargetAmount >= 0.5);
  end;
end;

procedure TFluentGrayscaleEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  FCurrentAmount := EnsureRange(FStartAmount + (FTargetAmount - FStartAmount) * AProgress, 0.0, 1.0);
  if Assigned(FMonochromeComponent) then
    FMonochromeComponent.Enabled := (FCurrentAmount >= 0.5);
end;

procedure TFluentGrayscaleEffect.DoFinish;
begin
  FCurrentAmount := FTargetAmount;
  if Assigned(FMonochromeComponent) then
    FMonochromeComponent.Enabled := (FTargetAmount >= 0.5);
end;

procedure TFluentGrayscaleEffect.DoReset;
begin
  FCurrentAmount := FInitialAmount;
  if Assigned(FMonochromeComponent) then
    FMonochromeComponent.Enabled := (FInitialAmount >= 0.5);
end;

function TFluentGrayscaleEffect.Clone: IMotionEffect;
var
  Res: TFluentGrayscaleEffect;
begin
  if FAutoCapture then
    Res := TFluentGrayscaleEffect.Create(FTargetAmount, FDurationMs)
  else
    Res := TFluentGrayscaleEffect.Create(FFromAmount, FTargetAmount, FDurationMs);

  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

end.
