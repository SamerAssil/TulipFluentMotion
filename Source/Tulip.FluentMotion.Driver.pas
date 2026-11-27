unit Tulip.FluentMotion.Driver;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Types,
  System.UITypes,
  System.Generics.Collections,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  System.Skia,
  FMX.Skia,
  FMX.Skia.Canvas,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces;

type
  { Companion Control attached to TControl that drives animations and Skia paints }
  TFluentMotionDriver = class(TControl, IMotionDriver)
  private
    FHostControl: TControl;
    FPhases: TList<IMotionPhase>;
    FCurrentPhaseIndex: Integer;
    FPaintEffects: TList<ISkiaPaintEffect>;
    FIsRunning: Boolean;
    FIsExecutingTick: Boolean;
    FIsDestroying: Boolean;
    FOnComplete: TMotionCallback;
    FOnProgress: TMotionProgressCallback;
    FTotalEngineDurationMs: Cardinal;
    FElapsedEngineSec: Single;
    FRepeatCount: Integer;
    FAutoreverse: Boolean;
    FCompletedIterations: Integer;
    FIsReversing: Boolean;
    FSpeed: Single;
    FIsPaused: Boolean;
    FIsPhaseSequenceFinished: Boolean;

    { Per-control persistent effect states (freed automatically with host control) }
    FBlurSoftness: Single;
    FGrayscaleAmount: Single;
    FHueAngleDeg: Single;
    FGlowSoftness: Single;
    FGlowOpacity: Single;
    FShadowDistance: Single;
    FShadowSoftness: Single;
    FShadowOpacity: Single;
    FLiquidWaveLevel: Single;
    function HasContinuousEffect: Boolean;
    procedure AdvanceToNextPhase(out APendingComplete: TMotionCallback);
    procedure RecalculateEngineDuration;
  protected
    procedure Paint; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateForControl(AControl: TControl); reintroduce;
    destructor Destroy; override;

    class function FindDriver(const AControl: TControl): TFluentMotionDriver; static;
    class function GetOrCreate(const AControl: TControl): TFluentMotionDriver; static;

    { IMotionDriver Implementation }
    function GetControl: TControl;
    procedure AddPhase(const APhase: IMotionPhase);
    procedure ClearPhases;
    procedure Start;
    procedure Stop;
    procedure Reset;
    procedure Pause;
    procedure Resume;
    function IsRunning: Boolean;
    function IsPaused: Boolean;
    procedure Tick(const ADeltaTimeSec: Single);
    procedure RegisterPaintEffect(const AEffect: ISkiaPaintEffect);
    procedure UnregisterPaintEffect(const AEffect: ISkiaPaintEffect);
    procedure RequestRepaint;
    procedure SetRepeatCount(const ACount: Integer);
    procedure SetAutoreverse(const AEnabled: Boolean);
    procedure SetSpeed(const ASpeed: Single);
    function GetSpeed: Single;
    procedure Seek(const AProgress: Single);

    property HostControl: TControl read FHostControl;
    property RepeatCount: Integer read FRepeatCount write FRepeatCount;
    property Autoreverse: Boolean read FAutoreverse write FAutoreverse;
    property Speed: Single read FSpeed write SetSpeed;
    property OnComplete: TMotionCallback read FOnComplete write FOnComplete;
    property OnProgress: TMotionProgressCallback read FOnProgress write FOnProgress;

    { Persistent Effect States }
    property BlurSoftness: Single read FBlurSoftness write FBlurSoftness;
    property GrayscaleAmount: Single read FGrayscaleAmount write FGrayscaleAmount;
    property HueAngleDeg: Single read FHueAngleDeg write FHueAngleDeg;
    property GlowSoftness: Single read FGlowSoftness write FGlowSoftness;
    property GlowOpacity: Single read FGlowOpacity write FGlowOpacity;
    property ShadowDistance: Single read FShadowDistance write FShadowDistance;
    property ShadowSoftness: Single read FShadowSoftness write FShadowSoftness;
    property ShadowOpacity: Single read FShadowOpacity write FShadowOpacity;
    property LiquidWaveLevel: Single read FLiquidWaveLevel write FLiquidWaveLevel;
  end;

implementation

uses
  Tulip.FluentMotion.Engine,
  Tulip.FluentMotion.Effect.Shader;

{ TFluentMotionDriver }

constructor TFluentMotionDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Stored := False;
  Locked := True;
  HitTest := False;
  Align := TAlignLayout.Contents;
  FPhases := TList<IMotionPhase>.Create;
  FPaintEffects := TList<ISkiaPaintEffect>.Create;
  FCurrentPhaseIndex := -1;
  FIsRunning := False;
  FIsExecutingTick := False;
  FIsDestroying := False;
  FElapsedEngineSec := 0.0;
  FTotalEngineDurationMs := 0;
  FRepeatCount := 0;
  FAutoreverse := False;
  FCompletedIterations := 0;
  FIsReversing := False;
  FSpeed := 1.0;
  FIsPaused := False;
end;

constructor TFluentMotionDriver.CreateForControl(AControl: TControl);
begin
  Create(AControl);
  FHostControl := AControl;
  if Assigned(AControl) then
  begin
    AControl.FreeNotification(Self);
    Parent := AControl;
  end;
end;

destructor TFluentMotionDriver.Destroy;
var
  LDriver: IMotionDriver;
  LEngine: TFluentMotionEngine;
begin
  FIsDestroying := True;
  FIsRunning := False;

  // Unregister safely before clearing internal lists
  LEngine := TFluentMotionEngine.Instance;
  if LEngine <> nil then
  begin
    if Supports(Self, IMotionDriver, LDriver) then
      LEngine.UnregisterDriver(LDriver);
  end;

  FreeAndNil(FPaintEffects);
  FreeAndNil(FPhases);
  inherited Destroy;
end;

procedure TFluentMotionDriver.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = TOperation.opRemove) and (AComponent = FHostControl) then
  begin
    FHostControl := nil;
    Stop;
  end;
end;

class function TFluentMotionDriver.FindDriver(const AControl: TControl): TFluentMotionDriver;
var
  I: Integer;
begin
  Result := nil;
  if not Assigned(AControl) then
    Exit;

  for I := 0 to AControl.ChildrenCount - 1 do
  begin
    if AControl.Children[I] is TFluentMotionDriver then
      Exit(TFluentMotionDriver(AControl.Children[I]));
  end;
end;

class function TFluentMotionDriver.GetOrCreate(const AControl: TControl): TFluentMotionDriver;
begin
  Result := FindDriver(AControl);
  if not Assigned(Result) then
    Result := TFluentMotionDriver.CreateForControl(AControl);
end;

function TFluentMotionDriver.GetControl: TControl;
begin
  Result := FHostControl;
end;

procedure TFluentMotionDriver.RecalculateEngineDuration;
var
  Phase: IMotionPhase;
begin
  FTotalEngineDurationMs := 0;
  for Phase in FPhases do
    FTotalEngineDurationMs := FTotalEngineDurationMs + Phase.GetTotalDurationMs;
end;

procedure TFluentMotionDriver.AddPhase(const APhase: IMotionPhase);
var
  I: Integer;
  Eff: IMotionEffect;
  PaintEff: ISkiaPaintEffect;
  ShaderEff: TFluentShaderEffect;
begin
  if Assigned(APhase) then
  begin
    FPhases.Add(APhase);
    RecalculateEngineDuration;

    for I := 0 to APhase.GetEffectsCount - 1 do
    begin
      Eff := APhase.GetEffect(I);
      if Supports(Eff, ISkiaPaintEffect, PaintEff) then
      begin
        RegisterPaintEffect(PaintEff);
        if (Eff is TFluentShaderEffect) then
        begin
          ShaderEff := TFluentShaderEffect(Eff);
          if ShaderEff.DrawMode = TShaderDrawMode.Background then
            SendToBack
          else
            BringToFront;
        end;
      end;
    end;
  end;
end;

procedure TFluentMotionDriver.ClearPhases;
var
  Phase: IMotionPhase;
begin
  Stop;
  if Assigned(FPhases) then
  begin
    for Phase in FPhases do
    begin
      if not Phase.IsFinished then
        Phase.Reset;
    end;
    FPhases.Clear;
  end;
  if Assigned(FPaintEffects) then
    FPaintEffects.Clear;
  FCurrentPhaseIndex := -1;
  FTotalEngineDurationMs := 0;
  FElapsedEngineSec := 0.0;
  FIsPhaseSequenceFinished := False;
end;

procedure TFluentMotionDriver.RegisterPaintEffect(const AEffect: ISkiaPaintEffect);
begin
  if Assigned(AEffect) and Assigned(FPaintEffects) and (not FPaintEffects.Contains(AEffect)) then
    FPaintEffects.Add(AEffect);
end;

procedure TFluentMotionDriver.UnregisterPaintEffect(const AEffect: ISkiaPaintEffect);
begin
  if Assigned(AEffect) and Assigned(FPaintEffects) then
    FPaintEffects.Remove(AEffect);
end;

procedure TFluentMotionDriver.RequestRepaint;
begin
  if FIsDestroying or (not Assigned(FHostControl)) then
    Exit;

  // Single invalidation on host control (automatically paints children including Self)
  FHostControl.Repaint;
end;

function TFluentMotionDriver.IsRunning: Boolean;
begin
  Result := FIsRunning and (not FIsDestroying);
end;

procedure TFluentMotionDriver.Start;
var
  LDriver: IMotionDriver;
  Phase: IMotionPhase;
  LEngine: TFluentMotionEngine;
begin
  if (FPhases.Count = 0) or (not Assigned(FHostControl)) or FIsDestroying then
    Exit;

  FCompletedIterations := 0;
  FIsReversing := False;
  for Phase in FPhases do
    Phase.SetReversed(False);

  FCurrentPhaseIndex := 0;
  FElapsedEngineSec := 0.0;
  FIsRunning := True;
  FIsPhaseSequenceFinished := False;

  FPhases[0].Start;

  LEngine := TFluentMotionEngine.Instance;
  if Assigned(LEngine) and Supports(Self, IMotionDriver, LDriver) then
    LEngine.RegisterDriver(LDriver);

  RequestRepaint;
end;

procedure TFluentMotionDriver.Stop;
var
  LDriver: IMotionDriver;
  LEngine: TFluentMotionEngine;
begin
  FIsRunning := False;
  LEngine := TFluentMotionEngine.Instance;
  if Assigned(LEngine) and Supports(Self, IMotionDriver, LDriver) then
    LEngine.UnregisterDriver(LDriver);
end;

procedure TFluentMotionDriver.Reset;
var
  Phase: IMotionPhase;
begin
  Stop;
  FIsReversing := False;
  FIsPaused := False;
  FCompletedIterations := 0;
  for Phase in FPhases do
  begin
    Phase.SetReversed(False);
    Phase.Reset;
  end;
  FCurrentPhaseIndex := -1;
  FElapsedEngineSec := 0.0;
  RequestRepaint;
end;

function TFluentMotionDriver.HasContinuousEffect: Boolean;
var
  I: Integer;
begin
  Result := False;
  if Assigned(FPaintEffects) then
  begin
    for I := 0 to FPaintEffects.Count - 1 do
    begin
      if Assigned(FPaintEffects[I]) and FPaintEffects[I].NeedsRepaint then
        Exit(True);
    end;
  end;
end;

procedure TFluentMotionDriver.AdvanceToNextPhase(out APendingComplete: TMotionCallback);
var
  Phase: IMotionPhase;
  NextIdx: Integer;
begin
  APendingComplete := nil;

  if FIsReversing then
    NextIdx := FCurrentPhaseIndex - 1
  else
    NextIdx := FCurrentPhaseIndex + 1;

  if (not FIsReversing) and (NextIdx < FPhases.Count) then
  begin
    FCurrentPhaseIndex := NextIdx;
    FPhases[FCurrentPhaseIndex].Start;
  end
  else if FIsReversing and (NextIdx >= 0) then
  begin
    FCurrentPhaseIndex := NextIdx;
    FPhases[FCurrentPhaseIndex].Start;
  end
  else
  begin
    // Completed current direction
    if FAutoreverse and (not FIsReversing) then
    begin
      FIsReversing := True;
      for Phase in FPhases do
      begin
        Phase.SetReversed(True);
        Phase.Restart;
      end;
      FCurrentPhaseIndex := FPhases.Count - 1;
      FPhases[FCurrentPhaseIndex].Start;
      Exit;
    end
    else
    begin
      if FIsReversing then
      begin
        FIsReversing := False;
        for Phase in FPhases do
          Phase.SetReversed(False);
      end;

      Inc(FCompletedIterations);
      if (FRepeatCount = -1) or (FCompletedIterations < FRepeatCount) then
      begin
        for Phase in FPhases do
          Phase.Reset;
        FCurrentPhaseIndex := 0;
        FPhases[0].Start;
        Exit;
      end;

      // Fully finished
      FIsPhaseSequenceFinished := True;
      APendingComplete := FOnComplete;
      FOnComplete := nil;

      if HasContinuousEffect then
      begin
        // Keep driver running to allow ambient shaders (e.g. LiquidWave) to undulate continuously!
        RequestRepaint;
      end
      else
      begin
        Stop;
        RequestRepaint;
      end;
    end;
  end;
end;

procedure TFluentMotionDriver.SetRepeatCount(const ACount: Integer);
begin
  FRepeatCount := ACount;
end;

procedure TFluentMotionDriver.SetAutoreverse(const AEnabled: Boolean);
begin
  FAutoreverse := AEnabled;
end;

procedure TFluentMotionDriver.Pause;
var
  LDriver: IMotionDriver;
  LEngine: TFluentMotionEngine;
begin
  if FIsRunning and (not FIsPaused) then
  begin
    FIsPaused := True;
    LEngine := TFluentMotionEngine.Instance;
    if Assigned(LEngine) and Supports(Self, IMotionDriver, LDriver) then
      LEngine.UnregisterDriver(LDriver);
  end;
end;

procedure TFluentMotionDriver.Resume;
var
  LDriver: IMotionDriver;
  LEngine: TFluentMotionEngine;
begin
  if FIsRunning and FIsPaused then
  begin
    FIsPaused := False;
    LEngine := TFluentMotionEngine.Instance;
    if Assigned(LEngine) and Supports(Self, IMotionDriver, LDriver) then
      LEngine.RegisterDriver(LDriver);
  end;
end;

function TFluentMotionDriver.IsPaused: Boolean;
begin
  Result := FIsPaused;
end;

procedure TFluentMotionDriver.SetSpeed(const ASpeed: Single);
begin
  FSpeed := Max(0.0, ASpeed);
end;

function TFluentMotionDriver.GetSpeed: Single;
begin
  Result := FSpeed;
end;

procedure TFluentMotionDriver.Seek(const AProgress: Single);
var
  Clamped, TargetSec, AccumSec, PhaseStartSec, PhaseEndSec, SubProgress: Single;
  I: Integer;
  Phase: IMotionPhase;
begin
  if FPhases.Count = 0 then
    Exit;

  Clamped := EnsureRange(AProgress, 0.0, 1.0);
  TargetSec := (FTotalEngineDurationMs / 1000.0) * Clamped;
  FElapsedEngineSec := TargetSec;

  AccumSec := 0.0;
  for I := 0 to FPhases.Count - 1 do
  begin
    Phase := FPhases[I];
    PhaseStartSec := AccumSec;
    PhaseEndSec := PhaseStartSec + (Phase.GetTotalDurationMs / 1000.0);

    if TargetSec <= PhaseStartSec then
      Phase.Seek(0.0)
    else if TargetSec >= PhaseEndSec then
      Phase.Seek(1.0)
    else
    begin
      FCurrentPhaseIndex := I;
      if (PhaseEndSec - PhaseStartSec) > 0.001 then
        SubProgress := (TargetSec - PhaseStartSec) / (PhaseEndSec - PhaseStartSec)
      else
        SubProgress := 1.0;
      Phase.Seek(SubProgress);
    end;

    AccumSec := PhaseEndSec;
  end;

  RequestRepaint;
  if Assigned(FOnProgress) then
    FOnProgress(Clamped);
end;

procedure TFluentMotionDriver.Tick(const ADeltaTimeSec: Single);
var
  CurrentPhase: IMotionPhase;
  EffectiveDelta, OverallProgress, TotalSec: Single;
  PendingComplete: TMotionCallback;
begin
  if (not FIsRunning) or FIsPaused or FIsDestroying or (FCurrentPhaseIndex < 0) or (FCurrentPhaseIndex >= FPhases.Count) then
  begin
    if not FIsPaused then
      Stop;
    Exit;
  end;

  PendingComplete := nil;
  FIsExecutingTick := True;
  try
    EffectiveDelta := ADeltaTimeSec * FSpeed;
    if EffectiveDelta <= 0.0 then
      Exit;

    FElapsedEngineSec := FElapsedEngineSec + EffectiveDelta;
    TotalSec := FTotalEngineDurationMs / 1000.0;
    if TotalSec > 0.001 then
    begin
      OverallProgress := FElapsedEngineSec / TotalSec;
      if Assigned(FOnProgress) then
        FOnProgress(OverallProgress);
    end;

    if not FIsPhaseSequenceFinished then
    begin
      CurrentPhase := FPhases[FCurrentPhaseIndex];
      CurrentPhase.Update(EffectiveDelta);

      if CurrentPhase.IsFinished then
        AdvanceToNextPhase(PendingComplete);
    end;

    if not FIsDestroying then
      RequestRepaint;
  finally
    FIsExecutingTick := False;
  end;

  // Fire callback at the end of Tick frame, when internal state and lists are completely settled
  if Assigned(PendingComplete) then
    PendingComplete();
end;

procedure TFluentMotionDriver.Paint;
var
  SkCanvas: ISkCanvas;
  PaintEff: ISkiaPaintEffect;
  R: TRectF;
  I: Integer;
begin
  inherited Paint;

  if FIsDestroying or (FPaintEffects = nil) or (FPaintEffects.Count = 0) or (not Assigned(FHostControl)) then
    Exit;

  R := LocalRect;
  if (R.Width <= 1.0) or (R.Height <= 1.0) then
    Exit;

  // 1. Hardware-Accelerated Skia Canvas
  if (Canvas is TSkCanvasCustom) and (TSkCanvasCustom(Canvas).Canvas <> nil) then
  begin
    SkCanvas := TSkCanvasCustom(Canvas).Canvas;
    for I := 0 to FPaintEffects.Count - 1 do
    begin
      PaintEff := FPaintEffects[I];
      if Assigned(PaintEff) and (PaintEff.NeedsRepaint or (PaintEff is TFluentShaderEffect)) then
        PaintEff.Paint(SkCanvas, R, AbsoluteOpacity);
    end;
    Exit;
  end;

  // 2. Fallback to standard FMX TCanvas
  for I := 0 to FPaintEffects.Count - 1 do
  begin
    PaintEff := FPaintEffects[I];
    if Assigned(PaintEff) and (PaintEff.NeedsRepaint or (PaintEff is TFluentShaderEffect)) then
      PaintEff.PaintFMX(Canvas, R, AbsoluteOpacity);
  end;
end;

end.
