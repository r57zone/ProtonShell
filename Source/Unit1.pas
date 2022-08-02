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
  WinOldWidth, WinOldHeight: integer;
  WinSaveSize: boolean;

implementation

{$R *.dfm}

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  Ini: TIniFile;
begin
  if (WinSaveSize) and (WindowState <> wsMaximized) then
    if (WinOldWidth <> Width) or (WinOldHeight <> Height) then begin
      Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
      Ini.WriteInteger('Window', 'Width', Width);
      Ini.WriteInteger('Window', 'Height', Height);
      Ini.Free;
    end;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile; URL, LocalFile: string;
begin
  EdgeBrowser.SetUserDataFolder(ExtractFilePath(ParamStr(0)) + 'Data');

  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Main.Caption:=Ini.ReadString('Main', 'Title', '');
  LocalFile:=Ini.ReadString('Main', 'File', '');
  LocalFile:=StringReplace(LocalFile, '%FULLPATH%/', ExtractFilePath(ParamStr(0)), []);
  LocalFile:=StringReplace(LocalFile, '\', '/', [rfReplaceAll]);

  if LocalFile <> '' then
    URL:=LocalFile
  else
    URL:=Ini.ReadString('Main', 'URL', '');

  EdgeBrowser.Navigate(URL);

  Width:=Ini.ReadInteger('Window', 'Width', Width);
  Height:=Ini.ReadInteger('Window', 'Height', Height);
  WinSaveSize:=Ini.ReadBool('Window', 'SaveSize', false);

  if Ini.ReadBool('Window', 'HideMaximize', false) then
    BorderIcons:=Main.BorderIcons-[biMaximize];
    
  if Ini.ReadBool('Window', 'HideMinimize', false) then
    BorderIcons:=Main.BorderIcons-[biMinimize];
    
  case Ini.ReadInteger('Window', 'BorderStyle', 0) of
    0: BorderStyle:=bsSizeable;
    1: BorderStyle:=bsSingle;
    2: BorderStyle:=bsDialog;
    3: BorderStyle:=bsSizeToolWin;
    4: BorderStyle:=bsToolWindow;
  end;

  case Ini.ReadInteger('Window', 'WindowState', 0) of
    1: WindowState:=wsMaximized;
    2: begin BorderStyle:=bsNone; WindowState:=wsMaximized; end;
    //3: WindowState:=wsMinimized;
  end;

  Ini.Free;
  WinOldWidth:=Width;
  WinOldHeight:=Height;
end;

end.
