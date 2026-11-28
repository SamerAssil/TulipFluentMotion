{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.Engine
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.Engine;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Diagnostics,
  FMX.Types,
  FMX.Platform,
  Tulip.FluentMotion.Interfaces;

type
  { Central Animation Ticker Singleton (Heartbeat Engine) - Hardened for Mobile }
  TFluentMotionEngine = class
  private
    class var FInstance: TFluentMotionEngine;
    class var FIsTerminated: Boolean;
  private
    FActiveDrivers: TList<IMotionDriver>;
    FTimer: TTimer;
    FStopwatch: TStopwatch;
    FTimeScale: Single;
    FIsRunning: Boolean;
    FIsPausedByAppLifecycle: Boolean;
    function GetActiveCount: Integer;
    procedure OnTimerTick(Sender: TObject);
    procedure CheckTimerState;
    function HandleApplicationEvents(AEvent: TApplicationEvent; AContext: TObject): Boolean;
    procedure SetupLifecycleHooks;
  public
    constructor Create;
    destructor Destroy; override;

    class function Instance: TFluentMotionEngine; static;
    class procedure ReleaseInstance; static;

    procedure RegisterDriver(const ADriver: IMotionDriver);
    procedure UnregisterDriver(const ADriver: IMotionDriver);

    { Headless / Test-driven manual ticking }
    procedure ManualTick(const ADeltaTimeSec: Single);

    procedure PauseAll;
    procedure ResumeAll;

    property TimeScale: Single read FTimeScale write FTimeScale;
    property ActiveCount: Integer read GetActiveCount;
    property IsRunning: Boolean read FIsRunning;
  end;

implementation

{ TFluentMotionEngine }

constructor TFluentMotionEngine.Create;
begin
  inherited Create;
  FActiveDrivers := TList<IMotionDriver>.Create;
  FTimeScale := 1.0;
  FIsRunning := False;
  FIsPausedByAppLifecycle := False;

  FTimer := TTimer.Create(nil);
  FTimer.Interval := 16; // ~60 FPS target
  FTimer.Enabled := False;
  FTimer.OnTimer := OnTimerTick;

  FStopwatch := TStopwatch.Create;
  SetupLifecycleHooks;
end;

destructor TFluentMotionEngine.Destroy;
begin
  if Assigned(FTimer) then
  begin
    FTimer.Enabled := False;
    FreeAndNil(FTimer);
  end;
  FreeAndNil(FActiveDrivers);
  inherited Destroy;
end;

procedure TFluentMotionEngine.SetupLifecycleHooks;
var
  AppEventService: IFMXApplicationEventService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXApplicationEventService, AppEventService) then
    AppEventService.SetApplicationEventHandler(HandleApplicationEvents);
end;

function TFluentMotionEngine.HandleApplicationEvents(AEvent: TApplicationEvent; AContext: TObject): Boolean;
begin
  Result := False;
  case AEvent of
    TApplicationEvent.EnteredBackground,
    TApplicationEvent.WillBecomeInactive:
      begin
        // Suspend ticking on mobile to avoid background battery/GPU violations
        if Assigned(FTimer) and FTimer.Enabled then
        begin
          FTimer.Enabled := False;
          FIsPausedByAppLifecycle := True;
        end;
      end;
    TApplicationEvent.BecameActive,
    TApplicationEvent.WillBecomeForeground:
      begin
        if FIsPausedByAppLifecycle then
        begin
          FIsPausedByAppLifecycle := False;
          FStopwatch.Reset;
          FStopwatch.Start;
          CheckTimerState;
        end;
      end;
  end;
end;

class function TFluentMotionEngine.Instance: TFluentMotionEngine;
begin
  if FIsTerminated then
    Exit(nil);

  if FInstance = nil then
    FInstance := TFluentMotionEngine.Create;
  Result := FInstance;
end;

class procedure TFluentMotionEngine.ReleaseInstance;
begin
  FIsTerminated := True;
  FreeAndNil(FInstance);
end;

procedure TFluentMotionEngine.CheckTimerState;
begin
  if FIsPausedByAppLifecycle or (FTimer = nil) then
    Exit;

  if FActiveDrivers.Count > 0 then
  begin
    if not FTimer.Enabled then
    begin
      FStopwatch.Reset;
      FStopwatch.Start;
      FTimer.Enabled := True;
      FIsRunning := True;
    end;
  end
  else
  begin
    if FTimer.Enabled then
    begin
      FTimer.Enabled := False;
      FStopwatch.Stop;
      FIsRunning := False;
    end;
  end;
end;

function TFluentMotionEngine.GetActiveCount: Integer;
begin
  if Assigned(FActiveDrivers) then
    Result := FActiveDrivers.Count
  else
    Result := 0;
end;

procedure TFluentMotionEngine.RegisterDriver(const ADriver: IMotionDriver);
begin
  if Assigned(ADriver) and Assigned(FActiveDrivers) and (not FActiveDrivers.Contains(ADriver)) then
  begin
    FActiveDrivers.Add(ADriver);
    CheckTimerState;
  end;
end;

procedure TFluentMotionEngine.UnregisterDriver(const ADriver: IMotionDriver);
begin
  if Assigned(ADriver) and Assigned(FActiveDrivers) then
  begin
    FActiveDrivers.Remove(ADriver);
    CheckTimerState;
  end;
end;

procedure TFluentMotionEngine.OnTimerTick(Sender: TObject);
var
  DeltaSec: Double;
begin
  DeltaSec := FStopwatch.Elapsed.TotalSeconds;
  FStopwatch.Reset;
  FStopwatch.Start;

  // Protect against extreme spikes (e.g. background wakeups, debugger breaks)
  if (DeltaSec > 0.1) or (DeltaSec <= 0.0) then
    DeltaSec := 0.016;

  ManualTick(DeltaSec * FTimeScale);
end;

procedure TFluentMotionEngine.ManualTick(const ADeltaTimeSec: Single);
var
  DriversSnapshot: TArray<IMotionDriver>;
  Driver: IMotionDriver;
  I: Integer;
begin
  if (FActiveDrivers = nil) or (FActiveDrivers.Count = 0) then
    Exit;

  // Safe snapshot iteration
  DriversSnapshot := FActiveDrivers.ToArray;
  for I := 0 to High(DriversSnapshot) do
  begin
    Driver := DriversSnapshot[I];
    // Re-verify existence in FActiveDrivers in case a previous driver's tick destroyed peer controls
    if Assigned(Driver) and Assigned(FActiveDrivers) and FActiveDrivers.Contains(Driver) and Driver.IsRunning then
    begin
      try
        Driver.Tick(ADeltaTimeSec);
      except
        // Prevent ticker freeze; isolate failing driver
        on E: Exception do
          UnregisterDriver(Driver);
      end;
    end;
  end;

  CheckTimerState;
end;

procedure TFluentMotionEngine.PauseAll;
begin
  if Assigned(FTimer) then
    FTimer.Enabled := False;
  FIsRunning := False;
end;

procedure TFluentMotionEngine.ResumeAll;
begin
  CheckTimerState;
end;

initialization

finalization
  TFluentMotionEngine.ReleaseInstance;

end.
