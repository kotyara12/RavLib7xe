program EchoBot;

uses
  System.StartUpCopy,
  FMX.Forms,
  EchoBot.Main in 'EchoBot.Main.pas' {Main};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
