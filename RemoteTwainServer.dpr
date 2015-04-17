program RemoteTwainServer;

uses
  Forms,
  ServMain in 'ServMain.pas' {frmSrvMain},
  DataMsg in 'DataMsg.pas',
  SharedUnit in 'SharedUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Remote TWAIN Server';
  Application.CreateForm(TfrmSrvMain, frmSrvMain);
  Application.Run;
end.
