program RemoteTwain;

uses
  Forms,
  Main in 'Main.pas' {frmMain},
  DataMsg in 'DataMsg.pas',
  SharedUnit in 'SharedUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Remote TWAIN';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
