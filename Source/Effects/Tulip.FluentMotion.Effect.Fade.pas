unit Tulip.FluentMotion.Effect.Fade;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Fade Effect (Transforms TControl.Opacity) }
  TFluentFadeEffect = class(TFluentMotionEffectBase, ITransformEffect)
  private
    FFromOpacity: Single;
    FTargetOpacity: Single;
    FStartOpacity: Single;
    FInitialOpacity: Single;
    FAutoCapture: Boolean;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetOpacity: Single; const ADurationMs: Cardinal = 200); reintroduce; overload;
    constructor Create(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal = 200); reintroduce; overload;

    { ITransformEffect Implementation }
    procedure CaptureInitialState;
    procedure RestoreInitialState;

    function Clone: IMotionEffect; override;

    property TargetOpacity: Single read FTargetOpacity write FTargetOpacity;
  end;

implementation

{ TFluentFadeEffect }

constructor TFluentFadeEffect.Create(const ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FTargetOpacity := EnsureRange(ATargetOpacity, 0.0, 1.0);
  FFromOpacity := 1.0;
  FAutoCapture := True;
end;

constructor TFluentFadeEffect.Create(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FFromOpacity := EnsureRange(AFromOpacity, 0.0, 1.0);
  FTargetOpacity := EnsureRange(ATargetOpacity, 0.0, 1.0);
  FAutoCapture := False;
end;

procedure TFluentFadeEffect.CaptureInitialState;
begin
  if Assigned(FControl) then
  begin
    FInitialOpacity := FControl.Opacity;
    if FAutoCapture then
      FFromOpacity := FInitialOpacity;
  end;
end;

procedure TFluentFadeEffect.RestoreInitialState;
begin
  if Assigned(FControl) then
    FControl.Opacity := FInitialOpacity;
end;

procedure TFluentFadeEffect.DoAttach;
begin
  CaptureInitialState;
end;

procedure TFluentFadeEffect.DoStart;
begin
  if Assigned(FControl) then
  begin
    // If control is not visible, ensure it is visible so fade is visually rendered
    if not FControl.Visible then
    begin
      FControl.Opacity := 0.0;
      FControl.Visible := True;
    end;

    if FAutoCapture then
    begin
      // Smart AutoCapture:
      // 1. If Target is 1.0 (FadeIn) and current Opacity is already 1.0 (e.g. freshly created control),
      //    the user intended to fade IN from 0.0!
      // 2. If Target is 0.0 (FadeOut) and current Opacity is already 0.0,
      //    the user intended to fade OUT from 1.0!
      if (FTargetOpacity >= 0.99) and (FControl.Opacity >= 0.99) then
      begin
        FStartOpacity := 0.0;
        FControl.Opacity := 0.0;
      end
      else if (FTargetOpacity <= 0.01) and (FControl.Opacity <= 0.01) then
      begin
        FStartOpacity := 1.0;
        FControl.Opacity := 1.0;
      end
      else
        FStartOpacity := FControl.Opacity;
    end
    else
    begin
      FStartOpacity := FFromOpacity;
      FControl.Opacity := FFromOpacity;
    end;
  end;
end;

procedure TFluentFadeEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurOpacity: Single;
begin
  if not Assigned(FControl) then
    Exit;

  CurOpacity := EnsureRange(FStartOpacity + (FTargetOpacity - FStartOpacity) * AProgress, 0.0, 1.0);
  FControl.Opacity := CurOpacity;
  FControl.Repaint;
end;

procedure TFluentFadeEffect.DoReset;
begin
  RestoreInitialState;
end;

function TFluentFadeEffect.Clone: IMotionEffect;
var
  Res: TFluentFadeEffect;
begin
  if FAutoCapture then
    Res := TFluentFadeEffect.Create(FTargetOpacity, FDurationMs)
  else
    Res := TFluentFadeEffect.Create(FFromOpacity, FTargetOpacity, FDurationMs);

  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

end.
