unit Tulip.FluentMotion.Effect.Base;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Types,
  FMX.Types,
  FMX.Forms,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces;

type
  { Cracker class to access protected TControl and TCommonCustomForm properties and methods }
  TControlAccess = class(TControl);
  TFormAccess = class(TCommonCustomForm);

  { Base Interfaced Class for all Motion Effects }
  TFluentMotionEffectBase = class(TInterfacedObject, IMotionEffect, IAnchorableEffect)
  protected
    FControl: TControl;
    FDurationMs: Cardinal;
    FDelayMs: Cardinal;
    FEase: TFluentEase;
    FUseSpring: Boolean;
    FSpring: TFluentSpring;
    FElapsedTimeSec: Single;
    FIsFinished: Boolean;
    FIsReversed: Boolean;
    FAnchor: TMotionAnchor;
    FCustomAnchorPoint: TPointF;
    FOriginalAlign: TAlignLayout;
    FHasLayoutOverride: Boolean;

    { Layout Alignment Safety for Dynamic Motion }
    procedure PrepareLayoutOverride;
    procedure RestoreLayoutOverride;

    { Virtual Hooks for Descendants }
    procedure DoAttach; virtual;
    procedure DoDetach; virtual;
    procedure DoStart; virtual;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); virtual; abstract;
    procedure DoFinish; virtual;
    procedure DoReset; virtual;

    { Calculates the effective progress [0.0 .. 1.0] taking Easing or Spring into account }
    function CalculateProgress(const AElapsedSec: Single): Single; virtual;
  public
    constructor Create(const ADurationMs: Cardinal = 250); virtual;

    { IMotionEffect Implementation }
    procedure Attach(const AControl: TControl);
    procedure Detach;
    procedure Start;
    procedure Update(const AProgress: Single; const AElapsedTimeSec: Single);
    procedure Finish;
    procedure Reset;
    function GetDurationMs: Cardinal;
    function GetDelayMs: Cardinal;
    function IsFinished: Boolean;
    function Clone: IMotionEffect; virtual; abstract;

    { Configuration Setters }
    procedure SetReversed(const AReversed: Boolean);
    function SetDuration(const ADurationMs: Cardinal): TFluentMotionEffectBase;
    function SetDelay(const ADelayMs: Cardinal): TFluentMotionEffectBase;
    function SetEase(const AEase: TFluentEase): TFluentMotionEffectBase;
    function SetSpring(const ASpring: TFluentSpring): TFluentMotionEffectBase;

    { IAnchorableEffect Implementation }
    procedure SetAnchor(const AAnchor: TMotionAnchor; const ACustomPoint: TPointF);
    function GetAnchor: TMotionAnchor;
    function GetAnchorPoint: TPointF;
    function SetAnchorConfig(const AAnchor: TMotionAnchor): TFluentMotionEffectBase; overload;
    function SetAnchorConfig(const AAnchor: TMotionAnchor; const ACustomPoint: TPointF): TFluentMotionEffectBase; overload;

    property Control: TControl read FControl;
    property DurationMs: Cardinal read FDurationMs write FDurationMs;
    property DelayMs: Cardinal read FDelayMs write FDelayMs;
    property Ease: TFluentEase read FEase write FEase;
    property UseSpring: Boolean read FUseSpring write FUseSpring;
    property Spring: TFluentSpring read FSpring write FSpring;
    property Anchor: TMotionAnchor read FAnchor write FAnchor;
    property CustomAnchorPoint: TPointF read FCustomAnchorPoint write FCustomAnchorPoint;
  end;

implementation

{ TFluentMotionEffectBase }

constructor TFluentMotionEffectBase.Create(const ADurationMs: Cardinal);
begin
  inherited Create;
  FDurationMs := Max(1, ADurationMs);
  FDelayMs := 0;
  FEase := TFluentEase.OutCubic;
  FUseSpring := False;
  FSpring := TFluentSpring.Smooth;
  FElapsedTimeSec := 0.0;
  FIsFinished := False;
  FIsReversed := False;
  FAnchor := TMotionAnchor.Center;
  FCustomAnchorPoint := PointF(0.5, 0.5);
  FControl := nil;
end;

procedure TFluentMotionEffectBase.Attach(const AControl: TControl);
begin
  FControl := AControl;
  DoAttach;
end;

procedure TFluentMotionEffectBase.Detach;
begin
  DoDetach;
  FControl := nil;
end;

procedure TFluentMotionEffectBase.PrepareLayoutOverride;
begin
  if Assigned(FControl) and (FControl.Align <> TAlignLayout.None) then
  begin
    // Force parent realign so FControl.Position is settled at its true aligned coordinate
    if Assigned(FControl.Parent) then
    begin
      if FControl.Parent is TControl then
        TControlAccess(FControl.Parent).Realign
      else if FControl.Parent is TCommonCustomForm then
        TFormAccess(FControl.Parent).Realign;
    end;

    FOriginalAlign := FControl.Align;
    FHasLayoutOverride := True;

    // Temporarily detach from FMX alignment engine during motion
    FControl.Align := TAlignLayout.None;
  end;
end;

procedure TFluentMotionEffectBase.RestoreLayoutOverride;
begin
  if FHasLayoutOverride and Assigned(FControl) then
  begin
    FControl.Align := FOriginalAlign;
    FHasLayoutOverride := False;
  end;
end;

procedure TFluentMotionEffectBase.DoAttach;
begin
  // Descendants can override
end;

procedure TFluentMotionEffectBase.DoDetach;
begin
  RestoreLayoutOverride;
end;

procedure TFluentMotionEffectBase.DoStart;
begin
  // Descendants can override
end;

procedure TFluentMotionEffectBase.DoFinish;
begin
  // Descendants can override
end;

procedure TFluentMotionEffectBase.DoReset;
begin
  RestoreLayoutOverride;
end;

procedure TFluentMotionEffectBase.Start;
begin
  FElapsedTimeSec := 0.0;
  FIsFinished := False;
  DoStart;
end;

procedure TFluentMotionEffectBase.Finish;
begin
  if not FIsFinished then
  begin
    FIsFinished := True;
    DoUpdate(1.0, FDurationMs / 1000.0);
    DoFinish;
  end;
end;

procedure TFluentMotionEffectBase.Reset;
begin
  FElapsedTimeSec := 0.0;
  FIsFinished := False;
  DoReset;
end;

function TFluentMotionEffectBase.GetDurationMs: Cardinal;
begin
  Result := FDurationMs;
end;

function TFluentMotionEffectBase.GetDelayMs: Cardinal;
begin
  Result := FDelayMs;
end;

function TFluentMotionEffectBase.IsFinished: Boolean;
begin
  Result := FIsFinished;
end;

function TFluentMotionEffectBase.CalculateProgress(const AElapsedSec: Single): Single;
var
  TotalSec, RawProgress: Single;
begin
  TotalSec := Max(0.001, FDurationMs / 1000.0);
  RawProgress := EnsureRange(AElapsedSec / TotalSec, 0.0, 1.0);

  if FIsReversed then
    RawProgress := 1.0 - RawProgress;

  if FUseSpring then
    Result := FSpring.Solve(AElapsedSec)
  else
    Result := TFluentEaseEvaluator.Evaluate(FEase, RawProgress);
end;

procedure TFluentMotionEffectBase.SetReversed(const AReversed: Boolean);
begin
  FIsReversed := AReversed;
end;

procedure TFluentMotionEffectBase.Update(const AProgress: Single; const AElapsedTimeSec: Single);
var
  DelaySec, EffectiveElapsed, Prog: Single;
begin
  if FIsFinished then
    Exit;

  FElapsedTimeSec := AElapsedTimeSec;
  DelaySec := FDelayMs / 1000.0;

  if FElapsedTimeSec < DelaySec then
    Exit; // Still in initial delay period

  EffectiveElapsed := FElapsedTimeSec - DelaySec;
  Prog := CalculateProgress(EffectiveElapsed);

  DoUpdate(Prog, EffectiveElapsed);

  if EffectiveElapsed >= (FDurationMs / 1000.0) then
  begin
    FIsFinished := True;
    DoFinish;
  end;
end;

function TFluentMotionEffectBase.SetDuration(const ADurationMs: Cardinal): TFluentMotionEffectBase;
begin
  FDurationMs := Max(1, ADurationMs);
  Result := Self;
end;

function TFluentMotionEffectBase.SetDelay(const ADelayMs: Cardinal): TFluentMotionEffectBase;
begin
  FDelayMs := ADelayMs;
  Result := Self;
end;

function TFluentMotionEffectBase.SetEase(const AEase: TFluentEase): TFluentMotionEffectBase;
begin
  FEase := AEase;
  FUseSpring := False;
  Result := Self;
end;

function TFluentMotionEffectBase.SetSpring(const ASpring: TFluentSpring): TFluentMotionEffectBase;
begin
  FSpring := ASpring;
  FUseSpring := True;
  Result := Self;
end;

procedure TFluentMotionEffectBase.SetAnchor(const AAnchor: TMotionAnchor; const ACustomPoint: TPointF);
begin
  FAnchor := AAnchor;
  FCustomAnchorPoint := ACustomPoint;
end;

function TFluentMotionEffectBase.GetAnchor: TMotionAnchor;
begin
  Result := FAnchor;
end;

function TFluentMotionEffectBase.GetAnchorPoint: TPointF;
begin
  Result := FAnchor.ToPointF(FCustomAnchorPoint);
end;

function TFluentMotionEffectBase.SetAnchorConfig(const AAnchor: TMotionAnchor): TFluentMotionEffectBase;
begin
  SetAnchor(AAnchor, AAnchor.ToPointF(PointF(0.5, 0.5)));
  Result := Self;
end;

function TFluentMotionEffectBase.SetAnchorConfig(const AAnchor: TMotionAnchor; const ACustomPoint: TPointF): TFluentMotionEffectBase;
begin
  SetAnchor(AAnchor, ACustomPoint);
  Result := Self;
end;

end.
