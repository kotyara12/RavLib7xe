unit TmplDialogSimple;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TDialogSTemplate = class(TForm)
    ButtonsPanel: TPanel;
    ButtonsMovedPanel: TPanel;
    OkBtn: TBitBtn;
    CancelBtn: TBitBtn;
    bvlButtons: TBevel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$IFDEF LC}
uses
  rLngDll, rLngUtils;
{$ENDIF}

{$R *.dfm}

procedure TDialogSTemplate.FormCreate(Sender: TObject);
begin
  Font.Name := Screen.MenuFont.Name;
  {$IFDEF LC}
  Font.Charset := lng_LCIDToCharset(rlr_GetLCID);
  {$ENDIF}
end;

end.
