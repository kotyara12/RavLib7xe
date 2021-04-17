unit RWinVerEx;

interface

uses
  Windows, Classes;

type
  TWinVersionInfo = packed record
    PlatformId: Longword;
    LanguageId: Longword;
    MajorVersion: Longword;
    MinorVersion: Longword;
    BuildNumber: Longword;
    ExtendedData: Boolean;
    ServicePackMajor: Word;
    ServicePackMinor: Word;
    SuiteMask: Word;
    ProductType: Byte;
    CSDVersion: string[128];
  end;

const
  VER_NT_WORKSTATION                 = $00000001;
  // The operating system is Windows Vista, Windows XP Professional,
  // Windows XP Home Edition, or Windows 2000 Professional.
  VER_NT_DOMAIN_CONTROLLER           = $00000002;
  // The system is a domain controller and the operating system is
  // Windows Server 2008, Windows Server 2003, or Windows 2000 Server.
  VER_NT_SERVER                      = $00000003;
  // The operating system is Windows Server 2008, Windows Server 2003, or Windows 2000 Server.
  // Note that a server that is also a domain controller is reported as VER_NT_DOMAIN_CONTROLLER, not VER_NT_SERVER.

  VER_SUITE_SMALLBUSINESS            = $00000001;
  // Microsoft Small Business Server was once installed on the system,
  // but may have been upgraded to another version of Windows.
  // Refer to the Remarks section for more information about this bit flag.
  VER_SUITE_ENTERPRISE               = $00000002;
  // Windows Server 2008 Enterprise, Windows Server 2003, Enterprise Edition,
  // or Windows 2000 Advanced Server is installed.
  // Refer to the Remarks section for more information about this bit flag.
  VER_SUITE_BACKOFFICE               = $00000004;
  // Microsoft BackOffice components are installed.
  VER_SUITE_TERMINAL                 = $00000010;
  // Terminal Services is installed. This value is always set.
  // If VER_SUITE_TERMINAL is set but VER_SUITE_SINGLEUSERTS is not set,
  // the system is running in application server mode.
  VER_SUITE_SMALLBUSINESS_RESTRICTED = $00000020;
  // Microsoft Small Business Server is installed with the restrictive
  // client license in force. Refer to the Remarks section for more information
  // about this bit flag.
  VER_SUITE_EMBEDDEDNT               = $00000040;
  // Windows XP Embedded is installed.
  VER_SUITE_DATACENTER               = $00000080;
  // Windows Server 2008 Datacenter, Windows Server 2003, Datacenter Edition,
  // or Windows 2000 Datacenter Server is installed.
  VER_SUITE_SINGLEUSERTS             = $00000100;
  // Remote Desktop is supported, but only one interactive session is supported.
  // This value is set unless the system is running in application server mode.
  VER_SUITE_PERSONAL                 = $00000200;
  // Windows Vista Home Premium, Windows Vista Home Basic,
  // or Windows XP Home Edition is installed.
  VER_SUITE_BLADE                    = $00000400;
  // Windows Server 2003, Web Edition is installed.
  VER_SUITE_STORAGE_SERVER           = $00002000;
  // Windows Storage Server 2003 R2 or Windows Storage Server 2003 is installed.
  VER_SUITE_COMPUTE_SERVER           = $00004000;
  // Windows Server 2003, Compute Cluster Edition is installed.
  VER_SUITE_WH_SERVER                = $00008000;
  // Windows Home Server is installed.

function GetLangAbbrLCID(const LocaleLCID: LCID): string;
function GetLangNameLCID(const LocaleLCID: LCID): string;
function GetLanguageName(const LangId: Cardinal): string;
function GetWindowsVersionInfo: TWinVersionInfo;
function GetWindowsVersionType(const VerInfo: TWinVersionInfo; const VersionFormat: string): string; overload;
function GetWindowsVersionType(const VerInfo: TWinVersionInfo): string; overload;
function GetWindowsVersionAbbr(const VerInfo: TWinVersionInfo; const VersionFormat: string): string; overload;
function GetWindowsVersionAbbr(const VerInfo: TWinVersionInfo): string; overload;
function GetWindowsVersionName(const VerInfo: TWinVersionInfo; const VersionFormat: string): string; overload;
function GetWindowsVersionName(const VerInfo: TWinVersionInfo): string; overload;
function GetWindowsVersionNameLng(const VerInfo: TWinVersionInfo): string;
function GetWindowsVersionNameExt(const VerInfo: TWinVersionInfo): string;
function GetWindowsVersionNumber(const VerInfo: TWinVersionInfo): string;
function GetWindowsVersionProductType(const VerInfo: TWinVersionInfo): string;
function GetWindowsSuiteText(const VerInfo: TWinVersionInfo): string;
procedure GetWindowsDescription(const VerInfo: TWinVersionInfo; TxtInfo: TStrings);

const
  SWindowsUnknown            = '???';
  SWindowsWS                 = 'Workstation';
  SWindowsWSS                = 'Wst %d.%d';
  SWindowsSRV                = 'Server';
  SWindowsVer                = '%d.%d';
  SWindows32S                = 'Win32s';
  SWindows95                 = '95';
  SwindowsOSR2               = 'OSR2';
  SwindowsSE                 = 'SE';
  SWindows98                 = '98';
  SWindowsME                 = 'ME';
  SWindowsNT                 = 'NT';
  SWindowsXP                 = 'XP';
  SWindows2K0                = '2000';
  SWindows2K3                = '2003';
  SWindows6x_WS              = 'Vista';
  SWindows6x_SRV             = '%d.%d';
  SWindows7x_WS              = '%d';
  SWindows7x_SRV             = '2008';
  SWindowsNx_WS              = '%d.%d';
  SWindowsNx_SRV             = '%d.%d';

  SWinExtSP                  = 'SP';
  SWinExtSPF                 = 'SERVICE PACK';
  SWinExtED                  = '%s, %s Edition';
  SWinExtHE                  = 'Home Edition';
  SWinExtHES                 = 'Home';
  SWinExtPRO                 = 'Professional';
  SWinExtPROS                = 'Pro';
  SWinExtEMB                 = 'Embedded';
  SWinExtEMBS                = 'Emb';
  SWinExtADV                 = 'Advanced';
  SWinExtENT                 = 'Enterprise';
  SWinExtWEB                 = 'Web';
  SWinExtSBS                 = 'Small Business';
  SWinExtSBSR                = 'Small Business Restricted';
  SWinExtBO                  = 'Back Office';
  SWinExtRD                  = 'Remote Desktop';
  SWinExtTS                  = 'Terminal Service';
  SWinExtSS                  = 'Storage Server';
  SWinExtHS                  = 'Home Server';
  SWinExtDC                  = 'Datacenter';
  SWinExtCC                  = 'Compute Cluster';

  SFmtWindowsVersionAbbr     = 'Windows %0:s %1:s %2:s';
  SFmtWindowsVersionType     = 'Microsoft Windows %0:s';
  SFmtWindowsVersionName     = 'Microsoft Windows %0:s %2:s';
  SFmtWindowsVersionNameLng  = 'Microsoft Windows %0:s %1:s %2:s';
  SFmtWindowsVersionNameExt  = 'Microsoft Windows %0:s %1:s %2:s [%3:d.%4:.2d.%5:.3d]';

resourcestring
  SOsName                    = '%s';
  SOsVersion                 = 'Версия: %d.%.2d.%.3d';
  SOsLanguage                = 'Язык GUI: %s (%s), id: %d (0x%4.4x)';
  SOsComponents              = 'Установленные компоненты: %s';

implementation

uses
  SysUtils;

function GetSystemDefaultUILanguage: UINT; stdcall; external kernel32 name 'GetSystemDefaultUILanguage';

type
  TOsVersionInfoEx = packed record
    Base: TOsVersionInfoA;
    wServicePackMajor: Word;
    wServicePackMinor: Word;
    wSuiteMask: Word;
    wProductType: Byte;
    wReserved: Byte;
 end;

function AddDelimStrEx(const BaseStr, AddStr, DelimStr: string): string;
begin
  if AddStr <> '' then begin
    if BaseStr = '' then
      Result := AddStr
    else
      Result := BaseStr + DelimStr + AddStr;
  end
  else
    Result := BaseStr;
end;

function DelDoubleSpaces(const S: string): string;
var
  i: Integer;
begin
  Result := S;
  for i := Length(Result) downto 2 do
  begin
    if (Result[i] = ' ') and (Result[i - 1] = ' ') then
      Delete(Result, i, 1);
  end;
  Result := Trim(Result);
end;

function GetLangAbbrLCID(const LocaleLCID: LCID): string;
var
  LangAbbr: array [0..2] of Char;
begin
  try
    GetLocaleInfo(LocaleLCID, LOCALE_SABBREVLANGNAME, LangAbbr, SizeOf(LangAbbr));
    Result := LangAbbr;
  except
    Result := EmptyStr;
  end;
end;

function GetLangNameLCID(const LocaleLCID: LCID): string;
var
  LangName: array [0..127] of Char;
begin
  try
    GetLocaleInfo(LocaleLCID, LOCALE_SLANGUAGE, LangName, SizeOf(LangName));
    Result := LangName;
  except
    Result := EmptyStr;
  end;
end;

function GetLanguageName(const LangId: Cardinal): string;
var
  LangName: array[0..127] of Char;
begin
  try
    VerLanguageName(LangId, LangName, SizeOf(LangName));
    Result := LangName;
  except
    Result := EmptyStr;
  end;
end;

function GetWindowsVersionInfo: TWinVersionInfo;
var
  VerInfo: TOsVersionInfoEx;
  ResBool: Boolean;
begin
  FillChar(VerInfo, SizeOf(VerInfo), 0);
  VerInfo.Base.dwOSVersionInfoSize := SizeOf(TOsVersionInfoEx);
  ResBool := GetVersionExA(VerInfo.Base);
  Result.ExtendedData := ResBool;
  if not Result.ExtendedData then
  begin
    VerInfo.Base.dwOSVersionInfoSize := SizeOf(TOsVersionInfo);
    ResBool := GetVersionExA(VerInfo.Base);
  end;
  if ResBool then
  begin
    Result.PlatformId := VerInfo.Base.dwPlatformId;
    Result.MajorVersion := VerInfo.Base.dwMajorVersion;
    Result.MinorVersion := VerInfo.Base.dwMinorVersion;
    Result.BuildNumber := VerInfo.Base.dwBuildNumber;
    Result.ServicePackMajor := VerInfo.wServicePackMajor;
    Result.ServicePackMinor := VerInfo.wServicePackMinor;
    Result.SuiteMask := VerInfo.wSuiteMask;
    Result.ProductType := VerInfo.wProductType;
    Result.CSDVersion := Trim(ShortString(VerInfo.Base.szCSDVersion));
    Result.LanguageId := GetSystemDefaultUILanguage;
    // GetSystemDefaultLCID; // GetSystemDefaultLangID
  end
  else
    raise Exception.Create(SysErrorMessage(GetLastError));
end;

function GetWindowsVersionType(const VerInfo: TWinVersionInfo; const VersionFormat: string): string;
var
  VersionName: string;
begin
  VersionName := SWindowsUnknown;
  with VerInfo do
    case PlatformId of
      VER_PLATFORM_WIN32S: VersionName := SWindows32S;
      VER_PLATFORM_WIN32_WINDOWS:
      begin
        if (MajorVersion = 4) and (MinorVersion = 0) then
          VersionName := SWindows95;
        if (MajorVersion = 4) and (MinorVersion = 10) then
          VersionName := SWindows98;
        if (MajorVersion = 4) and (MinorVersion = 90) then
          VersionName := SWindowsME;
      end;
      VER_PLATFORM_WIN32_NT:
      begin
        if (MajorVersion <= 4) then
        begin
          if ExtendedData then
          begin
            if ProductType <> VER_NT_WORKSTATION
            then VersionName := Format(SWindowsNT + #32 + SWindowsSRV + #32 + SWindowsVer,
              [MajorVersion, MinorVersion])
            else VersionName := Format(SWindowsNT + #32 + SWindowsWS + #32 + SWindowsVer,
              [MajorVersion, MinorVersion]);
          end
          else VersionName := Format(SWindowsNT + #32 + SWindowsVer,
            [MajorVersion, MinorVersion]);
        end;
        if (MajorVersion = 5) and (MinorVersion = 0) then
        begin
          if ExtendedData and (ProductType <> VER_NT_WORKSTATION)
          then VersionName := SWindows2K0 + #32 + SWindowsSRV
          else VersionName := SWindows2K0;
        end;
        if (MajorVersion = 5) and (MinorVersion = 1) then
          VersionName := SWindowsXP;
        if (MajorVersion = 5) and (MinorVersion = 2) then
          VersionName := SWindowsSRV + #32 + SWindows2K3;
        if (MajorVersion = 6) and (MinorVersion = 0) then
        begin
          if ExtendedData and (ProductType <> VER_NT_WORKSTATION)
          then VersionName := SWindowsSRV + #32 + Format(SWindows6x_SRV, [MajorVersion, MinorVersion])
          else VersionName := SWindows6x_WS;
        end;
        if (MajorVersion = 7) then
        begin
          if ExtendedData and (ProductType <> VER_NT_WORKSTATION)
          then VersionName := SWindowsSRV + #32 + SWindows7x_SRV
          else VersionName := Format(SWindows7x_WS, [MajorVersion]);
        end;
        if (MajorVersion > 7) then
        begin
          if ExtendedData and (ProductType <> VER_NT_WORKSTATION)
          then VersionName := SWindowsSRV + #32 + Format(SWindowsNx_SRV, [MajorVersion, MinorVersion])
          else VersionName := Format(SWindowsNx_WS, [MajorVersion]);
        end;
      end;
    end;
  Result := Format(VersionFormat, [VersionName]);
end;

function GetWindowsVersionType(const VerInfo: TWinVersionInfo): string;
begin
  Result := GetWindowsVersionType(VerInfo, SFmtWindowsVersionType);
end;

function GetWindowsVersionAbbr(const VerInfo: TWinVersionInfo; const VersionFormat: string): string;
var
  VersionName, TypeName, LanguageName, ServicePackName: string;
begin
  with VerInfo do
  begin
    VersionName := SWindowsUnknown;
    TypeName := EmptyStr;
    ServicePackName := EmptyStr;
    case PlatformId of
      VER_PLATFORM_WIN32S:
        VersionName := SWindows32S;
      VER_PLATFORM_WIN32_WINDOWS:
      begin
        if (MajorVersion = 4) and (MinorVersion = 0) then
        begin
          VersionName := SWindows95;
          if (Length(CSDVersion) > 0) and (CSDVersion[1] in ['B', 'C']) then
            TypeName := SWindowsOSR2
        end;
        if (MajorVersion = 4) and (MinorVersion = 10) then
        begin
          VersionName := SWindows98;
          if (Length(CSDVersion) > 0) and (CSDVersion[1] in ['A']) then
            TypeName := SWindowsSE
        end;
        if (MajorVersion = 4) and (MinorVersion = 90) then
          VersionName := SWindowsME;
        VersionName := VersionName + TypeName;
      end;
      VER_PLATFORM_WIN32_NT:
      begin
        if ExtendedData then
        begin
          if ProductType = VER_NT_WORKSTATION then
          begin
           if (MajorVersion <= 4)
           then TypeName := Format(SWindowsWSS, [MajorVersion, MinorVersion])
           else begin
             if (SuiteMask and VER_SUITE_EMBEDDEDNT) > 0
             then TypeName := SWinExtEMBS
             else if (SuiteMask and VER_SUITE_PERSONAL) > 0
                  then TypeName := SWinExtHES
                  else TypeName := SWinExtPROS;
           end;
          end
          else begin
            if (ProductType = VER_NT_SERVER)
            or (ProductType = VER_NT_DOMAIN_CONTROLLER) then
            begin
              if (MajorVersion <= 4)
              then TypeName := Format(SWindowsSRV + #32 + SWindowsVer,
                [MajorVersion, MinorVersion])
              else TypeName := SWindowsSRV;
            end;
          end;
        end;
        if (MajorVersion <= 4) then
          VersionName := AddDelimStrEx(SWindowsNT, TypeName, #32);
        if (MajorVersion = 5) and (MinorVersion = 0) then
          VersionName := AddDelimStrEx(SWindows2K0, TypeName, #32);
        if (MajorVersion = 5) and (MinorVersion = 1) then
          VersionName := AddDelimStrEx(SWindowsXP, TypeName, #32);
        if (MajorVersion = 5) and (MinorVersion = 2) then
          VersionName := AddDelimStrEx(TypeName, SWindows2K3, #32);
        if (MajorVersion = 6) and (MinorVersion = 0) then
        begin
          if ExtendedData and (ProductType <> VER_NT_WORKSTATION)
          then VersionName := AddDelimStrEx(TypeName, Format(SWindows6x_SRV, [MajorVersion, MinorVersion]), #32)
          else VersionName := AddDelimStrEx(SWindows6x_WS, TypeName, #32);
        end;
        if (MajorVersion = 7) then
        begin
          if ExtendedData and (ProductType <> VER_NT_WORKSTATION)
          then VersionName := AddDelimStrEx(TypeName, SWindows7x_SRV, #32)
          else VersionName := AddDelimStrEx(Format(SWindows7x_WS, [MajorVersion]), TypeName, #32);
        end;
        if (MajorVersion > 7) then
        begin
          if ExtendedData and (ProductType <> VER_NT_WORKSTATION)
          then VersionName := AddDelimStrEx(TypeName, Format(SWindowsNx_SRV, [MajorVersion, MinorVersion]), #32)
          else VersionName := AddDelimStrEx(Format(SWindowsNx_WS, [MajorVersion]), TypeName, #32);
        end;
        if Pos(SWinExtSPF, AnsiUpperCase(CSDVersion)) = 1
        then ServicePackName := SWinExtSP + Trim(Copy(CSDVersion, 13, Length(CSDVersion) - 12))
        else ServicePackName := Trim(CSDVersion);
      end;
    end;
    LanguageName := GetLangAbbrLCID(LanguageId);
    Result := DelDoubleSpaces(Format(VersionFormat,
      [VersionName, LanguageName, ServicePackName,
       MajorVersion, MinorVersion, (BuildNumber and $FFFF),
       LanguageId]));
  end;
end;

function GetWindowsVersionAbbr(const VerInfo: TWinVersionInfo): string;
begin
  Result := GetWindowsVersionAbbr(VerInfo, SFmtWindowsVersionAbbr);
end;

function GetWindowsVersionName(const VerInfo: TWinVersionInfo; const VersionFormat: string): string;
var
  VersionName, TypeName, ServerName, LanguageName, ServicePackName: string;
begin
  with VerInfo do
  begin
    VersionName := SWindowsUnknown;
    TypeName := EmptyStr;
    ServerName := EmptyStr;
    ServicePackName := EmptyStr;
    case PlatformId of
      VER_PLATFORM_WIN32S:
        VersionName := SWindows32S;
      VER_PLATFORM_WIN32_WINDOWS:
      begin
        if (MajorVersion = 4) and (MinorVersion = 0) then
        begin
          VersionName := SWindows95;
          if (Length(CSDVersion) > 0) and (CSDVersion[1] in ['B', 'C']) then
            TypeName := SWindowsOSR2
        end;
        if (MajorVersion = 4) and (MinorVersion = 10) then
        begin
          VersionName := SWindows98;
          if (Length(CSDVersion) > 0) and (CSDVersion[1] in ['A']) then
            TypeName := SWindowsSE
        end;
        if (MajorVersion = 4) and (MinorVersion = 90) then
          VersionName := SWindowsME;
        VersionName := VersionName + TypeName;
      end;
      VER_PLATFORM_WIN32_NT:
      begin
        if ExtendedData then
        begin
          if ProductType = VER_NT_WORKSTATION then
          begin
           if (MajorVersion <= 4)
           then TypeName := Format(SWindowsWS + #32 + SWindowsVer,
             [MajorVersion, MinorVersion])
           else begin
             if (SuiteMask and VER_SUITE_EMBEDDEDNT) > 0
             then TypeName := SWinExtEMB
             else if (SuiteMask and VER_SUITE_PERSONAL) > 0
                  then TypeName := SWinExtHE
                  else TypeName := SWinExtPRO;
           end;
          end
          else begin
            if (ProductType = VER_NT_SERVER)
            or (ProductType = VER_NT_DOMAIN_CONTROLLER) then
            begin
              if (MajorVersion <= 4)
              then TypeName := Format(SWindowsSRV + #32 + SWindowsVer,
                [MajorVersion, MinorVersion])
              else TypeName := SWindowsSRV;
              if (SuiteMask and VER_SUITE_SMALLBUSINESS) > 0 then
                ServerName := SWinExtSBS;
              if (SuiteMask and VER_SUITE_SMALLBUSINESS_RESTRICTED) > 0 then
                ServerName := SWinExtSBSR;
              if (SuiteMask and VER_SUITE_DATACENTER) > 0 then
                ServerName := SWinExtDC;
              if (SuiteMask and VER_SUITE_ENTERPRISE) > 0 then
              begin
                if (MajorVersion = 5) and (MinorVersion = 0)
                then ServerName := SWinExtADV
                else ServerName := SWinExtENT;
              end;
              if (SuiteMask and VER_SUITE_BLADE) > 0 then
                ServerName := SWinExtWEB;
              if (SuiteMask and VER_SUITE_STORAGE_SERVER) > 0 then
                TypeName := SWinExtSS;
              if (SuiteMask and VER_SUITE_COMPUTE_SERVER) > 0 then
                ServerName := SWinExtCC;
              if (SuiteMask and VER_SUITE_WH_SERVER) > 0 then
                TypeName := SWinExtHS;
            end;
          end;
        end;
        if (MajorVersion <= 4) then
          VersionName := AddDelimStrEx(SWindowsNT, AddDelimStrEx(ServerName, TypeName, #32), #32);
        if (MajorVersion = 5) and (MinorVersion = 0) then
          VersionName := AddDelimStrEx(SWindows2K0, AddDelimStrEx(ServerName, TypeName, #32), #32);
        if (MajorVersion = 5) and (MinorVersion = 1) then
          VersionName := AddDelimStrEx(SWindowsXP, TypeName, #32);
        if (MajorVersion = 5) and (MinorVersion = 2) then
        begin
          VersionName := AddDelimStrEx(TypeName, SWindows2K3, #32);
          if ServerName <> EmptyStr then
            VersionName := Format(SWinExtED, [VersionName, ServerName]);
        end;
        if (MajorVersion = 6) then
        begin
          if ExtendedData and (ProductType <> VER_NT_WORKSTATION)
          then VersionName := AddDelimStrEx(AddDelimStrEx(TypeName, Format(SWindows6x_SRV, [MajorVersion, MinorVersion]), #32), ServerName, #32)
          else VersionName := AddDelimStrEx(SWindows6x_WS, TypeName, #32);
        end;
        if (MajorVersion = 7) then
        begin
          if ExtendedData and (ProductType <> VER_NT_WORKSTATION)
          then VersionName := AddDelimStrEx(AddDelimStrEx(TypeName, SWindows7x_SRV, #32), ServerName, #32)
          else VersionName := AddDelimStrEx(Format(SWindows7x_WS, [MajorVersion]), TypeName, #32);
        end;
        if (MajorVersion > 7) then
        begin
          if ExtendedData and (ProductType <> VER_NT_WORKSTATION)
          then VersionName := AddDelimStrEx(AddDelimStrEx(TypeName, Format(SWindowsNx_SRV, [MajorVersion, MinorVersion]), #32), ServerName, #32)
          else VersionName := AddDelimStrEx(Format(SWindowsNx_WS, [MajorVersion]), TypeName, #32);
        end;
        ServicePackName := Trim(CSDVersion);
      end;
    end;
    LanguageName := GetLangAbbrLCID(LanguageId);
    Result := DelDoubleSpaces(Format(VersionFormat,
      [VersionName, LanguageName, ServicePackName,
       MajorVersion, MinorVersion, (BuildNumber and $FFFF),
       LanguageId]));
  end;
end;

function GetWindowsVersionName(const VerInfo: TWinVersionInfo): string;
begin
  Result := GetWindowsVersionName(VerInfo, SFmtWindowsVersionName);
end;

function GetWindowsVersionNameLng(const VerInfo: TWinVersionInfo): string;
begin
  Result := GetWindowsVersionName(VerInfo, SFmtWindowsVersionNameLng);
end;

function GetWindowsVersionNameExt(const VerInfo: TWinVersionInfo): string;
begin
  Result := GetWindowsVersionName(VerInfo, SFmtWindowsVersionNameExt);
end;

function GetWindowsVersionNumber(const VerInfo: TWinVersionInfo): string;
begin
  Result := Format(SWindowsVer, [VerInfo.MajorVersion, VerInfo.MinorVersion]);
end;

function GetWindowsVersionProductType(const VerInfo: TWinVersionInfo): string;
begin
  if VerInfo.ExtendedData and (VerInfo.ProductType <> VER_NT_WORKSTATION)
  then Result := SWindowsSRV
  else Result := SWindowsWS;
end;

function GetWindowsSuiteText(const VerInfo: TWinVersionInfo): string;
begin
  Result := EmptyStr;
  if VerInfo.ExtendedData then
  begin
    if (VerInfo.SuiteMask and VER_SUITE_SMALLBUSINESS) > 0
    then Result := AddDelimStrEx(Result, SWinExtSBS + #32 + SWindowsSRV, ', ');
    if (VerInfo.SuiteMask and VER_SUITE_SMALLBUSINESS_RESTRICTED) > 0
    then Result := AddDelimStrEx(Result, SWinExtSBSR + #32 + SWindowsSRV, ', ');
    if (VerInfo.SuiteMask and VER_SUITE_BACKOFFICE) > 0
    then Result := AddDelimStrEx(Result, SWinExtBO, ', ');
    if (VerInfo.SuiteMask and VER_SUITE_WH_SERVER) > 0
    then Result := AddDelimStrEx(Result, SWinExtHS, ', ');
    if (VerInfo.SuiteMask and VER_SUITE_SINGLEUSERTS) > 0
    then Result := AddDelimStrEx(Result, SWinExtRD, ', ');
    if (VerInfo.SuiteMask and VER_SUITE_TERMINAL) > 0 then
    begin
      if (VerInfo.SuiteMask and VER_SUITE_SINGLEUSERTS) > 0
      then Result := AddDelimStrEx(Result, SWinExtRD, ', ')
      else Result := AddDelimStrEx(Result, SWinExtTS, ', ');
    end;
  end;
end;

procedure GetWindowsDescription(const VerInfo: TWinVersionInfo; TxtInfo: TStrings);
var
  ExtComp: string;
begin
  if (VerInfo.PlatformId > 0) and (VerInfo.MajorVersion > 0) then
  begin
    TxtInfo.BeginUpdate;
    try
      TxtInfo.Clear;
      TxtInfo.Add(Format(SOsName, [GetWindowsVersionName(VerInfo)]));
      TxtInfo.Add(Format(SOsVersion, [VerInfo.MajorVersion,
        VerInfo.MinorVersion, VerInfo.BuildNumber]));
      TxtInfo.Add(Format(SOsLanguage, [GetLangNameLCID(VerInfo.LanguageId),
        GetLangAbbrLCID(VerInfo.LanguageId), VerInfo.LanguageId, VerInfo.LanguageId]));
      ExtComp := GetWindowsSuiteText(VerInfo);
      if ExtComp <> EmptyStr then TxtInfo.Add(Format(SOsComponents, [ExtComp]));
    finally
      TxtInfo.EndUpdate;
    end;
  end;
end;

end.
