unit Tulip.FluentMotion.Effect.Transition;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Types,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Slide Transition Effect (FromLeft, FromRight, FromTop, FromBottom) }
  TFluentSlideEffect = class(TFluentMotionEffectBase, ITransformEffect)
  private
    FDirection: TTransitionDirection;
    FIsSlideIn: Boolean;
    FDistance: Single;
    FInitialPosition: TPointF;
    FInitialOpacity: Single;
    FStartOffset: TPointF;
    FTargetOffset: TPointF;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ADirection: TTransitionDirection; const AIsSlideIn: Boolean; const ADistance: Single = 0; const ADurationMs: Cardinal = 300); reintroduce;

    { ITransformEffect Implementation }
    procedure CaptureInitialState;
    procedure RestoreInitialState;

    function Clone: IMotionEffect; override;

    property Direction: TTransitionDirection read FDirection write FDirection;
    property IsSlideIn: Boolean read FIsSlideIn write FIsSlideIn;
    property Distance: Single read FDistance write FDistance;
  end;

  { Pop Transition Effect (Zoom In / Out with Spring physics and Anchor Point) }
  TFluentPopEffect = class(TFluentMotionEffectBase, ITransformEffect)
  private
    FIsPopIn: Boolean;
    FInitialScale: TPointF;
    FInitialOpacity: Single;
    FInitialPosX: Single;
    FInitialPosY: Single;
    FStartPosX: Single;
    FStartPosY: Single;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const AIsPopIn: Boolean; const ADurationMs: Cardinal = 350); reintroduce;

    { ITransformEffect Implementation }
    procedure CaptureInitialState;
    procedure RestoreInitialState;

    function Clone: IMotionEffect; override;

    property IsPopIn: Boolean read FIsPopIn write FIsPopIn;
  end;

implementation

type
  TControlAccess = class(TControl);

{ TFluentSlideEffect }

constructor TFluentSlideEffect.Create(const ADirection: TTransitionDirection; const AIsSlideIn: Boolean; const ADistance: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FDirection := ADirection;
  FIsSlideIn := AIsSlideIn;
  FDistance := ADistance;
  FEase := TFluentEase.OutCubic;
end;

procedure TFluentSlideEffect.CaptureInitialState;
begin
  if Assigned(FControl) then
  begin
    FInitialPosition := PointF(FControl.Position.X, FControl.Position.Y);
    FInitialOpacity := FControl.Opacity;
  end;
end;

procedure TFluentSlideEffect.RestoreInitialState;
begin
  if Assigned(FControl) then
  begin
    FControl.Position.X := FInitialPosition.X;
    FControl.Position.Y := FInitialPosition.Y;
    FControl.Opacity := FInitialOpacity;
  end;
end;

procedure TFluentSlideEffect.DoAttach;
begin
  CaptureInitialState;
end;

procedure TFluentSlideEffect.DoStart;
var
  EffectiveDist: Single;
begin
  PrepareLayoutOverride;
  CaptureInitialState;
  EffectiveDist := FDistance;
  if EffectiveDist <= 0.001 then
  begin
    if Assigned(FControl) then
    begin
      if FDirection in [TTransitionDirection.FromLeft, TTransitionDirection.FromRight] then
        EffectiveDist := Max(100.0, FControl.Width + 40.0)
      else
        EffectiveDist := Max(100.0, FControl.Height + 40.0);
    end
    else
      EffectiveDist := 200.0;
  end;

  case FDirection of
    TTransitionDirection.FromLeft:
      FStartOffset := PointF(-EffectiveDist, 0);
    TTransitionDirection.FromRight:
      FStartOffset := PointF(EffectiveDist, 0);
    TTransitionDirection.FromTop:
      FStartOffset := PointF(0, -EffectiveDist);
    TTransitionDirection.FromBottom:
      FStartOffset := PointF(0, EffectiveDist);
  end;

  if FIsSlideIn then
  begin
    FTargetOffset := PointF(0, 0);
    if Assigned(FControl) then
    begin
      FControl.Position.X := FInitialPosition.X + FStartOffset.X;
      FControl.Position.Y := FInitialPosition.Y + FStartOffset.Y;
      FControl.Opacity := 0.0;
    end;
  end
  else
  begin
    FTargetOffset := FStartOffset;
    FStartOffset := PointF(0, 0);
  end;
end;

procedure TFluentSlideEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurOffsetX, CurOffsetY, CurOpacity: Single;
begin
  if not Assigned(FControl) then
    Exit;

  CurOffsetX := FStartOffset.X + (FTargetOffset.X - FStartOffset.X) * AProgress;
  CurOffsetY := FStartOffset.Y + (FTargetOffset.Y - FStartOffset.Y) * AProgress;

  if FIsSlideIn then
    CurOpacity := EnsureRange(AProgress * FInitialOpacity, 0.0, 1.0)
  else
    CurOpacity := EnsureRange((1.0 - AProgress) * FInitialOpacity, 0.0, 1.0);

  FControl.Position.X := FInitialPosition.X + CurOffsetX;
  FControl.Position.Y := FInitialPosition.Y + CurOffsetY;
  FControl.Opacity := CurOpacity;
end;

procedure TFluentSlideEffect.DoFinish;
begin
  if Assigned(FControl) then
  begin
    FControl.Position.X := FInitialPosition.X + FTargetOffset.X;
    FControl.Position.Y := FInitialPosition.Y + FTargetOffset.Y;
    if FIsSlideIn then
    begin
      FControl.Opacity := FInitialOpacity;
      RestoreLayoutOverride;
    end
    else
    begin
      FControl.Opacity := 0.0;
      FControl.Visible := False;
      RestoreLayoutOverride;
    end;
  end;
end;

procedure TFluentSlideEffect.DoReset;
begin
  RestoreInitialState;
  RestoreLayoutOverride;
end;

function TFluentSlideEffect.Clone: IMotionEffect;
var
  Res: TFluentSlideEffect;
begin
  Res := TFluentSlideEffect.Create(FDirection, FIsSlideIn, FDistance, FDurationMs);
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

{ TFluentPopEffect }

constructor TFluentPopEffect.Create(const AIsPopIn: Boolean; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FIsPopIn := AIsPopIn;
  if AIsPopIn then
  begin
    FUseSpring := True;
    FSpring := TFluentSpring.Bouncy;
  end
  else
    FEase := TFluentEase.InCubic;
end;

procedure TFluentPopEffect.CaptureInitialState;
begin
  if Assigned(FControl) then
  begin
    FInitialScale := PointF(TControlAccess(FControl).Scale.X, TControlAccess(FControl).Scale.Y);
    FInitialOpacity := FControl.Opacity;
    FInitialPosX := FControl.Position.X;
    FInitialPosY := FControl.Position.Y;
  end;
end;

procedure TFluentPopEffect.RestoreInitialState;
begin
  if Assigned(FControl) then
  begin
    FControl.Position.X := FInitialPosX;
    FControl.Position.Y := FInitialPosY;
    TControlAccess(FControl).Scale.X := FInitialScale.X;
    TControlAccess(FControl).Scale.Y := FInitialScale.Y;
    FControl.Opacity := FInitialOpacity;
  end;
end;

procedure TFluentPopEffect.DoAttach;
begin
  CaptureInitialState;
end;

procedure TFluentPopEffect.DoStart;
begin
  PrepareLayoutOverride;
  CaptureInitialState;
  if Assigned(FControl) then
  begin
    FStartPosX := FControl.Position.X;
    FStartPosY := FControl.Position.Y;
  end;

  if FIsPopIn and Assigned(FControl) then
  begin
    TControlAccess(FControl).Scale.X := 0.0;
    TControlAccess(FControl).Scale.Y := 0.0;
    FControl.Opacity := 0.0;
  end;
end;

procedure TFluentPopEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurScale, CurOpacity: Single;
  AnchorPt: TPointF;
  DeltaW, DeltaH: Single;
begin
  if not Assigned(FControl) then
    Exit;

  if FIsPopIn then
  begin
    CurScale := AProgress;
    CurOpacity := EnsureRange(AProgress * FInitialOpacity, 0.0, 1.0);
  end
  else
  begin
    CurScale := 1.0 - AProgress;
    CurOpacity := EnsureRange((1.0 - AProgress) * FInitialOpacity, 0.0, 1.0);
  end;

  AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
  DeltaW := FControl.Width * ((FInitialScale.X * CurScale) - FInitialScale.X);
  DeltaH := FControl.Height * ((FInitialScale.Y * CurScale) - FInitialScale.Y);

  FControl.Position.X := FStartPosX - (DeltaW * AnchorPt.X);
  FControl.Position.Y := FStartPosY - (DeltaH * AnchorPt.Y);

  TControlAccess(FControl).Scale.X := FInitialScale.X * CurScale;
  TControlAccess(FControl).Scale.Y := FInitialScale.Y * CurScale;
  FControl.Opacity := CurOpacity;
end;

procedure TFluentPopEffect.DoFinish;
begin
  if Assigned(FControl) then
  begin
    if FIsPopIn then
    begin
      TControlAccess(FControl).Scale.X := FInitialScale.X;
      TControlAccess(FControl).Scale.Y := FInitialScale.Y;
      FControl.Position.X := FStartPosX;
      FControl.Position.Y := FStartPosY;
      FControl.Opacity := FInitialOpacity;
      RestoreLayoutOverride;
    end
    else
    begin
      TControlAccess(FControl).Scale.X := 0.0;
      TControlAccess(FControl).Scale.Y := 0.0;
      FControl.Opacity := 0.0;
    end;
  end;
end;

procedure TFluentPopEffect.DoReset;
begin
  RestoreInitialState;
  RestoreLayoutOverride;
end;

function TFluentPopEffect.Clone: IMotionEffect;
var
  Res: TFluentPopEffect;
begin
  Res := TFluentPopEffect.Create(FIsPopIn, FDurationMs);
  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Res.FAnchor := FAnchor;
  Res.FCustomAnchorPoint := FCustomAnchorPoint;
  Result := Res;
end;

end.
