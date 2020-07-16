object PrintFrm: TPrintFrm
  Left = 505
  Top = 170
  BorderStyle = bsDialog
  Caption = 'Print'
  ClientHeight = 105
  ClientWidth = 288
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox6: TGroupBox
    Left = 8
    Top = 0
    Width = 273
    Height = 65
    Caption = ' Output to '
    TabOrder = 0
    object bPrinterSetup: TButton
      Left = 8
      Top = 40
      Width = 89
      Height = 17
      Caption = 'Printer Setup'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = bPrinterSetupClick
    end
    object edPrinterName: TEdit
      Left = 8
      Top = 16
      Width = 257
      Height = 20
      AutoSize = False
      Color = clGradientInactiveCaption
      ReadOnly = True
      TabOrder = 1
      Text = 'edPrinterName'
    end
  end
  object bOK: TButton
    Left = 8
    Top = 72
    Width = 57
    Height = 25
    Caption = 'OK'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ModalResult = 1
    ParentFont = False
    TabOrder = 1
  end
  object bCancel: TButton
    Left = 72
    Top = 72
    Width = 57
    Height = 17
    Caption = 'Cancel'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ModalResult = 2
    ParentFont = False
    TabOrder = 2
  end
  object KillFormTimer: TTimer
    Enabled = False
    Interval = 50
    OnTimer = KillFormTimerTimer
    Left = 168
    Top = 72
  end
end
