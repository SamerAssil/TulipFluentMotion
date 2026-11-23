unit Tulip.FluentMotion.Effect.Shadow;

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
  { Shadow / Elevation Effect: Smoothly animates depth, softness, and opacity using FMX TShadowEffect }
  TFluentShadowEffect = class(TFluentMotionEffectBase)
  private
    FShadowComponent: TShadowEffect;
    FFromDistance: Single;
    FTargetDistance: Single;
    FStartDistance: Single;
    FInitialDistance: Single;

    FFromSoftness: Single;
    FTargetSoftness: Single;
    FStartSoftness: Single;
    FInitialSoftness: Single;

    FFromOpacity: Single;
    FTargetOpacity: Single;
    FStartOpacity: Single;
    FInitialOpacity: Single;

    FShadowColor: TAlphaColor;
    FAutoCapture: Boolean;
    function GetOrCreateShadowComponent: TShadowEffect;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetDistance: Single; const ATargetSoftness: Single = 0.3; const ATargetOpacity: Single = 0.5; const ADurationMs: Cardinal = 250); reintroduce; overload;
    constructor Create(const AFromDistance, ATargetDistance, AFromSoftness, ATargetSoftness, AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal = 250); reintroduce; overload;

    class function MakeElevation(const AElevationLevel: Single; const ADurationMs: Cardinal = 250): TFluentShadowEffect; static;

    function Clone: IMotionEffect; override;

    property TargetDistance: Single read FTargetDistance write FTargetDistance;
    property TargetSoftness: Single read FTargetSoftness write FTargetSoftness;
    property TargetOpacity: Single read FTargetOpacity write FTargetOpacity;
    property ShadowColor: TAlphaColor read FShadowColor write FShadowColor;
  end;

implementation

{ TFluentShadowEffect }

constructor TFluentShadowEffect.Create(const ATargetDistance, ATargetSoftness, ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FTargetDistance := Max(0.0, ATargetDistance);
  FTargetSoftness := EnsureRange(ATargetSoftness, 0.0, 1.0);
  FTargetOpacity := EnsureRange(ATargetOpacity, 0.0, 1.0);
  FFromDistance := 0.0;
  FFromSoftness := 0.0;
  FFromOpacity := 0.0;
  FShadowColor := $80000000;
  FAutoCapture := True;
  FEase := TFluentEase.OutCubic;
end;

constructor TFluentShadowEffect.Create(const AFromDistance, ATargetDistance, AFromSoftness, ATargetSoftness, AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FFromDistance := Max(0.0, AFromDistance);
  FTargetDistance := Max(0.0, ATargetDistance);
  FFromSoftness := EnsureRange(AFromSoftness, 0.0, 1.0);
  FTargetSoftness := EnsureRange(ATargetSoftness, 0.0, 1.0);
  FFromOpacity := EnsureRange(AFromOpacity, 0.0, 1.0);
  FTargetOpacity := EnsureRange(ATargetOpacity, 0.0, 1.0);
  FShadowColor := $80000000;
  FAutoCapture := False;
  FEase := TFluentEase.OutCubic;
end;

class function TFluentShadowEffect.MakeElevation(const AElevationLevel: Single; const ADurationMs: Cardinal): TFluentShadowEffect;
var
  LClampedLevel: Single;
  Dist, Soft, Opac: Single;
begin
  LClampedLevel := EnsureRange(AElevationLevel, 0.0, 5.0);
  if LClampedLevel <= 0.001 then
  begin
    Dist := 0.0;
    Soft := 0.0;
    Opac := 0.0;
  end
  else
  begin
    // Linear / quadratic scale: elevation 1 -> 2px dist, 0.2 soft, 0.25 opac
    // elevation 4 -> 16px dist, 0.65 soft, 0.55 opac
    Dist := LClampedLevel * 3.5;
    Soft := EnsureRange(0.15 + (LClampedLevel * 0.12), 0.0, 1.0);
    Opac := EnsureRange(0.20 + (LClampedLevel * 0.08), 0.0, 1.0);
  end;

  Result := TFluentShadowEffect.Create(Dist, Soft, Opac, ADurationMs);
end;

function TFluentShadowEffect.GetOrCreateShadowComponent: TShadowEffect;
var
  I: Integer;
begin
  if not Assigned(FControl) then
    Exit(nil);

  for I := 0 to FControl.ChildrenCount - 1 do
  begin
    if FControl.Children[I] is TShadowEffect then
    begin
      FShadowComponent := TShadowEffect(FControl.Children[I]);
      Exit(FShadowComponent);
    end;
  end;

  FShadowComponent := TShadowEffect.Create(FControl);
  FShadowComponent.Stored := False;
  FShadowComponent.Parent := FControl;
  FShadowComponent.Enabled := False;
  FShadowComponent.Distance := 0.0;
  FShadowComponent.Softness := 0.0;
  FShadowComponent.Opacity := 0.0;
  FShadowComponent.Direction := 90.0;
  FShadowComponent.ShadowColor := FShadowColor;
  Result := FShadowComponent;
end;

procedure TFluentShadowEffect.DoAttach;
begin
  GetOrCreateShadowComponent;
  if Assigned(FShadowComponent) then
  begin
    if FShadowComponent.Enabled then
    begin
      FInitialDistance := FShadowComponent.Distance;
      FInitialSoftness := FShadowComponent.Softness;
      FInitialOpacity := FShadowComponent.Opacity;
    end
    else
    begin
      FInitialDistance := 0.0;
      FInitialSoftness := 0.0;
      FInitialOpacity := 0.0;
    end;

    if FAutoCapture then
    begin
      FFromDistance := FInitialDistance;
      FFromSoftness := FInitialSoftness;
      FFromOpacity := FInitialOpacity;
    end;
  end;
end;

procedure TFluentShadowEffect.DoStart;
begin
  GetOrCreateShadowComponent;
  if Assigned(FShadowComponent) then
  begin
    if FAutoCapture then
    begin
      if FShadowComponent.Enabled then
      begin
        FStartDistance := FShadowComponent.Distance;
        FStartSoftness := FShadowComponent.Softness;
        FStartOpacity := FShadowComponent.Opacity;
      end
      else
      begin
        FStartDistance := 0.0;
        FStartSoftness := 0.0;
        FStartOpacity := 0.0;
      end;
    end
    else
    begin
      FStartDistance := FFromDistance;
      FStartSoftness := FFromSoftness;
      FStartOpacity := FFromOpacity;
    end;

    if (FStartDistance > 0.01) or (FTargetDistance > 0.01) or (FTargetOpacity > 0.01) then
      FShadowComponent.Enabled := True;
  end;
end;

procedure TFluentShadowEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurDist, CurSoft, CurOpac: Single;
begin
  if not Assigned(FShadowComponent) then
    Exit;

  CurDist := Max(0.0, FStartDistance + (FTargetDistance - FStartDistance) * AProgress);
  CurSoft := EnsureRange(FStartSoftness + (FTargetSoftness - FStartSoftness) * AProgress, 0.0, 1.0);
  CurOpac := EnsureRange(FStartOpacity + (FTargetOpacity - FStartOpacity) * AProgress, 0.0, 1.0);

  FShadowComponent.Distance := CurDist;
  FShadowComponent.Softness := CurSoft;
  FShadowComponent.Opacity := CurOpac;
  FShadowComponent.Enabled := (CurDist > 0.01) and (CurOpac > 0.01);
end;

procedure TFluentShadowEffect.DoFinish;
begin
  if Assigned(FShadowComponent) then
  begin
    FShadowComponent.Distance := FTargetDistance;
    FShadowComponent.Softness := FTargetSoftness;
    FShadowComponent.Opacity := FTargetOpacity;
    FShadowComponent.Enabled := (FTargetDistance > 0.01) and (FTargetOpacity > 0.01);
  end;
end;

procedure TFluentShadowEffect.DoReset;
begin
  if Assigned(FShadowComponent) then
  begin
    FShadowComponent.Distance := FInitialDistance;
    FShadowComponent.Softness := FInitialSoftness;
    FShadowComponent.Opacity := FInitialOpacity;
    FShadowComponent.Enabled := (FInitialDistance > 0.01) and (FInitialOpacity > 0.01);
  end;
end;

function TFluentShadowEffect.Clone: IMotionEffect;
var
  Res: TFluentShadowEffect;
begin
  if FAutoCapture then
    Res := TFluentShadowEffect.Create(FTargetDistance, FTargetSoftness, FTargetOpacity, FDurationMs)
  else
    Res := TFluentShadowEffect.Create(FFromDistance, FTargetDistance, FFromSoftness, FTargetSoftness, FFromOpacity, FTargetOpacity, FDurationMs);

  Res.FShadowColor := FShadowColor;
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

end.
