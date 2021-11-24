unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, WebView2, Winapi.ActiveX, Vcl.Edge, IniFiles;

type
  TMain = class(TForm)
    EdgeBrowser: TEdgeBrowser;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;
  OldWidth, OldHeight: integer;

implementation

{$R *.dfm}

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  Ini: TIniFile;
begin
  if (Main.WindowState <> wsMaximized) then
    if (OldWidth <> Width) or (OldHeight <> Height) then begin
      Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
      Ini.WriteInteger('Main', 'Width', Width);
      Ini.WriteInteger('Main', 'Height', Height);
      Ini.Free;
    end;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile; URL, LocalFile: string;
begin
  EdgeBrowser.SetUserDataFolder(ExtractFilePath(ParamStr(0)) + 'Data');

  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Width:=Ini.ReadInteger('Main', 'Width', Width);
  Height:=Ini.ReadInteger('Main', 'Height', Height);
  Main.Caption:=Ini.ReadString('Main', 'Caption', '');

  LocalFile:=Ini.ReadString('Main', 'File', '');
  LocalFile:=StringReplace(LocalFile, '%FULLPATH%/', ExtractFilePath(ParamStr(0)), []);
  LocalFile:=StringReplace(LocalFile, '\', '/', [rfReplaceAll]);

  if LocalFile <> '' then
    URL:=LocalFile
  else
    URL:=Ini.ReadString('Main', 'URL', '');

  EdgeBrowser.Navigate(URL);

  Ini.Free;
  OldWidth:=Width;
  OldHeight:=Height;
end;

end.
