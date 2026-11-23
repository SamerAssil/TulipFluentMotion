unit Tulip.FluentMotion.Effect.Text;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Rtti,
  System.Generics.Collections,
  FMX.Controls,
  FMX.Objects,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Effect.Base;

type
  { Helper for setting Text on any FMX control (TText, TLabel, TSkLabel, TEdit, etc.) }
  TFluentTextHelper = record
  public
    class function GetText(const AControl: TControl): string; static;
    class procedure SetText(const AControl: TControl; const AText: string); static;
    class function TryExtractNumber(const AText: string; out AValue: Double): Boolean; static;
  end;

  { Arabic-Aware Unicode Grapheme Cluster Splitter }
  TFluentGraphemeHelper = record
  public
    class function IsCombiningMark(const Ch: Char): Boolean; static;
    class function SplitGraphemes(const S: string): TArray<string>; static;
  end;

  { Numeric Counter Effect: Smoothly animates numbers and financial currencies }
  TFluentCountEffect = class(TFluentMotionEffectBase)
  private
    FFromValue: Double;
    FTargetValue: Double;
    FStartValue: Double;
    FInitialValue: Double;
    FFormatStr: string;
    FAutoCapture: Boolean;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetValue: Double; const AFormatStr: string = '%0.2f'; const ADurationMs: Cardinal = 1500); reintroduce; overload;
    constructor Create(const AFromValue, ATargetValue: Double; const AFormatStr: string = '%0.2f'; const ADurationMs: Cardinal = 1500); reintroduce; overload;

    function Clone: IMotionEffect; override;

    property TargetValue: Double read FTargetValue write FTargetValue;
    property FormatStr: string read FFormatStr write FFormatStr;
  end;

  { Typewriter Effect: Progressive letter-by-letter typing with Arabic Tashkeel & Cursor safety }
  TFluentTypewriterEffect = class(TFluentMotionEffectBase)
  private
    FTargetText: string;
    FBlinkingCursor: Boolean;
    FCursorChar: Char;
    FCursorBlinkRateSec: Single;
    FClusters: TArray<string>;
    FInitialText: string;
    procedure BuildClusterArray;
  protected
    procedure DoAttach; override;
    procedure DoStart; override;
    procedure DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single); override;
    procedure DoFinish; override;
    procedure DoReset; override;
  public
    constructor Create(const ATargetText: string; const ACharDelayMs: Cardinal = 40; const ABlinkingCursor: Boolean = True; const ACursorChar: Char = '|'); reintroduce;

    function Clone: IMotionEffect; override;

    property TargetText: string read FTargetText write FTargetText;
    property BlinkingCursor: Boolean read FBlinkingCursor write FBlinkingCursor;
    property CursorChar: Char read FCursorChar write FCursorChar;
  end;

implementation

{ TFluentTextHelper }

class function TFluentTextHelper.GetText(const AControl: TControl): string;
var
  Ctx: TRttiContext;
  Prop: TRttiProperty;
begin
  Result := '';
  if not Assigned(AControl) then
    Exit;

  if AControl is TText then
    Exit(TText(AControl).Text);

  Ctx := TRttiContext.Create;
  try
    Prop := Ctx.GetType(AControl.ClassType).GetProperty('Text');
    if Assigned(Prop) and Prop.IsReadable then
      Result := Prop.GetValue(AControl).AsString;
  finally
    Ctx.Free;
  end;
end;

class procedure TFluentTextHelper.SetText(const AControl: TControl; const AText: string);
var
  Ctx: TRttiContext;
  Prop: TRttiProperty;
begin
  if not Assigned(AControl) then
    Exit;

  if AControl is TText then
  begin
    TText(AControl).Text := AText;
    Exit;
  end;

  Ctx := TRttiContext.Create;
  try
    Prop := Ctx.GetType(AControl.ClassType).GetProperty('Text');
    if Assigned(Prop) and Prop.IsWritable then
      Prop.SetValue(AControl, AText);
  finally
    Ctx.Free;
  end;
end;

class function TFluentTextHelper.TryExtractNumber(const AText: string; out AValue: Double): Boolean;
var
  Cleaned: string;
  I: Integer;
  Ch: Char;
  HasDot: Boolean;
begin
  AValue := 0.0;
  Cleaned := '';
  HasDot := False;

  for I := 1 to Length(AText) do
  begin
    Ch := AText[I];
    if (Ch >= '0') and (Ch <= '9') then
      Cleaned := Cleaned + Ch
    else if (Ch = '.') or (Ch = ',') then
    begin
      if not HasDot then
      begin
        Cleaned := Cleaned + FormatSettings.DecimalSeparator;
        HasDot := True;
      end;
    end
    else if (Ch = '-') and (Cleaned = '') then
      Cleaned := '-';
  end;

  if Cleaned = '' then
    Exit(False);

  Result := TryStrToFloat(Cleaned, AValue);
end;

{ TFluentGraphemeHelper }

class function TFluentGraphemeHelper.IsCombiningMark(const Ch: Char): Boolean;
var
  Code: Word;
begin
  Code := Word(Ch);
  Result := ((Code >= $064B) and (Code <= $065F)) or // Arabic Harakat / Tashkeel
            (Code = $0670) or                         // Dagger Alif
            ((Code >= $06D6) and (Code <= $06ED)) or // Arabic Quranic marks
            ((Code >= $0300) and (Code <= $036F)) or // Combining Diacritical Marks
            (Code = $200C) or (Code = $200D);        // ZWNJ, ZWJ
end;

class function TFluentGraphemeHelper.SplitGraphemes(const S: string): TArray<string>;
var
  List: TList<string>;
  I, Len: Integer;
  CurGrapheme: string;
begin
  List := TList<string>.Create;
  try
    I := 1;
    Len := Length(S);
    while I <= Len do
    begin
      CurGrapheme := S[I];
      Inc(I);
      // Consume all trailing combining marks so Tashkeel is never severed from base letter
      while (I <= Len) and IsCombiningMark(S[I]) do
      begin
        CurGrapheme := CurGrapheme + S[I];
        Inc(I);
      end;
      List.Add(CurGrapheme);
    end;
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

{ TFluentCountEffect }

constructor TFluentCountEffect.Create(const ATargetValue: Double; const AFormatStr: string; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FTargetValue := ATargetValue;
  FFormatStr := AFormatStr;
  FFromValue := 0.0;
  FAutoCapture := True;
  FEase := TFluentEase.OutExpo; // Fast initial count, elegant smooth settling
end;

constructor TFluentCountEffect.Create(const AFromValue, ATargetValue: Double; const AFormatStr: string; const ADurationMs: Cardinal);
begin
  inherited Create(ADurationMs);
  FFromValue := AFromValue;
  FTargetValue := ATargetValue;
  FFormatStr := AFormatStr;
  FAutoCapture := False;
  FEase := TFluentEase.OutExpo;
end;

procedure TFluentCountEffect.DoAttach;
var
  Extracted: Double;
begin
  if Assigned(FControl) then
  begin
    if TFluentTextHelper.TryExtractNumber(TFluentTextHelper.GetText(FControl), Extracted) then
      FInitialValue := Extracted
    else
      FInitialValue := 0.0;
  end;
end;

procedure TFluentCountEffect.DoStart;
var
  Extracted: Double;
begin
  if FAutoCapture and Assigned(FControl) then
  begin
    if TFluentTextHelper.TryExtractNumber(TFluentTextHelper.GetText(FControl), Extracted) then
      FStartValue := Extracted
    else
      FStartValue := 0.0;
  end
  else
    FStartValue := FFromValue;

  TFluentTextHelper.SetText(FControl, Format(FFormatStr, [FStartValue]));
end;

procedure TFluentCountEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  CurValue: Double;
begin
  if not Assigned(FControl) then
    Exit;

  CurValue := FStartValue + (FTargetValue - FStartValue) * AProgress;
  TFluentTextHelper.SetText(FControl, Format(FFormatStr, [CurValue]));
end;

procedure TFluentCountEffect.DoFinish;
begin
  if Assigned(FControl) then
    TFluentTextHelper.SetText(FControl, Format(FFormatStr, [FTargetValue]));
end;

procedure TFluentCountEffect.DoReset;
begin
  if Assigned(FControl) then
    TFluentTextHelper.SetText(FControl, Format(FFormatStr, [FStartValue]));
end;

function TFluentCountEffect.Clone: IMotionEffect;
var
  Res: TFluentCountEffect;
begin
  if FAutoCapture then
    Res := TFluentCountEffect.Create(FTargetValue, FFormatStr, FDurationMs)
  else
    Res := TFluentCountEffect.Create(FFromValue, FTargetValue, FFormatStr, FDurationMs);

  Res.FEase := FEase;
  Res.FUseSpring := FUseSpring;
  Res.FSpring := FSpring;
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

{ TFluentTypewriterEffect }

constructor TFluentTypewriterEffect.Create(const ATargetText: string; const ACharDelayMs: Cardinal; const ABlinkingCursor: Boolean; const ACursorChar: Char);
var
  Clusters: TArray<string>;
  TotalDuration: Cardinal;
begin
  Clusters := TFluentGraphemeHelper.SplitGraphemes(ATargetText);
  TotalDuration := Cardinal(Max(50, Integer(Length(Clusters)) * Integer(Max(Cardinal(10), ACharDelayMs))));

  inherited Create(TotalDuration);
  FTargetText := ATargetText;
  FBlinkingCursor := ABlinkingCursor;
  FCursorChar := ACursorChar;
  FCursorBlinkRateSec := 0.4; // 400ms half-period blink
  FEase := TFluentEase.Linear;
  BuildClusterArray;
end;

procedure TFluentTypewriterEffect.BuildClusterArray;
begin
  FClusters := TFluentGraphemeHelper.SplitGraphemes(FTargetText);
end;

procedure TFluentTypewriterEffect.DoAttach;
begin
  if Assigned(FControl) then
    FInitialText := TFluentTextHelper.GetText(FControl);
end;

procedure TFluentTypewriterEffect.DoStart;
begin
  BuildClusterArray;
  if Assigned(FControl) then
  begin
    if FBlinkingCursor then
      TFluentTextHelper.SetText(FControl, FCursorChar)
    else
      TFluentTextHelper.SetText(FControl, '');
  end;
end;

procedure TFluentTypewriterEffect.DoUpdate(const AProgress: Single; const AElapsedTimeSec: Single);
var
  Count, MaxCount, I: Integer;
  VisibleText: string;
  ShowCursor: Boolean;
begin
  if not Assigned(FControl) then
    Exit;

  MaxCount := Length(FClusters);
  if MaxCount = 0 then
    Exit;

  Count := EnsureRange(Round(AProgress * MaxCount), 0, MaxCount);

  VisibleText := '';
  for I := 0 to Count - 1 do
    VisibleText := VisibleText + FClusters[I];

  if FBlinkingCursor and (Count < MaxCount) then
  begin
    // Cursor blinks at FCursorBlinkRateSec intervals
    ShowCursor := (Frac(AElapsedTimeSec / (FCursorBlinkRateSec * 2.0)) < 0.5);
    if ShowCursor then
      VisibleText := VisibleText + FCursorChar;
  end;

  TFluentTextHelper.SetText(FControl, VisibleText);
end;

procedure TFluentTypewriterEffect.DoFinish;
begin
  if Assigned(FControl) then
    TFluentTextHelper.SetText(FControl, FTargetText);
end;

procedure TFluentTypewriterEffect.DoReset;
begin
  if Assigned(FControl) then
    TFluentTextHelper.SetText(FControl, FInitialText);
end;

function TFluentTypewriterEffect.Clone: IMotionEffect;
var
  Res: TFluentTypewriterEffect;
begin
  Res := TFluentTypewriterEffect.Create(FTargetText, 40, FBlinkingCursor, FCursorChar);
  Res.FDurationMs := FDurationMs;
  Res.FEase := FEase;
  Res.FDelayMs := FDelayMs;
  Result := Res;
end;

end.
