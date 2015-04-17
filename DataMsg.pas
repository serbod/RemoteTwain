unit DataMsg;

interface
uses SysUtils, Classes;

type
  TDataMsg = class(TObject)
  public
    SourceID: Integer;
    TargetID: Integer;
    ParamsList: TStringList;
    Data: TMemoryStream;
    constructor Create();
    destructor Destroy; override;
    function ToStream(AStream: TStream): boolean;
    function FromStream(AStream: TStream): Boolean;
  end;

implementation

//============================================
// TDataMsg
//============================================
constructor TDataMsg.Create();
begin
  Self.ParamsList:=TStringList.Create();
  Self.Data:=TMemoryStream.Create();
end;

destructor TDataMsg.Destroy;
begin
  FreeAndNil(Self.Data);
  FreeAndNil(Self.ParamsList);
end;

function TDataMsg.ToStream(AStream: TStream): boolean;
var
  ms: TMemoryStream;
  iParamsSize, iDataSize: Cardinal;
begin
  Result:=False;
  if not Assigned(AStream) then Exit;
  iParamsSize:=Length(Self.ParamsList.Text);
  iDataSize:=Self.Data.Size;
  ms:=TMemoryStream.Create();
  ms.Write(Self.SourceID, SizeOf(Self.SourceID));
  ms.Write(Self.TargetID, SizeOf(Self.TargetID));
  ms.Write(iParamsSize, SizeOf(iParamsSize));
  Self.ParamsList.SaveToStream(ms);
  ms.Write(iDataSize, SizeOf(iDataSize));
  Self.Data.Seek(0, soFromBeginning);
  ms.CopyFrom(Self.Data, iDataSize);

  ms.Seek(0, soFromBeginning);
  AStream.Size:=ms.Size;
  AStream.Seek(0, soFromBeginning);
  ms.SaveToStream(AStream);
  FreeAndNil(ms);
  Result:=true;
end;

function TDataMsg.FromStream(AStream: TStream): Boolean;
var
  ms: TMemoryStream;
  iParamsSize, iDataSize: Cardinal;
begin
  Result:=False;
  if not Assigned(AStream) then Exit;
  AStream.Seek(0, soFromBeginning);
  AStream.Read(Self.SourceID, SizeOf(Self.SourceID));
  AStream.Read(Self.TargetID, SizeOf(Self.TargetID));
  AStream.Read(iParamsSize, SizeOf(iParamsSize));

  Self.ParamsList.Clear();
  ms:=TMemoryStream.Create();
  ms.CopyFrom(AStream, iParamsSize);
  ms.Seek(0, soFromBeginning);
  Self.ParamsList.LoadFromStream(ms);
  FreeAndNil(ms);

  Self.Data.Clear();
  AStream.Read(iDataSize, SizeOf(iDataSize));
  Self.Data.CopyFrom(AStream, iDataSize);
  Result:=True;
end;


end.
