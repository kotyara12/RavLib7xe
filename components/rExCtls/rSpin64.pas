unit rSpin64;

interface

uses Windows, Classes, StdCtrls, ExtCtrls, Controls, Messages, SysUtils,
  Forms, Graphics, Menus, Buttons, Spin;

type
{ TSpinEdit64 }

  TSpinEdit64 = class(TCustomEdit)
  private
    FMinValue: Int64;
    FMaxValue: Int64;
    FIncrement: Int64;
    FButton: TSpinButton;
    FEditorEnabled: Boolean;
    function GetMinHeight: Integer;
    function GetValue: Int64;
    function CheckValue (NewValue: Int64): Int64;
    procedure SetValue (NewValue: Int64);
    procedure SetEditRect;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure CMEnter(var Message: TCMGotFocus); message CM_ENTER;
    procedure CMExit(var Message: TCMExit);   message CM_EXIT;
    procedure WMPaste(var Message: TWMPaste);   message WM_PASTE;
    procedure WMCut(var Message: TWMCut);   message WM_CUT;
  protected
    function IsValidChar(Key: Char): Boolean; virtual;
    procedure UpClick (Sender: TObject); virtual;
    procedure DownClick (Sender: TObject); virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Button: TSpinButton read FButton;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
  published
    property Anchors;
    property AutoSelect;
    property AutoSize;
    property Color;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragMode;
    property EditorEnabled: Boolean read FEditorEnabled write FEditorEnabled default True;
    property Enabled;
    property Font;
    property Increment: Int64 read FIncrement write FIncrement default 1;
    property MaxLength;
    property MaxValue: Int64 read FMaxValue write FMaxValue;
    property MinValue: Int64 read FMinValue write FMinValue;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Value: Int64 read GetValue write SetValue;
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
    property OnStartDrag;
  end;

implementation

uses Themes;

{ TSpinEdit64 }

constructor TSpinEdit64.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FButton := TSpinButton.Create(Self);
  FButton.Width := 15;
  FButton.Height := 17;
  FButton.Visible := True;
  FButton.Parent := Self;
  FButton.FocusControl := Self;
  FButton.OnUpClick := UpClick;
  FButton.OnDownClick := DownClick;
  Text := '0';
  ControlStyle := ControlStyle - [csSetCaption];
  FIncrement := 1;
  FEditorEnabled := True;
  ParentBackground := False;
end;

destructor TSpinEdit64.Destroy;
begin
  FButton := nil;
  inherited Destroy;
end;

procedure TSpinEdit64.GetChildren(Proc: TGetChildProc; Root: TComponent);
begin
end;

procedure TSpinEdit64.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_UP then UpClick (Self)
  else if Key = VK_DOWN then DownClick (Self);
  inherited KeyDown(Key, Shift);
end;

procedure TSpinEdit64.KeyPress(var Key: Char);
begin
  if not IsValidChar(Key) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
  if Key <> #0 then inherited KeyPress(Key);
end;

function TSpinEdit64.IsValidChar(Key: Char): Boolean;
begin
  Result := CharInSet(Key, [FormatSettings.DecimalSeparator, '+', '-', '0'..'9']) or
    ((Key < #32) and (Key <> Chr(VK_RETURN)));
  if not FEditorEnabled and Result and ((Key >= #32) or
      (Key = Char(VK_BACK)) or (Key = Char(VK_DELETE))) then
    Result := False;
end;

procedure TSpinEdit64.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
{  Params.Style := Params.Style and not WS_BORDER;  }
  Params.Style := Params.Style or ES_MULTILINE or WS_CLIPCHILDREN;
end;

procedure TSpinEdit64.CreateWnd;
begin
  inherited CreateWnd;
  SetEditRect;
end;

procedure TSpinEdit64.SetEditRect;
var
  Loc: TRect;
begin
  SendMessage(Handle, EM_GETRECT, 0, Int64(@Loc));
  Loc.Bottom := ClientHeight + 1;  {+1 is workaround for windows paint bug}
  Loc.Right := ClientWidth - FButton.Width - 2;
  Loc.Top := 0;  
  Loc.Left := 0;  
  SendMessage(Handle, EM_SETRECTNP, 0, Int64(@Loc));
  SendMessage(Handle, EM_GETRECT, 0, Int64(@Loc));  {debug}
end;

procedure TSpinEdit64.WMSize(var Message: TWMSize);
var
  MinHeight: Integer;
begin
  inherited;
  MinHeight := GetMinHeight;
    { text edit bug: if size to less than minheight, then edit ctrl does
      not display the text }
  if Height < MinHeight then   
    Height := MinHeight
  else if FButton <> nil then
  begin
    if NewStyleControls and Ctl3D then
      FButton.SetBounds(Width - FButton.Width - 5, 0, FButton.Width, Height - 5)
    else FButton.SetBounds (Width - FButton.Width, 1, FButton.Width, Height - 3);
    SetEditRect;
  end;
end;

function TSpinEdit64.GetMinHeight: Integer;
var
  DC: HDC;
  SaveFont: HFont;
  I: Integer;
  SysMetrics, Metrics: TTextMetric;
begin
  DC := GetDC(0);
  GetTextMetrics(DC, SysMetrics);
  SaveFont := SelectObject(DC, Font.Handle);
  GetTextMetrics(DC, Metrics);
  SelectObject(DC, SaveFont);
  ReleaseDC(0, DC);
  I := SysMetrics.tmHeight;
  if I > Metrics.tmHeight then I := Metrics.tmHeight;
  Result := Metrics.tmHeight + I div 4 + GetSystemMetrics(SM_CYBORDER) * 4 + 2;
end;

procedure TSpinEdit64.UpClick (Sender: TObject);
begin
  if ReadOnly then MessageBeep(0)
  else Value := Value + FIncrement;
end;

procedure TSpinEdit64.DownClick (Sender: TObject);
begin
  if ReadOnly then MessageBeep(0)
  else Value := Value - FIncrement;
end;

procedure TSpinEdit64.WMPaste(var Message: TWMPaste);
begin
  if not FEditorEnabled or ReadOnly then Exit;
  inherited;
end;

procedure TSpinEdit64.WMCut(var Message: TWMPaste);   
begin
  if not FEditorEnabled or ReadOnly then Exit;
  inherited;
end;

procedure TSpinEdit64.CMExit(var Message: TCMExit);
begin
  inherited;
  if CheckValue (Value) <> Value then
    SetValue (Value);
end;

function TSpinEdit64.GetValue: Int64;
begin
  try
    Result := StrToInt64 (Text);
  except
    Result := FMinValue;
  end;
end;

procedure TSpinEdit64.SetValue (NewValue: Int64);
begin
  Text := IntToStr (CheckValue (NewValue));
end;

function TSpinEdit64.CheckValue (NewValue: Int64): Int64;
begin
  Result := NewValue;
  if (FMaxValue <> FMinValue) then
  begin
    if NewValue < FMinValue then
      Result := FMinValue
    else if NewValue > FMaxValue then
      Result := FMaxValue;
  end;
end;

procedure TSpinEdit64.CMEnter(var Message: TCMGotFocus);
begin
  if AutoSelect and not (csLButtonDown in ControlState) then
    SelectAll;
  inherited;
end;

end.
