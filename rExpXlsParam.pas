unit rExpXlsParam;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, StdCtrls, Buttons, ExtCtrls, rFloatEdit, TmplDialogSimple;

type
  TFormExpExcelParam = class(TDialogSTemplate)
    edCaption: TEdit;
    lblCaption: TLabel;
    edAlign: TComboBox;
    lblAlign: TLabel;
    lblWidth: TLabel;
    edWidth: TRFloatEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

end.
