object FormWait: TFormWait
  Left = 416
  Top = 336
  BorderStyle = bsNone
  Caption = 'FormWait'
  ClientHeight = 77
  ClientWidth = 355
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object InfoPanel: TPanel
    Left = 0
    Top = 0
    Width = 355
    Height = 77
    Align = alClient
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 0
    object InfoLabel: TLabel
      Left = 4
      Top = 4
      Width = 346
      Height = 13
      Alignment = taCenter
      Constraints.MaxHeight = 53
      Constraints.MaxWidth = 346
      Constraints.MinHeight = 10
      Constraints.MinWidth = 346
      WordWrap = True
    end
  end
end
