{*******************************************************}
{                                                       }
{       Borland Delphi Visual Component Library         }
{       Rav Soft Extended Color Combo Box               }
{                                                       }
{       Copyright (c) 2005-19 Razzhivin Alexandr        }
{                                                       }
{*******************************************************}

unit rClrCombo;

interface

uses
  Classes, Windows, StdCtrls, Graphics;

const
  ColorsInListBase     = 20;
  ColorsInListExtended = 45;
  ColorsList: array [0..ColorsInListExtended - 1] of TColor =
    (clBlack, clMaroon, clGreen, clOlive, clNavy, clPurple, clTeal,
     clRed, clLime, clYellow, clBlue, clFuchsia, clAqua, clGray, clSilver, clWhite,
     clMoneyGreen, clSkyBlue, clCream, clMedGray,
     clBackground, clAppWorkSpace,
     clActiveCaption, clCaptionText, clActiveBorder,
     clInactiveCaption, clInactiveCaptionText, clInactiveBorder,
     clMenu, clMenuText, clGrayText, clHighlight, clHighlightText,
     clWindow, clWindowFrame, clWindowText, clScrollBar,
     clBtnFace, clBtnText, clBtnShadow, clBtnHighlight,
     cl3DDkShadow, cl3DLight, clInfoText, clInfoBk);

type
  TrCCOption = (ccSystemColors, ccUserDefinedColor, ccUserColorDialog);
  TrCCOptions = set of TrCCOption;

type
  TrColorStorage = class
  private
    fColor: TColor;
  public
    constructor Create(const aColor: TColor);
    property Color: TColor read fColor write fColor;
  end;

  TrColorCombo = class (TCustomComboBox)
  private
    fColorUser: Integer;
    fDisplayNames: Boolean;
    fOptions: TrCCOptions;
    fOnChange: TNotifyEvent;
    function  GetColorValue: TColor;
    procedure SetColorValue(aValue: TColor);
    procedure SetDisplayNames(aValue: Boolean);
    procedure SetOptions(aValue: TrCCOptions);
  protected
    procedure SetStyle(Value: TComboBoxStyle); override;
    procedure DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState); override;
    procedure CreateWnd; override;
    procedure PopulateList;
    procedure InsertUserColor(aValue: TColor);
    procedure DefineUserColor;
    procedure Click; override;
    procedure DoChange; dynamic;
  public
    constructor Create(aOwner: TComponent); override;
  published
    property ColorValue: TColor read GetColorValue write SetColorValue default clBlack;
    property DisplayNames: Boolean read fDisplayNames write SetDisplayNames default True;
    property Options: TrCCOptions read fOptions write SetOptions;
    property Color;
    property Ctl3D;
    property DragMode;
    property DragCursor;
    property Enabled;
    property Font;
    property Anchors;
    property BiDiMode;
    property Constraints;
    property DragKind;
    property ParentBiDiMode;
    property ImeMode;
    property ImeName;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    // property Style;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDropDown;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnStartDrag;
    property OnContextPopup;
    property OnEndDock;
    property OnStartDock;
  end;

function GetColorName(const Color: TColor): string;

implementation

uses
  Themes, SysUtils, Dialogs, rClrStrings;

{ == Utilites ================================================================== }
function GetColorName(const Color: TColor): string;
begin
  case Color of
    clBlack: Result := rsClrBlack;
    clMaroon: Result := rsClrMaroon;
    clGreen: Result := rsClrGreen;
    clOlive: Result := rsClrOlive;
    clNavy: Result := rsClrNavy;
    clPurple: Result := rsClrPurple;
    clTeal: Result := rsClrTeal;
    clRed: Result := rsClrRed;
    clLime: Result := rsClrLime;
    clYellow: Result := rsClrYellow;
    clBlue: Result := rsClrBlue;
    clFuchsia: Result := rsClrFuchsia;
    clAqua: Result := rsClrAqua;
    clGray: Result := rsClrGray;
    clSilver: Result := rsClrSilver;
    clWhite: Result := rsClrWhite;
    clMoneyGreen: Result := rsClrMoneyGreen;
    clSkyBlue: Result := rsClrSkyBlue;
    clCream: Result := rsClrCream;
    clMedGray: Result := rsClrMedGray;
    clScrollBar: Result := rsClrScrollBar;
    clBackground: Result := rsClrBackground;
    clActiveCaption: Result := rsClrActiveCaption;
    clInactiveCaption: Result := rsClrInactiveCaption;
    clMenu: Result := rsClrMenu;
    clWindow: Result := rsClrWindow;
    clWindowFrame: Result := rsClrWindowFrame;
    clMenuText: Result := rsClrMenuText;
    clWindowText: Result := rsClrWindowText;
    clCaptionText: Result := rsClrCaptionText;
    clActiveBorder: Result := rsClrActiveBorder;
    clInactiveBorder: Result := rsClrInactiveBorder;
    clAppWorkSpace: Result := rsClrAppWorkSpace;
    clHighlight: Result := rsClrHighlight;
    clHighlightText: Result := rsClrHighlightText;
    clBtnFace: Result := rsClrBtnFace;
    clBtnShadow: Result := rsClrBtnShadow;
    clGrayText: Result := rsClrGrayText;
    clBtnText: Result := rsClrBtnText;
    clInactiveCaptionText: Result := rsClrInactiveCaptionText;
    clBtnHighlight: Result := rsClrBtnHighlight;
    cl3DDkShadow: Result := rsClr3DDkShadow;
    cl3DLight: Result := rsClr3DLight;
    clInfoText: Result := rsClrInfoText;
    clInfoBk: Result := rsClrInfoBk;
    else Result := rsClrUserDefined;
  end;
end;

{ == TrColorStorage ============================================================ }

constructor TrColorStorage.Create(const aColor: TColor);
begin
  inherited Create;
  fColor := aColor;
end;

{ == TrColorCombo ============================================================== }

constructor TrColorCombo.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  Style := csOwnerDrawFixed;
  ParentCtl3D := False;
  fDisplayNames := True;
  fColorUser := -1;
  fOptions := [ccSystemColors, ccUserDefinedColor, ccUserColorDialog];
end;

procedure TrColorCombo.SetStyle(Value: TComboBoxStyle);
begin
  inherited SetStyle(csOwnerDrawFixed);
end;

procedure TrColorCombo.SetDisplayNames(aValue: Boolean);
begin
  if fDisplayNames <> aValue then
  begin
    fDisplayNames := aValue;
    Invalidate;
  end;
end;

procedure TrColorCombo.SetOptions(aValue: TrCCOptions);
begin
  if fOptions <> aValue then
  begin
    fOptions := aValue;
    if not (csLoading in ComponentState) then
      RecreateWnd;
  end;
end;

procedure TrColorCombo.CreateWnd;
begin
  inherited CreateWnd;
  PopulateList;
  SetColorValue(ColorValue);
end;

procedure TrColorCombo.PopulateList;
var
  i, MaxColors: Integer;
begin
  Items.BeginUpdate;
  try
    Clear;
    if ccSystemColors in fOptions
    then MaxColors := ColorsInListExtended - 1
    else MaxColors := ColorsInListBase - 1;
    for i := 0 to MaxColors do
      Items.AddObject(GetColorName(ColorsList[i]), TRColorStorage.Create(ColorsList[i]));
    if ccUserDefinedColor in fOptions then
      InsertUserColor(ColorValue);
  finally
    Items.EndUpdate;
  end;
end;

procedure TrColorCombo.InsertUserColor(aValue: TColor);
begin
  Items.BeginUpdate;
  try
    if fColorUser > -1
    then TRColorStorage(Items.Objects[fColorUser]).Color := aValue
    else fColorUser := Items.AddObject(rsClrUserDefined, TrColorStorage.Create(aValue));
  finally
    Items.EndUpdate;
  end;
end;

procedure TrColorCombo.DefineUserColor;
var
  Dialog: TColorDialog;
begin
  Dialog := TColorDialog.Create(Self);
  try
    Dialog.Options := [cdFullOpen];
    if fColorUser > -1
    then Dialog.Color := TRColorStorage(Items.Objects[fColorUser]).Color
    else Dialog.Color := clBlack;
    if Dialog.Execute then InsertUserColor(Dialog.Color);
  finally
    Dialog.Free;
  end;
end;

procedure TrColorCombo.DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState);
const
  ColorWidth = 22;
var
  ARect: TRect;
  Text: array[0..255] of Char;
  rsClrafer: TColor;
begin
  ARect := Rect;
  Inc(ARect.Top, 2);
  Inc(ARect.Left, 2);
  Dec(ARect.Bottom, 2);
  if fDisplayNames then ARect.Right := ARect.Left + ColorWidth
  else Dec(ARect.Right, 2);
  with Canvas do begin
    FillRect(Rect);
    rsClrafer := Brush.Color;
    if (odSelected in State) then Pen.Color := clWhite else Pen.Color := clBlack;
    Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
    Brush.Color := TRColorStorage(Items.Objects[Index]).Color;
    try
      InflateRect(ARect, -1, -1);
      FillRect(ARect);
    finally
      Brush.Color := rsClrafer;
    end;
    if fDisplayNames then
    begin
      StrPCopy(Text, Items[Index]);
      Rect.Left := Rect.Left + ColorWidth + 6;
      DrawText(Canvas.Handle, Text, StrLen(Text), Rect, DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX));
    end;
  end;
end;

procedure TrColorCombo.Click;
begin
  if (ItemIndex > -1) and (ItemIndex < Items.Count) then
    ColorValue := TRColorStorage(Items.Objects[ItemIndex]).Color;
  inherited Click;
end;

procedure TrColorCombo.DoChange;
begin
  if not (csReading in ComponentState) then
    if Assigned(FOnChange) then FOnChange(Self);
end;

function TrColorCombo.GetColorValue: TColor;
begin
  if (ItemIndex > -1) and (ItemIndex < Items.Count)
  then Result := TRColorStorage(Items.Objects[ItemIndex]).Color
  else Result := clBlack;
end;

procedure TrColorCombo.SetColorValue(aValue: TColor);
var
  i: Integer;
begin
  if (ItemIndex > -1) and (ItemIndex = fColorUser)
  and (ccUserDefinedColor in fOptions) then
  begin
    if not (csDesigning in ComponentState)
    and (ccUserColorDialog in fOptions)
    then DefineUserColor
    else InsertUserColor(aValue);
    ItemIndex := fColorUser;
    DoChange;
  end
  else begin
    for i := 0 to Items.Count - 1 do
    begin
      if TRColorStorage(Items.Objects[i]).Color = aValue then
      begin
        if ItemIndex <> i then ItemIndex := i;
        DoChange;
        Exit;
      end;
    end;
    if ccUserDefinedColor in fOptions then
    begin
      InsertUserColor(aValue);
      ItemIndex := fColorUser;
      DoChange;
    end
    else ItemIndex := 0;
  end;
end;

end.
