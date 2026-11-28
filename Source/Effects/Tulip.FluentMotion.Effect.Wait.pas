{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Effect.Wait
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Effect.Wait;

interface

uses
  System.SysUtils,
  System.Classes,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Wait Effect (Idle pause during sequential chains) }
  TFluentWaitEffect = class(TFluentMotionEffectBase)
  protected
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
  public
    constructor Create(const ADurationMs: Cardinal); override;
    function Clone: IMotionEffect; override;
  end;

  { Action Effect (Inline callback executed between sequential phases) }
  TFluentActionEffect = class(TFluentMotionEffectBase)
  private
    FCallback: TMotionCallback;
    FExecuted: Boolean;
  protected
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
  public
    constructor Create(const ACallback: TMotionCallback); reintroduce;
    function Clone: IMotionEffect; override;
  end;

implementation

{ TFluentWaitEffect }

constructor TFluentWaitEffect.Create(const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FEase := TFluentEase.Linear;
end;

procedure TFluentWaitEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  // Pure time passage, no visual modifications
end;

function TFluentWaitEffect.Clone: IMotionEffect;
var
  Res: TFluentWaitEffect;
begin
  Res := TFluentWaitEffect.Create(FDurationMs);
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

{ TFluentActionEffect }

constructor TFluentActionEffect.Create(const ACallback: TMotionCallback);
begin
  inherited Create(1);
  FCallback := ACallback;
  FExecuted := False;
  FEase := TFluentEase.Linear;
end;

procedure TFluentActionEffect.DoStart;
begin
  FExecuted := False;
end;

procedure TFluentActionEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
begin
  if not FExecuted then
  begin
    FExecuted := True;
    if Assigned(FCallback) then
      FCallback();
  end;
end;

function TFluentActionEffect.Clone: IMotionEffect;
var
  Res: TFluentActionEffect;
begin
  Res := TFluentActionEffect.Create(FCallback);
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

end.
