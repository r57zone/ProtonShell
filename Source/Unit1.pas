unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, WebView2, Winapi.ActiveX, Vcl.Edge, IniFiles, ShellAPI,
  Registry, WinInet, Vcl.StdCtrls, Vcl.ExtCtrls, System.JSON, Vcl.Clipbrd, ShlObj;

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
    procedure SendWebMessage(const AID: string; AOk: Boolean; const AResult, AError: string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;
  WinOldWidth, WinOldHeight, WinOldTop, WinOldLeft, WinOldState: integer;
  WinSaveSize, WinSavePos, WinSaveState, ReturnPrevSystemProxy, UserAgentsCBChanged: boolean;
  AppPath, MainURL, EdgeUserAgent, NewUserAgent, SystemProxy, PrevSystemProxy, ConfigFile: string;
  OpenExternalLinks, LoadUserScript: boolean;
  ZoomDefault: integer;
  UserScriptFile: TStringList;

  IDS_CONFIRM_DELETE_ALL_DATA, IDS_RESOLUTION: string;

  SavedBorderStyle: TFormBorderStyle;
  SavedWindowState: TWindowState;
  Fullscreen: boolean;

implementation

{$R *.dfm}

function FixPathOrig(Path: string): string;
begin
  if (Length(Path) > 0) and (Path[2] <> ':') then
    Path:=AppPath + Path;

  if (Length(Path) > 2) and (Path[Length(Path)] = '\') and (Path[Length(Path) - 1] = '\') then
    Path:=Copy(Path, 1, Length(Path) - 1);

  Result:=Path;
end;

function FixPath(Path: string): string;
begin
  // Если путь относительный, добавляем папку ProtonShell
  // Пути вида C:\... оставляем без изменений
  if (Length(Path) > 1) and (Path[2] <> ':') then
    Path:=AppPath + Path;

  // Убираем лишний обратный слеш в конце пути.
  if (Length(Path) > 2) and
     (Path[Length(Path)] = '\') and
     (Path[Length(Path) - 1] = '\') then
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

  if ZoomDefault <> 100 then
    EdgeBrowser.ExecuteScript('document.body.style.transform = "scale(' + StringReplace(FloatToStr(ZoomDefault * 0.01), ',', '.', []) + ')";' +
                              'document.body.style.transformOrigin = "0 0";');

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

function IsURL(const Value: string): Boolean;
begin
  Result:=
    (Pos('://', Value) > 0) or
    (Pos('mailto:', LowerCase(Value)) = 1) or
    (Pos('tel:', LowerCase(Value)) = 1);
end;

function JavaScriptString(const S: string): string;
begin
  Result:=S;

  Result:=StringReplace(Result, '\', '\\', [rfReplaceAll]);
  Result:=StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result:=StringReplace(Result, #8, '\b', [rfReplaceAll]);
  Result:=StringReplace(Result, #9, '\t', [rfReplaceAll]);
  Result:=StringReplace(Result, #10, '\n', [rfReplaceAll]);
  Result:=StringReplace(Result, #12, '\f', [rfReplaceAll]);
  Result:=StringReplace(Result, #13, '\r', [rfReplaceAll]);

  // Защита от специальных Unicode-разделителей JavaScript
  Result:=StringReplace(Result, #$2028, '\u2028', [rfReplaceAll]);
  Result:=StringReplace(Result, #$2029, '\u2029', [rfReplaceAll]);
end;

function BrowseFolderDialog(Title: PChar; Flags: Cardinal): string;
var
  TitleName: string;
  lpItemid: pItemIdList;
  BrowseInfo: TBrowseInfo;
  DisplayName: array[0..MAX_PATH] of Char;
  TempPath: array[0..MAX_PATH] of Char;
begin
  FillChar(BrowseInfo, SizeOf(TBrowseInfo), #0);
  BrowseInfo.hwndOwner:=GetDesktopWindow;
  BrowseInfo.pSzDisplayName:=@DisplayName;
  TitleName:=Title;
  BrowseInfo.lpSzTitle:=PChar(TitleName);
  BrowseInfo.ulFlags:=Flags; // BIF_RETURNONLYFSDIRS
  lpItemId:=shBrowseForFolder(BrowseInfo);
  if lpItemId <> nil then begin
    shGetPathFromIdList(lpItemId, TempPath);
    Result:=TempPath;
    GlobalFreePtr(lpItemId);
  end;
end;

procedure TMain.SendWebMessage(const AID: string; AOk: Boolean;
  const AResult, AError: string);
var
  Response: TJSONObject;
  ResultJSON: TJSONValue;
  Script: string;
begin
  Response:=TJSONObject.Create;
  try

    if AID <> '' then
      Response.AddPair('id', AID);

    Response.AddPair('ok', TJSONBool.Create(AOk));

    if AOk then begin

      if AResult <> '' then begin
        ResultJSON:=TJSONObject.ParseJSONValue(AResult);

        if Assigned(ResultJSON) then
          Response.AddPair('result', ResultJSON);
      end;

    end else
      Response.AddPair('error', AError);

    Script:=
      'handleMessageFromHost("' +
      JavaScriptString(Response.ToString) +
      '");';

    EdgeBrowser.ExecuteScript(Script);

  finally
    Response.Free;
  end;
end;

procedure TMain.EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser;
  Args: TWebMessageReceivedEventArgs);
var
  CommandP: PChar;
  CommandStr: string;
  Request, Data, Response: TJSONObject;
  ID, Command, Path, Text, Arguments, Title: string;
  Items: TJSONArray;
  SR: TSearchRec;
  OpenDialog: TOpenDialog;
  SaveDialog: TSaveDialog;
  ResultJSON: TJSONValue;
  AllowCreateFolder: boolean;
begin
  CommandP:=nil;

  Args.ArgsInterface.TryGetWebMessageAsString(CommandP);

  if CommandP = nil then
    Exit;

  CommandStr:=CommandP;
  try
    CoTaskMemFree(CommandP);
  except
  end;

  { Parse request }
  Request:=TJSONObject.ParseJSONValue(CommandStr) as TJSONObject;
  if not Assigned(Request) then
    Exit;

  try
    ID:='';
    if Request.GetValue('id') <> nil then
      ID:=Request.GetValue('id').Value;

    Command:='';
    if Request.GetValue('cmd') <> nil then
      Command:=Request.GetValue('cmd').Value;

    if Command = '' then begin
      SendWebMessage(ID, false, '', 'Command is missing');
      Exit;
    end;

    Data:=Request.GetValue('data') as TJSONObject;

    // App
    if Command = 'app.close' then begin
      Close;
      Exit;
    end;

    if Command = 'app.fullscreen' then begin
      if not Fullscreen then begin
        SavedBorderStyle:=BorderStyle;
        SavedWindowState:=WindowState;
        Fullscreen:=true;
      end;
      BorderStyle:=bsNone;
      WindowState:=wsMaximized;
      SendWebMessage(ID, true, '{"fullscreen":true}', '');
      Exit;
    end;

    if Command = 'app.restore' then begin
      if Fullscreen then begin
        WindowState:=SavedWindowState;
        BorderStyle:=SavedBorderStyle;
        Fullscreen:=false;
      end;
      SendWebMessage(ID, true, '{"fullscreen":false}', '');
      Exit;
    end;

    if Command = 'app.setTitle' then begin
      if not Assigned(Data) then begin
        SendWebMessage(ID, false, '', 'Data is missing');
        Exit;
      end;

      if Data.GetValue('title') = nil then begin
        SendWebMessage(ID, false, '', 'Title is missing');
        Exit;
      end;

      Title:=Data.GetValue('title').Value;
      Caption:=Title;
      SendWebMessage(ID, true, '{"title":"' + JavaScriptString(Title) + '"}', '');
      Exit;
    end;

    // System
    if Command = 'system.open' then begin
      if not Assigned(Data) then begin
        SendWebMessage(ID, false, '', 'Data is missing');
        Exit;
      end;

      if Data.GetValue('path') = nil then begin
        SendWebMessage(ID, false, '', 'Path is missing');
        Exit;
      end;

      Path:=Data.GetValue('path').Value;
      Arguments:='';

      if Data.GetValue('args') <> nil then
        Arguments:=Data.GetValue('args').Value;

      // URL не должен проходить через FixPath
      if not IsURL(Path) then
        Path:=FixPath(Path);

      if ShellExecute(0, 'open', PChar(Path), PChar(Arguments), nil, SW_SHOWNORMAL) <=32 then
        SendWebMessage(ID, false, '', 'Unable to open: ' + Path)
      else
        SendWebMessage(ID, true, '{"opened":true}', '');

      Exit;
    end;

    // File
    if Command = 'file.exists' then begin
      if not Assigned(Data) then begin
        SendWebMessage(ID, false, '', 'Data is missing');
        Exit;
      end;

      if Data.GetValue('path') = nil then begin
        SendWebMessage(ID, false, '', 'Path is missing');
        Exit;
      end;

      Path:=FixPath(Data.GetValue('path').Value);
      SendWebMessage(ID, true, '{"exists":' + LowerCase(BoolToStr(FileExists(Path),True)) + '}', '');
      Exit;
    end;

    if Command = 'file.delete' then begin
      if not Assigned(Data) then begin
        SendWebMessage(ID, false, '', 'Data is missing');
        Exit;
      end;

      if Data.GetValue('path') = nil then begin
        SendWebMessage(ID, false, '' ,'Path is missing');
        Exit;
      end;

      Path:=FixPath(Data.GetValue('path').Value);

      if not FileExists(Path) then begin
        SendWebMessage(ID, false, '', 'File not found');
        Exit;
      end;

      if DeleteFile(Path) then
        SendWebMessage(ID, true, '{"deleted":true}', '')
      else
        SendWebMessage(ID, false, '', 'Unable to delete file');

      Exit;
    end;

    if Command = 'file.writeText' then begin
      if not Assigned(Data) then begin
        SendWebMessage(ID, false, '', 'Data is missing');
        Exit;
      end;

      if Data.GetValue('path') = nil then begin
        SendWebMessage(ID, false, '', 'Path is missing');
        Exit;
      end;

      if Data.GetValue('text') = nil then begin
        SendWebMessage(ID, false, '', 'Text is missing');
        Exit;
      end;

      Path:=FixPath(Data.GetValue('path').Value);
      Text:=Data.GetValue('text').Value;

      try
        with TStringList.Create do
        try
          Text:=StringReplace(Text, #13#10, #10, [rfReplaceAll]);
          Text:=StringReplace(Text, #10, sLineBreak, [rfReplaceAll]);
          Add(Text);
          SaveToFile(Path, TEncoding.UTF8);
        finally
          Free;
        end;

        SendWebMessage(ID, true, '{"written":true}', '');
      except
        on E: Exception do
          SendWebMessage(ID, false, '', E.Message);
      end;

      Exit;
    end;

    if Command = 'file.readText' then begin
      if not Assigned(Data) then begin
        SendWebMessage(ID, false, '', 'Data is missing');
        Exit;
      end;

      if Data.GetValue('path') = nil then begin
        SendWebMessage(ID, false, '', 'Path is missing');
        Exit;
      end;

      Path:=FixPath(Data.GetValue('path').Value);

      if not FileExists(Path) then begin
        SendWebMessage(ID, false, '', 'File not found');
        Exit;
      end;

      try
        with TStringList.Create do
        try
          LoadFromFile(Path, TEncoding.UTF8);
          Text:=Self.Text;
        finally
          Free;
        end;

        Response:=TJSONObject.Create;
        try
          Response.AddPair('text',Text);
          SendWebMessage(ID, true, Response.ToString, '');
        finally
          Response.Free;
        end;
      except
        on E: Exception do
          SendWebMessage(ID, false, '', E.Message);
      end;

      Exit;
    end;

    // Folder
    if Command = 'folder.exists' then begin
      if not Assigned(Data) then begin
        SendWebMessage(ID, false, '', 'Data is missing');
        Exit;
      end;

      if Data.GetValue('path') = nil then begin
        SendWebMessage(ID, false, '', 'Path is missing');
        Exit;
      end;

      Path:=FixPath(Data.GetValue('path').Value);
      SendWebMessage(ID, true, '{"exists":' + LowerCase(BoolToStr(DirectoryExists(Path),True)) + '}', '');
      Exit;
    end;

    if Command = 'folder.create' then begin
      if not Assigned(Data) then begin
        SendWebMessage(ID, false, '','Data is missing');
        Exit;
      end;

      if Data.GetValue('path') = nil then begin
        SendWebMessage(ID, false, '', 'Path is missing');
        Exit;
      end;

      Path:=FixPath(Data.GetValue('path').Value);

      if DirectoryExists(Path) then begin
        SendWebMessage(ID, true, '{"created":false,"exists":true}', '');
        Exit;
      end;

      if ForceDirectories(Path) then
        SendWebMessage(ID, true, '{"created":true}', '')
      else
        SendWebMessage(ID, false, '', 'Unable to create folder');

      Exit;
    end;

    if Command = 'folder.delete' then begin
      if not Assigned(Data) then begin
        SendWebMessage(ID, false, '', 'Data is missing');
        Exit;
      end;

      if Data.GetValue('path') = nil then begin
        SendWebMessage(ID, false, '', 'Path is missing');
        Exit;
      end;

      Path:=FixPath(Data.GetValue('path').Value);

      if not DirectoryExists(Path) then begin
        SendWebMessage(ID, false, '', 'Folder not found');
        Exit;
      end;

      if RemoveDir(Path) then
        SendWebMessage(ID, true, '{"deleted":true}', '')
      else
        SendWebMessage(ID, false, '', 'Unable to delete folder. Folder may not be empty.');

      Exit;
    end;

    if Command = 'folder.list' then begin
      if not Assigned(Data) then begin
        SendWebMessage(ID, false, '', 'Data is missing');
        Exit;
      end;

      if Data.GetValue('path') = nil then begin
        SendWebMessage(ID, false, '', 'Path is missing');
        Exit;
      end;

      Path:=FixPath(Data.GetValue('path').Value);

      if not DirectoryExists(Path) then begin
        SendWebMessage(ID, false, '', 'Folder not found');
        Exit;
      end;

      Items:=TJSONArray.Create;
      try
        if FindFirst(IncludeTrailingPathDelimiter(Path) + '*.*', faAnyFile, SR) = 0 then
        try
          repeat
            if (SR.Name = '.') or (SR.Name = '..') then
              Continue;

            Response:=TJSONObject.Create;
            Response.AddPair('name', SR.Name);

            if (SR.Attr and faDirectory) <> 0 then begin
              Response.AddPair('type', 'folder');
              Response.AddPair('size', TJSONNumber.Create(0));
              Response.AddPair('path', IncludeTrailingPathDelimiter(Path) + SR.Name);
            end else begin
              Response.AddPair('type', 'file');
              Response.AddPair('size', TJSONNumber.Create(Int64(SR.Size)));
              Response.AddPair('path', IncludeTrailingPathDelimiter(Path) + SR.Name);
            end;

            Response.AddPair('modified', FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', FileDateToDateTime(SR.Time)));

            Items.AddElement(Response);
          until FindNext(SR) <> 0;
        finally
          FindClose(SR);
        end;

        Response:=TJSONObject.Create;
        try
          Response.AddPair('items', Items);
          Items:=nil;
          SendWebMessage(ID, true, Response.ToString, '');
        finally
          Response.Free;
        end;
      finally
        Items.Free;
      end;

      Exit;
    end;

    // Clipboard
    if Command = 'clipboard.get' then begin
      Text:=Clipboard.AsText;
      Response:=TJSONObject.Create;
      try
        Response.AddPair('text', Text);
        SendWebMessage(ID, true, Response.ToString, '');
      finally
        Response.Free;
      end;
      Exit;
    end;

    if Command = 'clipboard.set' then begin
      if not Assigned(Data) then begin
        SendWebMessage(ID, false, '', 'Data is missing');
        Exit;
      end;

      if Data.GetValue('text') = nil then begin
        SendWebMessage(ID, false, '', 'Text is missing');
        Exit;
      end;

      Text:=Data.GetValue('text').Value;
      Clipboard.AsText:=Text;
      SendWebMessage(ID, true, '{"set":true}', '');
      Exit;
    end;

    // Dialog
    if Command = 'dialog.openFile' then begin
      OpenDialog:=TOpenDialog.Create(Self);
      try
        OpenDialog.Options:=OpenDialog.Options + [ofFileMustExist];

        if Assigned(Data) then begin
          if Data.GetValue('title') <> nil then
            OpenDialog.Title:=Data.GetValue('title').Value;

          if Data.GetValue('filter') <> nil then
            OpenDialog.Filter:=Data.GetValue('filter').Value;

          if Data.GetValue('defaultPath') <> nil then
            OpenDialog.InitialDir:=FixPath(Data.GetValue('defaultPath').Value);
        end;

        if OpenDialog.Execute then begin
          Response:=TJSONObject.Create;
          try
            Response.AddPair('path', OpenDialog.FileName);
            SendWebMessage(ID, true, Response.ToString, '');
          finally
            Response.Free;
          end;
        end else
          SendWebMessage(ID, true, '{"cancelled":true}', '');
      finally
        OpenDialog.Free;
      end;

      Exit;
    end;

    if Command='dialog.saveFile' then begin
      SaveDialog:=TSaveDialog.Create(Self);
      try
        if Assigned(Data) then begin
          if Data.GetValue('title') <> nil then
            SaveDialog.Title:=Data.GetValue('title').Value;

          if Data.GetValue('filter') <> nil then
            SaveDialog.Filter:=Data.GetValue('filter').Value;

          if Data.GetValue('defaultPath') <> nil then
            SaveDialog.InitialDir:=FixPath(Data.GetValue('defaultPath').Value);
        end;

        if SaveDialog.Execute then begin
          Response:=TJSONObject.Create;
          try
            Response.AddPair('path', SaveDialog.FileName);
            SendWebMessage(ID, true, Response.ToString, '');
          finally
            Response.Free;
          end;
        end else
          SendWebMessage(ID, true, '{"cancelled":true}', '');
      finally
        SaveDialog.Free;
      end;

      Exit;
    end;

    if Command = 'dialog.selectFolder' then begin
      AllowCreateFolder:=false;
      try
        if Assigned(Data) then begin
          if Data.GetValue('title') <> nil then
            Title:=Data.GetValue('title').Value;

          if (Data.GetValue('allowCreateFolder') <> nil) and (SameText(Data.GetValue('allowCreateFolder').Value, 'true')) then
            AllowCreateFolder:=true;
        end;


      except
      end;

      if AllowCreateFolder = false then
        Path:=BrowseFolderDialog(PChar(Title), BIF_RETURNONLYFSDIRS)
      else
        Path:=BrowseFolderDialog(PChar(Title), BIF_RETURNONLYFSDIRS or BIF_USENEWUI);

      if Path = '' then begin SendWebMessage(ID, true, '{"cancelled":true}', ''); Exit; end;

      if Path[Length(Path)] <> '\' then Path:=Path + '\';

      Response:=TJSONObject.Create;
      try
        Response.AddPair('path', Path);
        SendWebMessage(ID, true, Response.ToString, '');
      finally
        Response.Free;
      end;

      Exit;
    end;

    { Unknown command }
    SendWebMessage(ID, false, '', 'Unknown command: ' + Command);
  finally
    Request.Free;
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
      Ini:=TIniFile.Create(AppPath + 'Config.ini');
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
  ChangePosition, DebugeMode, IsFullscreen: boolean;
  WND: HWND;
begin
  EdgeUserAgent:='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36 Edg/152.0.0.0';
  AppPath:=ExtractFilePath(ParamStr(0));
  WindowBorderStyle:=1;
  IsFullscreen:=false;
  WinSavePos:=false;
  WinSaveState:=false;

  EdgeBrowser.UserDataFolder:=AppPath + 'Data';

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
  //CustomConfig:=false;
  for i:=0 to ParamCount - 1 do
    if (AnsiLowerCase(ParamStr(i)) = '-c') and (Trim(ParamStr(i + 1)) <> '') and (FileExists(ParamStr(i + 1))) then begin
      ConfigFile:=ParamStr(i + 1);
      //CustomConfig:=true;
    end;

  //if (CustomConfig) then begin //(ParamCount = 0) or

  // Config parameters
  Ini:=TIniFile.Create(AppPath + ConfigFile);
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

  ZoomDefault:=Ini.ReadInteger('Main', 'Zoom', 100);

  // System proxy
  ReturnPrevSystemProxy:=Ini.ReadBool('Main', 'ReturnPreviousProxy', false);
  SystemProxy:=Trim(Ini.ReadString('Main', 'SystemProxy', ''));

  // Debug mode
  DebugeMode:=Ini.ReadBool('Main', 'Debug', false);

  Ini.Free;

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

    if i + 1 > ParamCount then break;
    if ParamStrLower = '-f' then begin LocalFile:=ParamStr(i + 1); WebAddress:=''; end;
    if ParamStrLower = '-a' then begin LocalFile:=''; WebAddress:=ParamStr(i + 1); end;
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
    LocalFile:=AppPath + LocalFile;

  //ShowMessage('Local file: "' + LocalFile + '", Web: "' + WebAddress + '"') ;

  // Applying parameters
  // Address
  if LocalFile <> '' then
    MainURL:=LocalFile
  else
    MainURL:=WebAddress;
  EdgeBrowser.Navigate(MainURL);

  // System proxy
  if SystemProxy <> '' then begin
    WND:=FindWindow('TMain', PChar(Main.Caption));
    if WND = 0 then begin
      SetProxy(SystemProxy);
      ProxyActivate(true);
    end;
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
    if FileExists(AppPath + 'DevicesList.txt') then begin
      DevicesCB.Items.LoadFromFile(AppPath + 'DevicesList.txt', TEncoding.UTF8);
      if DevicesCB.Items.Count > 0 then
        DevicesCB.ItemIndex:=0;
    end;

    if FileExists(AppPath + 'UserAgentsList.txt') then begin
      UserAgentsCB.Items.LoadFromFile(AppPath + 'UserAgentsList.txt', TEncoding.UTF8);
      if UserAgentsCB.Items.Count > 0 then
        UserAgentsCB.ItemIndex:=0;
    end;
  end;
end;

procedure TMain.FormDestroy(Sender: TObject);
var
  WND: HWND;
begin
  if SystemProxy <> '' then begin
    WND:=FindWindow('TMain', PChar(Main.Caption));
    if WND = 0 then begin
      if ReturnPrevSystemProxy then begin
        SetProxy(PrevSystemProxy);
        ProxyActivate(true);
      end else if SystemProxy <> '' then
        ProxyActivate(false);
    end;
  end;
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
