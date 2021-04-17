unit RProgress;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, Gauges, StdCtrls;

type
  TFormProgress = class(TForm)
    Panel: TPanel;
    Text: TLabel;
    Gauge: TGauge;
    BtnStop: TButton;
    procedure BtnStopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure SetStopButton(const Value: Boolean);
    function  GetStopButton: Boolean;
    function  GetStopFlag: Boolean;
    procedure SetStopFlag(const Value: Boolean);
  public
    procedure FileProgress(Sender: TObject; const CurrPos, MaxPos: Integer);
    procedure CheckBreak(Sender: TObject; var IsBreak: Boolean);
    property StopButton: Boolean read GetStopButton write SetStopButton;
    property StopFlag: Boolean read GetStopFlag write SetStopFlag;
  end;

procedure ShowProgress(const AMessage: string; const AMax: Integer;
  const ShowStopButton: Boolean = False);
procedure ShowProgressDefault(const AMax: Integer);
procedure CloseProgress;
function  IsShowProgress: Boolean;
function  IsStopProgress: Boolean;

procedure UpdateProgressMessage(const AMessage: string);
procedure UpdateProgressPosition(const AValue: Integer);
procedure UpdateProgressStep(const AValue: Integer);
procedure UpdateProgressMax(const AValue: Integer);

implementation

{$R *.DFM}

resourcestring
  SWaitMessageDefault         = 'Пожалуйста подожите...';
  SErrorProgressAlreadyExists = 'Окно индикатора уже создано!';
  SErrorProgressNotExists     = 'Окно индикатора не существует!';

var
  Progress: TFormProgress;

procedure InternalUpdate;
begin
  if Progress <> nil then
  begin
    Progress.Update;
    Progress.BringToFront;
    Application.ProcessMessages;
  end;
end;

{ == Показать форму с индиктором прогресса ===================================== }
procedure ShowProgress(const AMessage: string; const AMax: Integer;
  const ShowStopButton: Boolean = False);
begin
  if Progress <> nil then
    raise Exception.Create(SErrorProgressAlreadyExists);
  Progress := TFormProgress.Create(Application);
  try
    Progress.StopButton := ShowStopButton;
    Progress.StopFlag := False;
    Progress.Text.Caption := AMessage;
    Progress.Gauge.MaxValue := AMax;
    Progress.Gauge.Progress := 0;
    Progress.Show;
    InternalUpdate;
  except
    FreeAndNil(Progress);
    raise;
  end;
end;

procedure ShowProgressDefault(const AMax: Integer);
begin
  ShowProgress(SWaitMessageDefault, AMax);
end;

function IsShowProgress: Boolean;
begin
  Result := Progress <> nil;
end;

function IsStopProgress: Boolean;
begin
  Result := (Progress <> nil) and Progress.StopFlag;
  InternalUpdate;
end;

{ == Убрать окно прогресса ===================================================== }
procedure CloseProgress;
begin
  if Progress <> nil then
  begin
    Progress.Free;
    Progress := nil;
  end;
end;

{ == Обновление окна прогресса ================================================= }
procedure UpdateProgressMessage(const AMessage: string);
begin
  if Progress <> nil then
  begin
    Progress.Text.Caption := AMessage;
    InternalUpdate;
  end;
end;

procedure UpdateProgressPosition(const AValue: Integer);
begin
  if Progress <> nil then
  begin
    if AValue <= Progress.Gauge.MaxValue
    then Progress.Gauge.Progress := AValue
    else Progress.Gauge.Progress := Progress.Gauge.MaxValue;
    InternalUpdate;
  end;
end;

procedure UpdateProgressStep(const AValue: Integer);
begin
  if Progress <> nil then
  begin
    if (Progress.Gauge.Progress + AValue) <= Progress.Gauge.MaxValue
    then Progress.Gauge.Progress := Progress.Gauge.Progress + AValue
    else Progress.Gauge.Progress := Progress.Gauge.MaxValue;
    InternalUpdate;
  end;
end;

procedure UpdateProgressMax(const AValue: Integer);
begin
  if Progress <> nil then
  begin
    Progress.Gauge.MaxValue := AValue;
    if Progress.Gauge.Progress > Progress.Gauge.MaxValue
    then Progress.Gauge.Progress := Progress.Gauge.MaxValue;
    InternalUpdate;
  end;
end;

{ TFormProgress }

procedure TFormProgress.FormCreate(Sender: TObject);
begin
  Font := Screen.IconFont;
end;

function TFormProgress.GetStopButton: Boolean;
begin
  Result := BtnStop.Visible;
end;

procedure TFormProgress.SetStopButton(const Value: Boolean);
begin
  if BtnStop.Visible <> Value then
  begin
    BtnStop.Visible := Value;
    if BtnStop.Visible
    then Height := 105
    else Height := 74;
  end;
end;

procedure TFormProgress.BtnStopClick(Sender: TObject);
begin
  StopFlag := True;
end;

function TFormProgress.GetStopFlag: Boolean;
begin
  Result := not BtnStop.Enabled;
end;

procedure TFormProgress.SetStopFlag(const Value: Boolean);
begin
  BtnStop.Enabled := not Value;
end;

procedure TFormProgress.FileProgress(Sender: TObject;
  const CurrPos, MaxPos: Integer);
begin
  if MaxPos > 0 then
  begin
    Gauge.MaxValue := 100;
    Gauge.Progress := Round(100 * CurrPos / MaxPos);
    Update;
    BringToFront;
    Application.ProcessMessages;
  end;
end;

procedure TFormProgress.CheckBreak(Sender: TObject; var IsBreak: Boolean);
begin
  IsBreak := StopFlag;
end;

initialization
  Progress := nil;

finalization
  if Progress <> nil then Progress.Free;

end.
