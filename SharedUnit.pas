unit SharedUnit;

interface

uses DelphiTwain, Twain;

  function CheckCap(ret: TCapabilityRet; Name: String = ''): Boolean;
  function ItemToStr(Item: integer; ItemType: string): string;
  function StrToItem(Item: string; ItemType: string): integer;
  function CapUnitToStr(Item: TTwainUnit): string;
  function StrToCapUnit(Item: string): TTwainUnit;

var
  sPreview: string = 'Предпросмотр';

  // Measure units
  sInches: string = 'Дюймы';
  sCentimeters: string = 'Сантиметры';
  sPicas: string = 'Picas';
  sPoints: string = 'Точки';
  sTwips: string = 'Twips';
  sPixels: string = 'Пиксели';
  sMillimeters: string = 'Миллиметры';
  sUnknown: string = 'Неизвестно';

  // Image file formats
  sTIFF: string = 'TIFF';  // Used for document imaging
  sPICT: string = 'PICT';  // Native Macintosh format
  sBMP: string = 'BMP';    // Native Microsoft format
  sXBM: string = 'XBM';    // Used for document imaging
  sJFIF: string = 'JFIF';  // Wrapper for JPEG images
  sFPX: string = 'FPX';    // FlashPix, used with digital cameras
  sTIFFMULTI: string = 'TIFF Multi';  // Multi-page TIFF files
  sPNG: string = 'PNG';    // An image format standard intended for use on the web, replaces GIF
  sSPIFF: string = 'SPIFF';  // A standard from JPEG, intended to replace JFIF, also supports JBIG
  sEXIF: string = 'EXIF';  // File format for use with digital cameras
  sPDF: string = 'PDF';    // A file format from Adobe
  sJP2: string = 'JP2';    // A file format from the Joint Photographic Experts Group
  sDEJAVU: string = 'DEJAVU';  // A file format from LizardTech
  sPDFA: string = 'PDFA';  // A file format from Adobe

  // Extra transfer formats
  sTransferMemory: string = 'Memory';
  sTransferNative: string = 'Native';

  // Pixel types
  sBW: string = 'Ч/Б';
  sGray: string = 'Градации серого';
  sRGB: string = 'Цвет (RGB)';
  sPalette: string = 'Цвет (палитра)';
  sCMY: string = 'Цвет (CMY)';
  sCMYK: string = 'Цвет (CMYK)';
  sYUV: string = 'Цвет (YUV)';
  sYUVK: string = 'Цвет (YUVK)';
  sCIEXYZ: string = 'Цвет (CIEXYZ)';
  sLAB: string = 'Цвет (LAB)';
  sSRGB: string = 'Цвет (SRGB)';

  sErrSrcBusy: string = 'Current source busy';
  sErrSrcNotFound: string = 'Source not found';
  sErrSrcNotEnabled: string = 'Source can''t be enabled';
  sErrAcquireCancelled: string = 'Image acquire cancelled';
  sErrAcquireError: string = 'Image acquire error';
  sErrColorModeNotFound: string = 'Requested color mode not found';

  sInfScanerListLoaded: string = 'Scanner list loaded..';
  sInfScanStarted: string = 'Scan started..';
  sInfScanning: string = 'Scanning.. ';
  sInfTransferingImage: string = 'Transfering image..';
  sInfTransferingImageFile: string = 'Transfering image file..';

implementation

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
  //memoDebug.Lines.Add(Name+': '+sr);
end;

function ItemToStr(Item: integer; ItemType: string): string;
begin
  Result:='';
  if ItemType='units' then
  begin
    if Item=TWUN_INCHES then Result:=sInches
    else if Item=TWUN_CENTIMETERS then Result:=sCentimeters
    else if Item=TWUN_PICAS then Result:=sPicas
    else if Item=TWUN_POINTS then Result:=sPoints
    else if Item=TWUN_TWIPS then Result:=sTwips
    else if Item=TWUN_PIXELS then Result:=sPixels
    else if Item=TWUN_MILLIMETERS then Result:=sMillimeters;
  end

  else if ItemType='img_formats' then
  begin
    if Item=TWFF_TIFF then Result:=sTIFF
    else if Item=TWFF_PICT then Result:=sPICT
    else if Item=TWFF_BMP then Result:=sBMP
    else if Item=TWFF_XBM then Result:=sXBM
    else if Item=TWFF_JFIF then Result:=sFPX
    else if Item=TWFF_TIFFMULTI then Result:=sTIFFMULTI
    else if Item=TWFF_PNG then Result:=sPNG
    else if Item=TWFF_SPIFF then Result:=sSPIFF
    else if Item=TWFF_EXIF then Result:=sEXIF
    else if Item=TWFF_PDF then Result:=sPDF
    else if Item=TWFF_DEJAVU then Result:=sDEJAVU;
  end

  else if ItemType='pixel_types' then
  begin
    if Item=TWPT_BW then Result:=sBW
    else if Item=TWPT_GRAY then Result:=sGray
    else if Item=TWPT_RGB then Result:=sRGB
    else if Item=TWPT_PALETTE then Result:=sPalette
    else if Item=TWPT_CMY then Result:=sCMY
    else if Item=TWPT_CMYK then Result:=sCMYK
    else if Item=TWPT_YUV then Result:=sYUV
    else if Item=TWPT_YUVK then Result:=sYUVK
    else if Item=TWPT_CIEXYZ then Result:=sCIEXYZ
    else if Item=TWPT_LAB then Result:=sLAB
    else if Item=TWPT_SRGB then Result:=sSRGB;
  end;
end;

function StrToItem(Item: string; ItemType: string): integer;
begin
  Result:=-1;
  if ItemType='units' then
  begin
    if Item=sInches then Result:=TWUN_INCHES
    else if Item=sCentimeters then Result:=TWUN_CENTIMETERS
    else if Item=sPicas then Result:=TWUN_PICAS
    else if Item=sPoints then Result:=TWUN_POINTS
    else if Item=sTwips then Result:=TWUN_TWIPS
    else if Item=sPixels then Result:=TWUN_PIXELS
    else if Item=sMillimeters then Result:=TWUN_MILLIMETERS;
  end

  else if ItemType='img_formats' then
  begin
    if Item=sTIFF then Result:=TWFF_TIFF
    else if Item=sPICT then Result:=TWFF_PICT
    else if Item=sBMP then Result:=TWFF_BMP
    else if Item=sXBM then Result:=TWFF_XBM
    else if Item=sFPX then Result:=TWFF_JFIF
    else if Item=sTIFFMULTI then Result:=TWFF_TIFFMULTI
    else if Item=sPNG then Result:=TWFF_PNG
    else if Item=sSPIFF then Result:=TWFF_SPIFF
    else if Item=sEXIF then Result:=TWFF_EXIF
    else if Item=sPDF then Result:=TWFF_PDF
    else if Item=sDEJAVU then Result:=TWFF_DEJAVU;
  end

  else if ItemType='pixel_types' then
  begin
    if Item=sBW then Result:=TWPT_BW
    else if Item=sGray then Result:=TWPT_GRAY
    else if Item=sRGB then Result:=TWPT_RGB
    else if Item=sPalette then Result:=TWPT_PALETTE
    else if Item=sCMY then Result:=TWPT_CMY
    else if Item=sCMYK then Result:=TWPT_CMYK
    else if Item=sYUV then Result:=TWPT_YUV
    else if Item=sYUVK then Result:=TWPT_YUVK
    else if Item=sCIEXYZ then Result:=TWPT_CIEXYZ
    else if Item=sLAB then Result:=TWPT_LAB
    else if Item=sSRGB then Result:=TWPT_SRGB;
  end;
end;

function CapUnitToStr(Item: TTwainUnit): string;
begin
  if Item=tuInches then Result:=sInches
  else if Item=tuCentimeters then Result:=sCentimeters
  else if Item=tuPicas then Result:=sPicas
  else if Item=tuPoints then Result:=sPoints
  else if Item=tuTwips then Result:=sTwips
  else if Item=tuPixels then Result:=sPixels
  else if Item=tuUnknown then Result:=sUnknown
  else Result:='';
end;

function StrToCapUnit(Item: string): TTwainUnit;
begin
  if Item=sInches then Result:=tuInches
  else if Item=sCentimeters then Result:=tuCentimeters
  else if Item=sPicas then Result:=tuPicas
  else if Item=sPoints then Result:=tuPoints
  else if Item=sTwips then Result:=tuTwips
  else if Item=sPixels then Result:=tuPixels
  else if Item=sUnknown then Result:=tuUnknown
  else Result:=tuUnknown;
end;

end.
