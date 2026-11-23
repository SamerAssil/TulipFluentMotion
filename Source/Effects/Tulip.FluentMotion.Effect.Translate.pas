unit Tulip.FluentMotion.Effect.Translate;

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
  { Translation Mode }
  TTranslateMode = (Relative, AbsolutePos);

  { Translate Effect (Transforms Position.X and Position.Y) }
  TFluentTranslateEffect = class(TFluentMotionEffectBase, ITransformEffect)
  private
    FDeltaX: Single;
    FDeltaY: Single;
    FRawTargetX: Single;
    FRawTargetY: Single;
    FStartAnchorX: Single;
    FStartAnchorY: Single;
    FTargetAnchorX: Single;
    FTargetAnchorY: Single;
    FInitialX: Single;
    FInitialY: Single;
    FMode: TTranslateMode;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor CreateRelative(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal = 250); reintroduce;
    class function MakeAbsolute(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.TopLeft): TFluentTranslateEffect; static;

    { ITransformEffect Implementation }
    procedure CaptureInitialState;
    procedure RestoreInitialState;

    function Clone: IMotionEffect; override;

    property Mode: TTranslateMode read FMode;
    property RawTargetX: Single read FRawTargetX;
    property RawTargetY: Single read FRawTargetY;
    property TargetX: Single read FTargetAnchorX;
    property TargetY: Single read FTargetAnchorY;
  end;

implementation

type
  TControlAccess = class(TControl);

{ TFluentTranslateEffect }

constructor TFluentTranslateEffect.CreateRelative(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FMode := TTranslateMode.Relative;
  FDeltaX := ADeltaX;
  FDeltaY := ADeltaY;
  FRawTargetX := 0;
  FRawTargetY := 0;
  FStartAnchorX := 0;
  FStartAnchorY := 0;
  FTargetAnchorX := 0;
  FTargetAnchorY := 0;
  FAnchor := TMotionAnchor.TopLeft;
  FCustomAnchorPoint := PointF(0.0, 0.0);
end;

class function TFluentTranslateEffect.MakeAbsolute(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor): TFluentTranslateEffect;
begin
  Result := TFluentTranslateEffect.CreateRelative(0, 0, ADurationMs);
  Result.FMode := TTranslateMode.AbsolutePos;
  Result.FRawTargetX := ATargetX;
  Result.FRawTargetY := ATargetY;
  Result.FTargetAnchorX := ATargetX;
  Result.FTargetAnchorY := ATargetY;
  Result.FAnchor := AAnchor;
  Result.FCustomAnchorPoint := AAnchor.ToPointF(PointF(0.0, 0.0));
end;

procedure TFluentTranslateEffect.CaptureInitialState;
begin
  if Assigned(FControl) then
  begin
    FInitialX := FControl.Position.X;
    FInitialY := FControl.Position.Y;
  end;
end;

procedure TFluentTranslateEffect.RestoreInitialState;
begin
  if Assigned(FControl) then
  begin
    FControl.Position.X := FInitialX;
    FControl.Position.Y := FInitialY;
  end;
end;

procedure TFluentTranslateEffect.DoAttach;
begin
  CaptureInitialState;
end;

procedure TFluentTranslateEffect.DoStart;
var
  AnchorPt: TPointF;
begin
  PrepareLayoutOverride;
  if Assigned(FControl) then
  begin
    AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
    FStartAnchorX := FControl.Position.X + (FControl.Width * TControlAccess(FControl).Scale.X * AnchorPt.X);
    FStartAnchorY := FControl.Position.Y + (FControl.Height * TControlAccess(FControl).Scale.Y * AnchorPt.Y);

    if FMode = TTranslateMode.Relative then
    begin
      FTargetAnchorX := FStartAnchorX + FDeltaX;
      FTargetAnchorY := FStartAnchorY + FDeltaY;
    end
    else
    begin
      FTargetAnchorX := FRawTargetX;
      FTargetAnchorY := FRawTargetY;
    end;
  end;
end;

procedure TFluentTranslateEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurAnchorX, CurAnchorY: Single;
  AnchorPt: TPointF;
begin
  if not Assigned(FControl) then
    Exit;

  AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
  CurAnchorX := FStartAnchorX + (FTargetAnchorX - FStartAnchorX) * AProgress;
  CurAnchorY := FStartAnchorY + (FTargetAnchorY - FStartAnchorY) * AProgress;

  FControl.Position.X := CurAnchorX - (FControl.Width * TControlAccess(FControl).Scale.X * AnchorPt.X);
  FControl.Position.Y := CurAnchorY - (FControl.Height * TControlAccess(FControl).Scale.Y * AnchorPt.Y);
end;

procedure TFluentTranslateEffect.DoFinish;
var
  AnchorPt: TPointF;
begin
  if Assigned(FControl) then
  begin
    AnchorPt := FAnchor.ToPointF(FCustomAnchorPoint);
    FControl.Position.X := FTargetAnchorX - (FControl.Width * TControlAccess(FControl).Scale.X * AnchorPt.X);
    FControl.Position.Y := FTargetAnchorY - (FControl.Height * TControlAccess(FControl).Scale.Y * AnchorPt.Y);
    if SameValue(FControl.Position.X, FInitialX, 0.5) and SameValue(FControl.Position.Y, FInitialY, 0.5) then
      RestoreLayoutOverride;
  end;
end;

procedure TFluentTranslateEffect.DoReset;
begin
  RestoreInitialState;
  RestoreLayoutOverride;
end;

function TFluentTranslateEffect.Clone: IMotionEffect;
var
  Res: TFluentTranslateEffect;
begin
  if FMode = TTranslateMode.Relative then
    Res := TFluentTranslateEffect.CreateRelative(FDeltaX, FDeltaY, FDurationMs)
  else
    Res := TFluentTranslateEffect.MakeAbsolute(FRawTargetX, FRawTargetY, FDurationMs, FAnchor);

  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Res.FAnchor := FAnchor;
  Res.FCustomAnchorPoint := FCustomAnchorPoint;
  Result := Res;
end;

end.
