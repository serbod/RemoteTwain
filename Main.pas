unit Main;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms, Clipbrd, Printers,
  Dialogs, ExtCtrls, StdCtrls, Twain, DelphiTwain, Buttons, ExtDlgs, IniFiles,
  IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent, Menus, DataMsg,
  jpeg, ComCtrls, pngimage, XPMan;

type
  TClientThread = class(TThread)
  private
    ms: TMemoryStream;
    procedure SyncProc();
  protected
    procedure Execute(); override;
  end;

  TfrmMain = class(TForm)
    grpScanner: TGroupBox;
    cbbScanner: TComboBox;
    lbScannerSel: TLabel;
    cbbResolution: TComboBox;
    lbResolutionSel: TLabel;
    grpPreview: TGroupBox;
    spl1: TSplitter;
    imgPreview: TImage;
    btnPreview: TBitBtn;
    btnScan: TBitBtn;
    cbbColorMode: TComboBox;
    lbColorModeSel: TLabel;
    cbbUnits: TComboBox;
    lbUnits: TLabel;
    lbSupportedCaps: TLabel;
    memoDebug: TMemo;
    dlgSavePic: TSavePictureDialog;
    cbbServerName: TComboBox;
    lbServerName: TLabel;
    idTcpClient: TIdTCPClient;
    pmDebug: TPopupMenu;
    mGetSources: TMenuItem;
    mGetSourceCap: TMenuItem;
    mScan: TMenuItem;
    mPreview: TMenuItem;
    pmImagePopup: TPopupMenu;
    mSaveAs: TMenuItem;
    mCopy: TMenuItem;
    btnToFile: TButton;
    btnToClipboard: TButton;
    panButtons: TPanel;
    btnToPrinter: TButton;
    mPrint: TMenuItem;
    dlgPrint: TPrintDialog;
    cbbCapList: TComboBox;
    cbbCapType: TComboBox;
    lbCapList: TLabel;
    lbCapType: TLabel;
    lbStatus: TLabel;
    pgcMain: TPageControl;
    tsScaner: TTabSheet;
    tsDebug: TTabSheet;
    tsAbout: TTabSheet;
    lb1: TLabel;
    lb2: TLabel;
    cbbFormat: TComboBox;
    lbFormat: TLabel;
    edFileSavePath: TEdit;
    btnFileNameSelect: TButton;
    lbFileSavePath: TLabel;
    lb3: TLabel;
    lb4: TLabel;
    XPManifest: TXPManifest;
    procedure FormCreate(Sender: TObject);
    procedure btnPreviewClick(Sender: TObject);
    procedure cbbScannerSelect(Sender: TObject);
    procedure cbbUnitsSelect(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure cbbServerNameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbbServerNameSelect(Sender: TObject);
    procedure idTcpClientConnected(Sender: TObject);
    procedure idTcpClientDisconnected(Sender: TObject);
    procedure pmDebugClick(Sender: TObject);
    procedure mSaveAsClick(Sender: TObject);
    procedure mCopyClick(Sender: TObject);
    procedure mPrintClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbbCapListSelect(Sender: TObject);
    procedure idTcpClientWorkBegin(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCountMax: Integer);
    procedure idTcpClientWork(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCount: Integer);
  private
    { Private declarations }
    ScanMode: string;
    TmpBMP: TBitmap;
    CapList: TStringList;
    ScanTransSize: Integer;
    function SendMsg(Msg: TDataMsg; Conn: TIdTCPConnection): boolean;
    function SendCapMsg(CapName, CapType: string; Conn: TIdTCPConnection): boolean;
    procedure OptionsFromList(OptList: TStringList);
    procedure OptionsToList(OptList: TStringList);
    procedure DebugMsg(rtMsg: TDataMsg);
    function ReadSourceCaps(rtMsg: TDataMsg): Boolean;
  public
    { Public declarations }
    Options: TStringList;
    procedure LoadOptions();
    procedure SaveOptions();
    function ReadCaps(): Boolean;
    procedure OpenServer(ServName: string);
    procedure OnReceive(rtMsg: TDataMsg; Conn: TIdTCPConnection);
  end;

var
  frmMain: TfrmMain;
  ClientThread: TClientThread;
  OptionsFilename: string;

  CurSource: TTwainSource;

  sPreview: string = 'Предпросмотр';

  sInches: string = 'Дюймы';
  sCentimeters: string = 'Сантиметры';
  sPicas: string = 'Picas';
  sPoints: string = 'Точки';
  sTwips: string = 'Twips';
  sPixels: string = 'Пиксели';
  sUnknown: string = 'Неизвестно';

implementation

{$R *.dfm}

//============================================
// TClientThread
//============================================
procedure TClientThread.SyncProc();
var
  rtMsg: TDataMsg;
begin
  rtMsg:=TDataMsg.Create();
  rtMsg.FromStream(ms);
  ms.Clear();
  frmMain.OnReceive(rtMsg, frmMain.idTcpClient);
  rtMsg.Free();
end;

procedure TClientThread.Execute();
begin
  ms:=TMemoryStream.Create();
  while not Terminated do
  begin
    if not frmMain.idTcpClient.Connected then
      Terminate()
    else
    try
      ms.Seek(0, soFromBeginning);
      frmMain.idTcpClient.ReadStream(ms);
      Synchronize(SyncProc);
    except
      on E: Exception do
      begin
        if Terminated or (not frmMain.idTcpClient.Connected) then Exit;
        frmMain.memoDebug.Lines.Add('Read error: '+E.Message);
      end;
    end;
  end;
  ms.Free();
end;

//============================================
function CheckCap(ret: TCapabilityRet; Name: String = ''): Boolean;
var
  sr: string;
begin
  Result := False;
  case ret of
    crSuccess: result:=True;
    crUnsupported:     sr:='Capability not supported by the source';
    crBadOperation:    sr:='Bad combination of values from the parameters.';
    crDependencyError: sr:='Capability depends on another capability which is not properly set';
    crLowMemory:       sr:='The system is short on memory';
    crInvalidState:    sr:='The source or the source manager are not ready to set this capability or do the requested operation';
    crInvalidContainer:sr:='The container used is invalid';
  else sr:='Uncnown error';
  end;
  if Result then Exit;
  //ShowMessage(Name+': '+sr);
  frmMain.memoDebug.Lines.Add(Name+': '+sr);
end;

function TfrmMain.SendMsg(Msg: TDataMsg; Conn: TIdTCPConnection): boolean;
var
  ms: TMemoryStream;
begin
  Result:=false;
  if not Assigned(Msg) then Exit;
  if not Assigned(Conn) then Exit;
  ms:=TMemoryStream.Create();
  Msg.ToStream(ms);
  ms.Seek(0, soFromBeginning);
  Conn.WriteStream(ms, True, true, ms.Size);
  ms.Free();
  memoDebug.Lines.Add('-> '+Msg.ParamsList.Values['cmd']);
  Result:=True;
end;

function TfrmMain.SendCapMsg(CapName, CapType: string; Conn: TIdTCPConnection): boolean;
var
  rtMsg: TDataMsg;
begin
  rtMsg:=TDataMsg.Create();
  rtMsg.ParamsList.Values['cmd']:='GET_SOURCE_CAP';
  rtMsg.ParamsList.Values['source_name']:=cbbScanner.Text;
  rtMsg.ParamsList.Values['cap_name']:=CapName;
  rtMsg.ParamsList.Values['cap_type']:=CapType;
  SendMsg(rtMsg, Conn);
  FreeAndNil(rtMsg);
  Result:=True;
end;

procedure TfrmMain.OptionsFromList(OptList: TStringList);
begin
  if not Assigned(OptList) then Exit;
  cbbScanner.Text:=   OptList.Values['SourceName'];
  cbbUnits.Text:=     OptList.Values['CapUnits'];
  cbbResolution.Text:=OptList.Values['Resolution'];
  cbbColorMode.Text:= OptList.Values['ColorMode'];
  //edSavePath.Text:=   OptList.Values['SavePath'];
end;

procedure TfrmMain.OptionsToList(OptList: TStringList);
begin
  if not Assigned(OptList) then Exit;
  OptList.Clear();
  OptList.Values['SourceName']  := cbbScanner.Text;
  OptList.Values['CapUnits']    := cbbUnits.Text;
  OptList.Values['Resolution']  := cbbResolution.Text;
  OptList.Values['ColorMode']   := cbbColorMode.Text;
  //OptList.Values['SavePath']    := edSavePath.Text;
end;

procedure TfrmMain.LoadOptions();
var
  ini: TIniFile;
  sl: TStringList;
  i: Integer;
  SectionName: string;
begin
  ini:=TIniFile.Create(OptionsFilename);
  SectionName:='Servers';
  sl:=TStringList.Create();
  ini.ReadSectionValues(SectionName, sl);

  for i:=0 to sl.Count-1 do
  begin
    if cbbServerName.Items.IndexOf(sl.ValueFromIndex[i]) < 0 then
      cbbServerName.AddItem(sl.ValueFromIndex[i], nil);
  end;
  sl.Free();

  SectionName:='Main';
  cbbServerName.Text:=ini.ReadString(SectionName, 'ServerHost', '');
  edFileSavePath.Text:=ini.ReadString(SectionName, 'ImageFilesDir', '');
  ini.Free();
end;

procedure TfrmMain.SaveOptions();
var
  ini: TIniFile;
  i: Integer;
  SectionName: string;
begin
  ini:=TIniFile.Create(OptionsFilename);
  SectionName:='Main';
  ini.WriteString(SectionName, 'ServerHost', cbbServerName.Text);
  ini.WriteString(SectionName, 'ImageFilesDir', edFileSavePath.Text);

  SectionName:='Servers';
  for i:=0 to cbbServerName.Items.Count-1 do
  begin
    ini.WriteString(SectionName, 'ServerHost'+IntToStr(i), cbbServerName.Items[i]);
  end;
  ini.UpdateFile();
  ini.Free();
end;

procedure TfrmMain.DebugMsg(rtMsg: TDataMsg);
var
  i: Integer;
begin
  memoDebug.Lines.Add('--------------------');
  for i:=0 to rtMsg.ParamsList.Count-1 do
  begin
    memoDebug.Lines.Add(rtMsg.ParamsList.Names[i]+'='+rtMsg.ParamsList.ValueFromIndex[i]);
  end;
end;

function TfrmMain.ReadCaps(): Boolean;
var
  rtMsg: TDataMsg;
begin
  Result:=False;

  rtMsg:=TDataMsg.Create();
  rtMsg.ParamsList.Values['cmd']:='GET_SOURCE_CAPS';
  rtMsg.ParamsList.Values['source_name']:=cbbScanner.Text;
  SendMsg(rtMsg, idTcpClient);
  rtMsg.Free();

  Exit;

  {
  cbbResolution.Clear();
  cbbResolution.AddItem('100', nil);
  cbbResolution.AddItem('200', nil);
  cbbResolution.AddItem('300', nil);
  cbbResolution.AddItem('400', nil);
  cbbResolution.AddItem('600', nil);
  cbbResolution.AddItem('1200', nil);
  cbbResolution.AddItem('2400', nil);
  cbbResolution.AddItem('4800', nil);
  cbbResolution.AddItem('9600', nil);

  cbbUnits.Clear();
  cbbUnits.AddItem(sInches, nil);
  cbbUnits.AddItem(sCentimeters, nil);
  cbbUnits.AddItem(sPicas, nil);
  cbbUnits.AddItem(sPoints, nil);
  cbbUnits.AddItem(sTwips, nil);
  cbbUnits.AddItem(sPixels, nil);
  cbbUnits.AddItem(sUnknown, nil);

  cbbColorMode.Clear();
  cbbColorMode.AddItem('32 bit color', nil);
  cbbColorMode.AddItem('24 bit color', nil);
  cbbColorMode.AddItem('16 bit color', nil);
  cbbColorMode.AddItem('8 bit color', nil);
  cbbColorMode.AddItem('16 bit mono', nil);
  cbbColorMode.AddItem('8 bit mono', nil);
  cbbColorMode.AddItem('4 bit mono', nil);
  cbbColorMode.AddItem('2 bit mono', nil);
  cbbColorMode.AddItem('1 bit mono', nil);

  SendCapMsg(IntToStr(ICAP_BITDEPTH), 'enum', idTcpClient);
  }
end;

function TfrmMain.ReadSourceCaps(rtMsg: TDataMsg): Boolean;
var
  SrcName, CapName, CapType, DefValue: string;
  ResList: TStringList;
  i: integer;
begin
  Result:=True;
  //DebugMsg(rtMsg);

  SrcName:=rtMsg.ParamsList.Values['source_name'];
  CapName:=rtMsg.ParamsList.Values['cap_name'];
  CapType:=rtMsg.ParamsList.Values['cap_type'];
  DefValue:=rtMsg.ParamsList.Values['default_value'];

//  memoDebug.Lines.Add('Source caps: '+SrcName);
//  memoDebug.Lines.Add('CapName='+CapName);
//  memoDebug.Lines.Add('CapType='+CapType);
//  memoDebug.Lines.Add('=== CapValues: ===');

  if CapType='' then
  begin
    ResList:=TStringList.Create();
    rtMsg.Data.Seek(0, soFromBeginning);
    ResList.LoadFromStream(rtMsg.Data);

    // Debug
    memoDebug.Lines.Add('=== CapValues: ===');
    for i:=0 to ResList.Count-1 do
    begin
      memoDebug.Lines.Add(ResList[i]);
    end;

    if CapName = 'color_modes' then
    begin
      cbbColorMode.Clear();
      for i:=0 to ResList.Count-1 do
      begin
        cbbColorMode.AddItem(ResList[i], nil);
      end;
      cbbColorMode.Text:=DefValue;
    end

    else if CapName = 'file_formats' then
    begin
      cbbFormat.Clear();
      for i:=0 to ResList.Count-1 do
      begin
        cbbFormat.AddItem(ResList[i], nil);
      end;
      cbbFormat.Text:=DefValue;
    end

    else if CapName = 'resolution_list' then
    begin
      cbbResolution.Clear();
      for i:=0 to ResList.Count-1 do
      begin
        cbbResolution.AddItem(ResList[i], nil);
      end;
      cbbResolution.Text:=DefValue;
    end

    else if CapName = 'measure_units' then
    begin
      cbbUnits.Clear();
      for i:=0 to ResList.Count-1 do
      begin
        cbbUnits.AddItem(ResList[i], nil);
      end;
      cbbUnits.Text:=DefValue;
    end;

  end
  else if CapType='array' then
  begin
  end;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Source: TTwainSource;
  i: Integer;
  FName: string;
begin
  // Load cap list
  CapList:=TStringList.Create();
  FName:=IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'capslist.ini';
  if FileExists(FName) then CapList.LoadFromFile(FName);
  for i:=0 to CapList.Count-1 do
  begin
    cbbCapList.AddItem(Trim(CapList.Names[i]), nil);
  end;

  // Load options
  OptionsFilename:=ChangeFileExt(ParamStr(0), '.ini');
  LoadOptions();
  if Length(cbbServerName.Text)>0 then OpenServer(cbbServerName.Text);

  ScanTransSize:=0;
  ScanMode:='';
  //Make sure that the library and Source Manager
  //are loaded

  Exit; // !!!!
//  DTwain.LibraryLoaded := TRUE;
//  DTwain.SourceManagerLoaded := TRUE;

  cbbScanner.AddItem('Выберите сканер', nil);
//  for i:=0 to DTwain.SourceCount-1 do
//  begin
//    Source:=DTwain.Source[i];
//    cbbScanner.AddItem(Source.ProductName, Source);
//  end;
//  cbbScanner.ItemIndex:=0;

end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  SaveOptions();
  if idTcpClient.Connected then
  begin
    if Assigned(ClientThread) then ClientThread.Terminate();
    idTcpClient.Disconnect();
  end;

  CapList.Free();
  //
end;

procedure TfrmMain.btnPreviewClick(Sender: TObject);
var
  SourceIndex: Integer;
  Source: TTwainSource;
begin
  //SelectSource method displays a common Twain dialog
  //to allow the user to select one of the avaliable
  //sources and returns it's index or -1 if either
  //the user pressed Cancel or if there were no sources
  //SourceIndex := DTwain.SelectSource();

//  SourceIndex:=cbbScanner.ItemIndex-1;
//  if (SourceIndex = -1) then Exit;

   //Now that we know the index of the source, we'll
   //get the object for this source
//   Source := DTwain.Source[SourceIndex];
//   Source.ShowUI := False;
//
//   Source.SetIXResolution(50);
//   Source.SetIYResolution(50);
//
//   ScanMode:='prev';
//   //Load source and acquire image
//   Source.Enabled := TRUE;

  pmDebugClick(mPreview);


end;

procedure TfrmMain.cbbScannerSelect(Sender: TObject);
begin
  if cbbScanner.ItemIndex>=0 then
  begin
    ReadCaps();
  end;
end;

procedure TfrmMain.cbbUnitsSelect(Sender: TObject);
begin
  //self.ReadCaps();
end;

procedure TfrmMain.btnScanClick(Sender: TObject);
var
  res: Integer;
begin
  pmDebugClick(mScan);
end;

procedure TfrmMain.OpenServer(ServName: string);
begin
  idTcpClient.Host:=ServName;
  if idTcpClient.Connected then idTcpClient.Disconnect();
  try
    idTcpClient.Connect(10000);
  except
    on E: Exception do frmMain.memoDebug.Lines.Add('Connection error: '+E.Message);
  end;
end;

procedure TfrmMain.cbbServerNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  s: string;
begin
  if Key = VK_RETURN then
  begin
    s:=Trim(cbbServerName.Text);
    if s='' then Exit;
    if cbbServerName.Items.IndexOf(s) < 0 then cbbServerName.Items.Add(s);
    OpenServer(s);
  end;
end;

procedure TfrmMain.cbbServerNameSelect(Sender: TObject);
begin
  OpenServer(cbbServerName.Text);
end;

procedure TfrmMain.idTcpClientConnected(Sender: TObject);
var
  rtMsg: TDataMsg;
begin
  memoDebug.Lines.Add('Connected');
  cbbScanner.Clear();

  ClientThread:=TClientThread.Create(true);
  ClientThread.FreeOnTerminate:=True;
  ClientThread.Resume();

  rtMsg:=TDataMsg.Create();
  rtMsg.ParamsList.Values['cmd']:='GET_SOURCES';
  SendMsg(rtMsg, idTcpClient);
  rtMsg.Free();
end;

procedure TfrmMain.idTcpClientDisconnected(Sender: TObject);
begin
  memoDebug.Lines.Add('Disconnected');
  ClientThread.Terminate();
end;

procedure TfrmMain.OnReceive(rtMsg: TDataMsg; Conn: TIdTCPConnection);
var
  Cmd: string;
  sl: TStringList;
  i, bpp: Integer;
  iScanLine, iBytes: Integer;
  sImgType, sFileName: string;
  PLine: Pointer;
begin
  Cmd:=rtMsg.ParamsList.Values['cmd'];
  if (Cmd<>'STATUS') and (Cmd<>'SCAN_LINE') then DebugMsg(rtMsg);

  if Cmd='' then
  begin

  end

  else if Cmd='ERROR' then
  begin
    memoDebug.Lines.Add('Error: '+rtMsg.ParamsList.Values['err_text']);
  end

  else if Cmd='SOURCE_CAP' then
  begin
    ReadSourceCaps(rtMsg);
  end

  else if Cmd='SCAN_BEGIN' then
  begin
    memoDebug.Lines.Add('SCAN_BEGIN '+rtMsg.ParamsList.Values['source_name']);
    ScanMode:='scan';
  end

  else if Cmd='SCAN_LINE' then
  begin
    ScanMode:='scan';
    if not Assigned(TmpBMP) then
    begin
      //TmpBMP:=TBitmap.Create();
      TmpBMP:=imgPreview.Picture.Bitmap;
      TmpBMP.Height:=StrToIntDef(rtMsg.ParamsList.Values['img_width'], 0);
      TmpBMP.Width:=StrToIntDef(rtMsg.ParamsList.Values['img_height'], 0);
      bpp:=StrToIntDef(rtMsg.ParamsList.Values['img_bpp'], 4);
      TmpBMP.PixelFormat:=pfDevice;
    end;

    iScanLine := StrToIntDef(rtMsg.ParamsList.Values['scanline_current'], 0);
    iBytes := bpp * TmpBMP.Width;
    if rtMsg.Data.Size < iBytes then iBytes := rtMsg.Data.Size;
    PLine:=imgPreview.Picture.Bitmap.ScanLine[iScanLine];
    rtMsg.Data.Read(PLine, iBytes);
  end

  else if Cmd='SCAN_END' then
  begin
    //ScanMode:='transfer';
    ScanTransSize:=0;
    memoDebug.Lines.Add('SCAN_END '+rtMsg.ParamsList.Values['source_name']);
    //memoDebug.Lines.Add('img_width='+rtMsg.ParamsList.Values['img_width']);
    //memoDebug.Lines.Add('img_height='+rtMsg.ParamsList.Values['img_height']);
    //memoDebug.Lines.Add('img_type='+rtMsg.ParamsList.Values['img_type']);
    memoDebug.Lines.Add('Data size='+IntToStr(rtMsg.Data.Size));
    grpPreview.Caption:=sPreview+'   '+rtMsg.ParamsList.Values['img_width']
    +' x '+rtMsg.ParamsList.Values['img_height'];
    ScanMode:='';
    rtMsg.Data.Seek(0, soFromBeginning);
    sImgType:=rtMsg.ParamsList.Values['img_type'];
    if sImgType='BITMAP' then
    begin
      imgPreview.Picture.Bitmap.LoadFromStream(rtMsg.Data);
      lbStatus.Caption:='Изображение принято';
    end
    else if sImgType='FILE' then
    begin
      sFileName:=IncludeTrailingPathDelimiter(edFileSavePath.Text)+'image.bmp';
      rtMsg.Data.SaveToFile(sFileName);
      lbStatus.Caption:='Файл с изображением записан';
    end;

  end

  else if Cmd='SOURCE' then
  begin
    memoDebug.Lines.Add('SOURCE '+rtMsg.ParamsList.Values['source_name']);
    memoDebug.Lines.Add('ProductName='+rtMsg.ParamsList.Values['ProductName']);
    memoDebug.Lines.Add('VersionInfo='+rtMsg.ParamsList.Values['VersionInfo']);
    memoDebug.Lines.Add('Manufacturer='+rtMsg.ParamsList.Values['Manufacturer']);
    memoDebug.Lines.Add('ProductFamily='+rtMsg.ParamsList.Values['ProductFamily']);
    cbbScanner.AddItem(rtMsg.ParamsList.Values['source_name'], nil);
  end

  else if Cmd='GET_SOURCES_OK' then
  begin
    memoDebug.Lines.Add('GET_SOURCES_OK');
    if cbbScanner.Items.Count>0 then
    begin
      cbbScanner.ItemIndex:=0;
      ReadCaps();
    end;
  end

  else if Cmd='STATUS' then
  begin
    lbStatus.Caption:=rtMsg.ParamsList.Values['status'];
  end

  else if Cmd='CAPS_SET_OK' then
  begin
    memoDebug.Lines.Add('CAPS_SET_OK');
  end

  else if Cmd='' then
  begin

  end;
end;

procedure TfrmMain.pmDebugClick(Sender: TObject);
var
  m: TMenuItem;
  rtMsg: TDataMsg;
begin
  if (Sender is TMenuItem) then m:=TMenuItem(Sender) else Exit;
  rtMsg:=TDataMsg.Create();
  if m = mGetSources then
  begin
    rtMsg.ParamsList.Values['cmd']:='GET_SOURCES';
  end

  else if m = mGetSourceCap then
  begin
    rtMsg.ParamsList.Values['cmd']:='GET_SOURCE_CAPS';
    rtMsg.ParamsList.Values['source_name']:=cbbScanner.Text;
  end

  else if m = mScan then
  begin
    rtMsg.ParamsList.Values['cmd']:='SCAN';
    rtMsg.ParamsList.Values['source_name']:=cbbScanner.Text;
    rtMsg.ParamsList.Values['color_mode']:=cbbColorMode.Text;
    rtMsg.ParamsList.Values['file_format']:=cbbFormat.Text;
    rtMsg.ParamsList.Values['resolution']:=cbbResolution.Text;
  end

  else if m = mPreview then
  begin
    rtMsg.ParamsList.Values['cmd']:='SCAN';
    rtMsg.ParamsList.Values['source_name']:=cbbScanner.Text;
    rtMsg.ParamsList.Values['color_mode']:=cbbColorMode.Text;
    //rtMsg.ParamsList.Values['file_format']:=cbbFormat.Text;
    rtMsg.ParamsList.Values['resolution']:='50';
  end;
  SendMsg(rtMsg, idTcpClient);
  FreeAndNil(rtMsg);
end;

procedure TfrmMain.mSaveAsClick(Sender: TObject);
var
  sExt: string;
  jpgImg: TJPEGImage;
  pngImg: TPNGObject;
begin
  //dlgSavePic.Filter:='All (*.jpg;*.jpeg;*.jpg;*.jpeg;*.bmp;*.ico;*.emf;*.wmf)|*.jpg;*.jpeg;*.jpg;*.jpeg;*.bmp;*.ico;*.emf;*.wmf|JPEG Image File (*.jpg)|*.jpg|JPEG Image File (*.jpeg)|*.jpeg|JPEG Image File (*.jpg)|*.jpg|JPEG Image File (*.jpeg)|*.jpeg|Bitmaps (*.bmp)|*.bmp|Icons (*.ico)|*.ico|Enhanced Metafiles (*.emf)|*.emf|Metafiles (*.wmf)|*.wmf';
  dlgSavePic.Filter:='PNG Image File (*.png)|*.png|Bitmaps (*.bmp)|*.bmp|JPEG Image File (*.jpg)|*.jpg';
  dlgSavePic.DefaultExt:='png';
  if not dlgSavePic.Execute then Exit;

  sExt:=AnsiLowerCase(ExtractFileExt(dlgSavePic.FileName));
  if sExt='.bmp' then
  begin
    imgPreview.Picture.SaveToFile(dlgSavePic.FileName);
  end
  else if sExt='.jpg' then
  begin
    jpgImg:=TJPEGImage.Create();
    try
      jpgImg.Assign(imgPreview.Picture.Bitmap);
      jpgImg.SaveToFile(dlgSavePic.FileName);
    finally
      jpgImg.Free();
    end;
  end
  else if sExt='.png' then
  begin
    pngImg:=TPNGObject.Create();
    try
      pngImg.Assign(imgPreview.Picture.Bitmap);
      pngImg.SaveToFile(dlgSavePic.FileName);
    finally
      pngImg.Free();
    end;
  end;
end;

procedure TfrmMain.mCopyClick(Sender: TObject);
var
  AFormat: Word;
  AData: THandle;
  APalette: HPALETTE;
begin
  //imgPreview.Picture.SaveToClipboardFormat(CF_BITMAP, AData, APalette);
  imgPreview.Picture.SaveToClipboardFormat(AFormat, AData, APalette);
  ClipBoard.SetAsHandle(AFormat, AData);
end;

procedure TfrmMain.mPrintClick(Sender: TObject);
var
  rect: TRect;
begin
  if not dlgPrint.Execute() then Exit;
  Printer.BeginDoc();
  //Printer.Canvas.Assign(imgPreview.Canvas);
//  rect.Left:=0;
//  rect.Top:=0;
//  rect.Right:=imgPreview.Canvas.ClipRect
  Printer.Canvas.StretchDraw(Printer.Canvas.ClipRect, imgPreview.Picture.Graphic);
  Printer.EndDoc();
end;

procedure TfrmMain.cbbCapListSelect(Sender: TObject);
begin
  SendCapMsg(CapList.Values[cbbCapList.Text], cbbCapType.Text, idTcpClient);
end;

procedure TfrmMain.idTcpClientWorkBegin(Sender: TObject;
  AWorkMode: TWorkMode; const AWorkCountMax: Integer);
begin
  if AWorkMode = wmWrite Then Exit;
  if ScanMode = '' then Exit;
  if AWorkCountMax < 10000 then Exit;
  ScanTransSize:=AWorkCountMax;
end;

procedure TfrmMain.idTcpClientWork(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
var
  rPerc: real;
begin
  if AWorkMode = wmWrite Then Exit;
  if ScanTransSize = 0 then Exit;
  rPerc:=AWorkCount/(ScanTransSize/100);
  lbStatus.Caption:='Transfering '+FormatFloat('##0.00',rPerc)+'%';
end;

end.
