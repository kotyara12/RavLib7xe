unit RWait;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls;

type
  TFormWait = class(TForm)
    InfoPanel: TPanel;
    InfoLabel: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

procedure ShowWaitMsg(const Msg: string);
procedure ChangeWaitMsg(const Msg: string);
procedure UpdateWaitMsg;
procedure CloseWaitMsg;

implementation

uses
  rDialogs;

{$R *.DFM}

var
  FormWait: TFormWait = nil;

procedure ShowWaitMsg(const Msg: string);
begin
  if not Assigned(FormWait) then
    FormWait := TFormWait.Create(Application);
  FormWait.Font := Screen.MenuFont;
  FormWait.InfoLabel.Caption := Msg;
  FormWait.InfoLabel.Top := (FormWait.InfoPanel.Height - FormWait.InfoLabel.Height) div 2;
  if not FormWait.Visible then FormWait.Show;
  FormWait.Update;
  FormWait.BringToFront;
  Application.ProcessMessages;
end;

procedure ChangeWaitMsg(const Msg: string);
begin
  if Assigned(FormWait) then
  begin
    FormWait.InfoLabel.Caption := Msg;
    FormWait.InfoLabel.Top := (FormWait.InfoPanel.Height - FormWait.InfoLabel.Height) div 2;
    FormWait.Update;
    FormWait.BringToFront;
    Application.ProcessMessages;
  end;
end;

procedure UpdateWaitMsg;
begin
  if Assigned(FormWait) then
  begin
    FormWait.Update;
    FormWait.BringToFront;
    Application.ProcessMessages;
  end;
end;

procedure CloseWaitMsg;
begin
  if Assigned(FormWait) then
    FreeAndNil(FormWait);
end;

end.
