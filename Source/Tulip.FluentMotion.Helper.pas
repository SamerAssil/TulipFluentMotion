unit Tulip.FluentMotion.Helper;

interface

uses
  System.SysUtils,
  System.UITypes,
  FMX.Forms,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Builder;

type
  { Class Helper for TControl: Provides .Motion property and SwiftUI one-liners }
  TFluentMotionControlHelper = class helper for TControl
  public
    { Primary Fluent Builder Entry Point }
    function Motion: IMotionBuilder;
    procedure StopMotion;
    procedure ResetMotion;

    { Instant Micro-interaction Helpers }
    procedure Shake(const AIntensity: Single = 8.0; const ADurationMs: Cardinal = 350);
    procedure Pulse(const AScalePeak: Single = 1.12; const ADurationMs: Cardinal = 280);
    procedure Bounce(const AHeight: Single = 16.0; const ADurationMs: Cardinal = 320);
    procedure Fade(const ATargetOpacity: Single; const ADurationMs: Cardinal = 200); overload;
    procedure Fade(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal = 200); overload;
    procedure FadeIn(const ADurationMs: Cardinal = 200);
    procedure FadeOut(const ADurationMs: Cardinal = 200);
    procedure Blur(const ATargetSoftness: Single = 4.0; const ADurationMs: Cardinal = 250);
    procedure Unblur(const ADurationMs: Cardinal = 250);
    procedure Shimmer(const ADurationMs: Cardinal = 1000; const ADirection: TShimmerDirection = TShimmerDirection.LeftToRight; const AAngleDeg: Single = 20.0); overload;
    procedure Shimmer(const ADirection: TShimmerDirection; const ADurationMs: Cardinal = 1000; const AAngleDeg: Single = 20.0); overload;
    procedure Ripple(const ADurationMs: Cardinal = 450);

    { SwiftUI-Parity One-Liners }
    procedure Flip3D(const ATargetAngleDeg: Single = 180.0; const AAxis: TFlipAxis = TFlipAxis.Horizontal; const ADurationMs: Cardinal = 350);
    procedure FlipHorizontal(const ATargetAngleDeg: Single = 180.0; const ADurationMs: Cardinal = 350);
    procedure FlipVertical(const ATargetAngleDeg: Single = 180.0; const ADurationMs: Cardinal = 350);
    procedure ColorTo(const ATargetColor: TAlphaColor; const ADurationMs: Cardinal = 250);
    procedure Tint(const ATintColor: TAlphaColor; const ADurationMs: Cardinal = 250);
    procedure Grayscale(const ATargetAmount: Single = 1.0; const ADurationMs: Cardinal = 250);
    procedure GrayscaleIn(const ADurationMs: Cardinal = 250);
    procedure GrayscaleOut(const ADurationMs: Cardinal = 250);
    procedure Shadow(const ADistance: Single = 6.0; const ASoftness: Single = 0.35; const AOpacity: Single = 0.45; const ADurationMs: Cardinal = 250);
    procedure Elevation(const AElevationLevel: Single; const ADurationMs: Cardinal = 250);

    { Transitions & Advanced One-Liners }
    procedure SlideIn(const ADirection: TTransitionDirection = TTransitionDirection.FromLeft; const ADurationMs: Cardinal = 300);
    procedure SlideOut(const ADirection: TTransitionDirection = TTransitionDirection.FromRight; const ADurationMs: Cardinal = 300);
    procedure PopIn(const ADurationMs: Cardinal = 350);
    procedure PopOut(const ADurationMs: Cardinal = 250);
    procedure Glow(const AColor: TAlphaColor = $8000A0FF; const AOpacity: Single = 0.8; const ADurationMs: Cardinal = 250);
    procedure Unglow(const ADurationMs: Cardinal = 250);
    procedure HueRotation(const ATargetAngleDeg: Single = 360.0; const ADurationMs: Cardinal = 500);
    procedure Wiggle(const AIntensityDeg: Single = 2.5; const ADurationMs: Cardinal = 350);
    procedure MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.TopLeft); overload;
    procedure MoveTo(const ATargetX, ATargetY: Single; const AAnchor: TMotionAnchor); overload;
    procedure Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal = 250); overload;
    procedure Move(const ADeltaX, ADeltaY: Single; const AAnchor: TMotionAnchor); overload;
    procedure Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor); overload;
    procedure ResizeTo(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal = 250; const AAnchor: TResizeAnchor = TResizeAnchor.Center);
    procedure ResizeWidth(const ATargetWidth: Single; const ADurationMs: Cardinal = 250; const AAnchor: TResizeAnchor = TResizeAnchor.Center);
    procedure ResizeHeight(const ATargetHeight: Single; const ADurationMs: Cardinal = 250; const AAnchor: TResizeAnchor = TResizeAnchor.Center);
    procedure CountTo(const ATargetValue: Double; const AFormatStr: string = '%0.2f'; const ADurationMs: Cardinal = 1500);
    procedure Typewriter(const ATargetText: string; const ACharDelayMs: Cardinal = 40; const ABlinkingCursor: Boolean = True; const ACursorChar: Char = '|');
    procedure ShimmerText(const ADurationMs: Cardinal = 1000; const ADirection: TShimmerDirection = TShimmerDirection.LeftToRight; const AAngleDeg: Single = 20.0); overload;
    procedure ShimmerText(const ADirection: TShimmerDirection; const ADurationMs: Cardinal = 1000; const AAngleDeg: Single = 20.0); overload;
    procedure ShimmerText(const AHighlightColor: TAlphaColor; const ADurationMs: Cardinal; const ADirection: TShimmerDirection = TShimmerDirection.LeftToRight; const AAngleDeg: Single = 20.0); overload;
    procedure LiquidGlass(const AStyle: TFluentGlassStyle = TFluentGlassStyle.Frosted; const ADurationMs: Cardinal = 2000); overload;
    procedure LiquidGlass(const ARefrMagnitude: Single; const AAberration: Single = 0.08; const ABlurRadius: Single = 0.8; const AGlowIntensity: Single = 0.40; const ADurationMs: Cardinal = 2000); overload;
    procedure FrostedGlass(const ATintColor: TAlphaColor = $40FFFFFF; const ABorderLight: Single = 0.8; const ADurationMs: Cardinal = 500);
  end;

  { Class Helper for TCommonCustomForm: Direct OS Window / Form animations }
  TFluentMotionFormHelper = class helper for TCommonCustomForm
  public
    procedure Shake(const AIntensity: Single = 12.0; const ADurationMs: Cardinal = 380);
    procedure Fade(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal = 250); overload;
    procedure Fade(const ATargetOpacity: Single; const ADurationMs: Cardinal = 250); overload;
    procedure FadeIn(const ADurationMs: Cardinal = 250);
    procedure FadeOut(const ADurationMs: Cardinal = 250; const AOnComplete: TMotionCallback = nil);
    procedure MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal = 250; const AAnchor: TMotionAnchor = TMotionAnchor.TopLeft); overload;
    procedure MoveTo(const ATargetX, ATargetY: Single; const AAnchor: TMotionAnchor); overload;
    procedure MoveBy(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal = 250);
    procedure ResizeTo(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal = 250);
    procedure SlideIn(const ADirection: TTransitionDirection = TTransitionDirection.FromBottom; const ADurationMs: Cardinal = 300);
    procedure SlideOut(const ADirection: TTransitionDirection = TTransitionDirection.FromBottom; const ADurationMs: Cardinal = 250);
    procedure PopIn(const ADurationMs: Cardinal = 350);
    procedure PopOut(const ADurationMs: Cardinal = 250);
    procedure Acrylic(const ATintColor: TAlphaColor = $60202020; const AKeepActive: Boolean = True);
    procedure Mica(const AAltTabbed: Boolean = False; const AKeepActive: Boolean = True);
    procedure DisableBackdrop;
    procedure HideTitleBar;
    procedure LiquidGlass(const AStyle: TFluentGlassStyle = TFluentGlassStyle.Frosted; const ADurationMs: Cardinal = 2000); overload;
    procedure LiquidGlass(const ARefrMagnitude: Single; const AAberration: Single = 0.08; const ABlurRadius: Single = 0.8; const AGlowIntensity: Single = 0.40; const ADurationMs: Cardinal = 2000); overload;
    procedure FrostedGlass(const ATintColor: TAlphaColor = $40FFFFFF; const ABorderLight: Single = 0.8; const ADurationMs: Cardinal = 500);
  end;

implementation

uses
  FMX.Types,
  FMX.Graphics,
  FMX.Objects,
  Tulip.FluentMotion.FormDriver;

{ TFluentMotionControlHelper }

function TFluentMotionControlHelper.Motion: IMotionBuilder;
begin
  Result := TFluentMotionBuilder.Create(Self);
end;

procedure TFluentMotionControlHelper.StopMotion;
begin
  Motion.Stop;
end;

procedure TFluentMotionControlHelper.ResetMotion;
begin
  Motion.Reset;
end;

procedure TFluentMotionControlHelper.Shake(const AIntensity: Single; const ADurationMs: Cardinal);
begin
  Motion.Shake(AIntensity, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Pulse(const AScalePeak: Single; const ADurationMs: Cardinal);
begin
  Motion.Pulse(AScalePeak, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Bounce(const AHeight: Single; const ADurationMs: Cardinal);
begin
  Motion.Bounce(AHeight, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Fade(const ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  Motion.Fade(ATargetOpacity, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Fade(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  Motion.Fade(AFromOpacity, ATargetOpacity, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.FadeIn(const ADurationMs: Cardinal);
begin
  Motion.FadeIn(ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.FadeOut(const ADurationMs: Cardinal);
begin
  Motion.FadeOut(ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Blur(const ATargetSoftness: Single; const ADurationMs: Cardinal);
begin
  Motion.Blur(ATargetSoftness, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Unblur(const ADurationMs: Cardinal);
begin
  Motion.BlurOut(ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Shimmer(const ADurationMs: Cardinal; const ADirection: TShimmerDirection; const AAngleDeg: Single);
begin
  Motion.Shimmer(ADurationMs, ADirection, AAngleDeg).Start;
end;

procedure TFluentMotionControlHelper.Shimmer(const ADirection: TShimmerDirection; const ADurationMs: Cardinal; const AAngleDeg: Single);
begin
  Motion.Shimmer(ADurationMs, ADirection, AAngleDeg).Start;
end;

procedure TFluentMotionControlHelper.Ripple(const ADurationMs: Cardinal);
begin
  Motion.Ripple(ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Flip3D(const ATargetAngleDeg: Single; const AAxis: TFlipAxis; const ADurationMs: Cardinal);
begin
  Motion.Flip3D(ATargetAngleDeg, AAxis, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.FlipHorizontal(const ATargetAngleDeg: Single; const ADurationMs: Cardinal);
begin
  Motion.FlipHorizontal(ATargetAngleDeg, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.FlipVertical(const ATargetAngleDeg: Single; const ADurationMs: Cardinal);
begin
  Motion.FlipVertical(ATargetAngleDeg, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.ColorTo(const ATargetColor: TAlphaColor; const ADurationMs: Cardinal);
begin
  Motion.ColorTo(ATargetColor, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Tint(const ATintColor: TAlphaColor; const ADurationMs: Cardinal);
begin
  Motion.Tint(ATintColor, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Grayscale(const ATargetAmount: Single; const ADurationMs: Cardinal);
begin
  Motion.Grayscale(ATargetAmount, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.GrayscaleIn(const ADurationMs: Cardinal);
begin
  Motion.GrayscaleIn(ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.GrayscaleOut(const ADurationMs: Cardinal);
begin
  Motion.GrayscaleOut(ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Shadow(const ADistance, ASoftness, AOpacity: Single; const ADurationMs: Cardinal);
begin
  Motion.Shadow(ADistance, ASoftness, AOpacity, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Elevation(const AElevationLevel: Single; const ADurationMs: Cardinal);
begin
  Motion.Elevation(AElevationLevel, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.SlideIn(const ADirection: TTransitionDirection; const ADurationMs: Cardinal);
begin
  Motion.SlideIn(ADirection, 0, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.SlideOut(const ADirection: TTransitionDirection; const ADurationMs: Cardinal);
begin
  Motion.SlideOut(ADirection, 0, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.PopIn(const ADurationMs: Cardinal);
begin
  Motion.PopIn(ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.PopOut(const ADurationMs: Cardinal);
begin
  Motion.PopOut(ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Glow(const AColor: TAlphaColor; const AOpacity: Single; const ADurationMs: Cardinal);
begin
  Motion.Glow(AColor, 0.5, AOpacity, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Unglow(const ADurationMs: Cardinal);
begin
  Motion.Glow(0.0, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.HueRotation(const ATargetAngleDeg: Single; const ADurationMs: Cardinal);
begin
  Motion.HueRotation(ATargetAngleDeg, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Wiggle(const AIntensityDeg: Single; const ADurationMs: Cardinal);
begin
  Motion.Wiggle(AIntensityDeg, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor);
begin
  Motion.MoveTo(ATargetX, ATargetY, ADurationMs, AAnchor).Start;
end;

procedure TFluentMotionControlHelper.MoveTo(const ATargetX, ATargetY: Single; const AAnchor: TMotionAnchor);
begin
  Motion.MoveTo(ATargetX, ATargetY, 250, AAnchor).Start;
end;

procedure TFluentMotionControlHelper.Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal);
begin
  Motion.Move(ADeltaX, ADeltaY, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Move(const ADeltaX, ADeltaY: Single; const AAnchor: TMotionAnchor);
begin
  Motion.Move(ADeltaX, ADeltaY, 250, AAnchor).Start;
end;

procedure TFluentMotionControlHelper.Move(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor);
begin
  Motion.Move(ADeltaX, ADeltaY, ADurationMs, AAnchor).Start;
end;

procedure TFluentMotionControlHelper.ResizeTo(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal; const AAnchor: TResizeAnchor);
begin
  Motion.ResizeTo(ATargetWidth, ATargetHeight, ADurationMs, AAnchor).Start;
end;

procedure TFluentMotionControlHelper.ResizeWidth(const ATargetWidth: Single; const ADurationMs: Cardinal; const AAnchor: TResizeAnchor);
begin
  Motion.ResizeWidth(ATargetWidth, ADurationMs, AAnchor).Start;
end;

procedure TFluentMotionControlHelper.ResizeHeight(const ATargetHeight: Single; const ADurationMs: Cardinal; const AAnchor: TResizeAnchor);
begin
  Motion.ResizeHeight(ATargetHeight, ADurationMs, AAnchor).Start;
end;

procedure TFluentMotionControlHelper.CountTo(const ATargetValue: Double; const AFormatStr: string; const ADurationMs: Cardinal);
begin
  Motion.CountTo(ATargetValue, AFormatStr, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.Typewriter(const ATargetText: string; const ACharDelayMs: Cardinal; const ABlinkingCursor: Boolean; const ACursorChar: Char);
begin
  Motion.Typewriter(ATargetText, ACharDelayMs, ABlinkingCursor, ACursorChar).Start;
end;

procedure TFluentMotionControlHelper.ShimmerText(const ADurationMs: Cardinal; const ADirection: TShimmerDirection; const AAngleDeg: Single);
begin
  Motion.ShimmerText(ADurationMs, ADirection, AAngleDeg).Start;
end;

procedure TFluentMotionControlHelper.ShimmerText(const ADirection: TShimmerDirection; const ADurationMs: Cardinal; const AAngleDeg: Single);
begin
  Motion.ShimmerText(ADirection, ADurationMs, AAngleDeg).Start;
end;

procedure TFluentMotionControlHelper.ShimmerText(const AHighlightColor: TAlphaColor; const ADurationMs: Cardinal; const ADirection: TShimmerDirection; const AAngleDeg: Single);
begin
  Motion.ShimmerText(AHighlightColor, ADurationMs, ADirection, AAngleDeg).Start;
end;

procedure TFluentMotionControlHelper.LiquidGlass(const AStyle: TFluentGlassStyle; const ADurationMs: Cardinal);
begin
  Motion.LiquidGlass(AStyle, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.LiquidGlass(const ARefrMagnitude: Single; const AAberration: Single; const ABlurRadius: Single; const AGlowIntensity: Single; const ADurationMs: Cardinal);
begin
  Motion.LiquidGlass(ARefrMagnitude, AAberration, ABlurRadius, AGlowIntensity, ADurationMs).Start;
end;

procedure TFluentMotionControlHelper.FrostedGlass(const ATintColor: TAlphaColor; const ABorderLight: Single; const ADurationMs: Cardinal);
begin
  Motion.FrostedGlass(ATintColor, ABorderLight, ADurationMs).Start;
end;

{ TFluentMotionFormHelper }

procedure TFluentMotionFormHelper.Shake(const AIntensity: Single; const ADurationMs: Cardinal);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).Shake(AIntensity, ADurationMs);
end;

procedure TFluentMotionFormHelper.Fade(const AFromOpacity, ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).Fade(AFromOpacity, ATargetOpacity, ADurationMs);
end;

procedure TFluentMotionFormHelper.Fade(const ATargetOpacity: Single; const ADurationMs: Cardinal);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).Fade(TFluentMotionFormDriver.GetOrCreate(Self).CurrentOpacity, ATargetOpacity, ADurationMs);
end;

procedure TFluentMotionFormHelper.FadeIn(const ADurationMs: Cardinal);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).FadeIn(ADurationMs);
end;

procedure TFluentMotionFormHelper.FadeOut(const ADurationMs: Cardinal; const AOnComplete: TMotionCallback);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).FadeOut(ADurationMs, AOnComplete);
end;

procedure TFluentMotionFormHelper.MoveTo(const ATargetX, ATargetY: Single; const ADurationMs: Cardinal; const AAnchor: TMotionAnchor);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).MoveTo(ATargetX, ATargetY, ADurationMs, AAnchor);
end;

procedure TFluentMotionFormHelper.MoveTo(const ATargetX, ATargetY: Single; const AAnchor: TMotionAnchor);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).MoveTo(ATargetX, ATargetY, 250, AAnchor);
end;

procedure TFluentMotionFormHelper.MoveBy(const ADeltaX, ADeltaY: Single; const ADurationMs: Cardinal);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).MoveBy(ADeltaX, ADeltaY, ADurationMs);
end;

procedure TFluentMotionFormHelper.ResizeTo(const ATargetWidth, ATargetHeight: Single; const ADurationMs: Cardinal);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).ResizeTo(ATargetWidth, ATargetHeight, ADurationMs);
end;

procedure TFluentMotionFormHelper.SlideIn(const ADirection: TTransitionDirection; const ADurationMs: Cardinal);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).SlideIn(ADirection, ADurationMs);
end;

procedure TFluentMotionFormHelper.SlideOut(const ADirection: TTransitionDirection; const ADurationMs: Cardinal);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).SlideOut(ADirection, ADurationMs);
end;

procedure TFluentMotionFormHelper.PopIn(const ADurationMs: Cardinal);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).PopIn(ADurationMs);
end;

procedure TFluentMotionFormHelper.PopOut(const ADurationMs: Cardinal);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).PopOut(ADurationMs);
end;

procedure TFluentMotionFormHelper.Acrylic(const ATintColor: TAlphaColor; const AKeepActive: Boolean);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).ApplyAcrylic(ATintColor, AKeepActive);
end;

procedure TFluentMotionFormHelper.Mica(const AAltTabbed: Boolean; const AKeepActive: Boolean);
begin
  TFluentMotionFormDriver.GetOrCreate(Self).ApplyMica(AAltTabbed, AKeepActive);
end;

procedure TFluentMotionFormHelper.DisableBackdrop;
begin
  TFluentMotionFormDriver.GetOrCreate(Self).DisableBackdrop;
end;

procedure TFluentMotionFormHelper.HideTitleBar;
begin
  TFluentMotionFormDriver.GetOrCreate(Self).HideTitleBar;
end;

procedure TFluentMotionFormHelper.LiquidGlass(const AStyle: TFluentGlassStyle; const ADurationMs: Cardinal);
var
  LRect: TRectangle;
  I: Integer;
begin
  Acrylic($30202020);

  LRect := nil;
  for I := 0 to ChildrenCount - 1 do
  begin
    if (Children[I] is TRectangle) and (TRectangle(Children[I]).Name = '__FluentGlassBackdrop') then
    begin
      LRect := TRectangle(Children[I]);
      Break;
    end;
  end;

  if not Assigned(LRect) then
  begin
    LRect := TRectangle.Create(Self);
    LRect.Name := '__FluentGlassBackdrop';
    LRect.Parent := Self;
    LRect.Align := TAlignLayout.Contents;
    LRect.HitTest := False;
    LRect.Stroke.Kind := TBrushKind.None;
    LRect.Fill.Color := $10FFFFFF;
    LRect.SendToBack;
  end;

  LRect.Motion.LiquidGlass(AStyle, ADurationMs).Start;
end;

procedure TFluentMotionFormHelper.LiquidGlass(const ARefrMagnitude, AAberration, ABlurRadius, AGlowIntensity: Single; const ADurationMs: Cardinal);
var
  LRect: TRectangle;
  I: Integer;
begin
  Acrylic($30202020);

  LRect := nil;
  for I := 0 to ChildrenCount - 1 do
  begin
    if (Children[I] is TRectangle) and (TRectangle(Children[I]).Name = '__FluentGlassBackdrop') then
    begin
      LRect := TRectangle(Children[I]);
      Break;
    end;
  end;

  if not Assigned(LRect) then
  begin
    LRect := TRectangle.Create(Self);
    LRect.Name := '__FluentGlassBackdrop';
    LRect.Parent := Self;
    LRect.Align := TAlignLayout.Contents;
    LRect.HitTest := False;
    LRect.Stroke.Kind := TBrushKind.None;
    LRect.Fill.Color := $10FFFFFF;
    LRect.SendToBack;
  end;

  LRect.Motion.LiquidGlass(ARefrMagnitude, AAberration, ABlurRadius, AGlowIntensity, ADurationMs).Start;
end;

procedure TFluentMotionFormHelper.FrostedGlass(const ATintColor: TAlphaColor; const ABorderLight: Single; const ADurationMs: Cardinal);
var
  LRect: TRectangle;
  I: Integer;
begin
  Acrylic(ATintColor);

  LRect := nil;
  for I := 0 to ChildrenCount - 1 do
  begin
    if (Children[I] is TRectangle) and (TRectangle(Children[I]).Name = '__FluentGlassBackdrop') then
    begin
      LRect := TRectangle(Children[I]);
      Break;
    end;
  end;

  if not Assigned(LRect) then
  begin
    LRect := TRectangle.Create(Self);
    LRect.Name := '__FluentGlassBackdrop';
    LRect.Parent := Self;
    LRect.Align := TAlignLayout.Contents;
    LRect.HitTest := False;
    LRect.Stroke.Kind := TBrushKind.None;
    LRect.Fill.Color := $10FFFFFF;
    LRect.SendToBack;
  end;

  LRect.Motion.FrostedGlass(ATintColor, ABorderLight, ADurationMs).Start;
end;

end.
