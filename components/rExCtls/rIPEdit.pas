unit rIPEdit;

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
  StdCtrls,
  RIpTools;

type
  TrIPAddrEdit = class(TCustomMemo)
  private
    fValue: RIpAddr;
    fBeepOnError: Boolean;
    procedure SetValue(const aValue: RIpAddr);
    function  GetStrValue: string;
    procedure SetStrValue(const aValue: string);
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
    property DragCursor;
    property DragMode;
    property Enabled;
    property Font;
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
    property Value: RIpAddr read fValue write SetValue;
    property Text: string read GetStrValue write SetStrValue;
    property Visible;
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
  Themes, StrUtils, rxStrUtilsE;

constructor TrIPAddrEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AutoSize := True;
  Alignment := taLeftJustify;
  Width := 121;
  Height := 25;
  fBeepOnError := True;
  AutoSelect := False;
  WantReturns := False;
  WordWrap := False;
  Text := '0.0.0.0';
  DisplayValue;
end;

procedure TrIPAddrEdit.SetValue(const aValue: RIpAddr);
begin
  if fValue.Socket <> aValue.Socket then
  begin
    fValue := aValue;
    DisplayValue;
  end;
  if Assigned(OnChange) then OnChange(Self);
end;

function TrIPAddrEdit.GetStrValue: string;
begin
  Result := IpAddrToStr(fValue);
end;

procedure TrIPAddrEdit.SetStrValue(const aValue: string);
begin
  SetValue(StrToIpAddr(aValue));
end;

procedure TrIPAddrEdit.DecodeText;
begin
  SetStrValue(inherited Text);
end;

procedure TrIPAddrEdit.DisplayValue;
begin
  inherited Text := IpAddrToStr(fValue);
end;

procedure TrIPAddrEdit.CMEnter(var Message: TCMEnter);
begin
  DisplayValue;
  SelectAll;
  inherited;
end;

procedure TrIPAddrEdit.CMExit(var Message: TCMExit);
begin
  DecodeText;
  DisplayValue;
  inherited;
end;

procedure TrIPAddrEdit.KeyPress(var Key: Char);
var
  i, n: Integer;
  SelValue: string;
begin
  if CharInSet(Key, ['-', '/', ',', #32]) then Key := IpDelim;
  if CharInSet(Key, ['0'..'9', '.', #8, #13, #27]) then
  begin
    // Проверка на количество октетов
    if (Key = IpDelim) then
    begin
      n := 0;
      for i := 1 to Length(inherited Text) do
        if inherited Text[i] = IpDelim then Inc(n);
      if n > 2 then
      begin
        if fBeepOnError then MessageBeep(0);
        Key := #0;
      end;
    end;
    // Проверка вводимого значения
    if CharInSet(Key, ['0'..'9', IpDelim]) then
    begin
      SelValue := EmptyStr;
      for i := SelStart downto 1 do
        if inherited Text[i] <> IpDelim
        then SelValue := inherited Text[i] + SelValue
        else Break;
      if Key <> IpDelim then SelValue := SelValue + Key;
      if (SelValue = EmptyStr)
      or (StrToIntDef(SelValue, 0) > 255) then
      begin
        if fBeepOnError then MessageBeep(0);
        Key := #0;
      end;
    end;
    // Обработка клавиши Enter
    if (Key = #13) then
    begin
      DecodeText;
      DisplayValue;
      SelectAll;
    end;
    // Обработка клавиши Esc
    if (Key = #27) then
    begin
      DisplayValue;
      SelectAll;
    end;
  end
  else begin
    if fBeepOnError then MessageBeep(0);
    Key := #0;
  end;
  inherited KeyPress(Key);
end;

procedure TrIPAddrEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  case Alignment of
    taLeftJustify: Params.Style := Params.Style or ES_LEFT and not ES_MULTILINE;
    taRightJustify: Params.Style := Params.Style or ES_RIGHT and not ES_MULTILINE;
    taCenter: Params.Style := Params.Style or ES_CENTER and not ES_MULTILINE;
  end;
end;

end.
