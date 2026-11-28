program TactileGlassCalc;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  UnitMain in 'UnitMain.pas' {MainForm};

{$R *.res}

begin
  GlobalUseSkia := True;
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait];
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
