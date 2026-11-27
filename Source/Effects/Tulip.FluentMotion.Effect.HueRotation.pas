unit Tulip.FluentMotion.Effect.HueRotation;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.Math,
  System.Skia,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Shader;

type
  { Hue Rotation Effect: Smoothly rotates color spectrum via SkSL (SwiftUI .hueRotation) }
  TFluentHueRotationEffect = class(TFluentShaderEffect)
  private
    const HUE_ROTATION_SKSL =
      'uniform shader image;' + sLineBreak +
      'uniform float uAngleRad;' + sLineBreak +
      'half4 main(vec2 fragCoord) {' + sLineBreak +
      '    half4 c = image.eval(fragCoord);' + sLineBreak +
      '    float cosA = cos(uAngleRad);' + sLineBreak +
      '    float sinA = sin(uAngleRad);' + sLineBreak +
      '    float k = 0.213;' + sLineBreak +
      '    float l = 0.715;' + sLineBreak +
      '    float m = 0.072;' + sLineBreak +
      '    half3 rRow = half3(k + cosA * (1.0 - k) + sinA * (-k), l + cosA * (-l) + sinA * (-l), m + cosA * (-m) + sinA * (1.0 - m));' + sLineBreak +
      '    half3 gRow = half3(k + cosA * (-k) + sinA * 0.143, l + cosA * (1.0 - l) + sinA * 0.140, m + cosA * (-m) + sinA * (-0.283));' + sLineBreak +
      '    half3 bRow = half3(k + cosA * (-k) + sinA * (-(1.0 - k)), l + cosA * (-l) + sinA * l, m + cosA * (1.0 - m) + sinA * m);' + sLineBreak +
      '    half3 rotated = half3(dot(c.rgb, rRow), dot(c.rgb, gRow), dot(c.rgb, bRow));' + sLineBreak +
      '    return half4(clamp(rotated, half3(0.0), half3(c.a)), c.a);' + sLineBreak +
      '}';
  private
    FFromAngleDeg: Single;
    FTargetAngleDeg: Single;
    FStartAngleDeg: Single;
    FInitialAngleDeg: Single;
    FCurrentAngleDeg: Single;
    FAutoCapture: Boolean;
    procedure SaveAngleDeg(const AValue: Single);
  protected
    procedure ApplyUniforms(const ABuilder: ISkRuntimeShaderBuilder; const ARect: TRectF; const AOpacity: Single); override;
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetAngleDeg: Single = 360.0; const ADurationMs: Cardinal = 500); reintroduce; overload;
    constructor Create(const AFromAngleDeg, ATargetAngleDeg: Single; const ADurationMs: Cardinal = 500); reintroduce; overload;

    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single); override;
    procedure PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single); override;

    function Clone: IMotionEffect; override;

    class function GetCurrentAngleDeg(const AControl: TControl): Single; static;

    property TargetAngleDeg: Single read FTargetAngleDeg write FTargetAngleDeg;
    property FromAngleDeg: Single read FFromAngleDeg write FFromAngleDeg;
    property CurrentAngleDeg: Single read FCurrentAngleDeg;
  end;

implementation

uses
  Tulip.FluentMotion.Driver;

{ TFluentHueRotationEffect }

class function TFluentHueRotationEffect.GetCurrentAngleDeg(const AControl: TControl): Single;
var
  Driver: TFluentMotionDriver;
begin
  Result := 0.0;
  Driver := TFluentMotionDriver.FindDriver(AControl);
  if Assigned(Driver) then
    Result := Driver.HueAngleDeg;
end;

procedure TFluentHueRotationEffect.SaveAngleDeg(const AValue: Single);
var
  Driver: TFluentMotionDriver;
begin
  Driver := TFluentMotionDriver.FindDriver(FControl);
  if Assigned(Driver) then
    Driver.HueAngleDeg := AValue;
end;

constructor TFluentHueRotationEffect.Create(const ATargetAngleDeg: Single; const ADurationMs: Cardinal);
begin
  inherited Create(HUE_ROTATION_SKSL, ADurationMs, TShaderDrawMode.Overlay);
  FTargetAngleDeg := ATargetAngleDeg;
  FFromAngleDeg := 0.0;
  FStartAngleDeg := 0.0;
  FInitialAngleDeg := 0.0;
  FCurrentAngleDeg := 0.0;
  FAutoCapture := True;
  FEase := TFluentEase.Linear;
end;

constructor TFluentHueRotationEffect.Create(const AFromAngleDeg, ATargetAngleDeg: Single; const ADurationMs: Cardinal);
begin
  inherited Create(HUE_ROTATION_SKSL, ADurationMs, TShaderDrawMode.Overlay);
  FFromAngleDeg := AFromAngleDeg;
  FTargetAngleDeg := ATargetAngleDeg;
  FStartAngleDeg := AFromAngleDeg;
  FInitialAngleDeg := AFromAngleDeg;
  FCurrentAngleDeg := AFromAngleDeg;
  FAutoCapture := False;
  FEase := TFluentEase.Linear;
end;

procedure TFluentHueRotationEffect.ApplyUniforms(const ABuilder: ISkRuntimeShaderBuilder; const ARect: TRectF; const AOpacity: Single);
begin
  inherited ApplyUniforms(ABuilder, ARect, AOpacity);
  if Assigned(FEffect) and (FEffect.IndexOfUniform('uAngleRad') >= 0) then
    ABuilder.SetUniform('uAngleRad', DegToRad(FCurrentAngleDeg));
end;

procedure TFluentHueRotationEffect.DoAttach;
begin
  inherited DoAttach;
  if FAutoCapture and Assigned(FControl) then
  begin
    FInitialAngleDeg := GetCurrentAngleDeg(FControl);
    FFromAngleDeg := FInitialAngleDeg;
  end;
end;

procedure TFluentHueRotationEffect.DoStart;
begin
  inherited DoStart;
  if FAutoCapture and Assigned(FControl) then
    FStartAngleDeg := GetCurrentAngleDeg(FControl)
  else
    FStartAngleDeg := FFromAngleDeg;

  FCurrentAngleDeg := FStartAngleDeg;
  SaveAngleDeg(FCurrentAngleDeg);
end;

procedure TFluentHueRotationEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  FCurrentAngleDeg := FStartAngleDeg + (FTargetAngleDeg - FStartAngleDeg) * AProgress;
  SaveAngleDeg(FCurrentAngleDeg);
end;

procedure TFluentHueRotationEffect.DoFinish;
begin
  FCurrentAngleDeg := FTargetAngleDeg;
  SaveAngleDeg(FCurrentAngleDeg);
end;

procedure TFluentHueRotationEffect.DoReset;
begin
  FCurrentAngleDeg := FInitialAngleDeg;
  SaveAngleDeg(FCurrentAngleDeg);
end;

procedure TFluentHueRotationEffect.Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
begin
  if Abs(FMod(FCurrentAngleDeg, 360.0)) <= 0.01 then
    Exit;
  inherited Paint(ACanvas, ARect, AOpacity);
end;

procedure TFluentHueRotationEffect.PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
begin
  // Pure Skia effect; no FMX THueAdjustEffect fallback
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
