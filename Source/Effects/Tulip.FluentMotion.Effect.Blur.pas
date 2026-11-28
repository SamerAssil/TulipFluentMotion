{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Blur
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Blur;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.Math,
  System.Skia,
  FMX.Types,
  FMX.Controls,
  FMX.Objects,
  FMX.Graphics,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Shader;

type
  { Blur Effect: Smoothly animates Gaussian blur using Skia TSkImageFilter.MakeBlur }
  TFluentBlurEffect = class(TFluentShaderEffect)
  private
    FFromSoftness: Single;
    FTargetSoftness: Single;
    FStartSoftness: Single;
    FInitialSoftness: Single;
    FCurrentSoftness: Single;
    FAutoCapture: Boolean;
    procedure SaveSoftness(const AValue: Single);
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetSoftness: Single; const ADurationMs: Cardinal = 250); reintroduce; overload;
    constructor Create(const AFromSoftness, ATargetSoftness: Single; const ADurationMs: Cardinal = 250); reintroduce; overload;

    procedure Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single); override;
    procedure PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single); override;

    function Clone: IMotionEffect; override;

    class function GetCurrentSoftness(const AControl: TControl): Single; static;

    property TargetSoftness: Single read FTargetSoftness write FTargetSoftness;
    property CurrentSoftness: Single read FCurrentSoftness;
  end;

implementation

uses
  Tulip.FluentMotion.Driver;

{ TFluentBlurEffect }

class function TFluentBlurEffect.GetCurrentSoftness(const AControl: TControl): Single;
var
  Driver: TFluentMotionDriver;
begin
  Result := 0.0;
  Driver := TFluentMotionDriver.FindDriver(AControl);
  if Assigned(Driver) then
    Result := Driver.BlurSoftness;
end;

procedure TFluentBlurEffect.SaveSoftness(const AValue: Single);
var
  Driver: TFluentMotionDriver;
begin
  Driver := TFluentMotionDriver.FindDriver(FControl);
  if Assigned(Driver) then
    Driver.BlurSoftness := AValue;
end;

constructor TFluentBlurEffect.Create(const ATargetSoftness: Single; const ADurationMs: Cardinal);
begin
  inherited Create('', ADurationMs, TShaderDrawMode.Overlay);
  FTargetSoftness := Max(0.0, ATargetSoftness);
  FFromSoftness := 0.0;
  FStartSoftness := 0.0;
  FInitialSoftness := 0.0;
  FCurrentSoftness := 0.0;
  FAutoCapture := True;
  FEase := TFluentEase.OutCubic;
end;

constructor TFluentBlurEffect.Create(const AFromSoftness, ATargetSoftness: Single; const ADurationMs: Cardinal);
begin
  inherited Create('', ADurationMs, TShaderDrawMode.Overlay);
  FFromSoftness := Max(0.0, AFromSoftness);
  FTargetSoftness := Max(0.0, ATargetSoftness);
  FStartSoftness := FFromSoftness;
  FInitialSoftness := FFromSoftness;
  FCurrentSoftness := FFromSoftness;
  FAutoCapture := False;
  FEase := TFluentEase.OutCubic;
end;

procedure TFluentBlurEffect.DoAttach;
begin
  inherited DoAttach;
  if FAutoCapture and Assigned(FControl) then
  begin
    FInitialSoftness := GetCurrentSoftness(FControl);
    FFromSoftness := FInitialSoftness;
  end;
end;

procedure TFluentBlurEffect.DoStart;
begin
  inherited DoStart;
  if FAutoCapture and Assigned(FControl) then
    FStartSoftness := GetCurrentSoftness(FControl)
  else
    FStartSoftness := FFromSoftness;

  FCurrentSoftness := FStartSoftness;
  SaveSoftness(FCurrentSoftness);
end;

procedure TFluentBlurEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  FCurrentSoftness := Max(0.0, FStartSoftness + (FTargetSoftness - FStartSoftness) * AProgress);
  SaveSoftness(FCurrentSoftness);
end;

procedure TFluentBlurEffect.DoFinish;
begin
  FCurrentSoftness := FTargetSoftness;
  SaveSoftness(FCurrentSoftness);
end;

procedure TFluentBlurEffect.DoReset;
begin
  FCurrentSoftness := FInitialSoftness;
  SaveSoftness(FCurrentSoftness);
end;

procedure TFluentBlurEffect.Paint(const ACanvas: ISkCanvas; const ARect: TRectF; const AOpacity: Single);
var
  Sigma, CornerRadius: Single;
  BlurFilter: ISkImageFilter;
  PaintObj: ISkPaint;
  SaveCount: Integer;
begin
  if (not Assigned(ACanvas)) or (FCurrentSoftness <= 0.001) then
    Exit;

  Sigma := FCurrentSoftness * 3.0;
  BlurFilter := TSkImageFilter.MakeBlur(Sigma, Sigma, nil, TSkTileMode.Clamp);
  if not Assigned(BlurFilter) then
    Exit;

  CornerRadius := ExtractCornerRadius;
  SaveCount := ACanvas.Save;
  try
    if CornerRadius > 0.5 then
    begin
      var LRoundRect := TSkRoundRect.Create(ARect, CornerRadius, CornerRadius);
      try
        ACanvas.ClipRoundRect(LRoundRect, TSkClipOp.Intersect, True);
      finally
        LRoundRect.Free;
      end;
    end
    else if Assigned(FControl) and (FControl is TCircle) then
    begin
      var LRoundRect := TSkRoundRect.Create(ARect, ARect.Width * 0.5, ARect.Height * 0.5);
      try
        ACanvas.ClipRoundRect(LRoundRect, TSkClipOp.Intersect, True);
      finally
        LRoundRect.Free;
      end;
    end
    else
      ACanvas.ClipRect(ARect, TSkClipOp.Intersect, True);

    PaintObj := TSkPaint.Create;
    PaintObj.AlphaF := AOpacity;
    ACanvas.SaveLayer(ARect, PaintObj, BlurFilter);
    ACanvas.Restore;
  finally
    ACanvas.RestoreToCount(SaveCount);
  end;
end;

procedure TFluentBlurEffect.PaintFMX(const ACanvas: TCanvas; const ARect: TRectF; const AOpacity: Single);
begin
  // Pure Skia effect; no FMX TBlurEffect fallback
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
