inherited frmUpdateInformer: TfrmUpdateInformer
  Left = 624
  Top = 246
  ActiveControl = OkBtn
  Caption = #1053#1072#1081#1076#1077#1085#1072' '#1085#1086#1074#1072#1103' '#1074#1077#1088#1089#1080#1103' '#1087#1088#1086#1075#1088#1072#1084#1084#1099
  ClientHeight = 360
  ClientWidth = 461
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  inherited bvlButtons: TBevel
    Top = 309
    Width = 461
    ExplicitTop = 309
    ExplicitWidth = 461
  end
  object lblVersionCur: TLabel [1]
    Left = 12
    Top = 16
    Width = 149
    Height = 13
    Caption = #1058#1077#1082#1091#1097#1072#1103' '#1074#1077#1088#1089#1080#1103' '#1087#1088#1086#1075#1088#1072#1084#1084#1099':'
    FocusControl = edVersionCur
  end
  object lblVersionNew: TLabel [2]
    Left = 12
    Top = 48
    Width = 136
    Height = 13
    Caption = #1053#1086#1074#1072#1103' '#1074#1077#1088#1089#1080#1103' '#1087#1088#1086#1075#1088#1072#1084#1084#1099':'
    FocusControl = edVersionNew
  end
  object lblVersionDsc: TLabel [3]
    Left = 12
    Top = 80
    Width = 92
    Height = 13
    Caption = #1054#1087#1080#1089#1072#1085#1080#1077' '#1074#1077#1088#1089#1080#1080':'
    FocusControl = edVersionDsc
  end
  inherited ButtonsPanel: TPanel
    Top = 311
    Width = 461
    ExplicitTop = 311
    ExplicitWidth = 461
    inherited ButtonsMovedPanel: TPanel
      Left = 239
      ExplicitLeft = 239
      inherited OkBtn: TBitBtn
        Hint = #1059#1089#1090#1072#1085#1086#1074#1080#1090#1100' '#1101#1090#1086' '#1086#1073#1085#1086#1074#1083#1077#1085#1080#1077
        Caption = #1059#1089#1090#1072#1085#1086#1074#1080#1090#1100
      end
      inherited CancelBtn: TBitBtn
        Hint = #1054#1090#1082#1072#1079#1072#1090#1100#1089#1103' '#1086#1090' '#1086#1073#1085#1086#1074#1083#1077#1085#1080#1103
      end
    end
  end
  object edVersionCur: TEdit
    Left = 284
    Top = 12
    Width = 165
    Height = 21
    TabStop = False
    ParentColor = True
    ReadOnly = True
    TabOrder = 1
  end
  object edVersionNew: TEdit
    Left = 284
    Top = 44
    Width = 165
    Height = 21
    TabStop = False
    ParentColor = True
    ReadOnly = True
    TabOrder = 2
  end
  object edVersionDsc: TMemo
    Left = 12
    Top = 96
    Width = 437
    Height = 189
    TabStop = False
    ParentColor = True
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
end
