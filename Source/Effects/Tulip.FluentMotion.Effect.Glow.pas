unit Tulip.FluentMotion.Effect.Glow;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Effects,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Glow Effect: Animates neon / ambient outer glow using FMX TGlowEffect }
  TFluentGlowEffect = class(TFluentMotionEffectBase)
  private
    FGlowComponent: TGlowEffect;
    FGlowColor: TAlphaColor;
    FFromSoftness: Single;
    FTargetSoftness: Single;
    FStartSoftness: Single;
    FInitialSoftness: Single;

    FFromOpacity: Single;
    FTargetOpacity: Single;
    FStartOpacity: Single;
    FInitialOpacity: Single;

    FAutoCapture: Boolean;
    function GetOrCreateGlowComponent: TGlowEffect;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const AGlowColor: TAlphaColor; const ATargetSoftness: Single = 0.5; const ATargetOpacity: Single = 0.8; const ADurationMs: Cardinal = 250); reintroduce; overload;
    constructor Create(const ATargetOpacity: Single; const ADurationMs: Cardinal = 250); reintroduce; overload;

    function Clone: IMotionEffect; override;

    property GlowColor: TAlphaColor read FGlowColor write FGlowColor;
    property TargetSoftness: Single read FTargetSoftness write FTargetSoftness;
    property TargetOpacity: Single read FTargetOpacity write FTargetOpacity;
  end;

implementation

{ TFluentGlowEffect }

constructor TFluentGlowEffect.Create(const AGlowColor: TAlphaColor; const ATargetSoftness, ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FGlowColor := AGlowColor;
  FTargetSoftness := EnsureRange(ATargetSoftness, 0.0, 1.0);
  FTargetOpacity := EnsureRange(ATargetOpacity, 0.0, 1.0);
  FFromSoftness := 0.0;
  FFromOpacity := 0.0;
  FAutoCapture := True;
  FEase := TFluentEase.OutCubic;
end;

constructor TFluentGlowEffect.Create(const ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  Create($8000A0FF, 0.5, ATargetOpacity, ADurationMs);
end;

function TFluentGlowEffect.GetOrCreateGlowComponent: TGlowEffect;
var
  I: Integer;
begin
  if not Assigned(FControl) then
    Exit(nil);

  for I := 0 to FControl.ChildrenCount - 1 do
  begin
    if FControl.Children[I] is TGlowEffect then
    begin
      FGlowComponent := TGlowEffect(FControl.Children[I]);
      Exit(FGlowComponent);
    end;
  end;

  FGlowComponent := TGlowEffect.Create(FControl);
  FGlowComponent.Stored := False;
  FGlowComponent.Parent := FControl;
  FGlowComponent.Enabled := False;
  FGlowComponent.Softness := 0.0;
  FGlowComponent.Opacity := 0.0;
  FGlowComponent.GlowColor := FGlowColor;
  Result := FGlowComponent;
end;

procedure TFluentGlowEffect.DoAttach;
begin
  GetOrCreateGlowComponent;
  if Assigned(FGlowComponent) then
  begin
    if FGlowComponent.Enabled then
    begin
      FInitialSoftness := FGlowComponent.Softness;
      FInitialOpacity := FGlowComponent.Opacity;
    end
    else
    begin
      FInitialSoftness := 0.0;
      FInitialOpacity := 0.0;
    end;

    if FAutoCapture then
    begin
      FFromSoftness := FInitialSoftness;
      FFromOpacity := FInitialOpacity;
    end;
  end;
end;

procedure TFluentGlowEffect.DoStart;
begin
  GetOrCreateGlowComponent;
  if Assigned(FGlowComponent) then
  begin
    FGlowComponent.GlowColor := FGlowColor;
    if FAutoCapture then
    begin
      if FGlowComponent.Enabled then
      begin
        FStartSoftness := FGlowComponent.Softness;
        FStartOpacity := FGlowComponent.Opacity;
      end
      else
      begin
        FStartSoftness := 0.0;
        FStartOpacity := 0.0;
      end;
    end
    else
    begin
      FStartSoftness := FFromSoftness;
      FStartOpacity := FFromOpacity;
    end;

    if (FStartOpacity > 0.01) or (FTargetOpacity > 0.01) then
      FGlowComponent.Enabled := True;
  end;
end;

procedure TFluentGlowEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurSoftness, CurOpacity: Single;
begin
  if not Assigned(FGlowComponent) then
    Exit;

  CurSoftness := EnsureRange(FStartSoftness + (FTargetSoftness - FStartSoftness) * AProgress, 0.0, 1.0);
  CurOpacity := EnsureRange(FStartOpacity + (FTargetOpacity - FStartOpacity) * AProgress, 0.0, 1.0);

  FGlowComponent.Softness := CurSoftness;
  FGlowComponent.Opacity := CurOpacity;
  FGlowComponent.Enabled := (CurOpacity > 0.01);
end;

procedure TFluentGlowEffect.DoFinish;
begin
  if Assigned(FGlowComponent) then
  begin
    FGlowComponent.Softness := FTargetSoftness;
    FGlowComponent.Opacity := FTargetOpacity;
    FGlowComponent.Enabled := (FTargetOpacity > 0.01);
  end;
end;

procedure TFluentGlowEffect.DoReset;
begin
  if Assigned(FGlowComponent) then
  begin
    FGlowComponent.Softness := FInitialSoftness;
    FGlowComponent.Opacity := FInitialOpacity;
    FGlowComponent.Enabled := (FInitialOpacity > 0.01);
  end;
end;

function TFluentGlowEffect.Clone: IMotionEffect;
var
  Res: TFluentGlowEffect;
begin
  Res := TFluentGlowEffect.Create(FGlowColor, FTargetSoftness, FTargetOpacity, FDurationMs);
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

end.
