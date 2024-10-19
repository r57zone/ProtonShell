object Main: TMain
  Left = 0
  Top = 0
  Caption = 'Main'
  ClientHeight = 480
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poDefault
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  TextHeight = 13
  object EdgeBrowser: TEdgeBrowser
    Left = 0
    Top = 113
    Width = 640
    Height = 367
    Align = alClient
    TabOrder = 0
    UserDataFolder = '%LOCALAPPDATA%\bds.exe.WebView2'
    OnCreateWebViewCompleted = EdgeBrowserCreateWebViewCompleted
    OnNavigationCompleted = EdgeBrowserNavigationCompleted
    OnNewWindowRequested = EdgeBrowserNewWindowRequested
    OnWebMessageReceived = EdgeBrowserWebMessageReceived
    ExplicitWidth = 636
    ExplicitHeight = 366
  end
  object DebugPanel: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 113
    Align = alTop
    TabOrder = 1
    Visible = False
    ExplicitWidth = 636
    object PanelTools: TPanel
      Left = 183
      Top = 0
      Width = 288
      Height = 113
      BevelOuter = bvNone
      TabOrder = 0
      object ResolutionLbl: TLabel
        Left = 9
        Top = 93
        Width = 75
        Height = 13
        Caption = 'Resolution: 0x0'
      end
      object LeftBtn: TButton
        Left = 7
        Top = 7
        Width = 25
        Height = 25
        Caption = #8592
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = LeftBtnClick
      end
      object RightBtn: TButton
        Left = 37
        Top = 7
        Width = 25
        Height = 25
        Caption = #8594
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = RightBtnClick
      end
      object RefreshBtn: TButton
        Left = 67
        Top = 7
        Width = 25
        Height = 25
        Caption = #8635
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = RefreshBtnClick
      end
      object HomeBtn: TButton
        Left = 97
        Top = 7
        Width = 25
        Height = 25
        Caption = #55356#57312
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = False
        TabOrder = 3
        OnClick = HomeBtnClick
      end
      object ClearBtn: TButton
        Left = 127
        Top = 7
        Width = 25
        Height = 25
        Caption = #55357#56785#65039
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 4
        OnClick = ClearBtnClick
      end
      object SetDeviceBtn: TButton
        Left = 226
        Top = 7
        Width = 25
        Height = 25
        Caption = #55357#56561
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 5
        OnClick = SetDeviceBtnClick
      end
      object RotateDeviceBtn: TButton
        Left = 256
        Top = 7
        Width = 25
        Height = 25
        Caption = #8634
        ParentShowHint = False
        ShowHint = True
        TabOrder = 6
        OnClick = RotateDeviceBtnClick
      end
      object DevicesCB: TComboBox
        Left = 8
        Top = 38
        Width = 212
        Height = 21
        Style = csDropDownList
        ParentShowHint = False
        ShowHint = True
        TabOrder = 7
        OnChange = DevicesCBChange
      end
      object ZoomCB: TComboBox
        Left = 227
        Top = 38
        Width = 53
        Height = 21
        Style = csDropDownList
        ItemIndex = 7
        TabOrder = 8
        Text = '100%'
        Items.Strings = (
          '30%'
          '40%'
          '50%'
          '60%'
          '70%'
          '80%'
          '90%'
          '100%'
          '125%'
          '150%'
          '175%'
          '200%')
      end
      object UserAgentsCB: TComboBox
        Left = 8
        Top = 66
        Width = 272
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        ParentShowHint = False
        ShowHint = True
        TabOrder = 9
        Text = 'Default User Agent'
        OnChange = UserAgentsCBChange
        Items.Strings = (
          'Default User Agent')
      end
    end
  end
end
