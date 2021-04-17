inherited FormExpExcelParam: TFormExpExcelParam
  ActiveControl = edCaption
  Caption = #1055#1072#1088#1072#1084#1077#1090#1088#1099' '#1087#1086#1083#1103
  ClientHeight = 171
  ClientWidth = 347
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  inherited bvlButtons: TBevel
    Top = 120
    Width = 347
  end
  object lblCaption: TLabel [1]
    Left = 12
    Top = 12
    Width = 101
    Height = 13
    Caption = #1047#1072#1075#1086#1083#1086#1074#1086#1082' '#1089#1090#1086#1083#1073#1094#1072':'
    FocusControl = edCaption
  end
  object lblAlign: TLabel [2]
    Left = 12
    Top = 60
    Width = 118
    Height = 13
    Caption = #1042#1099#1088#1072#1074#1085#1080#1074#1072#1085#1080#1077' '#1076#1072#1085#1085#1099#1093':'
    FocusControl = edAlign
  end
  object lblWidth: TLabel [3]
    Left = 240
    Top = 60
    Width = 42
    Height = 13
    Caption = #1064#1080#1088#1080#1085#1072':'
    FocusControl = edWidth
  end
  inherited ButtonsPanel: TPanel
    Top = 122
    Width = 347
    TabOrder = 3
    inherited ButtonsMovedPanel: TPanel
      Left = 125
    end
  end
  object edCaption: TEdit
    Left = 12
    Top = 28
    Width = 321
    Height = 21
    Hint = #1047#1072#1075#1086#1083#1086#1074#1086#1082' '#1089#1090#1086#1083#1073#1094#1072
    TabOrder = 0
  end
  object edAlign: TComboBox
    Left = 12
    Top = 76
    Width = 217
    Height = 21
    Hint = #1042#1099#1088#1072#1074#1085#1080#1074#1072#1085#1080#1077' '#1076#1072#1085#1085#1099#1093
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 1
  end
  object edWidth: TRFloatEdit
    Left = 240
    Top = 76
    Width = 93
    Height = 21
    Hint = #1064#1080#1088#1080#1085#1072' '#1089#1090#1086#1083#1073#1094#1072
    DisplayFormat = ',0.00'
    TabOrder = 2
  end
end
