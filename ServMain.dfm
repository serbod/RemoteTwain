object frmSrvMain: TfrmSrvMain
  Left = 637
  Top = 293
  Width = 311
  Height = 393
  Caption = 'Remote TWAIN Server'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMinimized
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pcMain: TPageControl
    Left = 0
    Top = 0
    Width = 303
    Height = 359
    ActivePage = tsOptions
    Align = alClient
    TabOrder = 0
    object tsDebug: TTabSheet
      Caption = 'Debug'
      object memoDebug: TMemo
        Left = 8
        Top = 8
        Width = 281
        Height = 313
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    object tsPreview: TTabSheet
      Caption = 'Preview'
      ImageIndex = 1
      object imgPreview: TImage
        Left = 0
        Top = 0
        Width = 295
        Height = 331
        Align = alClient
        Proportional = True
        Stretch = True
      end
    end
    object tsOptions: TTabSheet
      Caption = 'Options'
      ImageIndex = 2
      object lbScanner: TLabel
        Left = 8
        Top = 8
        Width = 40
        Height = 13
        Caption = 'Scanner'
      end
      object lbUnits: TLabel
        Left = 176
        Top = 72
        Width = 24
        Height = 13
        Caption = 'Units'
      end
      object lbColorMode: TLabel
        Left = 8
        Top = 72
        Width = 53
        Height = 13
        Caption = 'Color mode'
      end
      object lbResolution: TLabel
        Left = 8
        Top = 120
        Width = 50
        Height = 13
        Caption = 'Resolution'
      end
      object lbFormat: TLabel
        Left = 8
        Top = 160
        Width = 64
        Height = 13
        Caption = 'Output format'
      end
      object cbbScanner: TComboBox
        Left = 8
        Top = 24
        Width = 281
        Height = 21
        ItemHeight = 13
        TabOrder = 0
        OnSelect = cbbScannerSelect
      end
      object btnPreview: TButton
        Left = 8
        Top = 296
        Width = 75
        Height = 25
        Caption = 'Preview'
        TabOrder = 1
        OnClick = btnPreviewClick
      end
      object cbbUnits: TComboBox
        Left = 176
        Top = 88
        Width = 113
        Height = 21
        ItemHeight = 13
        TabOrder = 2
      end
      object cbbColorMode: TComboBox
        Left = 8
        Top = 88
        Width = 145
        Height = 21
        ItemHeight = 13
        TabOrder = 3
      end
      object cbbResolution: TComboBox
        Left = 8
        Top = 136
        Width = 145
        Height = 21
        ItemHeight = 13
        TabOrder = 4
      end
      object cbbFormat: TComboBox
        Left = 8
        Top = 176
        Width = 145
        Height = 21
        ItemHeight = 13
        TabOrder = 5
        OnChange = cbbFormatChange
      end
      object btnScan: TButton
        Left = 160
        Top = 296
        Width = 75
        Height = 25
        Caption = 'Scan'
        TabOrder = 6
        OnClick = btnScanClick
      end
    end
    object tsAbout: TTabSheet
      Caption = 'About'
      ImageIndex = 3
      object lb1: TLabel
        Left = 16
        Top = 128
        Width = 188
        Height = 13
        Caption = 'Thanks to Gustavo Huffenbacher Daud'
      end
      object lb2: TLabel
        Left = 16
        Top = 16
        Width = 110
        Height = 13
        Caption = 'Remote TWAIN Server'
      end
      object lb3: TLabel
        Left = 16
        Top = 32
        Width = 100
        Height = 13
        Caption = 'Sergey Bodrov, 2009'
      end
    end
  end
  object idTcpSrv: TIdTCPServer
    Bindings = <>
    CommandHandlers = <>
    DefaultPort = 4040
    Greeting.NumericCode = 0
    MaxConnectionReply.NumericCode = 0
    OnConnect = idTcpSrvConnect
    OnExecute = idTcpSrvExecute
    OnDisconnect = idTcpSrvDisconnect
    ReplyExceptionCode = 0
    ReplyTexts = <>
    ReplyUnknownCommand.NumericCode = 0
    ThreadMgr = idThrdMgr
    Left = 40
    Top = 64
  end
  object idThrdMgr: TIdThreadMgrDefault
    Left = 104
    Top = 64
  end
  object AppEvents: TApplicationEvents
    OnException = AppEventsException
    Left = 36
    Top = 128
  end
  object pmTrayMenu: TPopupMenu
    Left = 100
    Top = 128
    object mniExit: TMenuItem
      Caption = 'Exit'
      OnClick = mniExitClick
    end
  end
end
