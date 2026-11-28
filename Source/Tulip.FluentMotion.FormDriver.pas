{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion.FormDriver
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MPL-2.0 (SPDX-License-Identifier: MPL-2.0)
*******************************************************************************}
unit Tulip.FluentMotion.FormDriver;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Types,
  System.UITypes,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  FMX.Forms,
  FMX.Types,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces;

type
  { Form Motion Action Type }
  TFormMotionType = (
    fmtNone,
    fmtShake,
    fmtFade,
    fmtMove,
    fmtResize
  );

  { Companion Component Driver attached to TCommonCustomForm }
  TFluentMotionFormDriver = class(TComponent, IMotionDriver)
  private
    FHostForm: TCommonCustomForm;
    FIsRunning: Boolean;
    FIsPaused: Boolean;
    FElapsedTimeSec: Single;
    FTotalDurationSec: Single;
    FMotionType: TFormMotionType;
    FEase: TFluentEase;
    FSpeed: Single;
    FOnComplete: TMotionCallback;

    { Shake State }
    FShakeIntensity: Single;
    FInitialLeft: Single;

    { Fade State }
    FFromOpacity: Single;
    FTargetOpacity: Single;
    FCurrentOpacity: Single;

    { Move State }
    FFromX: Single;
    FFromY: Single;
    FTargetX: Single;
    FTargetY: Single;

    { Resize State }
    FFromWidth: Single;
    FFromHeight: Single;
    FTargetWidth: Single;
    FTargetHeight: Single;

    { Windows Backdrop Hook State }
    FBackdropActive: Boolean;
    FBackdropIsMica: Boolean;
    FMicaAltTabbed: Boolean;
    FKeepActiveBackdrop: Boolean;
    FTitleBarHidden: Boolean;
    FBackdropTintColor: TAlphaColor;
    FOldWndProc: Pointer;
    FOriginalOnShow: TNotifyEvent;
    FOriginalOnCloseQuery: TCloseQueryEvent;
    FExitAnimation: Boolean;
    FPendingClose: Boolean;
    procedure FormShowHook(Sender: TObject);
    procedure FormCloseQueryHook(Sender: TObject; var CanClose: Boolean);
    procedure HookFormShow;
    procedure HookFormCloseQuery;
    procedure ApplyBackdropInternal;
    procedure UpdateTintLayer;
    {$IFDEF MSWINDOWS}
    procedure InstallWndHook(const AWnd: HWND);
    procedure UninstallWndHook(const AWnd: HWND);
    {$ENDIF}

    function GetRootControl: TControl;
    function CalculateProgress(const AElapsedSec: Single): Single;
    procedure ApplyOpacity(const AValue: Single);
    procedure StopInternal;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateForForm(AForm: TCommonCustomForm); reintroduce;
    destructor Destroy; override;

    class function FindDriver(const AForm: TCommonCustomForm): TFluentMotionFormDriver; static;
    class function GetOrCreate(const AForm: TCommonCustomForm): TFluentMotionFormDriver; static;

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

    { Form Motion Actions }
    procedure Shake(const AIntensity: Single = 12.0; const ADurationMs: Cardinal = 380);
    procedure Fade(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal = 250);
    procedure FadeIn(const ADurationMs: Cardinal = 250);
    procedure FadeOut(const ADurationMs: Cardinal = 250; const AOnComplete: TMotionCallback = nil);
    procedure MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.TopLeft);
    procedure MoveBy(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal = 250);
    procedure ResizeTo(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal = 250);
    procedure SlideIn(const ADirection: TTransitionDirection = TTransitionDirection.FromBottom; const ADurationMs: Cardinal = 300);
    procedure SlideOut(const ADirection: TTransitionDirection = TTransitionDirection.FromBottom; const ADurationMs: Cardinal = 250);
    procedure PopIn(const ADurationMs: Cardinal = 350);
    procedure PopOut(const ADurationMs: Cardinal = 250);

    { Windows Fluent Backdrop / Acrylic Blur Behind }
    procedure ApplyAcrylic(const ATintColor: TAlphaColor = $60202020; const AKeepActive: Boolean = True);
    procedure ApplyMica(const AAltTabbed: Boolean = False; const AKeepActive: Boolean = True);
    procedure DisableBackdrop;
    procedure HideTitleBar;

    property KeepActiveBackdrop: Boolean read FKeepActiveBackdrop write FKeepActiveBackdrop;
    property TitleBarHidden: Boolean read FTitleBarHidden write FTitleBarHidden;
    property HostForm: TCommonCustomForm read FHostForm;
    property CurrentOpacity: Single read FCurrentOpacity;
    property MotionType: TFormMotionType read FMotionType;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Messages,
  Winapi.Dwmapi,
  Winapi.UxTheme,
  FMX.Platform.Win,
  {$ENDIF}
  FMX.Graphics,
  FMX.Objects,
  Tulip.FluentMotion.Engine,
  Tulip.FluentMotion.Helper;

{$IFDEF MSWINDOWS}
type
  TAccentState = (
    ACCENT_DISABLED = 0,
    ACCENT_ENABLE_GRADIENT = 1,
    ACCENT_ENABLE_TRANSPARENTGRADIENT = 2,
    ACCENT_ENABLE_BLURBEHIND = 3,
    ACCENT_ENABLE_ACRYLICBLURBEHIND = 4,
    ACCENT_ENABLE_HOSTBACKDROP = 5,
    ACCENT_INVALID_STATE = 6
  );

  TAccentPolicy = packed record
    AccentState: Integer;
    AccentFlags: Integer;
    GradientColor: Cardinal; // ABGR format
    AnimationId: Integer;
  end;

  TWindowCompositionAttributeData = packed record
    Attribute: Integer;
    Data: Pointer;
    SizeOfData: Integer;
  end;

  TSetWindowCompositionAttribute = function(Wnd: HWND; const AttrData: TWindowCompositionAttributeData): BOOL; stdcall;

const
  WCA_ACCENT_POLICY = 19;
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  DWMWA_BORDER_COLOR = 34;
  DWMWA_COLOR_NONE = -2;
  DWMWA_SYSTEMBACKDROP_TYPE = 38;
  DWMSBT_AUTO = 0;
  DWMSBT_NONE = 1;
  DWMSBT_MAINWINDOW = 2;     // Mica
  DWMSBT_TRANSIENTWINDOW = 3;// Acrylic
  DWMSBT_TABBEDWINDOW = 4;   // Mica Alt

function AlphaColorToABGR(const AColor: TAlphaColor): Cardinal;
var
  A, R, G, B: Byte;
begin
  A := (AColor shr 24) and $FF;
  R := (AColor shr 16) and $FF;
  G := (AColor shr 8) and $FF;
  B := AColor and $FF;
  Result := (Cardinal(A) shl 24) or (Cardinal(B) shl 16) or (Cardinal(G) shl 8) or Cardinal(R);
end;

const
  TULIP_DRIVER_PROP = 'TulipFluentMotion_Driver';

function FluentBackdropWndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  LDriver: TFluentMotionFormDriver;
  LOldProc: Pointer;
begin
  LDriver := TFluentMotionFormDriver(GetProp(hWnd, TULIP_DRIVER_PROP));
  if Assigned(LDriver) then
  begin
    LOldProc := LDriver.FOldWndProc;
    case uMsg of
      WM_NCCALCSIZE:
        begin
          if LDriver.FTitleBarHidden or
            (Assigned(LDriver.FHostForm) and (LDriver.FHostForm.BorderStyle = TFmxFormBorderStyle.None)) then
          begin
            if wParam <> 0 then
            begin
              // Returning 0 when wParam is TRUE tells Windows the client area fills the
              // entire window rectangle, completely eliminating the non-client top frame / caption line.
              Result := 0;
              Exit;
            end;
          end;
        end;
      WM_NCPAINT:
        begin
          if LDriver.FTitleBarHidden or
            (Assigned(LDriver.FHostForm) and (LDriver.FHostForm.BorderStyle = TFmxFormBorderStyle.None)) then
          begin
            // Suppress Windows & FMX drawing the non-client frame or top border line
            Result := 0;
            Exit;
          end;
        end;
      WM_NCACTIVATE:
        begin
          if LDriver.KeepActiveBackdrop and LDriver.FBackdropActive then
          begin
            // Force active state to DWM so Desktop Acrylic / Mica blur does not revert
            // to an opaque/solid fallback color when the window loses focus
            Result := DefWindowProc(hWnd, WM_NCACTIVATE, 1, -1);
            Exit;
          end;
        end;
      WM_DESTROY:
        begin
          LDriver.UninstallWndHook(hWnd);
        end;
    end;

    if Assigned(LOldProc) then
      Result := CallWindowProc(LOldProc, hWnd, uMsg, wParam, lParam)
    else
      Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end
  else
    Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
end;
{$ENDIF}

{ TFluentMotionFormDriver }

constructor TFluentMotionFormDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIsRunning := False;
  FIsPaused := False;
  FElapsedTimeSec := 0.0;
  FTotalDurationSec := 0.25;
  FSpeed := 1.0;
  FMotionType := fmtNone;
  FExitAnimation := False;
  FEase := TFluentEase.OutCubic;
  FCurrentOpacity := 1.0;
  FKeepActiveBackdrop := True;
end;

constructor TFluentMotionFormDriver.CreateForForm(AForm: TCommonCustomForm);
begin
  Create(AForm);
  FHostForm := AForm;
  if Assigned(AForm) then
    AForm.FreeNotification(Self);
end;

destructor TFluentMotionFormDriver.Destroy;
var
  LDriver: IMotionDriver;
  LEngine: TFluentMotionEngine;
  {$IFDEF MSWINDOWS}
  H: HWND;
  {$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if Assigned(FHostForm) and FHostForm.IsHandleAllocated then
  begin
    H := FmxHandleToHWND(FHostForm.Handle);
    if H <> 0 then
      UninstallWndHook(H);
  end;
  {$ENDIF}
  if Assigned(FHostForm) and Assigned(FOriginalOnShow) then
    FHostForm.OnShow := FOriginalOnShow;
  if Assigned(FHostForm) and Assigned(FOriginalOnCloseQuery) then
    FHostForm.OnCloseQuery := FOriginalOnCloseQuery;
  FIsRunning := False;
  LEngine := TFluentMotionEngine.Instance;
  if LEngine <> nil then
  begin
    if Supports(Self, IMotionDriver, LDriver) then
      LEngine.UnregisterDriver(LDriver);
  end;
  inherited Destroy;
end;

{$IFDEF MSWINDOWS}
procedure TFluentMotionFormDriver.InstallWndHook(const AWnd: HWND);
begin
  if (AWnd = 0) or (FOldWndProc <> nil) then
    Exit;

  SetProp(AWnd, TULIP_DRIVER_PROP, THandle(Self));
  FOldWndProc := Pointer(SetWindowLongPtr(AWnd, GWLP_WNDPROC, NativeInt(@FluentBackdropWndProc)));
end;

procedure TFluentMotionFormDriver.UninstallWndHook(const AWnd: HWND);
begin
  if AWnd <> 0 then
  begin
    RemoveProp(AWnd, TULIP_DRIVER_PROP);
    if FOldWndProc <> nil then
    begin
      SetWindowLongPtr(AWnd, GWLP_WNDPROC, NativeInt(FOldWndProc));
      FOldWndProc := nil;
    end;
  end;
end;
{$ENDIF}

procedure TFluentMotionFormDriver.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = TOperation.opRemove) and (AComponent = FHostForm) then
  begin
    FHostForm := nil;
    StopInternal;
  end;
end;

class function TFluentMotionFormDriver.FindDriver(const AForm: TCommonCustomForm): TFluentMotionFormDriver;
var
  I: Integer;
begin
  Result := nil;
  if not Assigned(AForm) then
    Exit;

  for I := 0 to AForm.ComponentCount - 1 do
  begin
    if AForm.Components[I] is TFluentMotionFormDriver then
      Exit(TFluentMotionFormDriver(AForm.Components[I]));
  end;
end;

class function TFluentMotionFormDriver.GetOrCreate(const AForm: TCommonCustomForm): TFluentMotionFormDriver;
begin
  Result := FindDriver(AForm);
  if not Assigned(Result) then
    Result := TFluentMotionFormDriver.CreateForForm(AForm);
end;

function TFluentMotionFormDriver.GetRootControl: TControl;
var
  I: Integer;
begin
  Result := nil;
  if not Assigned(FHostForm) then
    Exit;

  for I := 0 to FHostForm.ChildrenCount - 1 do
  begin
    if FHostForm.Children[I] is TControl then
      Exit(TControl(FHostForm.Children[I]));
  end;
end;

function TFluentMotionFormDriver.CalculateProgress(const AElapsedSec: Single): Single;
var
  NormalizedTime: Single;
begin
  if FTotalDurationSec <= 0.0001 then
    Exit(1.0);

  NormalizedTime := Min(1.0, Max(0.0, AElapsedSec / FTotalDurationSec));

  case FEase of
    TFluentEase.Linear:
      Result := NormalizedTime;
    TFluentEase.InQuad:
      Result := NormalizedTime * NormalizedTime;
    TFluentEase.OutQuad:
      Result := 1.0 - (1.0 - NormalizedTime) * (1.0 - NormalizedTime);
    TFluentEase.InOutQuad:
      if NormalizedTime < 0.5 then
        Result := 2.0 * NormalizedTime * NormalizedTime
      else
        Result := 1.0 - Power(-2.0 * NormalizedTime + 2.0, 2) / 2.0;
    TFluentEase.InCubic:
      Result := NormalizedTime * NormalizedTime * NormalizedTime;
    TFluentEase.OutCubic:
      Result := 1.0 - Power(1.0 - NormalizedTime, 3);
    TFluentEase.InOutCubic:
      if NormalizedTime < 0.5 then
        Result := 4.0 * NormalizedTime * NormalizedTime * NormalizedTime
      else
        Result := 1.0 - Power(-2.0 * NormalizedTime + 2.0, 3) / 2.0;
    TFluentEase.OutBack:
      Result := 1.0 + 2.70158 * Power(NormalizedTime - 1.0, 3) + 1.70158 * Power(NormalizedTime - 1.0, 2);
    TFluentEase.OutBounce:
      begin
        if NormalizedTime < (1 / 2.75) then
          Result := 7.5625 * NormalizedTime * NormalizedTime
        else if NormalizedTime < (2 / 2.75) then
        begin
          NormalizedTime := NormalizedTime - (1.5 / 2.75);
          Result := 7.5625 * NormalizedTime * NormalizedTime + 0.75;
        end
        else if NormalizedTime < (2.5 / 2.75) then
        begin
          NormalizedTime := NormalizedTime - (2.25 / 2.75);
          Result := 7.5625 * NormalizedTime * NormalizedTime + 0.9375;
        end
        else
        begin
          NormalizedTime := NormalizedTime - (2.625 / 2.75);
          Result := 7.5625 * NormalizedTime * NormalizedTime + 0.984375;
        end;
      end;
  else
    Result := 1.0 - Power(1.0 - NormalizedTime, 3);
  end;
end;

procedure TFluentMotionFormDriver.ApplyOpacity(const AValue: Single);
var
  Clamped: Single;
  LRoot: TControl;
  {$IFDEF MSWINDOWS}
  H: HWND;
  ExStyle: NativeInt;
  {$ENDIF}
begin
  Clamped := EnsureRange(AValue, 0.0, 1.0);
  FCurrentOpacity := Clamped;

  {$IFDEF MSWINDOWS}
  if Assigned(FHostForm) and FHostForm.IsHandleAllocated then
  begin
    H := FmxHandleToHWND(FHostForm.Handle);
    if H <> 0 then
    begin
      ExStyle := GetWindowLong(H, GWL_EXSTYLE);
      if (ExStyle and WS_EX_LAYERED) = 0 then
        SetWindowLong(H, GWL_EXSTYLE, ExStyle or WS_EX_LAYERED);
      SetLayeredWindowAttributes(H, 0, Byte(Round(Clamped * 255)), LWA_ALPHA);
    end;
  end;
  {$ENDIF}

  LRoot := GetRootControl;
  if Assigned(LRoot) then
    LRoot.Opacity := Clamped;
end;

function TFluentMotionFormDriver.GetControl: TControl;
begin
  Result := GetRootControl;
end;

procedure TFluentMotionFormDriver.AddPhase(const APhase: IMotionPhase);
begin
  // Form driver operates directly on Form bounds and opacity
end;

procedure TFluentMotionFormDriver.ClearPhases;
begin
  Stop;
end;

procedure TFluentMotionFormDriver.Start;
var
  LDriver: IMotionDriver;
begin
  if not Assigned(FHostForm) or (FMotionType = fmtNone) then
    Exit;

  FIsRunning := True;
  FIsPaused := False;
  FElapsedTimeSec := 0.0;

  if Supports(Self, IMotionDriver, LDriver) then
    TFluentMotionEngine.Instance.RegisterDriver(LDriver);
end;

procedure TFluentMotionFormDriver.StopInternal;
var
  LDriver: IMotionDriver;
begin
  if FIsRunning then
  begin
    FIsRunning := False;
    if Supports(Self, IMotionDriver, LDriver) then
      TFluentMotionEngine.Instance.UnregisterDriver(LDriver);
  end;
  FMotionType := fmtNone;
  FExitAnimation := False;
end;

procedure TFluentMotionFormDriver.Stop;
begin
  StopInternal;
end;

procedure TFluentMotionFormDriver.Reset;
begin
  Stop;
  FElapsedTimeSec := 0.0;
end;

procedure TFluentMotionFormDriver.Pause;
begin
  FIsPaused := True;
end;

procedure TFluentMotionFormDriver.Resume;
begin
  FIsPaused := False;
end;

function TFluentMotionFormDriver.IsRunning: Boolean;
begin
  Result := FIsRunning;
end;

function TFluentMotionFormDriver.IsPaused: Boolean;
begin
  Result := FIsPaused;
end;

procedure TFluentMotionFormDriver.RegisterPaintEffect(const AEffect: ISkiaPaintEffect);
begin
  // Forms do not host ISkiaPaintEffect directly on window border
end;

procedure TFluentMotionFormDriver.UnregisterPaintEffect(const AEffect: ISkiaPaintEffect);
begin
  // Forms do not host ISkiaPaintEffect directly on window border
end;

procedure TFluentMotionFormDriver.RequestRepaint;
begin
  if Assigned(FHostForm) then
    FHostForm.Invalidate;
end;

procedure TFluentMotionFormDriver.SetRepeatCount(const ACount: Integer);
begin
end;

procedure TFluentMotionFormDriver.SetAutoreverse(const AEnabled: Boolean);
begin
end;

procedure TFluentMotionFormDriver.SetSpeed(const ASpeed: Single);
begin
  FSpeed := Max(0.01, ASpeed);
end;

function TFluentMotionFormDriver.GetSpeed: Single;
begin
  Result := FSpeed;
end;

procedure TFluentMotionFormDriver.Seek(const AProgress: Single);
begin
  if FTotalDurationSec > 0.0001 then
  begin
    FElapsedTimeSec := EnsureRange(AProgress, 0.0, 1.0) * FTotalDurationSec;
    Tick(0.0);
  end;
end;

procedure TFluentMotionFormDriver.Tick(const ADeltaTimeSec: Single);
var
  Progress: Single;
  CurrentProgressRaw: Single;
  Offset: Single;
  LCallback: TMotionCallback;
  LShouldClose: Boolean;
  {$IFNDEF MSWINDOWS}
  LRoot: TControl;
  {$ENDIF}
begin
  if (not FIsRunning) or FIsPaused or (not Assigned(FHostForm)) then
    Exit;

  {$IFNDEF MSWINDOWS}
  LRoot := GetRootControl;
  {$ENDIF}
  FElapsedTimeSec := FElapsedTimeSec + ADeltaTimeSec;
  CurrentProgressRaw := Min(1.0, FElapsedTimeSec / Max(0.0001, FTotalDurationSec));
  Progress := CalculateProgress(FElapsedTimeSec);

  case FMotionType of
    fmtShake:
      begin
        // Damped harmonic oscillation
        Offset := FShakeIntensity * Sin(CurrentProgressRaw * PI * 8.0) * (1.0 - CurrentProgressRaw);
        {$IFDEF MSWINDOWS}
        FHostForm.Left := Round(FInitialLeft + Offset);
        {$ELSE}
        if Assigned(LRoot) then
          LRoot.Position.X := Offset;
        {$ENDIF}
      end;

    fmtFade:
      begin
        ApplyOpacity(FFromOpacity + (FTargetOpacity - FFromOpacity) * Progress);
      end;

    fmtMove:
      begin
        {$IFDEF MSWINDOWS}
        FHostForm.Left := Round(FFromX + (FTargetX - FFromX) * Progress);
        FHostForm.Top := Round(FFromY + (FTargetY - FFromY) * Progress);
        {$ELSE}
        if Assigned(LRoot) then
        begin
          LRoot.Position.X := (FTargetX - FFromX) * Progress;
          LRoot.Position.Y := (FTargetY - FFromY) * Progress;
        end;
        {$ENDIF}
      end;

    fmtResize:
      begin
        {$IFDEF MSWINDOWS}
        FHostForm.Width := Round(FFromWidth + (FTargetWidth - FFromWidth) * Progress);
        FHostForm.Height := Round(FFromHeight + (FTargetHeight - FFromHeight) * Progress);
        {$ELSE}
        if Assigned(LRoot) then
        begin
          LRoot.Width := FFromWidth + (FTargetWidth - FFromWidth) * Progress;
          LRoot.Height := FFromHeight + (FTargetHeight - FFromHeight) * Progress;
        end;
        {$ENDIF}
      end;
  end;

  if FElapsedTimeSec >= FTotalDurationSec then
  begin
    // Settle cleanly to final target value
    case FMotionType of
      fmtShake:
        begin
          {$IFDEF MSWINDOWS}
          FHostForm.Left := Round(FInitialLeft);
          {$ELSE}
          if Assigned(LRoot) then
            LRoot.Position.X := 0;
          {$ENDIF}
        end;
      fmtFade:
        begin
          ApplyOpacity(FTargetOpacity);
        end;
      fmtMove:
        begin
          {$IFDEF MSWINDOWS}
          FHostForm.Left := Round(FTargetX);
          FHostForm.Top := Round(FTargetY);
          {$ELSE}
          if Assigned(LRoot) then
          begin
            LRoot.Position.X := FTargetX - FFromX;
            LRoot.Position.Y := FTargetY - FFromY;
          end;
          {$ENDIF}
        end;
      fmtResize:
        begin
          {$IFDEF MSWINDOWS}
          FHostForm.Width := Round(FTargetWidth);
          FHostForm.Height := Round(FTargetHeight);
          {$ELSE}
          if Assigned(LRoot) then
          begin
            LRoot.Width := FTargetWidth;
            LRoot.Height := FTargetHeight;
          end;
          {$ENDIF}
        end;
    end;

    LCallback := FOnComplete;
    FOnComplete := nil;
    LShouldClose := FPendingClose and Assigned(FHostForm);
    FPendingClose := False;
    StopInternal;

    if Assigned(LCallback) then
      LCallback();

    if LShouldClose and Assigned(FHostForm) then
      FHostForm.Close;
  end;
end;

procedure TFluentMotionFormDriver.Shake(const AIntensity: Single; const ADurationMs: Cardinal);
begin
  if not Assigned(FHostForm) then
    Exit;

  {$IFNDEF MSWINDOWS}
  if GetRootControl <> nil then
  begin
    GetRootControl.Shake(AIntensity, ADurationMs);
    Exit;
  end;
  {$ENDIF}

  StopInternal;
  FMotionType := fmtShake;
  FShakeIntensity := Max(1.0, AIntensity);
  FTotalDurationSec := Max(0.05, ADurationMs / 1000.0);
  FInitialLeft := FHostForm.Left;
  FEase := TFluentEase.Linear;
  Start;
end;

procedure TFluentMotionFormDriver.Fade(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  if not Assigned(FHostForm) then
    Exit;

  {$IFNDEF MSWINDOWS}
  if GetRootControl <> nil then
  begin
    GetRootControl.Fade(AFromOpacity, ATargetOpacity, ADurationMs);
    Exit;
  end;
  {$ENDIF}

  StopInternal;
  FMotionType := fmtFade;
  FFromOpacity := EnsureRange(AFromOpacity, 0.0, 1.0);
  FTargetOpacity := EnsureRange(ATargetOpacity, 0.0, 1.0);
  FTotalDurationSec := Max(0.05, ADurationMs / 1000.0);
  FEase := TFluentEase.OutCubic;
  ApplyOpacity(FFromOpacity);
  Start;
end;

procedure TFluentMotionFormDriver.FadeIn(const ADurationMs: Cardinal);
begin
  Fade(FCurrentOpacity, 1.0, ADurationMs);
end;

procedure TFluentMotionFormDriver.FadeOut(const ADurationMs: Cardinal; const AOnComplete: TMotionCallback);
begin
  Fade(FCurrentOpacity, 0.0, ADurationMs);
  FExitAnimation := True;
  FOnComplete := AOnComplete;
  HookFormCloseQuery;
end;

procedure TFluentMotionFormDriver.MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor);
var
  AnchorPt: TPointF;
begin
  if not Assigned(FHostForm) then
    Exit;

  StopInternal;
  FMotionType := fmtMove;
  FFromX := FHostForm.Left;
  FFromY := FHostForm.Top;
  AnchorPt := AAnchor.ToPointF;
  FTargetX := ATargetX - (FHostForm.Width * AnchorPt.X);
  FTargetY := ATargetY - (FHostForm.Height * AnchorPt.Y);
  FTotalDurationSec := Max(0.05, ADurationMs / 1000.0);
  FEase := TFluentEase.OutCubic;
  Start;
end;

procedure TFluentMotionFormDriver.MoveBy(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal);
begin
  if Assigned(FHostForm) then
    MoveTo(FHostForm.Left + ADeltaX, FHostForm.Top + ADeltaY, ADurationMs);
end;

procedure TFluentMotionFormDriver.ResizeTo(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal);
begin
  if not Assigned(FHostForm) then
    Exit;

  StopInternal;
  FMotionType := fmtResize;
  FFromWidth := FHostForm.Width;
  FFromHeight := FHostForm.Height;
  FTargetWidth := Max(10.0, ATargetWidth);
  FTargetHeight := Max(10.0, ATargetHeight);
  FTotalDurationSec := Max(0.05, ADurationMs / 1000.0);
  FEase := TFluentEase.OutCubic;
  Start;
end;

procedure TFluentMotionFormDriver.SlideIn(const ADirection: TTransitionDirection; const ADurationMs: Cardinal);
var
  DestX, DestY: Single;
  StartX, StartY: Single;
begin
  if not Assigned(FHostForm) then
    Exit;

  {$IFNDEF MSWINDOWS}
  if GetRootControl <> nil then
  begin
    GetRootControl.SlideIn(ADirection, ADurationMs);
    Exit;
  end;
  {$ENDIF}

  DestX := FHostForm.Left;
  DestY := FHostForm.Top;
  StartX := DestX;
  StartY := DestY;

  case ADirection of
    TTransitionDirection.FromLeft:
      StartX := DestX - 250.0;
    TTransitionDirection.FromRight:
      StartX := DestX + 250.0;
    TTransitionDirection.FromTop:
      StartY := DestY - 200.0;
    TTransitionDirection.FromBottom:
      StartY := DestY + 200.0;
  else
    StartY := DestY + 200.0;
  end;

  FHostForm.Left := Round(StartX);
  FHostForm.Top := Round(StartY);
  MoveTo(DestX, DestY, ADurationMs);
  FadeIn(ADurationMs);
end;

procedure TFluentMotionFormDriver.SlideOut(const ADirection: TTransitionDirection; const ADurationMs: Cardinal);
var
  TargetX, TargetY: Single;
begin
  if not Assigned(FHostForm) then
    Exit;

  {$IFNDEF MSWINDOWS}
  if GetRootControl <> nil then
  begin
    GetRootControl.SlideOut(ADirection, ADurationMs);
    Exit;
  end;
  {$ENDIF}

  TargetX := FHostForm.Left;
  TargetY := FHostForm.Top;

  case ADirection of
    TTransitionDirection.FromRight:
      TargetX := TargetX - 250.0;
    TTransitionDirection.FromLeft:
      TargetX := TargetX + 250.0;
    TTransitionDirection.FromBottom:
      TargetY := TargetY - 200.0;
    TTransitionDirection.FromTop:
      TargetY := TargetY + 200.0;
  else
    TargetY := TargetY + 200.0;
  end;

  MoveTo(TargetX, TargetY, ADurationMs);
  FadeOut(ADurationMs);
end;

procedure TFluentMotionFormDriver.PopIn(const ADurationMs: Cardinal);
begin
  if not Assigned(FHostForm) then
    Exit;

  {$IFNDEF MSWINDOWS}
  if GetRootControl <> nil then
  begin
    GetRootControl.PopIn(ADurationMs);
    Exit;
  end;
  {$ENDIF}

  FadeIn(ADurationMs);
  Shake(8.0, ADurationMs);
end;

procedure TFluentMotionFormDriver.PopOut(const ADurationMs: Cardinal);
begin
  if not Assigned(FHostForm) then
    Exit;

  {$IFNDEF MSWINDOWS}
  if GetRootControl <> nil then
  begin
    GetRootControl.PopOut(ADurationMs);
    Exit;
  end;
  {$ENDIF}

  FadeOut(ADurationMs);
end;

procedure TFluentMotionFormDriver.HookFormShow;
begin
  if Assigned(FHostForm) and (not Assigned(FOriginalOnShow)) then
  begin
    FOriginalOnShow := FHostForm.OnShow;
    FHostForm.OnShow := FormShowHook;
  end;
end;

procedure TFluentMotionFormDriver.FormShowHook(Sender: TObject);
begin
  ApplyBackdropInternal;
  if Assigned(FOriginalOnShow) then
    FOriginalOnShow(Sender);
end;

procedure TFluentMotionFormDriver.HookFormCloseQuery;
begin
  if Assigned(FHostForm) and (not Assigned(FOriginalOnCloseQuery)) then
  begin
    FOriginalOnCloseQuery := FHostForm.OnCloseQuery;
    FHostForm.OnCloseQuery := FormCloseQueryHook;
  end;
end;

procedure TFluentMotionFormDriver.FormCloseQueryHook(Sender: TObject; var CanClose: Boolean);
begin
  if FIsRunning and FExitAnimation then
  begin
    // Form is currently performing an exit animation (FadeOut, SlideOut, PopOut).
    // Defer the closing until the animation completes.
    CanClose := False;
    FPendingClose := True;
    Exit;
  end;

  CanClose := True;
  if Assigned(FOriginalOnCloseQuery) then
    FOriginalOnCloseQuery(Sender, CanClose);
end;

procedure TFluentMotionFormDriver.ApplyBackdropInternal;
{$IFDEF MSWINDOWS}
var
  H: HWND;
  LStyle: NativeInt;
  LMargins: TMargins;
  LBackdrop, LDark: Integer;
  LBorderColor: Cardinal;
  HLib: HMODULE;
  SetAttr: TSetWindowCompositionAttribute;
  Accent: TAccentPolicy;
  Data: TWindowCompositionAttributeData;
{$ENDIF}
begin
  if (not Assigned(FHostForm)) or (not FBackdropActive) then
    Exit;

  // IMPORTANT: Transparency MUST be False so Windows creates a standard
  // HWND compatible with DWM hardware-accelerated system backdrops
  FHostForm.Transparency := False;

  if FHostForm is TCustomForm then
  begin
    if Assigned(TCustomForm(FHostForm).Fill) then
      TCustomForm(FHostForm).Fill.Kind := TBrushKind.None;
    TCustomForm(FHostForm).StyleLookup := 'none';
  end;

  if not FHostForm.IsHandleAllocated then
    FHostForm.HandleNeeded;

  if FHostForm.BorderStyle = TFmxFormBorderStyle.None then
  begin
    FTitleBarHidden := True;
    if Assigned(FHostForm.Border) then
      FHostForm.Border.Styling := False;
  end;

  {$IFDEF MSWINDOWS}
  H := FmxHandleToHWND(FHostForm.Handle);
  if H <> 0 then
  begin
    // 1. Install window hook FIRST so WM_NCCALCSIZE and WM_NCPAINT are intercepted immediately
    InstallWndHook(H);

    // 2. Windows 11 Immersive Dark Mode & Border Suppression
    LDark := 1;
    DwmSetWindowAttribute(H, DWMWA_USE_IMMERSIVE_DARK_MODE, @LDark, SizeOf(LDark));

    if FTitleBarHidden or (FHostForm.BorderStyle = TFmxFormBorderStyle.None) then
    begin
      LBorderColor := Cardinal(DWMWA_COLOR_NONE);
      DwmSetWindowAttribute(H, DWMWA_BORDER_COLOR, @LBorderColor, SizeOf(LBorderColor));
    end;

    // 3. Ensure WS_THICKFRAME for DWM frame and strip WS_CAPTION if title bar is hidden
    LStyle := GetWindowLong(H, GWL_STYLE);
    if FTitleBarHidden or (FHostForm.BorderStyle = TFmxFormBorderStyle.None) then
    begin
      LStyle := (LStyle or WS_THICKFRAME) and (not WS_CAPTION);
      SetWindowLong(H, GWL_STYLE, LStyle);
      SetWindowPos(H, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
    end
    else if (LStyle and WS_THICKFRAME) = 0 then
    begin
      LStyle := LStyle or WS_THICKFRAME;
      SetWindowLong(H, GWL_STYLE, LStyle);
      SetWindowPos(H, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
    end;

    LMargins.cxLeftWidth := -1;
    LMargins.cxRightWidth := -1;
    LMargins.cyTopHeight := -1;
    LMargins.cyBottomHeight := -1;
    DwmExtendFrameIntoClientArea(H, LMargins);

    if FBackdropIsMica then
    begin
      if FMicaAltTabbed then
        LBackdrop := DWMSBT_TABBEDWINDOW
      else
        LBackdrop := DWMSBT_MAINWINDOW;
      DwmSetWindowAttribute(H, DWMWA_SYSTEMBACKDROP_TYPE, @LBackdrop, SizeOf(LBackdrop));
    end
    else
    begin
      // 1. Windows 11 Official Hardware-accelerated Acrylic Backdrop (Build 22621+)
      LBackdrop := DWMSBT_TRANSIENTWINDOW;
      DwmSetWindowAttribute(H, DWMWA_SYSTEMBACKDROP_TYPE, @LBackdrop, SizeOf(LBackdrop));

      // 2. Windows 10 & 11 SetWindowCompositionAttribute
      HLib := GetModuleHandle('user32.dll');
      if HLib = 0 then
        HLib := LoadLibrary('user32.dll');
      if HLib <> 0 then
      begin
        @SetAttr := GetProcAddress(HLib, 'SetWindowCompositionAttribute');
        if Assigned(SetAttr) then
        begin
          Accent.AccentState := Ord(ACCENT_ENABLE_ACRYLICBLURBEHIND);
          Accent.AccentFlags := 2;
          Accent.GradientColor := AlphaColorToABGR(FBackdropTintColor);
          Accent.AnimationId := 0;

          Data.Attribute := WCA_ACCENT_POLICY;
          Data.Data := @Accent;
          Data.SizeOfData := SizeOf(Accent);
          SetAttr(H, Data);
        end;
      end;
    end;
  end;
  {$ENDIF}

  UpdateTintLayer;
  FHostForm.Invalidate;
end;

procedure TFluentMotionFormDriver.UpdateTintLayer;
var
  LRect: TRectangle;
  I: Integer;
begin
  if not Assigned(FHostForm) then
    Exit;

  LRect := nil;
  for I := 0 to FHostForm.ChildrenCount - 1 do
  begin
    if (FHostForm.Children[I] is TRectangle) and (TRectangle(FHostForm.Children[I]).Name = '__FluentBackdropTint') then
    begin
      LRect := TRectangle(FHostForm.Children[I]);
      Break;
    end;
  end;

  if FBackdropActive and (not FBackdropIsMica) and (FBackdropTintColor <> 0) then
  begin
    if not Assigned(LRect) then
    begin
      LRect := TRectangle.Create(FHostForm);
      LRect.Name := '__FluentBackdropTint';
      LRect.Parent := FHostForm;
      LRect.Align := TAlignLayout.Contents;
      LRect.HitTest := False;
      LRect.Stroke.Kind := TBrushKind.None;
    end;
    LRect.Fill.Kind := TBrushKind.Solid;
    LRect.Fill.Color := FBackdropTintColor;
    LRect.Visible := True;
    LRect.SendToBack;
  end
  else
  begin
    if Assigned(LRect) then
      LRect.Visible := False;
  end;
end;

procedure TFluentMotionFormDriver.ApplyAcrylic(const ATintColor: TAlphaColor; const AKeepActive: Boolean);
begin
  if not Assigned(FHostForm) then
    Exit;
  FBackdropActive := True;
  FBackdropIsMica := False;
  FKeepActiveBackdrop := AKeepActive;
  FBackdropTintColor := ATintColor;
  HookFormShow;
  ApplyBackdropInternal;
end;

procedure TFluentMotionFormDriver.ApplyMica(const AAltTabbed: Boolean; const AKeepActive: Boolean);
begin
  if not Assigned(FHostForm) then
    Exit;
  FBackdropActive := True;
  FBackdropIsMica := True;
  FMicaAltTabbed := AAltTabbed;
  FKeepActiveBackdrop := AKeepActive;
  HookFormShow;
  ApplyBackdropInternal;
end;

procedure TFluentMotionFormDriver.DisableBackdrop;
{$IFDEF MSWINDOWS}
var
  H: HWND;
  LMargins: TMargins;
  LBackdrop: Integer;
  HLib: HMODULE;
  SetAttr: TSetWindowCompositionAttribute;
  Accent: TAccentPolicy;
  Data: TWindowCompositionAttributeData;
{$ENDIF}
begin
  FBackdropActive := False;
  if not Assigned(FHostForm) then
    Exit;

  {$IFDEF MSWINDOWS}
  if FHostForm.IsHandleAllocated then
  begin
    H := FmxHandleToHWND(FHostForm.Handle);
    if H <> 0 then
    begin
      UninstallWndHook(H);
      LBackdrop := DWMSBT_NONE;
      DwmSetWindowAttribute(H, DWMWA_SYSTEMBACKDROP_TYPE, @LBackdrop, SizeOf(LBackdrop));

      HLib := GetModuleHandle('user32.dll');
      if HLib <> 0 then
      begin
        @SetAttr := GetProcAddress(HLib, 'SetWindowCompositionAttribute');
        if Assigned(SetAttr) then
        begin
          Accent.AccentState := Ord(ACCENT_DISABLED);
          Accent.AccentFlags := 0;
          Accent.GradientColor := 0;
          Accent.AnimationId := 0;

          Data.Attribute := WCA_ACCENT_POLICY;
          Data.Data := @Accent;
          Data.SizeOfData := SizeOf(Accent);
          SetAttr(H, Data);
        end;
      end;

      FillChar(LMargins, SizeOf(LMargins), 0);
      DwmExtendFrameIntoClientArea(H, LMargins);
    end;
  end;
  {$ENDIF}

  if FHostForm is TCustomForm then
  begin
    if Assigned(TCustomForm(FHostForm).Fill) then
      TCustomForm(FHostForm).Fill.Kind := TBrushKind.Solid;
    TCustomForm(FHostForm).StyleLookup := '';
  end;

  // Clean up any glass backdrop rectangle created by FormHelper
  for var I := FHostForm.ChildrenCount - 1 downto 0 do
  begin
    if (FHostForm.Children[I] is TRectangle) and
       (TRectangle(FHostForm.Children[I]).Name = '__FluentGlassBackdrop') then
    begin
      var LBackdropRect := TRectangle(FHostForm.Children[I]);
      LBackdropRect.StopMotion;
      LBackdropRect.Parent := nil;
      LBackdropRect.Free;
    end;
  end;

  UpdateTintLayer;
  FHostForm.Invalidate;
end;

procedure TFluentMotionFormDriver.HideTitleBar;
{$IFDEF MSWINDOWS}
var
  H: HWND;
  LStyle: NativeInt;
  LDark: Integer;
  LBorderColor: Cardinal;
begin
  FTitleBarHidden := True;
  if not Assigned(FHostForm) then
    Exit;
  if Assigned(FHostForm.Border) then
    FHostForm.Border.Styling := False;
  if not FHostForm.IsHandleAllocated then
    FHostForm.HandleNeeded;
  H := FmxHandleToHWND(FHostForm.Handle);
  if H <> 0 then
  begin
    InstallWndHook(H);

    LDark := 1;
    DwmSetWindowAttribute(H, DWMWA_USE_IMMERSIVE_DARK_MODE, @LDark, SizeOf(LDark));
    LBorderColor := Cardinal(DWMWA_COLOR_NONE);
    DwmSetWindowAttribute(H, DWMWA_BORDER_COLOR, @LBorderColor, SizeOf(LBorderColor));

    LStyle := GetWindowLong(H, GWL_STYLE);
    LStyle := (LStyle or WS_THICKFRAME) and (not WS_CAPTION);
    SetWindowLong(H, GWL_STYLE, LStyle);
    SetWindowPos(H, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
  end;
end;
{$ELSE}
begin
  FTitleBarHidden := True;
  if Assigned(FHostForm) then
    FHostForm.BorderStyle := TFmxFormBorderStyle.None;
end;
{$ENDIF}

end.
