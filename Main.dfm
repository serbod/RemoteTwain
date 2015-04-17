object frmMain: TfrmMain
  Left = 421
  Top = 201
  Width = 631
  Height = 500
  Caption = 'Remote TWAIN client'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object spl1: TSplitter
    Left = 289
    Top = 0
    Height = 466
  end
  object grpPreview: TGroupBox
    Left = 292
    Top = 0
    Width = 331
    Height = 466
    Align = alClient
    Caption = #1055#1088#1077#1076#1087#1088#1086#1089#1084#1086#1090#1088
    TabOrder = 0
    object imgPreview: TImage
      Left = 2
      Top = 15
      Width = 327
      Height = 408
      Align = alClient
      Center = True
      PopupMenu = pmImagePopup
      Proportional = True
      Stretch = True
    end
    object panButtons: TPanel
      Left = 2
      Top = 423
      Width = 327
      Height = 41
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
      object btnToClipboard: TButton
        Left = 8
        Top = 8
        Width = 105
        Height = 25
        Caption = #1042' '#1073#1091#1092#1077#1088' '#1086#1073#1084#1077#1085#1072
        TabOrder = 0
        OnClick = mCopyClick
      end
      object btnToFile: TButton
        Left = 120
        Top = 8
        Width = 97
        Height = 25
        Caption = #1042' '#1092#1072#1081#1083
        TabOrder = 1
        OnClick = mSaveAsClick
      end
      object btnToPrinter: TButton
        Left = 224
        Top = 8
        Width = 97
        Height = 25
        Caption = #1053#1072' '#1087#1077#1095#1072#1090#1100
        TabOrder = 2
        OnClick = mPrintClick
      end
    end
  end
  object pgcMain: TPageControl
    Left = 0
    Top = 0
    Width = 289
    Height = 466
    ActivePage = tsScaner
    Align = alLeft
    TabOrder = 1
    object tsScaner: TTabSheet
      Caption = 'Scaner'
      object grpScanner: TGroupBox
        Left = 0
        Top = 0
        Width = 281
        Height = 438
        Align = alClient
        Caption = #1057#1082#1072#1085#1077#1088
        PopupMenu = pmDebug
        TabOrder = 0
        object lbScannerSel: TLabel
          Left = 16
          Top = 56
          Width = 37
          Height = 13
          Caption = #1057#1082#1072#1085#1077#1088
        end
        object lbResolutionSel: TLabel
          Left = 8
          Top = 104
          Width = 139
          Height = 13
          Caption = #1044#1077#1090#1072#1083#1080#1079#1072#1094#1080#1103' ('#1088#1072#1079#1088#1077#1096#1077#1085#1080#1077')'
        end
        object lbColorModeSel: TLabel
          Left = 8
          Top = 144
          Width = 54
          Height = 13
          Caption = #1062#1074#1077#1090#1085#1086#1089#1090#1100
        end
        object lbUnits: TLabel
          Left = 168
          Top = 104
          Width = 45
          Height = 13
          Caption = #1045#1076#1080#1085#1080#1094#1099
        end
        object lbServerName: TLabel
          Left = 16
          Top = 16
          Width = 120
          Height = 13
          Caption = #1057#1077#1090#1077#1074#1086#1081' '#1072#1076#1088#1077#1089' '#1089#1082#1072#1085#1077#1088#1072
        end
        object lbStatus: TLabel
          Left = 8
          Top = 376
          Width = 257
          Height = 17
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGreen
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lbFormat: TLabel
          Left = 8
          Top = 208
          Width = 148
          Height = 13
          Caption = #1060#1086#1088#1084#1072#1090' '#1092#1072#1081#1083#1072' '#1080#1079#1086#1073#1088#1072#1078#1077#1085#1080#1103
        end
        object lbFileSavePath: TLabel
          Left = 8
          Top = 256
          Width = 187
          Height = 13
          Caption = #1050#1091#1076#1072' '#1089#1086#1093#1088#1072#1085#1103#1090#1100' '#1092#1072#1081#1083#1099' '#1080#1079#1086#1073#1088#1072#1078#1077#1085#1080#1081
        end
        object cbbScanner: TComboBox
          Left = 8
          Top = 72
          Width = 249
          Height = 21
          ItemHeight = 13
          TabOrder = 0
          OnSelect = cbbScannerSelect
        end
        object cbbResolution: TComboBox
          Left = 8
          Top = 120
          Width = 145
          Height = 21
          ItemHeight = 13
          TabOrder = 1
        end
        object btnPreview: TBitBtn
          Left = 8
          Top = 400
          Width = 105
          Height = 25
          Caption = #1055#1088#1077#1076#1087#1088#1086#1089#1084#1086#1090#1088
          TabOrder = 2
          OnClick = btnPreviewClick
        end
        object btnScan: TBitBtn
          Left = 152
          Top = 400
          Width = 105
          Height = 25
          Caption = #1057#1082#1072#1085#1080#1088#1086#1074#1072#1090#1100
          TabOrder = 3
          OnClick = btnScanClick
        end
        object cbbColorMode: TComboBox
          Left = 8
          Top = 160
          Width = 145
          Height = 21
          ItemHeight = 13
          TabOrder = 4
        end
        object cbbUnits: TComboBox
          Left = 168
          Top = 120
          Width = 89
          Height = 21
          ItemHeight = 13
          TabOrder = 5
          OnSelect = cbbUnitsSelect
        end
        object cbbServerName: TComboBox
          Left = 8
          Top = 32
          Width = 249
          Height = 21
          ItemHeight = 13
          TabOrder = 6
          OnKeyDown = cbbServerNameKeyDown
          OnSelect = cbbServerNameSelect
          Items.Strings = (
            'localhost')
        end
        object cbbFormat: TComboBox
          Left = 8
          Top = 224
          Width = 145
          Height = 21
          ItemHeight = 13
          TabOrder = 7
        end
        object edFileSavePath: TEdit
          Left = 8
          Top = 272
          Width = 241
          Height = 21
          TabOrder = 8
        end
        object btnFileNameSelect: TButton
          Left = 252
          Top = 271
          Width = 20
          Height = 23
          Caption = '...'
          TabOrder = 9
        end
      end
    end
    object tsDebug: TTabSheet
      Caption = 'Debug'
      ImageIndex = 1
      object lbSupportedCaps: TLabel
        Left = 8
        Top = 32
        Width = 122
        Height = 13
        Caption = #1054#1090#1083#1072#1076#1086#1095#1085#1099#1077' '#1089#1086#1086#1073#1097#1077#1085#1080#1103
      end
      object lbCapList: TLabel
        Left = 8
        Top = 368
        Width = 53
        Height = 13
        Caption = 'Capabilities'
      end
      object lbCapType: TLabel
        Left = 176
        Top = 368
        Width = 42
        Height = 13
        Caption = 'Cap type'
      end
      object memoDebug: TMemo
        Left = 8
        Top = 56
        Width = 257
        Height = 305
        ScrollBars = ssVertical
        TabOrder = 0
      end
      object cbbCapList: TComboBox
        Left = 8
        Top = 384
        Width = 161
        Height = 21
        ItemHeight = 13
        TabOrder = 1
        OnSelect = cbbCapListSelect
      end
      object cbbCapType: TComboBox
        Left = 176
        Top = 384
        Width = 89
        Height = 21
        ItemHeight = 13
        TabOrder = 2
        Text = 'enum'
        Items.Strings = (
          'array'
          'enum'
          'range')
      end
    end
    object tsAbout: TTabSheet
      Caption = 'About'
      ImageIndex = 2
      object lb1: TLabel
        Left = 16
        Top = 32
        Width = 105
        Height = 13
        Caption = 'Remote TWAIN Client'
      end
      object lb2: TLabel
        Left = 16
        Top = 56
        Width = 115
        Height = 13
        Caption = 'By Sergey Bodrov, 2009'
      end
      object lb3: TLabel
        Left = 16
        Top = 104
        Width = 51
        Height = 13
        Caption = 'Thanks to:'
      end
      object lb4: TLabel
        Left = 16
        Top = 120
        Width = 137
        Height = 13
        Caption = 'Gustavo Huffenbacher Daud'
      end
    end
  end
  object dlgSavePic: TSavePictureDialog
    DefaultExt = 'bmp'
    FileName = 'pic00001'
    Left = 400
    Top = 352
  end
  object idTcpClient: TIdTCPClient
    MaxLineAction = maException
    OnDisconnected = idTcpClientDisconnected
    OnWork = idTcpClientWork
    OnWorkBegin = idTcpClientWorkBegin
    OnConnected = idTcpClientConnected
    Port = 4040
    Left = 336
    Top = 352
  end
  object pmDebug: TPopupMenu
    AutoHotkeys = maManual
    Left = 312
    Top = 224
    object mGetSources: TMenuItem
      Caption = 'GET_SOURCES'
      OnClick = pmDebugClick
    end
    object mGetSourceCap: TMenuItem
      Caption = 'GET_SOURCE_CAP'
      OnClick = pmDebugClick
    end
    object mScan: TMenuItem
      Caption = 'SCAN'
      OnClick = pmDebugClick
    end
    object mPreview: TMenuItem
      Caption = 'PREVIEW'
      OnClick = pmDebugClick
    end
  end
  object pmImagePopup: TPopupMenu
    Left = 388
    Top = 224
    object mSaveAs: TMenuItem
      Caption = 'Save As..'
      OnClick = mSaveAsClick
    end
    object mCopy: TMenuItem
      Caption = 'Copy to clipboard'
      OnClick = mCopyClick
    end
    object mPrint: TMenuItem
      Caption = 'Print'
      OnClick = mPrintClick
    end
  end
  object dlgPrint: TPrintDialog
    Copies = 1
    Left = 464
    Top = 352
  end
  object XPManifest: TXPManifest
    Left = 476
    Top = 224
  end
end
