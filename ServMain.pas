unit ServMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, IdThreadMgr, IdThreadMgrDefault, IdBaseComponent,
  IdComponent, IdTCPServer, IdTCPConnection, DelphiTwain, StdCtrls,
  CoolTrayIcon, SyncObjs, Twain, ComCtrls, ExtCtrls, DataMsg, AppEvnts,
  SharedUnit;

type
  TColorMode = record
    Name: string;
    PixelType: DWORD;
    BitPerPixel: DWORD;
  end;
  TColorModeList = array of TColorMode;

  TfrmSrvMain = class(TForm)
    idTcpSrv: TIdTCPServer;
    idThrdMgr: TIdThreadMgrDefault;
    memoDebug: TMemo;
    pcMain: TPageControl;
    tsDebug: TTabSheet;
    tsPreview: TTabSheet;
    tsOptions: TTabSheet;
    tsAbout: TTabSheet;
    imgPreview: TImage;
    cbbScanner: TComboBox;
    btnPreview: TButton;
    lbScanner: TLabel;
    cbbUnits: TComboBox;
    lbUnits: TLabel;
    cbbColorMode: TComboBox;
    lbColorMode: TLabel;
    cbbResolution: TComboBox;
    lbResolution: TLabel;
    lb1: TLabel;
    lb2: TLabel;
    lb3: TLabel;
    cbbFormat: TComboBox;
    lbFormat: TLabel;
    btnScan: TButton;
    AppEvents: TApplicationEvents;
    pmTrayMenu: TPopupMenu;
    mniExit: TMenuItem;
    procedure TrayIconClick(Sender: TObject);
    procedure idTcpSrvExecute(AThread: TIdPeerThread);
    procedure FormCreate(Sender: TObject);
    procedure idTcpSrvConnect(AThread: TIdPeerThread);
    procedure idTcpSrvDisconnect(AThread: TIdPeerThread);
    procedure DTwainTwainAcquire(Sender: TObject; const Index: Integer;
      Image: TBitmap; var Cancel: Boolean);
    procedure DTwainAcquireError(Sender: TObject; const Index: Integer;
      ErrorCode, Additional: Integer);
    procedure DTwainAcquireCancel(Sender: TObject; const Index: Integer);
    procedure DTwainAcquireProgress(Sender: TObject; const Index: Integer;
      const Image: HBITMAP; const Current, Total: Integer);
    procedure cbbScannerSelect(Sender: TObject);
    procedure btnPreviewClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbbFormatChange(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure DTwainSourceFileTransfer(Sender: TObject;
      const Index: Integer; Filename: TW_STR255; Format: TTwainFormat;
      var Cancel: Boolean);
    procedure AppEventsException(Sender: TObject; E: Exception);
    procedure mniExitClick(Sender: TObject);
  private
    { Private declarations }
    CurSource: TTwainSource;
    CurConn: TIdTCPConnection;
    CurColorMode: TColorMode;
    ColorModeList: TColorModeList;
    //ScanMode: string;
    TmpBMP: TBitmap;
    SyncMsg: TDataMsg;
    ImgFileName: string;
    function SendMsg(Msg: TDataMsg; Conn: TIdTCPConnection): boolean;
    function SendErrMsg(Msg: string; Conn: TIdTCPConnection): boolean;
    function SendStatusMsg(Msg: string; Conn: TIdTCPConnection): boolean;
    procedure GetSource(n: integer; rtMsgOut: TDataMsg);
    procedure GetSourceCap(rtMsg: TDataMsg; Conn: TIdTCPConnection);
    procedure GetSourceCaps(rtMsg: TDataMsg; Conn: TIdTCPConnection);
    procedure SetSourceCaps(rtMsg: TDataMsg; Conn: TIdTCPConnection);
    procedure SyncProc();
  public
    { Public declarations }
    CS : TCriticalSection;
    DTwain: TDelphiTwain;
    TrayIcon: TCoolTrayIcon;
    function ReadCaps(Conn: TIdTCPConnection): Boolean;
    procedure StartScan(rtMsg: TDataMsg; Conn: TIdTCPConnection);
  end;

  TRTClient = class(TObject)
  public
    ClientID: string;
    ClientHost: string;
    ClientUser: string;
    Conn: TIdTCPConnection;
    Thread: TThread;
  end;

var
  frmSrvMain: TfrmSrvMain;

implementation

{$R *.dfm}

//============================================
function TfrmSrvMain.SendMsg(Msg: TDataMsg; Conn: TIdTCPConnection): boolean;
var
  ms: TMemoryStream;
begin
  Result:=false;
  if not Assigned(Msg) then Exit;
  if not Assigned(Conn) then Exit;
  ms:=TMemoryStream.Create();
  Msg.ToStream(ms);
  ms.Seek(0, soFromBeginning);
  Conn.WriteStream(ms, True, True, ms.Size);
  ms.Free();
  Result:=True;
end;

function TfrmSrvMain.SendErrMsg(Msg: string; Conn: TIdTCPConnection): boolean;
var
  rtMsgOut: TDataMsg;
begin
  Result:=false;
  if Msg='' then Exit;
  if not Assigned(Conn) then Exit;
  rtMsgOut:=TDataMsg.Create();
  rtMsgOut.ParamsList.Values['cmd']:='ERROR';
  rtMsgOut.ParamsList.Values['err_text']:=Msg;
  SendMsg(rtMsgOut, Conn);
  rtMsgOut.Free();
  Result:=True;
end;

function TfrmSrvMain.SendStatusMsg(Msg: string; Conn: TIdTCPConnection): boolean;
var
  rtMsgOut: TDataMsg;
begin
  Result:=false;
  if Msg='' then Exit;
  if not Assigned(Conn) then Exit;
  rtMsgOut:=TDataMsg.Create();
  rtMsgOut.ParamsList.Values['cmd']:='STATUS';
  rtMsgOut.ParamsList.Values['status']:=Msg;
  SendMsg(rtMsgOut, Conn);
  rtMsgOut.Free();
  Result:=True;
end;

function TfrmSrvMain.ReadCaps(Conn: TIdTCPConnection): Boolean;
var
  Source: TTwainSource;
  rx, ry: TTwainResolution;
  ex, ey: Extended;
  BitDepth, CurBitDepth: Word;
  BitDepthList: TTwainBitDepth;
  CapUnitList: TTwainUnitSet;
  CapUnit: TTwainUnit;
  i, n, iStep, iMax, iCurItem, iDefItem: Integer;
  ItemType, CurPixelType, DefPixelType: TW_UINT16;
  ItemList, PixelTypes: TGetCapabilityList;
  SetList: TSetCapabilityList;
  s, sMin, sMax, sStep, sDef, sCur: string;
  rtMsg: TDataMsg;
begin
  Result:=False;
  if not Assigned(CurSource) then Exit;

    Source:=CurSource;

    // Get cap units
    if CheckCap(Source.GetICapUnits(CapUnit, CapUnitList), 'GetICapUnits') then
    begin
      cbbUnits.Clear();
      if tuInches in CapUnitList then cbbUnits.AddItem(sInches, nil);
      if tuCentimeters in CapUnitList then cbbUnits.AddItem(sCentimeters, nil);
      if tuPicas in CapUnitList then cbbUnits.AddItem(sPicas, nil);
      if tuPoints in CapUnitList then cbbUnits.AddItem(sPoints, nil);
      if tuTwips in CapUnitList then cbbUnits.AddItem(sTwips, nil);
      if tuPixels in CapUnitList then cbbUnits.AddItem(sPixels, nil);
      if tuUnknown in CapUnitList then cbbUnits.AddItem(sUnknown, nil);
    end;

    CapUnit:=tuInches;
    {if cbbUnits.ItemIndex<>-1 then
    begin
      if cbbUnits.Text=sInches then CapUnit:=tuInches
      else if cbbUnits.Text=sInches then CapUnit:=tuInches
      else if cbbUnits.Text=sCentimeters then CapUnit:=tuCentimeters
      else if cbbUnits.Text=sPicas then CapUnit:=tuPicas
      else if cbbUnits.Text=sPoints then CapUnit:=tuPoints
      else if cbbUnits.Text=sTwips then CapUnit:=tuTwips
      else if cbbUnits.Text=sPixels then CapUnit:=tuPixels
      else if cbbUnits.Text=sUnknown then CapUnit:=tuUnknown;
    end; }

    if CheckCap(Source.SetICapUnits(CapUnit), 'SetICapUnits') then
    begin
      cbbUnits.Text:=cbbUnits.Items[0];
    end
    else
    begin
      if CheckCap(Source.GetICapUnits(CapUnit, CapUnitList), 'GetICapUnits') then
      begin
        cbbUnits.Text:=CapUnitToStr(CapUnit);
      end;
    end;

    {// Get supported caps
    if CheckCap(Source.GetArrayValue(CAP_SUPPORTEDCAPS, ItemType, ItemList), 'GetArrayValue CAP_SUPPORTEDCAPS') then
    begin
      memoDebug.Lines.Add('Supported caps:');
      for i:=0 to Length(ItemList)-1 do
      begin
        memoDebug.Lines.Add(ItemList[i]);
      end;
    end; }

    // Pixel types list
    SetLength(ColorModeList, 0);
    cbbColorMode.Clear();
    if CheckCap(Source.GetEnumerationValue(ICAP_PIXELTYPE, ItemType, PixelTypes, iCurItem, iDefItem), 'GetEnumerationValue(ICAP_PIXELTYPE)') then
    begin
      // Memorize current settings
      DefPixelType:=StrToIntDef(PixelTypes[iCurItem], -1);
      CheckCap(Source.GetIBitDepth(CurBitDepth, BitDepthList), 'GetIBitDepth(CurBitDepth)');
      // For each pixel type get bit depth
      for i:=0 to Length(PixelTypes)-1 do
      begin
        CurPixelType:=StrToIntDef(PixelTypes[i], -1);
        if CheckCap(Source.SetOneValue(ICAP_PIXELTYPE, TWTY_UINT16, @CurPixelType), 'SetOneValue(ICAP_PIXELTYPE)') then
        begin
          if CheckCap(Source.GetIBitDepth(BitDepth, BitDepthList), 'GetIBitDepth') then
          begin
            for n:=0 to Length(BitDepthList)-1 do
            begin
              s:=''+ItemToStr(Integer(CurPixelType), 'pixel_types')+' '+Format('%u', [BitDepthList[n]])+' bit';
              cbbColorMode.AddItem(s, nil);
              SetLength(ColorModeList, Length(ColorModeList)+1);
              with ColorModeList[Length(ColorModeList)-1] do
              begin
                Name:=s;
                PixelType:=CurPixelType;
                BitPerPixel:=BitDepthList[n];
              end;
            end;
          end;
        end;
      end;
      CheckCap(Source.SetOneValue(ICAP_PIXELTYPE, TWTY_UINT16, @DefPixelType), 'SetOneValue(ICAP_PIXELTYPE)');
      CheckCap(Source.SetIBitDepth(CurBitDepth), 'SetIBitDepth(CurBitDepth)');

      // Set current color mode in combobox
      for i:=0 to Length(ColorModeList)-1 do
      begin
        with ColorModeList[i] do
        begin
          if (PixelType = DefPixelType) and (BitPerPixel = CurBitDepth) then
          begin
            cbbColorMode.Text := Name;
            Break;
          end;
        end;
      end;
    end;

    // Output format list
    //CurSource.SetupFileTransfer('ss', tfBMP);
    // ICAP_IMAGEFILEFORMAT
    // ICAP_XFERMECH

    cbbFormat.Clear();
    cbbFormat.AddItem(sTransferNative, nil);
    cbbFormat.AddItem(sTransferMemory, nil);
    if CheckCap(Source.GetEnumerationValue(ICAP_IMAGEFILEFORMAT, ItemType, ItemList, iCurItem, iDefItem), 'GetEnumerationValue(ICAP_IMAGEFILEFORMAT)') then
    begin
      for i:=0 to Length(ItemList)-1 do
      begin
        cbbFormat.AddItem(ItemToStr(StrToIntDef(ItemList[i], -1), 'img_formats'), nil);
      end;
    end;
    cbbFormat.Text:=cbbFormat.Items[1];

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
    cbbResolution.Text:=cbbResolution.Items[2];

    // Get resolutions list
    {if CheckCap(Source.GetRangeValue(ICAP_XRESOLUTION, ItemType, sMin, sMax, sStep, sDef, sCur), 'GetRangeValue ICAP_XRESOLUTION') then
    begin
      memoDebug.Lines.Add('Supported X-Resolution:');
      memoDebug.Lines.Add('Min='+sMin);
      memoDebug.Lines.Add('Max='+sMax);
      memoDebug.Lines.Add('Step='+sStep);
      memoDebug.Lines.Add('Cur='+sCur);
      memoDebug.Lines.Add('Def='+sDef);
      Exit;
    end;}
    //if CheckCap(Source.GetEnumerationValue(ICAP_XRESOLUTION, ItemType, ItemList, iCurItem, iDefItem), 'GetEnumerationValue ICAP_XRESOLUTION') then
    //if CheckCap(Source.GetArrayValue(ICAP_XRESOLUTION, ItemType, ItemList), 'GetArrayValue ICAP_XRESOLUTION') then
//    begin
//      for i:=0 to Length(ItemList)-1 do
//      begin
//        cbbResolution.AddItem(ItemList[i], nil);
//      end;
//      Exit;
//    end;

    {if CheckCap(Source.GetIXResolution(ex, rx), 'GetIXResolution') then
    begin
      cbbResolution.Clear();
      for i:=0 to Length(rx)-1 do
      begin
        cbbResolution.AddItem(Format('%n', [rx[i]]), nil);
      end;

    end; }
    //Source.GetIYResolution(ey, ry);
    {if cbbColorMode.Items.Count>0 then cbbColorMode.ItemIndex:=cbbColorMode.Items.Count-1;
    cbbFormat.ItemIndex:=1;
    cbbResolution.ItemIndex:=2; }

    if Assigned(Conn) then
    begin
      // Send color modes list
      rtMsg:=TDataMsg.Create();
      rtMsg.ParamsList.Values['cmd']:='SOURCE_CAP';
      rtMsg.ParamsList.Values['source_name']:=Source.ProductName;
      rtMsg.ParamsList.Values['cap_name']:='color_modes';
      rtMsg.ParamsList.Values['cap_type']:='';
      rtMsg.ParamsList.Values['default_value']:=cbbColorMode.Text;
      cbbColorMode.Items.SaveToStream(rtMsg.Data);
      SendMsg(rtMsg, CurConn);
      rtMsg.Free();

      // Send file formats list
      rtMsg:=TDataMsg.Create();
      rtMsg.ParamsList.Values['cmd']:='SOURCE_CAP';
      rtMsg.ParamsList.Values['source_name']:=Source.ProductName;
      rtMsg.ParamsList.Values['cap_name']:='file_formats';
      rtMsg.ParamsList.Values['cap_type']:='';
      rtMsg.ParamsList.Values['default_value']:=cbbFormat.Text;
      cbbFormat.Items.SaveToStream(rtMsg.Data);
      SendMsg(rtMsg, CurConn);
      rtMsg.Free();

      // Send resolution list
      rtMsg:=TDataMsg.Create();
      rtMsg.ParamsList.Values['cmd']:='SOURCE_CAP';
      rtMsg.ParamsList.Values['source_name']:=Source.ProductName;
      rtMsg.ParamsList.Values['cap_name']:='resolution_list';
      rtMsg.ParamsList.Values['default_value']:=cbbResolution.Text;
      rtMsg.ParamsList.Values['cap_type']:='';
      cbbResolution.Items.SaveToStream(rtMsg.Data);
      SendMsg(rtMsg, CurConn);
      rtMsg.Free();

      // Send measure units list
      rtMsg:=TDataMsg.Create();
      rtMsg.ParamsList.Values['cmd']:='SOURCE_CAP';
      rtMsg.ParamsList.Values['source_name']:=Source.ProductName;
      rtMsg.ParamsList.Values['cap_name']:='measure_units';
      rtMsg.ParamsList.Values['default_value']:=cbbUnits.Text;
      rtMsg.ParamsList.Values['cap_type']:='';
      cbbUnits.Items.SaveToStream(rtMsg.Data);
      SendMsg(rtMsg, CurConn);
      rtMsg.Free();
    end;

end;

procedure TfrmSrvMain.GetSource(n: integer; rtMsgOut: TDataMsg);
var
  Source: TTwainSource;
begin
  Source:=DTwain.Source[n];
  rtMsgOut.ParamsList.Values['cmd']:='SOURCE';
  rtMsgOut.ParamsList.Values['source_name']:=Source.ProductName;
  rtMsgOut.ParamsList.Values['ProductName']:=Source.ProductName;
  rtMsgOut.ParamsList.Values['VersionInfo']:=Source.VersionInfo;
  rtMsgOut.ParamsList.Values['Manufacturer']:=Source.Manufacturer;
  rtMsgOut.ParamsList.Values['ProductFamily']:=Source.ProductFamily;
end;

procedure TfrmSrvMain.GetSourceCaps(rtMsg: TDataMsg; Conn: TIdTCPConnection);
var
  Source: TTwainSource;
  SrcName: string;
  i: integer;
begin
  SrcName:=rtMsg.ParamsList.Values['source_name'];
  Source:=nil;
  for i:=0 to DTwain.SourceCount-1 do
  begin
    if DTwain.Source[i].ProductName = SrcName then
    begin
      Source:=DTwain.Source[i];
      Break;
    end;
  end;
  if not Assigned(Source) then
  begin
    memoDebug.Lines.Add('Source not found: '+SrcName);
    SendErrMsg(sErrSrcNotFound+': '+SrcName, Conn);
    Exit;
  end;

  Source.Loaded := TRUE;
  CurSource:=Source;

  cbbScanner.Text:=CurSource.ProductName;
  ReadCaps(Conn);

  Source.Loaded:=false;
  CurSource:=nil;

end;

procedure TfrmSrvMain.GetSourceCap(rtMsg: TDataMsg; Conn: TIdTCPConnection);
var
  Source: TTwainSource;
  SrcName, CapName, CapType, ErrDesc: string;
  rtMsgOut: TDataMsg;
  i: Integer;
  iStep, iMax, iCurItem, iDefItem: Integer;
  sMin, sMax, sStep, sDef, sCur: string;
  ItemType, CapID: TW_UINT16;
  ItemList: TGetCapabilityList;
  ResList: TStringList;

begin
  SrcName:=rtMsg.ParamsList.Values['source_name'];
  CapName:=rtMsg.ParamsList.Values['cap_name'];
  CapType:=rtMsg.ParamsList.Values['cap_type'];
  Source:=nil;
  for i:=0 to DTwain.SourceCount-1 do
  begin
    if DTwain.Source[i].ProductName = SrcName then
    begin
      Source:=DTwain.Source[i];
      Break;
    end;
  end;
  if not Assigned(Source) then
  begin
    memoDebug.Lines.Add('Source not found: '+SrcName);
    SendErrMsg(sErrSrcNotFound+': '+SrcName, Conn);
    Exit;
  end;

  rtMsgOut:=TDataMsg.Create();
  rtMsgOut.ParamsList.Values['source_name']:=SrcName;

  ErrDesc:='';
  ResList:=TStringList.Create();
  CapID:=StrToIntDef(CapName, 0);
  if CapType='' then
  begin
    if CapName = 'resolution' then
    begin

    end;

  end
  else if CapType='array' then
  begin
    if CheckCap(Source.GetArrayValue(CapID, ItemType, ItemList), 'GetArrayValue '+CapName) then
    begin
      for i:=0 to Length(ItemList)-1 do
      begin
        ResList.Add(ItemList[i]);
      end;
    end
    else ErrDesc:='GetArrayValue '+CapName+' error';
  end

  else if CapType='enum' then
  begin
    if CheckCap(Source.GetEnumerationValue(CapID, ItemType, ItemList, iCurItem, iDefItem), 'GetEnumerationValue '+CapName) then
    begin
      rtMsgOut.ParamsList.Values['cur_item']:=IntToStr(iCurItem);
      rtMsgOut.ParamsList.Values['def_item']:=IntToStr(iDefItem);
      for i:=0 to Length(ItemList)-1 do
      begin
        ResList.Add(ItemList[i]);
      end;
    end
    else ErrDesc:='GetEnumerationValue '+CapName+' error';
  end

  else if CapType='range' then
  begin
    if CheckCap(Source.GetRangeValue(CapID, ItemType, sMin, sMax, sStep, sDef, sCur), 'GetRangeValue '+CapName) then
    begin
      ResList.Add('min='+sMin);
      ResList.Add('max='+sMax);
      ResList.Add('step='+sStep);
      ResList.Add('cur='+sCur);
      ResList.Add('def='+sDef);
    end
    else ErrDesc:='GetRangeValue '+CapName+' error';
  end;

  if ErrDesc<>'' then
  begin
    rtMsgOut.ParamsList.Values['cmd']:='ERROR';
    rtMsgOut.ParamsList.Values['err_text']:=ErrDesc;
  end
  else
  begin
    rtMsgOut.ParamsList.Values['cmd']:='SOURCE_CAP';
    rtMsgOut.ParamsList.Values['cap_name']:=CapName;
    rtMsgOut.ParamsList.Values['cap_type']:=CapType;
    ResList.SaveToStream(rtMsgOut.Data);
  end;
  //rtMsgOut.ParamsList.Values['']:='';
  ResList.Free();
  SendMsg(rtMsgOut, Conn);
  rtMsgOut.Free();
end;

procedure TfrmSrvMain.SetSourceCaps(rtMsg: TDataMsg; Conn: TIdTCPConnection);
var
  Source: TTwainSource;
  SrcName, CapName, CapType, ErrDesc: string;
  rtMsgOut: TDataMsg;
  i: Integer;
  ItemType, CapID, CapValue: TW_UINT16;
  plst: TStringList;
begin
  SrcName:=rtMsg.ParamsList.Values['source_name'];
  Source:=nil;
  for i:=0 to DTwain.SourceCount-1 do
  begin
    if DTwain.Source[i].ProductName = SrcName then
    begin
      Source:=DTwain.Source[i];
      Break;
    end;
  end;
  if not Assigned(Source) then
  begin
    memoDebug.Lines.Add('Source not found: '+SrcName);
    SendErrMsg(sErrSrcNotFound+': '+SrcName, Conn);
    Exit;
  end;

  plst:=rtMsg.ParamsList;
  for i:=0 to plst.Count-1 do
  begin
    CapName:=plst.Names[i];
    if CapName='source_name' then Continue;
    CapID:=StrToIntDef(CapName, 0);
    CapValue:=StrToIntDef(plst.ValueFromIndex[i], 7777);
    if CapID=0 then Continue;
    if CapValue=7777 then Continue;
    if not CheckCap(Source.SetOneValue(CapID, TWTY_UINT16, @CapValue)) then
    begin
      SendErrMsg('Error set value: '+IntToStr(CapID)+' -> '+IntToStr(CapValue), Conn);
    end;
  end;

  rtMsgOut:=TDataMsg.Create();
  rtMsgOut.ParamsList.Values['cmd']:='CAPS_SET_OK';
  SendMsg(rtMsgOut, Conn);
  rtMsgOut.Free();

end;

procedure TfrmSrvMain.StartScan(rtMsg: TDataMsg; Conn: TIdTCPConnection);
var
  rtMsgOut: TDataMsg;
  SrcName, OptValue: string;
  res: Integer;
  i, n: Integer;
  bColorModeFound: Boolean;
begin
  CurConn:=Conn;
  SrcName:=rtMsg.ParamsList.Values['source_name'];
  if Assigned(CurSource) then
  begin
    if CurSource.Enabled then
    begin
      memoDebug.Lines.Add(sErrSrcBusy+': '+SrcName);
      SendErrMsg(sErrSrcBusy+': '+SrcName, Conn);
      Exit;
    end;
  end;

  CurSource:=nil;
  for i:=0 to DTwain.SourceCount-1 do
  begin
    if DTwain.Source[i].ProductName = SrcName then
    begin
      CurSource:=DTwain.Source[i];
      Break;
    end;
  end;
  if not Assigned(CurSource) then
  begin
    memoDebug.Lines.Add(sErrSrcNotFound+': '+SrcName);
    SendErrMsg(sErrSrcNotFound+': '+SrcName, Conn);
    Exit;
  end;

  //CurSource.ShowUI := False;
  CurSource.Loaded:=True;
  ReadCaps(nil);

  // Set scan options
  res:=StrToIntDef(rtMsg.ParamsList.Values['resolution'], 50);
  CheckCap(CurSource.SetIXResolution(res), 'SetIXResolution('+IntToStr(res)+')');
  CheckCap(CurSource.SetIYResolution(res), 'SetIYResolution('+IntToStr(res)+')');

  CheckCap(CurSource.SetIndicators(false), 'SetIndicators(false)');

  OptValue:=rtMsg.ParamsList.Values['color_mode'];
  if Length(OptValue)>0 then
  begin
    cbbColorMode.Text:=OptValue;
  end;

  // Установка режима цветности
  bColorModeFound:=False;
  for i:=0 to Length(Self.ColorModeList)-1 do
  begin
    if Self.ColorModeList[i].Name = cbbColorMode.Text then
    begin
      n:=Self.ColorModeList[i].PixelType;
      CheckCap(CurSource.SetOneValue(ICAP_PIXELTYPE, TWTY_UINT16, @n), 'SetOneValue(ICAP_PIXELTYPE, '+IntToStr(n)+')');
      //CheckCap(CurSource.SetIPixelType(n), 'SetIPixelType('+IntToStr(n)+')');
      n:=self.ColorModeList[i].BitPerPixel;
      CheckCap(CurSource.SetIBitDepth(n), 'SetIBitDepth('+IntToStr(n)+')');
      bColorModeFound:=True;
    end;
  end;
  if not bColorModeFound then SendErrMsg(sErrColorModeNotFound, Conn);

  OptValue:=rtMsg.ParamsList.Values['file_format'];
  if Length(OptValue)>0 then
  begin
    cbbFormat.Text:=OptValue;
    cbbFormatChange(nil);
  end;

  //CheckCap(CurSource.SetFeederEnabled(true), 'SetFeederEnabled(true)');
  //CheckCap(CurSource.SetAutoFeed(true), 'SetAutoFeed(true)');

  //Load source and acquire image
  //CurSource.Enabled := TRUE;
  if CurSource.EnableSource(False, false) then
  begin
    SendStatusMsg(sInfScanStarted, Conn);

    rtMsgOut:=TDataMsg.Create();
    rtMsgOut.ParamsList.Values['cmd']:='SCAN_BEGIN';
    rtMsgOut.ParamsList.Values['source_name']:=SrcName;
    SendMsg(rtMsgOut, Conn);
    rtMsgOut.Free();
  end
  else
  begin
    SendErrMsg(sErrSrcNotEnabled, Conn);
  end;
end;

procedure TfrmSrvMain.TrayIconClick(Sender: TObject);
begin
  Self.TrayIcon.ShowMainForm();
end;

procedure TfrmSrvMain.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  CS:=TCriticalSection.Create();

  DTwain:=TDelphiTwain.Create(Self);
  DTwain.OnTwainAcquire:=DTwainTwainAcquire;
  DTwain.OnAcquireError:=DTwainAcquireError;
  DTwain.OnAcquireProgress:=DTwainAcquireProgress;
  DTwain.OnAcquireCancel:=DTwainAcquireCancel;
  DTwain.OnSourceFileTransfer:=DTwainSourceFileTransfer;

  TrayIcon:=TCoolTrayIcon.Create(Self);
  TrayIcon.PopupMenu:=pmTrayMenu;
  TrayIcon.OnClick:=TrayIconClick;
  TrayIcon.MinimizeToTray:=True;
  TrayIcon.ShowHint:=True;
  TrayIcon.Icon:=Application.Icon;
  TrayIcon.IconVisible:=True;

  DTwain.LibraryLoaded := TRUE;
  DTwain.SourceManagerLoaded := TRUE;

  // Get sources list
  cbbScanner.Clear();
  for i:=0 to DTwain.SourceCount-1 do
  begin
    cbbScanner.AddItem(DTwain.Source[i].ProductName, nil);
  end;

  // Activate server
  idTcpSrv.Active:=true;
  if idTcpSrv.Active = true then memoDebug.Lines.Add('Active');
end;

procedure TfrmSrvMain.FormDestroy(Sender: TObject);
begin
  idThrdMgr.TerminateThreads();
  DTwain.UnloadSourceManager(true);
  DTwain.UnloadLibrary();
end;

procedure TfrmSrvMain.idTcpSrvConnect(AThread: TIdPeerThread);
begin
  memoDebug.Lines.Add('Connected '+AThread.Connection.LocalName);
  CurConn:=AThread.Connection;
end;

procedure TfrmSrvMain.idTcpSrvDisconnect(AThread: TIdPeerThread);
begin
  memoDebug.Lines.Add('Disconnected '+AThread.Connection.LocalName);
end;

procedure TfrmSrvMain.SyncProc();
var
  rtMsgOut: TDataMsg;
  Cmd: string;
  i: Integer;
begin
  Cmd:=SyncMsg.ParamsList.Values['cmd'];
  memoDebug.Lines.Add('cmd='+Cmd);

  if Cmd='' then
  begin

  end

  else if Cmd='GET_SOURCES' then
  begin
    for i:=0 to DTwain.SourceCount-1 do
    begin
      rtMsgOut:=TDataMsg.Create();
      GetSource(i, rtMsgOut);
      SendMsg(rtMsgOut, CurConn);
      rtMsgOut.Free();
    end;
    rtMsgOut:=TDataMsg.Create();
    rtMsgOut.ParamsList.Values['cmd']:='GET_SOURCES_OK';
    SendMsg(rtMsgOut, CurConn);
    rtMsgOut.Free();
    SendStatusMsg(sInfScanerListLoaded, CurConn);
  end

  else if Cmd='GET_SOURCE_CAP' then
  begin
    GetSourceCap(SyncMsg, CurConn);
  end

  else if Cmd='GET_SOURCE_CAPS' then
  begin
    GetSourceCaps(SyncMsg, CurConn);
  end

  else if Cmd='SET_SOURCE_CAPS' then
  begin
    SetSourceCaps(SyncMsg, CurConn);
  end

  else if Cmd='SCAN' then
  begin
    StartScan(SyncMsg, CurConn);
  end;
end;

procedure TfrmSrvMain.idTcpSrvExecute(AThread: TIdPeerThread);
var
  ms: TMemoryStream;
begin
  ms:=TMemoryStream.Create();
  while (not AThread.Terminated) and (AThread.Connection.Connected) do
  begin
    try
      AThread.Connection.ReadStream(ms);
    except
      on E: Exception do
      begin
        if AThread.Terminated or (not AThread.Connection.Connected) then Exit;
        memoDebug.Lines.Add('Read error: '+E.Message);
      end;
    end;

    if ms.Size = 0 then Continue;

    CS.Enter();
    CurConn:=AThread.Connection;
    SyncMsg:=TDataMsg.Create();
    SyncMsg.FromStream(ms);
    ms.Clear();
    AThread.Synchronize(SyncProc);
    FreeAndNil(SyncMsg);
    CS.Leave();
  end;
  ms.Free();
end;


procedure TfrmSrvMain.DTwainTwainAcquire(Sender: TObject;
  const Index: Integer; Image: TBitmap; var Cancel: Boolean);
var
  rtMsgOut: TDataMsg;
begin
  memoDebug.Lines.Add('Image acquired');
  //Copies the acquired bitmap to the TImage control
  imgPreview.Picture.Assign(Image);

  if not Assigned(CurConn) then
  begin
    memoDebug.Lines.Add('Current connection not assigned');
    Exit;
  end;
  SendStatusMsg(sInfTransferingImage, CurConn);

  rtMsgOut:=TDataMsg.Create();
  rtMsgOut.ParamsList.Values['cmd']:='SCAN_END';
  rtMsgOut.ParamsList.Values['img_width']:=IntToStr(Image.Width);
  rtMsgOut.ParamsList.Values['img_height']:=IntToStr(Image.Height);
  rtMsgOut.ParamsList.Values['img_type']:='BITMAP';
  Image.SaveToStream(rtMsgOut.Data);
  SendMsg(rtMsgOut, CurConn);
  rtMsgOut.Free();

  //Because the component supports multiple images
  //from the source device, Cancel will tell the
  //source that we don't want no more images
  Cancel:=True;
end;

procedure TfrmSrvMain.DTwainSourceFileTransfer(Sender: TObject;
  const Index: Integer; Filename: TW_STR255; Format: TTwainFormat;
  var Cancel: Boolean);
var
  rtMsgOut: TDataMsg;
  sFileName: string;
begin
  sFileName:=Trim(Filename);
  memoDebug.Lines.Add('Image file acquired: '+sFileName);

  if not Assigned(CurConn) then
  begin
    memoDebug.Lines.Add('Current connection not assigned');
    Exit;
  end;
  SendStatusMsg(sInfTransferingImageFile, CurConn);

  rtMsgOut:=TDataMsg.Create();
  rtMsgOut.ParamsList.Values['cmd']:='SCAN_END';
  rtMsgOut.ParamsList.Values['img_type']:='FILE';
  rtMsgOut.ParamsList.Values['file_name']:=sFileName;
  rtMsgOut.Data.LoadFromFile(sFileName);
  DeleteFile(sFileName);
  SendMsg(rtMsgOut, CurConn);
  rtMsgOut.Free();
  Cancel:=True;
end;


procedure TfrmSrvMain.DTwainAcquireError(Sender: TObject;
  const Index: Integer; ErrorCode, Additional: Integer);
var
  sMsg: string;
begin
  sMsg:=sErrAcquireError+' '+IntToStr(ErrorCode)+' '+IntToStr(Additional);
  memoDebug.Lines.Add(sMsg);
  if not Assigned(CurConn) then
  begin
    memoDebug.Lines.Add('Current connection not assigned');
    Exit;
  end;
  SendErrMsg(sMsg, CurConn);
end;

procedure TfrmSrvMain.DTwainAcquireCancel(Sender: TObject;
  const Index: Integer);
var
  sMsg: string;
begin
  sMsg:=sErrAcquireCancelled;
  memoDebug.Lines.Add(sMsg);
  if not Assigned(CurConn) then
  begin
    memoDebug.Lines.Add('Current connection not assigned');
    Exit;
  end;
  SendErrMsg(sMsg, CurConn);
end;

procedure TfrmSrvMain.DTwainAcquireProgress(Sender: TObject;
  const Index: Integer; const Image: HBITMAP; const Current,
  Total: Integer);
var
  Bitmap: TBitmap;
  PLineS, PLineD: Pointer;
  bpp, iBytes: integer;
  rtMsg: TDataMsg;
  rPerc: real;
begin
  rPerc:=Current/(Total/100);

  //SendStatusMsg(sInfScanning+' '+IntToStr(Current)+'/'+IntToStr(Total), CurConn);
  //SendStatusMsg(sInfScanning+' '+FormatFloat('##0.00',rPerc)+'%', CurConn);

  // Send scanline
  rtMsg:=TDataMsg.Create();
  rtMsg.ParamsList.Values['cmd']:='SCAN_LINE';
  rtMsg.ParamsList.Values['scanline_total']:=IntToStr(Total);
  rtMsg.ParamsList.Values['scanline_current']:=IntToStr(Current);
  SendMsg(rtMsg, CurConn);
  rtMsg.Free();

  Exit;
  if not Assigned(TmpBMP) then TmpBMP:=TBitmap.Create();

  //Bitmap:=imgPreview.Picture.Bitmap;
  if TmpBMP.Handle <> Image then TmpBMP.Handle := Image;
  PLineS:=TmpBMP.ScanLine[Index];
  bpp:=4;
  case TmpBMP.PixelFormat of
    pfDevice: bpp:=4;
    pf8bit  : bpp:=1;
    pf16bit : bpp:=2;
    pf24bit : bpp:=3;
    pf32bit : bpp:=4;
  end;
  iBytes := bpp * TmpBMP.Width;
  PLineD:=imgPreview.Picture.Bitmap.ScanLine[1];
  Move(PLineS, PLineD, iBytes);
  //Sleep(500);

end;

procedure TfrmSrvMain.cbbScannerSelect(Sender: TObject);
var
  Source: TTwainSource;
  CapUnitList: TTwainUnitSet;
  CapUnit: TTwainUnit;
  i: Integer;
begin
  if cbbScanner.ItemIndex>=0 then
  begin
    Source:=DTwain.Source[cbbScanner.ItemIndex-1];
    CurSource:=Source;
    Source.Loaded := TRUE;

    ReadCaps(nil);

    if cbbUnits.Items.Count>0 then cbbUnits.ItemIndex:=0;
    if cbbColorMode.Items.Count>0 then cbbColorMode.ItemIndex:=cbbColorMode.Items.Count-1;
    cbbFormat.ItemIndex:=1;
    cbbResolution.ItemIndex:=2;

  end;

end;

procedure TfrmSrvMain.btnPreviewClick(Sender: TObject);
var
  SrcName: string;
  rtMsg: TDataMsg;
begin
  CurSource:=nil;
  SrcName:=cbbScanner.Text;

  rtMsg:=TDataMsg.Create();
  rtMsg.ParamsList.Values['cmd']:='SCAN';
  rtMsg.ParamsList.Values['source_name']:=SrcName;
  rtMsg.ParamsList.Values['resolution']:='50';
  StartScan(rtMsg, nil);
  rtMsg.Free();
end;

procedure TfrmSrvMain.btnScanClick(Sender: TObject);
var
  SrcName: string;
  rtMsg: TDataMsg;
begin
  CurSource:=nil;
  SrcName:=cbbScanner.Text;

  rtMsg:=TDataMsg.Create();
  rtMsg.ParamsList.Values['cmd']:='SCAN';
  rtMsg.ParamsList.Values['source_name']:=SrcName;
  rtMsg.ParamsList.Values['resolution']:=cbbResolution.Text;
  StartScan(rtMsg, nil);
  rtMsg.Free();
end;

procedure TfrmSrvMain.cbbFormatChange(Sender: TObject);
begin
  if cbbFormat.Text='' then Exit
  else if cbbFormat.Text=sTransferMemory then
  begin
    CurSource.TransferMode:=ttmMemory;
  end
  else if cbbFormat.Text=sTransferNative then
  begin
    CurSource.TransferMode:=ttmNative;
  end
  else
  begin
    ImgFileName:=IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP'))+'tmp_img.'+cbbFormat.Text;
    CurSource.TransferMode:=ttmFile;
    CurSource.SetupFileTransferTWFF(ImgFileName, StrToItem(cbbFormat.Text, 'img_formats'));
  end;
end;


procedure TfrmSrvMain.AppEventsException(Sender: TObject; E: Exception);
begin
  memoDebug.Lines.Add('Internal error: '+E.Message);
end;

procedure TfrmSrvMain.mniExitClick(Sender: TObject);
begin
  Self.Close();
end;

end.
