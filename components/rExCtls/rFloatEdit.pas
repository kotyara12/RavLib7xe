unit rFloatEdit;

interface

uses
  SysUtils,
  WinTypes,
  WinProcs,
  Messages,
  Classes,
  Graphics,
  Controls,
  Menus,
  Forms,
  Dialogs,
  StdCtrls;

type
  TrFloatEdit = class(TCustomMemo)
  private
    fValue: Extended;
    fDisplayFormat: string;
    fBeepOnError: Boolean;
    fUndoOnError: Boolean;
    fFormatOnEdit: Boolean;
    fTextChanged: Boolean;
    procedure SetFormat(const aValue: string);
    procedure SetValue(const aValue: Extended);
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure DecodeText;
    procedure DisplayValue;
  protected
    procedure KeyPress(var Key: Char); override;
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Alignment default taRightJustify;
    property AutoSize default True;
    property BeepOnError: Boolean read fBeepOnError write fBeepOnError default True;
    property BorderStyle;
    property Color;
    property Ctl3D;
    property DisplayFormat: string read fDisplayFormat write SetFormat;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Font;
    property FormatOnEdit: Boolean read fFormatOnEdit write fFormatOnEdit default True;
    property HideSelection;
    property MaxLength;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property TabOrder;
    property Value: Extended read fValue write SetValue;
    property Visible;
    property UndoOnError: Boolean read fUndoOnError write fUndoOnError default True;
    property OnChange;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  Themes;

constructor TrFloatEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AutoSize := True;
  Alignment := taRightJustify;
  Width := 121;
  Height := 25;
  fDisplayFormat := ',0.00';
  fValue := 0.0;
  fBeepOnError := True;
  fUndoOnError := True;
  fFormatOnEdit := True;
  AutoSelect := False;
  WantReturns := False;
  WordWrap := False;
  DisplayValue;
end;

procedure TrFloatEdit.SetFormat(const aValue: string);
begin
  if fDisplayFormat <> aValue then
  begin
    fDisplayFormat := aValue;
    DisplayValue;
  end;
end;

procedure TrFloatEdit.SetValue(const aValue: Extended);
begin
  if fValue <> aValue then
  begin
    fValue := aValue;
    DisplayValue;
  end;
  if Assigned(OnChange) then OnChange(Self);
end;

procedure TrFloatEdit.DecodeText;
var
  TmpValue: Extended;
  TmpText: string;
  i: Integer;
  IsNeg: Boolean;
begin
  IsNeg := Pos('-', Text) > 0;
  TmpText := '';
  TmpValue := fValue;
  for i := 1 to Length(Text) do
  begin
    if CharInSet(Text[i], ['0'..'9'])
    or (CharInSet(Text[i], [FormatSettings.DecimalSeparator]) and (Pos(FormatSettings.DecimalSeparator, TmpText) = 0)) then
      TmpText := TmpText + Text[i];
  end;
  try
    fValue := StrToFloat(TmpText);
    if IsNeg then fValue := - fValue;
    if Assigned(OnChange) then OnChange(Self);
  except
    if fBeepOnError then MessageBeep(0);
    if not fUndoOnError then fValue := TmpValue;
  end;
end;

procedure TrFloatEdit.DisplayValue;
begin
  fTextChanged := False;
  if (fFormatOnEdit or not Focused) and (fDisplayFormat <> EmptyStr) then
    Text := FormatFloat(fDisplayFormat, fValue)
  else
    Text := FloatToStr(fValue);
end;

procedure TrFloatEdit.CMEnter(var Message: TCMEnter);
begin
  DisplayValue;
  SelectAll;
  inherited;
end;

procedure TrFloatEdit.CMExit(var Message: TCMExit);
begin
  DecodeText;
  DisplayValue;
  inherited;
end;

procedure TrFloatEdit.KeyPress(var Key: Char);
begin
  if CharInSet(Key, ['.', ',']) then Key := FormatSettings.DecimalSeparator;
  if CharInSet(Key, ['0'..'9', '-', '+', #8, #13, #27, FormatSettings.DecimalSeparator]) then
  begin
    if Key = '+' then Key := #0;
    if (Key = FormatSettings.DecimalSeparator) and (Pos(FormatSettings.DecimalSeparator, Text) > 0) then Key := #0;
    if (Key = #13) and fFormatOnEdit then
    begin
      if fTextChanged then Key := #0;
      DecodeText;
      DisplayValue;
      SelectAll;
    end;
    if (Key = #27) then
    begin
      if fTextChanged then Key := #0;
      DisplayValue;
      SelectAll;
    end;
  end
  else begin
    if fBeepOnError then MessageBeep(0);
    Key := #0;
  end;
  fTextChanged := Key <> #0;
  inherited KeyPress(Key);
end;

procedure TrFloatEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  case Alignment of
    taLeftJustify: Params.Style := Params.Style or ES_LEFT and not ES_MULTILINE;
    taRightJustify: Params.Style := Params.Style or ES_RIGHT and not ES_MULTILINE;
    taCenter: Params.Style := Params.Style or ES_CENTER and not ES_MULTILINE;
  end;
end;

end.
