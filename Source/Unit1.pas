unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, WebView2, Winapi.ActiveX, Vcl.Edge, IniFiles, ShellAPI,
  Registry, WinInet, Vcl.StdCtrls, Vcl.ExtCtrls;

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
    DebugPanel: TPanel;
    PanelTools: TPanel;
    LeftBtn: TButton;
    RightBtn: TButton;
    RefreshBtn: TButton;
    HomeBtn: TButton;
    ClearBtn: TButton;
    SetDeviceBtn: TButton;
    RotateDeviceBtn: TButton;
    DevicesCB: TComboBox;
    ZoomCB: TComboBox;
    UserAgentsCB: TComboBox;
    ResolutionLbl: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser;
      AResult: HRESULT);
    procedure EdgeBrowserNewWindowRequested(Sender: TCustomEdgeBrowser;
      Args: TNewWindowRequestedEventArgs);
    procedure EdgeBrowserNavigationCompleted(Sender: TCustomEdgeBrowser;
      IsSuccess: Boolean; WebErrorStatus: TOleEnum);
    procedure FormDestroy(Sender: TObject);
    procedure LeftBtnClick(Sender: TObject);
    procedure RightBtnClick(Sender: TObject);
    procedure RefreshBtnClick(Sender: TObject);
    procedure HomeBtnClick(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
    procedure SetDeviceBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure RotateDeviceBtnClick(Sender: TObject);
    procedure UserAgentsCBChange(Sender: TObject);
    procedure DevicesCBChange(Sender: TObject);
    procedure EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser;
      Args: TWebMessageReceivedEventArgs);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;
  WinOldWidth, WinOldHeight, WinOldTop, WinOldLeft, WinOldState: integer;
  WinSaveSize, WinSavePos, WinSaveState, ReturnPrevSystemProxy, UserAgentsCBChanged: boolean;
  FullPath, MainURL, EdgeUserAgent, NewUserAgent, SystemProxy, PrevSystemProxy, ConfigFile: string;
  OpenExternalLinks, LoadUserScript: boolean;
  UserScriptFile: TStringList;

  IDS_CONFIRM_DELETE_ALL_DATA, IDS_RESOLUTION: string;

implementation

{$R *.dfm}

function FixPath(Path: string): string;
begin
  if (Length(Path) > 0) and (Path[2] <> ':') then
    Path:=FullPath + Path;

  if (Length(Path) > 2) and (Path[Length(Path)] = '\') and (Path[Length(Path) - 1] = '\') then
    Path:=Copy(Path, 1, Length(Path) - 1);

  Result:=Path;
end;

procedure TMain.ClearBtnClick(Sender: TObject);
var
  ScriptStr: string;
begin
  case MessageBox(Handle, PChar(IDS_CONFIRM_DELETE_ALL_DATA), PChar(Caption), 35) of
    7: Exit;
    2: Exit;
  end;

  ScriptStr:=
    'localStorage.clear();' + sLineBreak +
    'sessionStorage.clear();' + sLineBreak +
    // Cookie
    'document.cookie.split(";").forEach(function(cookie) {' + sLineBreak +
    '    document.cookie = cookie.split("=")[0] + "=;expires=" + new Date(0).toUTCString() + ";path=/";' + sLineBreak +
    '});' + sLineBreak +
    // IndexedDB
    'indexedDB.databases().then(function(databases) {' + sLineBreak +
    '    databases.forEach(function(db) {' + sLineBreak +
    '        indexedDB.deleteDatabase(db.name);' + sLineBreak +
    '    });' + sLineBreak +
    '});' + sLineBreak +
    // PWA
    'caches.keys().then(function(names) {' + sLineBreak +
    '    for (let name of names) caches.delete(name);' + sLineBreak +
    '});' + sLineBreak +
    'window.location.reload();';

  EdgeBrowser.ExecuteScript(ScriptStr);
end;

procedure TMain.DevicesCBChange(Sender: TObject);
begin
  if DevicesCB.ItemIndex = -1 then Exit;
  DevicesCB.Hint:=DevicesCB.Items.Strings[DevicesCB.ItemIndex];
end;

procedure TMain.EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser;
  AResult: HRESULT);
var
  WebViewSettings: ICoreWebView2Settings2;
begin
  if Trim(NewUserAgent) = '' then Exit;
  // You must query SettingsInterface2 from SettingsInterface it's important
  Sender.SettingsInterface.QueryInterface(IID_ICoreWebView2Settings2, WebViewSettings);
  if not Assigned(WebViewSettings) then
    raise Exception.Create('ICoreWebView2Settings2 not found');

  WebViewSettings.Set_UserAgent(PWideChar(NewUserAgent));

  //HR := WebViewSettings.Get_UserAgent(PWideChar(EdgeUserAgent));
  //if not SUCCEEDED(HR) then
    //raise Exception.Create('Get_UserAgent failed');
end;

procedure TMain.EdgeBrowserNavigationCompleted(Sender: TCustomEdgeBrowser;
  IsSuccess: Boolean; WebErrorStatus: TOleEnum);
var
  WebViewSettings: ICoreWebView2Settings2;
  EdgeUserAgentTemp: string;
  UAPosDots: integer;
begin
  if UserScriptFile.Text <> '' then
    EdgeBrowser.ExecuteScript(UserScriptFile.Text);

  // Debug mode User Agents
  if (DebugPanel.Visible = false) or (UserAgentsCBChanged = false) then Exit;
  UserAgentsCBChanged:=false;

  Sender.SettingsInterface.QueryInterface(IID_ICoreWebView2Settings2, WebViewSettings);

  if not Assigned(WebViewSettings) then
    raise Exception.Create('ICoreWebView2Settings2 not found');

  if UserAgentsCB.ItemIndex < 1 then
    WebViewSettings.Set_UserAgent(PWideChar(EdgeUserAgent))
  else begin
    EdgeUserAgentTemp:=UserAgentsCB.Items.Strings[UserAgentsCB.ItemIndex];
    UAPosDots:=Pos(':', EdgeUserAgentTemp);
    if UAPosDots <> 0 then
      Delete(EdgeUserAgentTemp, 1, UAPosDots);
    WebViewSettings.Set_UserAgent(PWideChar(Trim(EdgeUserAgentTemp)));
  end;
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

procedure TMain.EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser;
  Args: TWebMessageReceivedEventArgs);
var
  CommandP: PChar; CommandStr: string; FilePath, FileParams, FolderPath: string;
  ResponseList: TStringList; SR: TSearchRec;
begin
  Args.ArgsInterface.TryGetWebMessageAsString(CommandP);
  CommandStr:=CommandP;
  //Args.ArgsInterface.Get_webMessageAsJson();
  //ShowMessage(CommandStr); Exit;

  if CommandStr = 'close' then
    Close

  else if Copy(CommandStr, 1, 5) = 'open ' then begin
    if (Length(CommandStr) > 5) and (CommandStr[6] = '"') then begin
      FilePath:=Copy(CommandStr, 7, Length(CommandStr) - 6);

      FileParams:=Trim(Copy(FilePath, Pos('"', FilePath) + 1, Length(FilePath)));
      FilePath:=Copy(FilePath, 1, Pos('"', FilePath) - 1);

      //ShowMessage(FilePath);
      //ShowMessage('"' + FileParams + '"');

      FilePath:=FixPath(FilePath);
    end else begin
      FilePath:=FixPath(Copy(CommandStr, 6, Length(CommandStr) - 5));
      FileParams:='';
    end;

    ShellExecute(0, 'open', PChar(FilePath), PChar(FileParams), nil, SW_SHOWNORMAL);

  end else if Copy(CommandStr, 1, 4) = 'del ' then begin
    FilePath:=Copy(CommandStr, 5, Length(CommandStr) - 4);
    DeleteFile(FilePath);

  end else if Copy(CommandStr, 1, 7) = 'folder ' then begin

    FolderPath:=Copy(CommandStr, 8, Length(CommandStr) - 7);


    // If the path is relative, then add the full path
    if (FolderPath <> '') then begin

      FolderPath:=FixPath(FolderPath);

      //ShowMessage(FolderPath);

      ResponseList:=TStringList.Create;

	    if FindFirst(FolderPath + '*.*', faAnyFile, SR) = 0 then begin
		    repeat
			    if (SR.Name = '.') or (SR.Name = '..') then Continue;
          if (SR.Attr <> faDirectory) then
            ResponseList.Add(SR.Name)
          else
            ResponseList.Add(SR.Name + '\\');
		    until FindNext(SR) <> 0;
	      FindClose(SR);
	    end;

      ResponseList.Text:=StringReplace(Trim(ResponseList.Text), #13#10, '\n', [rfReplaceAll]);

      //ShowMessage(ResponseList.Text);

      EdgeBrowser.ExecuteScript('handleMessageFromHost("' + Trim(ResponseList.Text) + '");');

      ResponseList.Free;
    end;
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
    end;
    Reg.WriteString('ProxyServer', Server);
    Reg.CloseKey;
  finally
    Reg.Free;
  end;
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  Ini: TIniFile; WinNewState: integer;
begin
  if (WinSaveSize) and (WindowState <> wsMaximized) then
    if (WinOldWidth <> ClientWidth) or (WinOldHeight <> ClientHeight) then begin
      Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + ConfigFile);
      Ini.WriteInteger('Window', 'Width', ClientWidth);
      Ini.WriteInteger('Window', 'Height', ClientHeight);
      Ini.Free;
    end;

  if (WinSavePos) and (WindowState <> wsMaximized) then
    if (WinOldTop <> Top) or (WinOldLeft <> Left) then begin
      Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + ConfigFile);
      Ini.WriteInteger('Window', 'Top', Top);
      Ini.WriteInteger('Window', 'Left', Left);
      Ini.Free;
    end;

  if (WinSaveState) then begin
    if WindowState = wsMaximized then begin
      if BorderStyle <> bsNone then
        WinNewState:=1
      else
        WinNewState:=2;
    end else if WindowState = wsMinimized then
      WinNewState:=3
    else // wsNormal
      WinNewState:=0;

    if WinOldState <> WinNewState then begin
      Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
      Ini.WriteInteger('Window', 'WindowState', WinNewState);
      Ini.Free;
    end;
  end;

  UserScriptFile.Free;
end;

procedure WindowToCenter;
var
  ScreenCenter: TPoint;
  ScreenTop: Integer;
begin
  with Screen.MonitorFromWindow(Main.Handle).WorkareaRect do begin
    ScreenCenter:=Point(Left + Width div 2, Top + Height div 2);
    ScreenTop:=Top;
  end;

  Main.Top:=ScreenCenter.Y - Main.Height div 2;
  if Main.Top < ScreenTop then Main.Top:=ScreenTop;

  Main.Left:=ScreenCenter.X - Main.Width div 2;
end;

function GetLocaleInformation(Flag: integer): string;
var
  pcLCA: array [0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, Flag, pcLCA, 19) <= 0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
  LocalFile, WebAddress, UserScriptPath, IconPath, AppTitle, IconCachePath, ParamStrLower: string;
  i, WindowTop, WindowLeft, WindowBorderStyle: integer;
  CustomConfig, ChangePosition, DebugeMode, IsFullscreen: boolean;
begin
  EdgeUserAgent:='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0';
  FullPath:=ExtractFilePath(ParamStr(0));
  WindowBorderStyle:=1;
  IsFullscreen:=false;
  WinSavePos:=false;
  WinSaveState:=false;

  EdgeBrowser.UserDataFolder:=FullPath + 'Data';

  // Translations
  if GetLocaleInformation(LOCALE_SENGLANGUAGE) = 'Russian' then begin
    IDS_CONFIRM_DELETE_ALL_DATA:='Вы действительно хотите удалить все данные?';
    IDS_RESOLUTION:='Разрешение: ';
    ClearBtn.Hint:='Удаление всех данных';
    SetDeviceBtn.Hint:='Изменить устройство';
    RotateDeviceBtn.Hint:='Повернуть устройство';
  end else begin
    IDS_CONFIRM_DELETE_ALL_DATA:='Are you sure you want to delete all data?';
    IDS_RESOLUTION:='Resolution: ';
    ClearBtn.Hint:='Deleting all data';
    SetDeviceBtn.Hint:='Change device';
    RotateDeviceBtn.Hint:='Rotate the device';
  end;

  // Custom config
  ConfigFile:='Config.ini';
  CustomConfig:=false;
  for i:=0 to ParamCount - 1 do
    if (AnsiLowerCase(ParamStr(i)) = '-c') and (Trim(ParamStr(i + 1)) <> '') and (FileExists(ParamStr(i + 1))) then begin
      ConfigFile:=ParamStr(i + 1);
      CustomConfig:=true;
    end;

  if (ParamCount = 0) or (CustomConfig) then begin

    // Config parameters
    Ini:=TIniFile.Create(FullPath + ConfigFile);
    LocalFile:=Trim(Ini.ReadString('Main', 'File', ''));
    WebAddress:=Ini.ReadString('Main', 'URL', '');

    NewUserAgent:=Ini.ReadString('Main', 'UserAgent', '');
    OpenExternalLinks:=Ini.ReadBool('Main', 'OpenExternalLinks', false);
    UserScriptPath:=Ini.ReadString('Main', 'UserScript', '');

    // Windows sizes
    ClientWidth:=Ini.ReadInteger('Window', 'Width', ClientWidth);
    ClientHeight:=Ini.ReadInteger('Window', 'Height', ClientHeight);
    WinSaveSize:=Ini.ReadBool('Window', 'SaveSize', false);
    WinOldWidth:=ClientWidth;
    WinOldHeight:=ClientHeight;

    // Windows position
    ChangePosition:=not ((Trim(Ini.ReadString('Window', 'Top', '')) = '') or (Trim(Ini.ReadString('Window', 'Left', ''))  = ''));
    if ChangePosition then begin
      WindowTop:=Ini.ReadInteger('Window', 'Top', Top);
      WindowLeft:=Ini.ReadInteger('Window', 'Left', Left);
    end;
    WinSavePos:=Ini.ReadBool('Window', 'SavePos', false);

    // Windows params
    AppTitle:=UTF8ToAnsi(Ini.ReadString('Window', 'Title', ''));

    IconPath:=Trim(Ini.ReadString('Window', 'IconPath', ''));

    if Ini.ReadBool('Window', 'HideMaximize', false) then
      BorderIcons:=Main.BorderIcons-[biMaximize];

    WindowBorderStyle:=Ini.ReadInteger('Window', 'BorderStyle', 1);

    WinOldState:=Ini.ReadInteger('Window', 'WindowState', 0);
    case WinOldState of // 0: default
      1: WindowState:=wsMaximized;
      2: begin BorderStyle:=bsNone; WindowState:=wsMaximized; IsFullscreen:=true; end;
      3: WindowState:=wsMinimized;
    end;
    WinSaveState:=Ini.ReadBool('Window', 'SaveState', false);

    if Ini.ReadBool('Window', 'StayOnTop', false) then
      FormStyle:=fsStayOnTop;

    // System proxy
    ReturnPrevSystemProxy:=Ini.ReadBool('Main', 'ReturnPreviousProxy', false);
    SystemProxy:=Trim(Ini.ReadString('Main', 'SystemProxy', ''));

    // Debug mode
    DebugeMode:=Ini.ReadBool('Main', 'Debug', false);

    Ini.Free;

  end else
    for i:=0 to ParamCount do begin
      ParamStrLower:=ParamStr(i);
      if ParamStrLower = '-d' then DebugeMode:=true;
      if ParamStrLower = '-fullscreen' then begin BorderStyle:=bsNone; WindowState:=wsMaximized; IsFullscreen:=true; end;
      {if (ParamStr(i) = '-iw') and (WebAddress <> '') then begin
        if not DirectoryExists(FullPath + 'Icons') then
          CreateDir(FullPath + 'Icons');
        IconCachePath:=FullPath + 'Icons\' + ConvertUrlToIdentifier(WebAddress) + '.ico';
        if not FileExists(IconCachePath) then
          HTTPDownloadFile(GetBaseUrl(WebAddress) + '/favicon.ico', IconCachePath);
        //ShowMessage(GetBaseUrl(WebAddress) + '/favicon.ico');
        IconPath:=IconCachePath; // SVG/PNG instead of ICO prevents this from being implemented
      end;}

      if i + 1 > ParamCount then Continue;
      if ParamStrLower = '-f' then LocalFile:=ParamStr(i + 1);
      if ParamStrLower = '-a' then WebAddress:=ParamStr(i + 1);
      if ParamStrLower = '-n' then AppTitle:=ParamStr(i + 1);
      if ParamStrLower = '-i' then IconPath:=ParamStr(i + 1);
      if ParamStrLower = '-p' then SystemProxy:=ParamStr(i + 1);
      if ParamStrLower = '-u' then NewUserAgent:=ParamStr(i + 1);
      if ParamStrLower = '-s' then UserScriptPath:=ParamStr(i + 1);
      if ParamStrLower = '-b' then WindowBorderStyle:=StrToIntDef(ParamStr(i + 1), 1);
      if ParamStrLower = '-rp' then ReturnPrevSystemProxy:=true;
      if ParamStrLower = '-t' then WindowTop:=StrToIntDef(ParamStr(i + 1), 0);
      if ParamStrLower = '-l' then WindowLeft:=StrToIntDef(ParamStr(i + 1), 0);
      if ParamStrLower = '-w' then ClientWidth:=StrToIntDef(ParamStr(i + 1), ClientWidth);
      if ParamStrLower = '-h' then ClientHeight:=StrToIntDef(ParamStr(i + 1), ClientHeight)
    end;

  // Windows params
  Main.Caption:=AppTitle;

  // Icon
  if (IconPath <> '') and (FileExists(IconPath)) then
    try
      Main.Icon.LoadFromFile(IconPath);
    except
      DeleteFile(IconPath);
    end;

  // Window
  if ChangePosition then begin
    Main.Top:=WindowTop;
    Main.Left:=WindowLeft;
  end else
    WindowToCenter;
    //Main.Top:=Screen.Height div 2 - Height div 2; // Main.Position - Some problems with Edge
    //Main.Left:=Screen.Width div 2 - Width div 2;
  WinOldTop:=Main.Top;
  WinOldLeft:=Main.Left;

  if IsFullscreen = false then
    case WindowBorderStyle of
      0: BorderStyle:=bsNone;
      1: BorderStyle:=bsSizeable;
      2: BorderStyle:=bsSingle;
      3: BorderStyle:=bsDialog;
      4: BorderStyle:=bsSizeToolWin;
      5: BorderStyle:=bsToolWindow;
   end;

  // If the path is relative, then add the full path
  if (LocalFile <> '') and (Length(LocalFile) > 1) and (LocalFile[2] <> ':') then
    LocalFile:=FullPath + LocalFile;

  // Applying parameters
  // Address
  if LocalFile <> '' then
    MainURL:=LocalFile
  else
    MainURL:=WebAddress;
  EdgeBrowser.Navigate(MainURL);

  // System proxy
  if SystemProxy <> '' then begin
    SetProxy(SystemProxy);
    ProxyActivate(true);
  end;

  // User scripts
  UserScriptFile:=TStringList.Create;
  if FileExists(UserScriptPath) then
    UserScriptFile.LoadFromFile(UserScriptPath, TEncoding.UTF8);

  // Debug mode
  if DebugeMode then begin
    DebugPanel.Visible:=true;
    ClientHeight:=ClientHeight + DebugPanel.Height;
    Top:=Top - DebugPanel.Height div 2;
    if FileExists(FullPath + 'DevicesList.txt') then begin
      DevicesCB.Items.LoadFromFile(FullPath + 'DevicesList.txt', TEncoding.UTF8);
      if DevicesCB.Items.Count > 0 then
        DevicesCB.ItemIndex:=0;
    end;

    if FileExists(FullPath + 'UserAgentsList.txt') then begin
      UserAgentsCB.Items.LoadFromFile(FullPath + 'UserAgentsList.txt', TEncoding.UTF8);
      if UserAgentsCB.Items.Count > 0 then
        UserAgentsCB.ItemIndex:=0;
    end;
  end;
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
  if ReturnPrevSystemProxy then begin
    SetProxy(PrevSystemProxy);
    ProxyActivate(true);
  end else if SystemProxy <> '' then
    ProxyActivate(false);
end;

procedure TMain.FormResize(Sender: TObject);
begin
  ResolutionLbl.Caption:=IDS_RESOLUTION + IntToStr(EdgeBrowser.Width) + 'x' + IntToStr(EdgeBrowser.Height);
  PanelTools.Left:=DebugPanel.Width div 2 - PanelTools.Width div 2;
end;

procedure TMain.HomeBtnClick(Sender: TObject);
begin
  EdgeBrowser.Navigate(MainURL);
end;

procedure TMain.LeftBtnClick(Sender: TObject);
begin
  EdgeBrowser.GoBack;
end;

procedure TMain.RefreshBtnClick(Sender: TObject);
begin
  EdgeBrowser.Refresh;
end;

procedure TMain.RightBtnClick(Sender: TObject);
begin
  EdgeBrowser.GoForward;
end;

procedure TMain.RotateDeviceBtnClick(Sender: TObject);
var
  TempWidth: integer;
begin
  if WindowState = wsMaximized then Exit;
  TempWidth:=Main.ClientWidth;
  Main.ClientWidth:=Main.ClientHeight - DebugPanel.Height;
  Main.ClientHeight:=TempWidth + DebugPanel.Height;
  WindowToCenter;
end;

procedure TMain.SetDeviceBtnClick(Sender: TObject);
var
  ResolutionStr: string; ZoomValue: real;
begin
  if DevicesCB.ItemIndex = -1 then Exit;

  if WindowState = wsMaximized then
    WindowState:=wsNormal;

  ZoomValue:=StrToIntDef(Copy(ZoomCB.Items.Strings[ZoomCB.ItemIndex], 1, Length(ZoomCB.Items.Strings[ZoomCB.ItemIndex]) - 1), 100) * 0.01;
  EdgeBrowser.ExecuteScript('document.body.style.transform = "scale(' + StringReplace(FloatToStr(ZoomValue), ',', '.', []) + ')";' +
                            'document.body.style.transformOrigin = "0 0";');

  ResolutionStr:=DevicesCB.Items[DevicesCB.ItemIndex];
  ResolutionStr:=Copy(ResolutionStr, Pos('(', ResolutionStr) + 1, Length(ResolutionStr));
  ResolutionStr:=Copy(ResolutionStr, 1, Pos(')', ResolutionStr) - 1);

  ClientWidth:=Trunc(StrToIntDef(Copy(ResolutionStr, 1, Pos('x', ResolutionStr) - 1), 640) * ZoomValue);
  ClientHeight:=Trunc((StrToIntDef(Copy(ResolutionStr, Pos('x', ResolutionStr) + 1, Length(ResolutionStr)), 480) + DebugPanel.Height) * ZoomValue);

  WindowToCenter;
end;

procedure TMain.UserAgentsCBChange(Sender: TObject);
begin
  if UserAgentsCB.ItemIndex = -1 then Exit;
  UserAgentsCBChanged:=true;
  UserAgentsCB.Hint:=UserAgentsCB.Items.Strings[UserAgentsCB.ItemIndex];
  Sleep(15);
  EdgeBrowser.Refresh;
end;

end.
