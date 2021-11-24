program Project1;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Main};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
