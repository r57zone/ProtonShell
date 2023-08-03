object Main: TMain
  Left = 0
  Top = 0
  Caption = 'Main'
  ClientHeight = 468
  ClientWidth = 796
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poDefault
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 13
  object EdgeBrowser: TEdgeBrowser
    Left = 0
    Top = 0
    Width = 796
    Height = 468
    Align = alClient
    TabOrder = 0
    UserDataFolder = '%LOCALAPPDATA%\bds.exe.WebView2'
    OnCreateWebViewCompleted = EdgeBrowserCreateWebViewCompleted
  end
end
