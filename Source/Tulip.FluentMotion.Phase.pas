unit Tulip.FluentMotion.Phase;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces;

type
  { Implements IMotionPhase: Executes a group of parallel effects concurrently }
  TFluentMotionPhase = class(TInterfacedObject, IMotionPhase)
  private
    FEffects: TList<IMotionEffect>;
    FElapsedTimeSec: Single;
    FIsFinished: Boolean;
    FTotalDurationMs: Cardinal;
    FReversed: Boolean;
    procedure RecalculateTotalDuration;
  public
    constructor Create;
    destructor Destroy; override;

    { IMotionPhase Implementation }
    procedure AddEffect(const AEffect: IMotionEffect);
    procedure Start;
    procedure Update(const ADeltaTimeSec: Single);
    function IsFinished: Boolean;
    procedure Reset;
    procedure Finish;
    function GetTotalDurationMs: Cardinal;
    function GetEffectsCount: Integer;
    function GetEffect(const Index: Integer): IMotionEffect;
    procedure SetReversed(const AReversed: Boolean);
    function IsReversed: Boolean;
    procedure Restart;
    procedure Seek(const AProgress: Single);
  end;

implementation

uses
  System.Generics.Defaults,
  Tulip.FluentMotion.Effect.Base,
  Tulip.FluentMotion.Effect.Translate,
  Tulip.FluentMotion.Effect.Resize,
  Tulip.FluentMotion.Effect.Scale;

{ TFluentMotionPhase }

constructor TFluentMotionPhase.Create;
begin
  inherited Create;
  FEffects := TList<IMotionEffect>.Create;
  FElapsedTimeSec := 0.0;
  FIsFinished := False;
  FTotalDurationMs := 0;
  FReversed := False;
end;

destructor TFluentMotionPhase.Destroy;
begin
  FEffects.Free;
  inherited Destroy;
end;

procedure TFluentMotionPhase.RecalculateTotalDuration;
var
  Effect: IMotionEffect;
  EffDuration: Cardinal;
begin
  FTotalDurationMs := 0;
  for Effect in FEffects do
  begin
    EffDuration := Effect.GetDelayMs + Effect.GetDurationMs;
    if EffDuration > FTotalDurationMs then
      FTotalDurationMs := EffDuration;
  end;
end;

procedure TFluentMotionPhase.AddEffect(const AEffect: IMotionEffect);
begin
  if Assigned(AEffect) then
  begin
    FEffects.Add(AEffect);
    RecalculateTotalDuration;
  end;
end;

procedure TFluentMotionPhase.Start;
var
  Effect: IMotionEffect;
  HasTranslate: Boolean;
begin
  FElapsedTimeSec := 0.0;
  FIsFinished := (FEffects.Count = 0);

  HasTranslate := False;
  for Effect in FEffects do
  begin
    if Effect is TFluentTranslateEffect then
    begin
      HasTranslate := True;
      Break;
    end;
  end;

  for Effect in FEffects do
  begin
    if Effect is TFluentResizeEffect then
      TFluentResizeEffect(Effect).SuppressPositionUpdate := HasTranslate
    else if Effect is TFluentScaleEffect then
      TFluentScaleEffect(Effect).SuppressPositionUpdate := HasTranslate;
  end;

  if HasTranslate and (FEffects.Count > 1) then
  begin
    FEffects.Sort(TComparer<IMotionEffect>.Construct(
      function(const L, R: IMotionEffect): Integer
      begin
        if (L is TFluentTranslateEffect) and not (R is TFluentTranslateEffect) then
          Result := 1
        else if not (L is TFluentTranslateEffect) and (R is TFluentTranslateEffect) then
          Result := -1
        else
          Result := 0;
      end));
  end;

  for Effect in FEffects do
    Effect.Start;
end;

procedure TFluentMotionPhase.Update(const ADeltaTimeSec: Single);
var
  Effect: IMotionEffect;
  AllDone: Boolean;
  TotalSec, RawProgress, EffProgress: Single;
begin
  if FIsFinished then
    Exit;

  FElapsedTimeSec := FElapsedTimeSec + ADeltaTimeSec;
  TotalSec := Max(0.001, FTotalDurationMs / 1000.0);
  RawProgress := EnsureRange(FElapsedTimeSec / TotalSec, 0.0, 1.0);

  if FReversed then
    EffProgress := 1.0 - RawProgress
  else
    EffProgress := RawProgress;

  AllDone := True;
  for Effect in FEffects do
  begin
    Effect.Update(EffProgress, FElapsedTimeSec);
    if not Effect.IsFinished then
      AllDone := False;
  end;

  if AllDone or (FElapsedTimeSec >= TotalSec) then
  begin
    FIsFinished := True;
    for Effect in FEffects do
      if not Effect.IsFinished then
        Effect.Finish;
  end;
end;

procedure TFluentMotionPhase.SetReversed(const AReversed: Boolean);
var
  Eff: IMotionEffect;
begin
  FReversed := AReversed;
  for Eff in FEffects do
  begin
    if Eff is TFluentMotionEffectBase then
      TFluentMotionEffectBase(Eff).SetReversed(AReversed);
  end;
end;

function TFluentMotionPhase.IsReversed: Boolean;
begin
  Result := FReversed;
end;

procedure TFluentMotionPhase.Restart;
begin
  FElapsedTimeSec := 0.0;
  FIsFinished := False;
end;

procedure TFluentMotionPhase.Seek(const AProgress: Single);
var
  Effect: IMotionEffect;
  TotalSec, ClampedProgress, EffProgress: Single;
begin
  ClampedProgress := EnsureRange(AProgress, 0.0, 1.0);
  TotalSec := Max(0.001, FTotalDurationMs / 1000.0);
  FElapsedTimeSec := TotalSec * ClampedProgress;

  if FReversed then
    EffProgress := 1.0 - ClampedProgress
  else
    EffProgress := ClampedProgress;

  for Effect in FEffects do
    Effect.Update(EffProgress, FElapsedTimeSec);

  FIsFinished := (ClampedProgress >= 1.0);
end;

function TFluentMotionPhase.IsFinished: Boolean;
begin
  Result := FIsFinished;
end;

procedure TFluentMotionPhase.Reset;
var
  Effect: IMotionEffect;
begin
  FElapsedTimeSec := 0.0;
  FIsFinished := False;
  for Effect in FEffects do
    Effect.Reset;
end;

procedure TFluentMotionPhase.Finish;
var
  Effect: IMotionEffect;
begin
  FIsFinished := True;
  for Effect in FEffects do
    Effect.Finish;
end;

function TFluentMotionPhase.GetTotalDurationMs: Cardinal;
begin
  Result := FTotalDurationMs;
end;

function TFluentMotionPhase.GetEffectsCount: Integer;
begin
  Result := FEffects.Count;
end;

function TFluentMotionPhase.GetEffect(const Index: Integer): IMotionEffect;
begin
  Result := FEffects[Index];
end;

end.
