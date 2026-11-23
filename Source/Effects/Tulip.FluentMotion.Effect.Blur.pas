unit Tulip.FluentMotion.Effect.Blur;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  FMX.Types,
  FMX.Controls,
  FMX.Effects,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Blur Effect: Smoothly animates blur softness using hardware-accelerated FMX TBlurEffect }
  TFluentBlurEffect = class(TFluentMotionEffectBase)
  private
    FBlurComponent: TBlurEffect;
    FFromSoftness: Single;
    FTargetSoftness: Single;
    FStartSoftness: Single;
    FInitialSoftness: Single;
    FAutoCapture: Boolean;
    function GetOrCreateBlurComponent: TBlurEffect;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetSoftness: Single; const ADurationMs: Cardinal = 250); reintroduce; overload;
    constructor Create(const AFromSoftness, ATargetSoftness: Single; const ADurationMs: Cardinal = 250); reintroduce; overload;

    function Clone: IMotionEffect; override;

    property TargetSoftness: Single read FTargetSoftness write FTargetSoftness;
  end;

implementation

{ TFluentBlurEffect }

constructor TFluentBlurEffect.Create(const ATargetSoftness: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FTargetSoftness := Max(0.0, ATargetSoftness);
  FFromSoftness := 0.0;
  FAutoCapture := True;
  FEase := TFluentEase.OutCubic;
end;

constructor TFluentBlurEffect.Create(const AFromSoftness, ATargetSoftness: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FFromSoftness := Max(0.0, AFromSoftness);
  FTargetSoftness := Max(0.0, ATargetSoftness);
  FAutoCapture := False;
  FEase := TFluentEase.OutCubic;
end;

function TFluentBlurEffect.GetOrCreateBlurComponent: TBlurEffect;
var
  I: Integer;
begin
  if not Assigned(FControl) then
    Exit(nil);

  for I := 0 to FControl.ChildrenCount - 1 do
  begin
    if FControl.Children[I] is TBlurEffect then
    begin
      FBlurComponent := TBlurEffect(FControl.Children[I]);
      Exit(FBlurComponent);
    end;
  end;

  FBlurComponent := TBlurEffect.Create(FControl);
  FBlurComponent.Stored := False;
  FBlurComponent.Parent := FControl;
  FBlurComponent.Enabled := False;
  FBlurComponent.Softness := 0.0;
  Result := FBlurComponent;
end;

procedure TFluentBlurEffect.DoAttach;
begin
  GetOrCreateBlurComponent;
  if Assigned(FBlurComponent) then
  begin
    if FBlurComponent.Enabled then
      FInitialSoftness := FBlurComponent.Softness
    else
      FInitialSoftness := 0.0;

    if FAutoCapture then
      FFromSoftness := FInitialSoftness;
  end;
end;

procedure TFluentBlurEffect.DoStart;
begin
  GetOrCreateBlurComponent;
  if Assigned(FBlurComponent) then
  begin
    if FAutoCapture then
    begin
      if FBlurComponent.Enabled then
        FStartSoftness := FBlurComponent.Softness
      else
        FStartSoftness := 0.0;
    end
    else
      FStartSoftness := FFromSoftness;

    if (FStartSoftness > 0.001) or (FTargetSoftness > 0.001) then
      FBlurComponent.Enabled := True;
  end;
end;

procedure TFluentBlurEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurSoftness: Single;
begin
  if not Assigned(FBlurComponent) then
    Exit;

  CurSoftness := Max(0.0, FStartSoftness + (FTargetSoftness - FStartSoftness) * AProgress);
  FBlurComponent.Softness := CurSoftness;
  FBlurComponent.Enabled := (CurSoftness > 0.001);
end;

procedure TFluentBlurEffect.DoFinish;
begin
  if Assigned(FBlurComponent) then
  begin
    FBlurComponent.Softness := FTargetSoftness;
    FBlurComponent.Enabled := (FTargetSoftness > 0.001);
  end;
end;

procedure TFluentBlurEffect.DoReset;
begin
  if Assigned(FBlurComponent) then
  begin
    FBlurComponent.Softness := FInitialSoftness;
    FBlurComponent.Enabled := (FInitialSoftness > 0.001);
  end;
end;

function TFluentBlurEffect.Clone: IMotionEffect;
var
  Res: TFluentBlurEffect;
begin
  if FAutoCapture then
    Res := TFluentBlurEffect.Create(FTargetSoftness, FDurationMs)
  else
    Res := TFluentBlurEffect.Create(FFromSoftness, FTargetSoftness, FDurationMs);

  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

end.
