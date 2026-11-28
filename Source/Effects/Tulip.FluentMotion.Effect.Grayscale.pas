{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Grayscale
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Grayscale;

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
  FMX.Filter.Effects,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Shader;

type
  { Grayscale Effect: Smooth GPU SkSL desaturation (0.0..1.0) with FMX TMonochromeEffect fallback }
  TFluentGrayscaleEffect = class(TFluentShaderEffect)
  private
    const GRAYSCALE_SKSL =
      'uniform shader image;' + sLineBreak +
      'uniform float uAmount;' + sLineBreak +
      'half4 main(vec2 fragCoord) {' + sLineBreak +
      '    half4 c = image.eval(fragCoord);' + sLineBreak +
      '    float lum = dot(c.rgb, half3(0.299, 0.587, 0.114));' + sLineBreak +
      '    half3 gray = half3(lum);' + sLineBreak +
      '    return half4(mix(c.rgb, gray, clamp(uAmount, 0.0, 1.0)), c.a);' + sLineBreak +
      '}';
  private
    FMonochromeComponent: TMonochromeEffect;
    FFromAmount: Single;
    FTargetAmount: Single;
    FStartAmount: Single;
    FInitialAmount: Single;
    FCurrentAmount: Single;
    FAutoCapture: Boolean;
    function GetOrCreateMonochromeComponent: TMonochromeEffect;
    procedure SaveAmount(const AValue: Single);
  protected
    procedure ApplyUniforms(const ABuilder: ISkRuntimeShaderBuilder; const ARect: TRectF; const AOpacity: Single); override;
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetAmount: Single = 1.0; const ADurationMs: Cardinal = 250); reintroduce; overload;
    constructor Create(const AFromAmount, ATargetAmount: Single; const ADurationMs: Cardinal = 250); reintroduce; overload;

    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single); override;
    procedure PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single); override;

    function Clone: IMotionEffect; override;

    class function GetCurrentAmount(const AControl: TControl): Single; static;

    property TargetAmount: Single read FTargetAmount write FTargetAmount;
    property CurrentAmount: Single read FCurrentAmount;
  end;

implementation

uses
  Tulip.FluentMotion.Driver;

{ TFluentGrayscaleEffect }

class function TFluentGrayscaleEffect.GetCurrentAmount(const AControl: TControl): Single;
var
  Driver: TFluentMotionDriver;
begin
  Result := 0.0;
  Driver := TFluentMotionDriver.FindDriver(AControl);
  if Assigned(Driver) then
    Result := Driver.GrayscaleAmount;
end;

procedure TFluentGrayscaleEffect.SaveAmount(const AValue: Single);
var
  Driver: TFluentMotionDriver;
begin
  Driver := TFluentMotionDriver.FindDriver(FControl);
  if Assigned(Driver) then
    Driver.GrayscaleAmount := AValue;
end;

constructor TFluentGrayscaleEffect.Create(const ATargetAmount: Single; const ADurationMs: Cardinal);
begin
  inherited Create(GRAYSCALE_SKSL, ADurationMs, TShaderDrawMode.Overlay);
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
  inherited Create(GRAYSCALE_SKSL, ADurationMs, TShaderDrawMode.Overlay);
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

procedure TFluentGrayscaleEffect.ApplyUniforms(const ABuilder: ISkRuntimeShaderBuilder; const ARect: TRectF; const AOpacity: Single);
begin
  inherited ApplyUniforms(ABuilder, ARect, AOpacity);
  if Assigned(FEffect) and (FEffect.IndexOfUniform('uAmount') >= 0) then
    ABuilder.SetUniform('uAmount', FCurrentAmount);
end;

procedure TFluentGrayscaleEffect.DoAttach;
begin
  inherited DoAttach;
  if FAutoCapture and Assigned(FControl) then
  begin
    FInitialAmount := GetCurrentAmount(FControl);
    FFromAmount := FInitialAmount;
  end;
end;

procedure TFluentGrayscaleEffect.DoStart;
begin
  inherited DoStart;
  if FAutoCapture and Assigned(FControl) then
    FStartAmount := GetCurrentAmount(FControl)
  else
    FStartAmount := FFromAmount;

  FCurrentAmount := FStartAmount;
  SaveAmount(FCurrentAmount);
end;

procedure TFluentGrayscaleEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  FCurrentAmount := EnsureRange(FStartAmount + (FTargetAmount - FStartAmount) * AProgress, 0.0, 1.0);
  SaveAmount(FCurrentAmount);
end;

procedure TFluentGrayscaleEffect.DoFinish;
begin
  FCurrentAmount := FTargetAmount;
  SaveAmount(FCurrentAmount);
end;

procedure TFluentGrayscaleEffect.DoReset;
begin
  FCurrentAmount := FInitialAmount;
  SaveAmount(FCurrentAmount);
  if Assigned(FMonochromeComponent) then
    FMonochromeComponent.Enabled := (FInitialAmount >= 0.5);
end;

procedure TFluentGrayscaleEffect.Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
begin
  if FCurrentAmount <= 0.001 then
    Exit;
  inherited Paint(ACanvas, ARect, AOpacity);
end;

procedure TFluentGrayscaleEffect.PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
begin
  GetOrCreateMonochromeComponent;
  if Assigned(FMonochromeComponent) then
    FMonochromeComponent.Enabled := (FCurrentAmount >= 0.5);
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
