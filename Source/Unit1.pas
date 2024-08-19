unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, WebView2, Winapi.ActiveX, Vcl.Edge, IniFiles, ShellAPI,
  Registry, WinInet;

const // https://stackoverflow.com/questions/66692031/how-to-set-useragent-in-new-delphi-tedgebrowser
   IID_ICoreWebView2Settings2: TGUID = '{EE9A0F68-F46C-4E32-AC23-EF8CAC224D2A}';

type
  ICoreWebView2Settings2 = interface(ICoreWebView2Settings)
    ['{EE9A0F68-F46C-4E32-AC23-EF8CAC224D2A}']
    function Get_UserAgent(out UserAgent: PWideChar): HResult; stdcall;
    function Set_UserAgent(UserAgent: PWideChar): HResult; stdcall;
  end;

type
  TMain = class(TForm)
    EdgeBrowser: TEdgeBrowser;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser;
      AResult: HRESULT);
    procedure EdgeBrowserNewWindowRequested(Sender: TCustomEdgeBrowser;
      Args: TNewWindowRequestedEventArgs);
    procedure EdgeBrowserNavigationCompleted(Sender: TCustomEdgeBrowser;
      IsSuccess: Boolean; WebErrorStatus: TOleEnum);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;
  WinOldWidth, WinOldHeight, WinOldTop, WinOldLeft: integer;
  WinSaveSize, WinSavePos, ReturnPrevSystemProxy: boolean;
  EdgeUserAgent, SystemProxy, PrevSystemProxy: string;
  OpenExternalLinks, LoadUserScript: boolean;
  UserScriptFile: TStringList;

implementation

{$R *.dfm}

procedure TMain.EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser;
  AResult: HRESULT);
var
  WebViewSettings: ICoreWebView2Settings2;
  //HR: HRESULT;
begin
  if Trim(EdgeUserAgent) = '' then Exit;
  // You must query SettingsInterface2 from SettingsInterface it's important
  Sender.SettingsInterface.QueryInterface(IID_ICoreWebView2Settings2, WebViewSettings);
  if not Assigned(WebViewSettings) then
    raise Exception.Create('ICoreWebView2Settings2 not found');
  WebViewSettings.Set_UserAgent(PWideChar(EdgeUserAgent));
  //HR := WebViewSettings.Get_UserAgent(PWideChar(EdgeUserAgent));
  //if not SUCCEEDED(HR) then
    //raise Exception.Create('Get_UserAgent failed');
end;

procedure TMain.EdgeBrowserNavigationCompleted(Sender: TCustomEdgeBrowser;
  IsSuccess: Boolean; WebErrorStatus: TOleEnum);
begin
  if UserScriptFile.Text <> '' then
    EdgeBrowser.ExecuteScript(UserScriptFile.Text);
end;

procedure TMain.EdgeBrowserNewWindowRequested(Sender: TCustomEdgeBrowser;
  Args: TNewWindowRequestedEventArgs);
var
  WebViewArgs: ICoreWebView2NewWindowRequestedEventArgs;
  PUri: PWideChar;
begin
  if OpenExternalLinks = false then Exit;

  // Get arguments WebView2
  WebViewArgs:=Args as ICoreWebView2NewWindowRequestedEventArgs;

  // Get URL
  if Succeeded(WebViewArgs.Get_uri(PUri)) and (PUri <> nil) then begin
    try
      ShellExecute(0, 'open', PUri, nil, nil, SW_SHOWNORMAL);
    finally
      CoTaskMemFree(PUri);
    end;

    // Blocking the opening of a new window
    Args.ArgsInterface.Set_Handled(1);
  end;
end;

procedure ProxyActivate(Enable: boolean);
var
  Reg: TRegistry;
begin
  Reg:=TRegistry.Create;
  try
    Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Internet Settings', False);
    Reg.WriteBool('ProxyEnable', Enable);
    Reg.CloseKey;
    InternetSetOption(0, INTERNET_OPTION_SETTINGS_CHANGED, 0, 0);
  finally
    Reg.Free;
  end;
end;

procedure SetProxy(const Server: String);
var
  Reg: TRegistry;
begin
  Reg:=TRegistry.Create;
  try
    Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Internet Settings', False);
    if ReturnPrevSystemProxy then begin
      if Reg.ValueExists('ProxyServer') then
        PrevSystemProxy:=Reg.ReadString('ProxyServer')
      else
        PrevSystemProxy:='';
      ShowMessage(PrevSystemProxy);
    end;
    Reg.WriteString('ProxyServer', Server);
    Reg.CloseKey;
  finally
    Reg.Free;
  end;
end;

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

  if (WinSavePos) and (WindowState <> wsMaximized) then
    if (WinOldTop <> Top) or (WinOldLeft <> Left) then begin
      Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
      Ini.WriteInteger('Window', 'Top', Top);
      Ini.WriteInteger('Window', 'Left', Left);
      Ini.Free;
    end;
  UserScriptFile.Free;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile; URL, LocalFile, FulllPath, UserScriptPath, IconPath: string;
begin
  EdgeBrowser.UserDataFolder:=ExtractFilePath(ParamStr(0)) + 'Data';

  FulllPath:=ExtractFilePath(ParamStr(0));
  Ini:=TIniFile.Create(FulllPath + 'Config.ini');
  LocalFile:=Ini.ReadString('Main', 'File', '');

  LocalFile:=StringReplace(LocalFile, '%FULLPATH%/', FulllPath, []);
  LocalFile:=StringReplace(LocalFile, '\', '/', [rfReplaceAll]);
  EdgeUserAgent:=Ini.ReadString('Main', 'UserAgent', '');
  OpenExternalLinks:=Ini.ReadBool('Main', 'OpenExternalLinks', false);
  UserScriptPath:=StringReplace(Ini.ReadString('Main', 'UserScript', ''), '%FULLPATH%/', FulllPath, []);
  UserScriptFile:=TStringList.Create;
  if FileExists(UserScriptPath) then
    UserScriptFile.LoadFromFile(UserScriptPath, TEncoding.UTF8);

  if LocalFile <> '' then
    URL:=LocalFile
  else
    URL:=Ini.ReadString('Main', 'URL', '');

  EdgeBrowser.Navigate(URL);

  // Windows sizes
  Width:=Ini.ReadInteger('Window', 'Width', Width);
  Height:=Ini.ReadInteger('Window', 'Height', Height);
  WinSaveSize:=Ini.ReadBool('Window', 'SaveSize', false);
  WinOldWidth:=Width;
  WinOldHeight:=Height;

  // Windows position
  if (Trim(Ini.ReadString('Window', 'Top', '')) <> '') and (Trim(Ini.ReadString('Window', 'Left', '')) <> '') then begin
    Main.Top:=Ini.ReadInteger('Window', 'Top', Top);
    Main.Left:=Ini.ReadInteger('Window', 'Left', Left);
  end else begin
    Main.Top:=Screen.Height div 2 - Height div 2; // Main.Position - Some problems with Edge
    Main.Left:=Screen.Width div 2 - Width div 2;
  end;
  WinSavePos:=Ini.ReadBool('Window', 'SavePos', false);
  WinOldTop:=Top;
  WinOldLeft:=Left;

  // Windows params
  Main.Caption:=UTF8ToAnsi(Ini.ReadString('Window', 'Title', ''));

  IconPath:=Trim(Ini.ReadString('Window', 'IconPath', ''));
  if (IconPath <> '') and (FileExists(IconPath)) then
    Main.Icon.LoadFromFile(IconPath);

  if Ini.ReadBool('Window', 'HideMaximize', false) then
    BorderIcons:=Main.BorderIcons-[biMaximize];

  case Ini.ReadInteger('Window', 'BorderStyle', 0) of
    0: BorderStyle:=bsNone;
    1: BorderStyle:=bsSizeable;
    2: BorderStyle:=bsSingle;
    3: BorderStyle:=bsDialog;
    4: BorderStyle:=bsSizeToolWin;
    5: BorderStyle:=bsToolWindow;
  end;

  case Ini.ReadInteger('Window', 'WindowState', 0) of
    1: WindowState:=wsMaximized;
    2: begin BorderStyle:=bsNone; WindowState:=wsMaximized; end;
    3: WindowState:=wsMinimized;
  end;

  if Ini.ReadBool('Window', 'StayOnTop', false) then
    FormStyle:=fsStayOnTop;

  // System proxy
  ReturnPrevSystemProxy:=Ini.ReadBool('Main', 'ReturnPreviousProxy', false);
  SystemProxy:=Trim(Ini.ReadString('Main', 'SystemProxy', ''));
  if SystemProxy <> '' then begin
    SetProxy(SystemProxy);
    ProxyActivate(true);
  end;

  Ini.Free;
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
  if ReturnPrevSystemProxy then begin
    SetProxy(PrevSystemProxy);
    ProxyActivate(true);
  end else if SystemProxy <> '' then
    ProxyActivate(false);
end;

end.
