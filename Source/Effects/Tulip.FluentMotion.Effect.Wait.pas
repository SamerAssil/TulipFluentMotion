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

end.
