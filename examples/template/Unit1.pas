unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.StdCtrls,
  Tulip.FluentMotion, FMX.Objects, FMX.Calendar, FMX.Edit, System.Skia, FMX.Skia;

type
  TForm1 = class(TForm)
    StyleBook1: TStyleBook;
    Rectangle1: TRectangle;
    Label2: TLabel;
    Label3: TLabel;
    Button1: TButton;
    Rectangle5: TRectangle;
    Rectangle2: TRectangle;
    Rectangle3: TRectangle;
    rect1: TRectangle;
    Label1: TLabel;
    Image1: TImage;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
begin

  rect1.LiquidGlass(TFluentGlassStyle.Frosted);
end;

end.
