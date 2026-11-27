unit Tulip.FluentMotion.Effect.Shadow;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.Math,
  System.UITypes,
  System.Generics.Collections,
  System.Skia,
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  FMX.Graphics,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Shader;

type
  { Shadow / Elevation Effect: Smoothly animates depth, softness, and opacity using Skia TSkMaskFilter.MakeBlur }
  TFluentShadowEffect = class(TFluentShaderEffect)
  private
    type
      TShadowState = record
        Distance: Single;
        Softness: Single;
        Opacity: Single;
      end;
    class var FControlStates: TDictionary<TControl, TShadowState>;
    class constructor CreateClass;
    class destructor DestroyClass;
  private
    FFromDistance: Single;
    FTargetDistance: Single;
    FStartDistance: Single;
    FInitialDistance: Single;
    FCurrentDistance: Single;

    FFromSoftness: Single;
    FTargetSoftness: Single;
    FStartSoftness: Single;
    FInitialSoftness: Single;
    FCurrentSoftness: Single;

    FFromOpacity: Single;
    FTargetOpacity: Single;
    FStartOpacity: Single;
    FInitialOpacity: Single;
    FCurrentOpacity: Single;

    FShadowColor: TAlphaColor;
    FAutoCapture: Boolean;
    procedure SaveControlState(const ADistance, ASoftness, AOpacity: Single);
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

    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single); override;
    procedure PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single); override;

    function Clone: IMotionEffect; override;

    property TargetDistance: Single read FTargetDistance write FTargetDistance;
    property TargetSoftness: Single read FTargetSoftness write FTargetSoftness;
    property TargetOpacity: Single read FTargetOpacity write FTargetOpacity;
    property ShadowColor: TAlphaColor read FShadowColor write FShadowColor;
  end;

implementation

{ TFluentShadowEffect }

class constructor TFluentShadowEffect.CreateClass;
begin
  FControlStates := TDictionary<TControl, TShadowState>.Create;
end;

class destructor TFluentShadowEffect.DestroyClass;
begin
  FreeAndNil(FControlStates);
end;

constructor TFluentShadowEffect.Create(const ATargetDistance, ATargetSoftness, ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  inherited Create('', ADurationMs, TShaderDrawMode.Background);
  FTargetDistance := Max(0.0, ATargetDistance);
  FTargetSoftness := EnsureRange(ATargetSoftness, 0.0, 1.0);
  FTargetOpacity := EnsureRange(ATargetOpacity, 0.0, 1.0);
  FFromDistance := 0.0;
  FFromSoftness := 0.0;
  FFromOpacity := 0.0;
  FStartDistance := 0.0;
  FStartSoftness := 0.0;
  FStartOpacity := 0.0;
  FInitialDistance := 0.0;
  FInitialSoftness := 0.0;
  FInitialOpacity := 0.0;
  FCurrentDistance := 0.0;
  FCurrentSoftness := 0.0;
  FCurrentOpacity := 0.0;
  FShadowColor := $80000000;
  FAutoCapture := True;
  FEase := TFluentEase.OutCubic;
end;

constructor TFluentShadowEffect.Create(const AFromDistance, ATargetDistance, AFromSoftness, ATargetSoftness, AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  inherited Create('', ADurationMs, TShaderDrawMode.Background);
  FFromDistance := Max(0.0, AFromDistance);
  FTargetDistance := Max(0.0, ATargetDistance);
  FFromSoftness := EnsureRange(AFromSoftness, 0.0, 1.0);
  FTargetSoftness := EnsureRange(ATargetSoftness, 0.0, 1.0);
  FFromOpacity := EnsureRange(AFromOpacity, 0.0, 1.0);
  FTargetOpacity := EnsureRange(ATargetOpacity, 0.0, 1.0);
  FStartDistance := FFromDistance;
  FStartSoftness := FFromSoftness;
  FStartOpacity := FFromOpacity;
  FInitialDistance := FFromDistance;
  FInitialSoftness := FFromSoftness;
  FInitialOpacity := FFromOpacity;
  FCurrentDistance := FFromDistance;
  FCurrentSoftness := FFromSoftness;
  FCurrentOpacity := FFromOpacity;
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

procedure TFluentShadowEffect.SaveControlState(const ADistance, ASoftness, AOpacity: Single);
var
  State: TShadowState;
begin
  if not Assigned(FControl) or not Assigned(FControlStates) then
    Exit;

  if (ADistance <= 0.01) or (AOpacity <= 0.01) then
    FControlStates.Remove(FControl)
  else
  begin
    State.Distance := ADistance;
    State.Softness := ASoftness;
    State.Opacity := AOpacity;
    FControlStates.AddOrSetValue(FControl, State);
  end;
end;

procedure TFluentShadowEffect.DoAttach;
var
  State: TShadowState;
begin
  inherited DoAttach;
  if FAutoCapture and Assigned(FControl) and Assigned(FControlStates) and FControlStates.TryGetValue(FControl, State) then
  begin
    FInitialDistance := State.Distance;
    FInitialSoftness := State.Softness;
    FInitialOpacity := State.Opacity;
    FFromDistance := FInitialDistance;
    FFromSoftness := FInitialSoftness;
    FFromOpacity := FInitialOpacity;
  end;
end;

procedure TFluentShadowEffect.DoStart;
var
  State: TShadowState;
begin
  inherited DoStart;
  if FAutoCapture and Assigned(FControl) and Assigned(FControlStates) and FControlStates.TryGetValue(FControl, State) then
  begin
    FStartDistance := State.Distance;
    FStartSoftness := State.Softness;
    FStartOpacity := State.Opacity;
  end
  else
  begin
    FStartDistance := FFromDistance;
    FStartSoftness := FFromSoftness;
    FStartOpacity := FFromOpacity;
  end;

  FCurrentDistance := FStartDistance;
  FCurrentSoftness := FStartSoftness;
  FCurrentOpacity := FStartOpacity;
  SaveControlState(FCurrentDistance, FCurrentSoftness, FCurrentOpacity);
end;

procedure TFluentShadowEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  FCurrentDistance := Max(0.0, FStartDistance + (FTargetDistance - FStartDistance) * AProgress);
  FCurrentSoftness := EnsureRange(FStartSoftness + (FTargetSoftness - FStartSoftness) * AProgress, 0.0, 1.0);
  FCurrentOpacity := EnsureRange(FStartOpacity + (FTargetOpacity - FStartOpacity) * AProgress, 0.0, 1.0);
  SaveControlState(FCurrentDistance, FCurrentSoftness, FCurrentOpacity);
end;

procedure TFluentShadowEffect.DoFinish;
begin
  FCurrentDistance := FTargetDistance;
  FCurrentSoftness := FTargetSoftness;
  FCurrentOpacity := FTargetOpacity;
  SaveControlState(FCurrentDistance, FCurrentSoftness, FCurrentOpacity);
end;

procedure TFluentShadowEffect.DoReset;
begin
  FCurrentDistance := FInitialDistance;
  FCurrentSoftness := FInitialSoftness;
  FCurrentOpacity := FInitialOpacity;
  SaveControlState(FCurrentDistance, FCurrentSoftness, FCurrentOpacity);
end;

procedure TFluentShadowEffect.Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
var
  Sigma, CornerRadius, FinalAlpha: Single;
  ShadowRect: TRectF;
  PaintObj: ISkPaint;
  SaveCount: Integer;
begin
  if (not Assigned(ACanvas)) or (FCurrentDistance <= 0.01) or (FCurrentOpacity <= 0.01) then
    Exit;

  Sigma := Max(0.5, FCurrentSoftness * 16.0);
  FinalAlpha := EnsureRange(FCurrentOpacity * AOpacity, 0.0, 1.0);
  CornerRadius := ExtractCornerRadius;

  ShadowRect := ARect;
  ShadowRect.Offset(0, FCurrentDistance);

  PaintObj := TSkPaint.Create;
  PaintObj.Color := FShadowColor;
  PaintObj.AlphaF := FinalAlpha;
  PaintObj.AntiAlias := True;
  PaintObj.MaskFilter := TSkMaskFilter.MakeBlur(TSkBlurStyle.Normal, Sigma);

  SaveCount := ACanvas.Save;
  try
    // Exclude control interior so drop shadow renders strictly around/beneath the control
    if CornerRadius > 0.5 then
    begin
      ACanvas.ClipRoundRect(TSkRoundRect.Create(ARect, CornerRadius, CornerRadius), TSkClipOp.Difference, True);
      ACanvas.DrawRoundRect(ShadowRect, CornerRadius, CornerRadius, PaintObj);
    end
    else if Assigned(FControl) and (FControl is TCircle) then
    begin
      ACanvas.ClipRoundRect(TSkRoundRect.Create(ARect, ARect.Width * 0.5, ARect.Height * 0.5), TSkClipOp.Difference, True);
      ACanvas.DrawOval(ShadowRect, PaintObj);
    end
    else
    begin
      ACanvas.ClipRect(ARect, TSkClipOp.Difference, True);
      ACanvas.DrawRect(ShadowRect, PaintObj);
    end;
  finally
    ACanvas.RestoreToCount(SaveCount);
  end;
end;

procedure TFluentShadowEffect.PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
begin
  // Pure Skia effect; no FMX TShadowEffect fallback
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
