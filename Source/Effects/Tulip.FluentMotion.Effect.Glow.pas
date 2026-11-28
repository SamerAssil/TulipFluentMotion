{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Glow
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Glow;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.Math,
  System.UITypes,
  System.Skia,
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  FMX.Graphics,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Shader;

type
  { Glow Effect: Animates neon / ambient outer glow using Skia TSkMaskFilter.MakeBlur }
  TFluentGlowEffect = class(TFluentShaderEffect)
  private
    FGlowColor: TAlphaColor;
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

    FAutoCapture: Boolean;
    procedure SaveControlState(const ASoftness, AOpacity: Single);
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const AGlowColor: TAlphaColor; const ATargetSoftness: Single = 0.5; const ATargetOpacity: Single = 0.8; const ADurationMs: Cardinal = 250); reintroduce; overload;
    constructor Create(const ATargetOpacity: Single; const ADurationMs: Cardinal = 250); reintroduce; overload;

    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single); override;
    procedure PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single); override;

    function Clone: IMotionEffect; override;

    property GlowColor: TAlphaColor read FGlowColor write FGlowColor;
    property TargetSoftness: Single read FTargetSoftness write FTargetSoftness;
    property TargetOpacity: Single read FTargetOpacity write FTargetOpacity;
  end;

implementation

uses
  Tulip.FluentMotion.Driver;

{ TFluentGlowEffect }

constructor TFluentGlowEffect.Create(const AGlowColor: TAlphaColor; const ATargetSoftness, ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  inherited Create('', ADurationMs, TShaderDrawMode.Background);
  FGlowColor := AGlowColor;
  FTargetSoftness := EnsureRange(ATargetSoftness, 0.0, 1.0);
  FTargetOpacity := EnsureRange(ATargetOpacity, 0.0, 1.0);
  FFromSoftness := 0.0;
  FFromOpacity := 0.0;
  FStartSoftness := 0.0;
  FStartOpacity := 0.0;
  FInitialSoftness := 0.0;
  FInitialOpacity := 0.0;
  FCurrentSoftness := 0.0;
  FCurrentOpacity := 0.0;
  FAutoCapture := True;
  FEase := TFluentEase.OutCubic;
end;

constructor TFluentGlowEffect.Create(const ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  Create($8000A0FF, 0.5, ATargetOpacity, ADurationMs);
end;

procedure TFluentGlowEffect.SaveControlState(const ASoftness, AOpacity: Single);
var
  Driver: TFluentMotionDriver;
begin
  Driver := TFluentMotionDriver.FindDriver(FControl);
  if Assigned(Driver) then
  begin
    Driver.GlowSoftness := ASoftness;
    Driver.GlowOpacity := AOpacity;
  end;
end;

procedure TFluentGlowEffect.DoAttach;
var
  Driver: TFluentMotionDriver;
begin
  inherited DoAttach;
  if FAutoCapture then
  begin
    Driver := TFluentMotionDriver.FindDriver(FControl);
    if Assigned(Driver) and (Driver.GlowOpacity > 0.01) then
    begin
      FInitialSoftness := Driver.GlowSoftness;
      FInitialOpacity := Driver.GlowOpacity;
      FFromSoftness := FInitialSoftness;
      FFromOpacity := FInitialOpacity;
    end;
  end;
end;

procedure TFluentGlowEffect.DoStart;
var
  Driver: TFluentMotionDriver;
begin
  inherited DoStart;
  if FAutoCapture then
  begin
    Driver := TFluentMotionDriver.FindDriver(FControl);
    if Assigned(Driver) and (Driver.GlowOpacity > 0.01) then
    begin
      FStartSoftness := Driver.GlowSoftness;
      FStartOpacity := Driver.GlowOpacity;
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

  FCurrentSoftness := FStartSoftness;
  FCurrentOpacity := FStartOpacity;
  SaveControlState(FCurrentSoftness, FCurrentOpacity);
end;

procedure TFluentGlowEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  FCurrentSoftness := EnsureRange(FStartSoftness + (FTargetSoftness - FStartSoftness) * AProgress, 0.0, 1.0);
  FCurrentOpacity := EnsureRange(FStartOpacity + (FTargetOpacity - FStartOpacity) * AProgress, 0.0, 1.0);
  SaveControlState(FCurrentSoftness, FCurrentOpacity);
end;

procedure TFluentGlowEffect.DoFinish;
begin
  FCurrentSoftness := FTargetSoftness;
  FCurrentOpacity := FTargetOpacity;
  SaveControlState(FCurrentSoftness, FCurrentOpacity);
end;

procedure TFluentGlowEffect.DoReset;
begin
  FCurrentSoftness := FInitialSoftness;
  FCurrentOpacity := FInitialOpacity;
  SaveControlState(FCurrentSoftness, FCurrentOpacity);
end;

procedure TFluentGlowEffect.Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
var
  Sigma, CornerRadius, FinalAlpha: Single;
  PaintObj: ISkPaint;
begin
  if (not Assigned(ACanvas)) or (FCurrentOpacity <= 0.01) then
    Exit;

  Sigma := Max(1.0, FCurrentSoftness * 20.0);
  FinalAlpha := EnsureRange(FCurrentOpacity * AOpacity, 0.0, 1.0);

  PaintObj := TSkPaint.Create;
  PaintObj.Color := FGlowColor;
  PaintObj.AlphaF := FinalAlpha;
  PaintObj.AntiAlias := True;
  PaintObj.MaskFilter := TSkMaskFilter.MakeBlur(TSkBlurStyle.Outer, Sigma);

  CornerRadius := ExtractCornerRadius;
  if CornerRadius > 0.5 then
    ACanvas.DrawRoundRect(ARect, CornerRadius, CornerRadius, PaintObj)
  else if Assigned(FControl) and (FControl is TCircle) then
    ACanvas.DrawOval(ARect, PaintObj)
  else
    ACanvas.DrawRect(ARect, PaintObj);
end;

procedure TFluentGlowEffect.PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
begin
  // Pure Skia effect; no FMX TGlowEffect fallback
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
