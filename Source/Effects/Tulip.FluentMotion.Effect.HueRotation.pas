unit Tulip.FluentMotion.Effect.HueRotation;

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
  { Hue Rotation Effect: Smoothly rotates color spectrum (SwiftUI .hueRotation) }
  TFluentHueRotationEffect = class(TFluentMotionEffectBase)
  private
    FHueComponent: THueAdjustEffect;
    FFromAngleDeg: Single;
    FTargetAngleDeg: Single;
    FStartAngleDeg: Single;
    FInitialAngleDeg: Single;
    FAutoCapture: Boolean;
    function GetOrCreateHueComponent: THueAdjustEffect;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetAngleDeg: Single = 360.0; const ADurationMs: Cardinal = 500); reintroduce; overload;
    constructor Create(const AFromAngleDeg, ATargetAngleDeg: Single; const ADurationMs: Cardinal = 500); reintroduce; overload;

    function Clone: IMotionEffect; override;

    property TargetAngleDeg: Single read FTargetAngleDeg write FTargetAngleDeg;
    property FromAngleDeg: Single read FFromAngleDeg write FFromAngleDeg;
  end;

implementation

{ TFluentHueRotationEffect }

constructor TFluentHueRotationEffect.Create(const ATargetAngleDeg: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FTargetAngleDeg := ATargetAngleDeg;
  FFromAngleDeg := 0.0;
  FStartAngleDeg := 0.0;
  FInitialAngleDeg := 0.0;
  FAutoCapture := True;
  FEase := TFluentEase.Linear;
end;

constructor TFluentHueRotationEffect.Create(const AFromAngleDeg, ATargetAngleDeg: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FFromAngleDeg := AFromAngleDeg;
  FTargetAngleDeg := ATargetAngleDeg;
  FStartAngleDeg := AFromAngleDeg;
  FInitialAngleDeg := AFromAngleDeg;
  FAutoCapture := False;
  FEase := TFluentEase.Linear;
end;

function TFluentHueRotationEffect.GetOrCreateHueComponent: THueAdjustEffect;
var
  I: Integer;
begin
  if not Assigned(FControl) then
    Exit(nil);

  for I := 0 to FControl.ChildrenCount - 1 do
  begin
    if FControl.Children[I] is THueAdjustEffect then
    begin
      FHueComponent := THueAdjustEffect(FControl.Children[I]);
      Exit(FHueComponent);
    end;
  end;

  FHueComponent := THueAdjustEffect.Create(FControl);
  FHueComponent.Stored := False;
  FHueComponent.Parent := FControl;
  FHueComponent.Enabled := False;
  FHueComponent.Hue := 0.0;
  Result := FHueComponent;
end;

procedure TFluentHueRotationEffect.DoAttach;
begin
  GetOrCreateHueComponent;
  if Assigned(FHueComponent) then
  begin
    if FHueComponent.Enabled then
      FInitialAngleDeg := (FHueComponent.Hue / (2.0 * Pi)) * 360.0
    else
      FInitialAngleDeg := 0.0;

    if FAutoCapture then
      FFromAngleDeg := FInitialAngleDeg;
  end;
end;

procedure TFluentHueRotationEffect.DoStart;
begin
  GetOrCreateHueComponent;
  if Assigned(FHueComponent) then
  begin
    if FAutoCapture then
      FStartAngleDeg := FInitialAngleDeg
    else
      FStartAngleDeg := FFromAngleDeg;

    FHueComponent.Enabled := True;
  end;
end;

procedure TFluentHueRotationEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurAngleDeg: Single;
  CurHueVal: Single;
begin
  if not Assigned(FHueComponent) then
    Exit;

  CurAngleDeg := FStartAngleDeg + (FTargetAngleDeg - FStartAngleDeg) * AProgress;
  CurHueVal := (CurAngleDeg / 360.0) * (2.0 * Pi);

  FHueComponent.Hue := CurHueVal;
  FHueComponent.Enabled := (Abs(CurAngleDeg) > 0.01);
end;

procedure TFluentHueRotationEffect.DoFinish;
var
  FinalHueVal: Single;
begin
  if Assigned(FHueComponent) then
  begin
    FinalHueVal := (FTargetAngleDeg / 360.0) * (2.0 * Pi);
    FHueComponent.Hue := FinalHueVal;
    FHueComponent.Enabled := (Abs(FTargetAngleDeg) > 0.01);
  end;
end;

procedure TFluentHueRotationEffect.DoReset;
var
  InitHueVal: Single;
begin
  if Assigned(FHueComponent) then
  begin
    InitHueVal := (FInitialAngleDeg / 360.0) * (2.0 * Pi);
    FHueComponent.Hue := InitHueVal;
    FHueComponent.Enabled := (Abs(FInitialAngleDeg) > 0.01);
  end;
end;

function TFluentHueRotationEffect.Clone: IMotionEffect;
var
  Res: TFluentHueRotationEffect;
begin
  if FAutoCapture then
    Res := TFluentHueRotationEffect.Create(FTargetAngleDeg, FDurationMs)
  else
    Res := TFluentHueRotationEffect.Create(FFromAngleDeg, FTargetAngleDeg, FDurationMs);

  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

end.
