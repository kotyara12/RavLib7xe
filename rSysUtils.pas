unit rSysUtils;

// (C) Copyright by RavSoft.

interface

uses
  Windows, SysUtils;

const
  LOGON_WITH_PROFILE                  = $00000001;
  LOGON_NETCREDENTIALS_ONLY           = $00000002;
  LOGON_ZERO_PASSWORD_BUFFER          = $80000000;

  // ����������� �������, �������������� ������� ����. (������ � ����������)
  CSIDL_DESKTOP                       = $0000;
  // ����������� ������� ��� Internet Explorer.
  CSIDL_INTERNET                      = $0001;
  // ���� ���� -> ���������
  CSIDL_PROGRAMS                      = $0002;
  // ����������� �������, ���������� ������ ������� ������ ����������
  CSIDL_CONTROLS                      = $0003;
  // ����������� �������, ���������� ������������� ��������
  CSIDL_PRINTERS                      = $0004;
  // ����������� �������, �������������� ����� "��� ���������"
  // �� Vista �������� �� �������� "��� ���������" �� ������ �����
  CSIDL_PERSONAL                      = $0005;
  // ���������. (������ C:\Documents and Settings\username\Favorites)
  CSIDL_FAVORITES                     = $0006;
  // ���� -> ��������� -> ������������
  CSIDL_STARTUP                       = $0007;
  // �������� ��������� (������ C:\Documents and Settings\username\My Recent Documents
  // ��� ���������� ������ ��������� ����������� SHAddToRecentDocs
  CSIDL_RECENT                        = $0008;
  // �����, ���������� ������ ���� "���������" (Sent to...) (������ C:\Documents and Settings\username\SendTo)
  CSIDL_SENDTO                        = $0009;
  // ����������� �������, ���������� ����� � ������� �������� ������������
  CSIDL_BITBUCKET                     = $000a;
  // �������� ���� ���� �������� ������������ (������ C:\Documents and Settings\username\Start Menu)
  CSIDL_STARTMENU                     = $000b;
  // ������� ���� �������� ������������ (������ C:\Documents and Settings\username\Desktop)
  CSIDL_DESKTOPDIRECTORY              = $0010;
  // ����������� �������, �������������� ����� "��� ���������"
  CSIDL_DRIVES                        = $0011;
  // ����������� �������, �������������� "������� ���������"
  CSIDL_NETWORK                       = $0012;
  // ����� "My Nethood Places" (������ C:\Documents and Settings\username\NetHood)
  // � �� ������ �� ��������� ����������� �������
  CSIDL_NETHOOD                       = $0013;
  // �����, ���������� ������������� ������. (������ C:\Windows\Fonts)
  CSIDL_FONTS                         = $0014;
  // ������� ����������. (������ Settings\username\Templates)
  CSIDL_TEMPLATES                     = $0015;
  // �������� ���� ���� ��� ���� �������������. (������ C:\Documents and Settings\All Users\Start Menu)
  // ���������, ������������ �� CSIDL_COMMON_ ���������� ������ � NT �������
  CSIDL_COMMON_STARTMENU              = $0016;
  // ���� ���� -> ��������� ��� ���� ������������� (������ C:\Documents and Settings\All Users\Start Menu\Programs)
  CSIDL_COMMON_PROGRAMS               = $0017;
  // ���� ���� -> ��������� -> ������������ ��� ���� ������������� (������ C:\Documents and Settings\All Users\Start Menu\Programs\Startup)
  CSIDL_COMMON_STARTUP                = $0018;
  // �������� �������� ����� ��� ���� ������������� (������ C:\Documents and Settings\All Users\Desktop)
  CSIDL_COMMON_DESKTOPDIRECTORY       = $0019;
  // �����, � ������� ��������� ������ ������� ���� ������(C:\Documents and Settings\username\Application Data)
  CSIDL_APPDATA                       = $001a;
  // ������������� ��������. (������ C:\Documents and Settings\username\PrintHood)
  CSIDL_PRINTHOOD                    = $001b;
  // user's nonlocalized Startup program group. ��������.
  CSIDL_ALTSTARTUP                   = $001d;         // DBCS
  // ��������
  CSIDL_COMMON_ALTSTARTUP            = $001e;         // DBCS
  // ������ "���������" ��� ���� �������������
  CSIDL_COMMON_FAVORITES             = $001f;
  // ��������� Internet ����� (������ C:\Documents and Settings\username\Local Settings\Temporary Internet Files)
  CSIDL_INTERNET_CACHE               = $0020;
  // ����� ��� �������� Cookies (������ C:\Documents and Settings\username\Cookies)
  CSIDL_COOKIES                      = $0021;
  // ������ ������ �������� ������� IE
  CSIDL_HISTORY                      = $0022;

  // ���������������� ����������� �������� ������������ (�������� ������� MMC). Win2000+
  CSIDL_ADMINTOOLS                   = $30;
  // ����� ��� ������, �������������� � ������ �� CD/DVD
  // (������ C:\Documents and Settings\username\Local Settings\Application Data\Microsoft\CD Burning)
  CSIDL_CDBURN_AREA                  = $3b;
  // �����, ���������� ����������� �����������������
  CSIDL_COMMON_ADMINTOOLS            = $2f;
  // ������ AppData ��� ���� �������������. (������ C:\Documents and Settings\All Users\Application Data)
  CSIDL_COMMON_APPDATA               = $23;
  // ����� "����� ���������" (������ C:\Documents and Settings\All Users\Documents)
  CSIDL_COMMON_DOCUMENTS             = $2e;
  // ����� �������� ���������� ��� ���� ������������� (������ C:\Documents and Settings\All Users\Templates)
  CSIDL_COMMON_TEMPLATES             = $2d;
  // ����� "��� ������" ��� ���� �������������. (������ C:\Documents and Settings\All Users\Documents\My Music)
  CSIDL_COMMON_MUSIC                 = $35;
  // ����� "��� �������" ��� ���� �������������. (������ C:\Documents and Settings\All Users\Documents\My Pictures)
  CSIDL_COMMON_PICTURES              = $36;
  // ����� "�� �����" ��� ���� ������������� (C:\Documents and Settings\All Users\Documents\My Videos)
  CSIDL_COMMON_VIDEO                 = $37;
  // ����������� �����, ������������ ������ ����������� � ����� ������� ������
  CSIDL_COMPUTERSNEARME              = $3d;
  // ����������� �����, ������������ ������ ������� �����������
  CSIDL_CONNECTIONS                  = $31;
  // AppData ��� ����������, ������� �� ����������� �� ������ ��������� (������ C:\Documents and Settings\username\Local Settings\Application Data)
  CSIDL_LOCAL_APPDATA                = $1c;
  // ����������� �������, �������������� ����� "��� ���������"
  CSIDL_MYDOCUMENTS                  = $0c;
  // ����� "��� ������"
  CSIDL_MYMUSIC                      = $0d;
  // ����� "��� ��������"
  CSIDL_MYPICTURES                   = $27;
  // ����� "�� �����"
  CSIDL_MYVIDEO                      = $0e;
  // ����� ������������ (������ C:\Documents and Settings\username)
  CSIDL_PROFILE                      = $28;
  // ����� Program Files (������ C:\Program Files)
  CSIDL_PROGRAM_FILES                = $26;
  CSIDL_PROGRAM_FILESX86             = $2a;
  // ����� Program Files\Common (������ C:\Program Files\Common)
  CSIDL_PROGRAM_FILES_COMMON         = $2b;
  CSIDL_PROGRAM_FILES_COMMONX86      = $2c;
  // ����� ��� ��������. Vista � ���� (������ C:\Windows\Resources)
  CSIDL_RESOURCES                    = $38;
  CSIDL_RESOURCES_LOCALIZED          = $39;
  // ����� System (������ C:\Windows\System32 ��� C:\Windows\System)
  CSIDL_SYSTEM                       = $25;
  CSIDL_SYSTEMX86                    = $29;
  // ����� Windows. ��� �� %windir% ��� %SYSTEMROOT% (������ C:\Windows)
  CSIDL_WINDOWS                      = $24;


  SE_CREATE_TOKEN_PRIV               = 'SeCreateTokenPrivilege';
  SE_ASSIGNPRIMARYTOKEN_PRIV         = 'SeAssignPrimaryTokenPrivilege';
  SE_LOCK_MEMORY_PRIV                = 'SeLockMemoryPrivilege';
  SE_INCREASE_QUOTA_PRIV             = 'SeIncreaseQuotaPrivilege';
  SE_UNSOLICITED_INPUT_PRIV          = 'SeUnsolicitedInputPrivilege';
  SE_MACHINE_ACCOUNT_PRIV            = 'SeMachineAccountPrivilege';
  SE_TCB_PRIV                        = 'SeTcbPrivilege';
  SE_SECURITY_PRIV                   = 'SeSecurityPrivilege';
  SE_TAKE_OWNERSHIP_PRIV             = 'SeTakeOwnershipPrivilege';
  SE_LOAD_DRIVER_PRIV                = 'SeLoadDriverPrivilege';
  SE_SYSTEM_PROFILE_PRIV             = 'SeSystemProfilePrivilege';
  SE_SYSTEMTIME_PRIV                 = 'SeSystemtimePrivilege';
  SE_PROF_SINGLE_PROCESS_PRIV        = 'SeProfileSingleProcessPrivilege';
  SE_INC_BASE_PRIORITY_PRIV          = 'SeIncreaseBasePriorityPrivilege';
  SE_CREATE_PAGEFILE_PRIV            = 'SeCreatePagefilePrivilege';
  SE_CREATE_PERMANENT_PRIV           = 'SeCreatePermanentPrivilege';
  SE_BACKUP_PRIV                     = 'SeBackupPrivilege';
  SE_RESTORE_PRIV                    = 'SeRestorePrivilege';
  SE_SHUTDOWN_PRIV                   = 'SeShutdownPrivilege';
  SE_DEBUG_PRIV                      = 'SeDebugPrivilege';
  SE_AUDIT_PRIV                      = 'SeAuditPrivilege';
  SE_SYSTEM_ENVIRONMENT_PRIV         = 'SeSystemEnvironmentPrivilege';
  SE_CHANGE_NOTIFY_PRIV              = 'SeChangeNotifyPrivilege';
  SE_REMOTE_SHUTDOWN_PRIV            = 'SeRemoteShutdownPrivilege';
  SE_UNDOCK_PRIV                     = 'SeUndockPrivilege';
  SE_SYNC_AGENT_PRIV                 = 'SeSyncAgentPrivilege';
  SE_ENABLE_DELEGATION_PRIV          = 'SeEnableDelegationPrivilege';
  SE_MANAGE_VOLUME_PRIV              = 'SeManageVolumePrivilege';

  DefMaxWaitTime                     = 3 * 60 * 60;

const
  ssIniExtension                     = '.ini';
  ssFormExtension                    = '.frm';
  ssDataExtension                    = '.dat';

type
  TProcWaitCheck     = procedure (var IsWaitBreak: Boolean);

  ESystemError       = class (Exception);

{ == ��������� ��������� �� ������ ============================================= }
function  GetSystemError(const SucFormat, ErrFormat: string; const ErrorCode: Integer): string; overload;
function  GetSystemError(const MsgFormat: string; const ErrorCode: Integer): string; overload;
function  GetSystemError(const ErrorCode: Integer; const ShowCode: Boolean = True): string; overload;
function  GetSystemError(const ShowCode: Boolean = True): string; overload;
procedure RaiseSystemErrorFmt(const Msg: string; const ErrorCode: Integer); overload;
procedure RaiseSystemErrorFmt(const Msg: string); overload;
procedure RaiseSystemError(const ErrorCode: Integer); overload;
procedure RaiseSystemError; overload;
{ == ��������� ���� ������ � �������� ������� ���������� ======================= }
function GetApplicationFileName: TFileName;
function GetModuleFileName: TFileName;
function GetModuleDirectory: TFileName;
function GetExecuteDirectory: TFileName;
function GetTempDirectory: TFileName;
function GetHelpDirectory: TFileName;
function GetApplicationIniFile: TFileName;
function GetModuleIniFile: TFileName;
function GetApplicationFormFile: TFileName;
function GetModuleFormFile: TFileName;
function GetApplicationDataFile: TFileName;
function GetApplicationVarFile(const AExtension: string): TFileName;
function GetModuleVarFile(const AExtension: string): TFileName;
{ == �������� � ������� ������ � ��������� ===================================== }
function ChangeFileName(const SourceName, NewPart: string): string;
function IsNetworkPath(const FileName: string): Boolean;
function CompressPath(const FileName: string; const EndParts: Integer = 2): string;
function MinimizePath(const FileName: string; const MaxLength: Integer): string;
{ == ��������� ���� ���������� � �������� ������������ ========================= }
function GetComputerFullName: string;
function GetComputerNetName: string;
function GetCurrentUserName: string;
{ == ��������� ��������� ����� ================================================= }
function GetWindowsDir: string;
function GetWindowsDirEx: string;
function GetTempDir: string;
function GetTempDirEx: string;
function GetShellFolder(const CSIDL: Word; const fCreate: Boolean = True): string;
function GetShellFolderEx(const CSIDL: Word; const fCreate: Boolean = True): string;
function GetShellFolderLocation(const CSIDL: Word): string;
function GetShellFolderLocationEx(const CSIDL: Word): string;
{ == ���������� ������, ��������������� � ������ =============================== }
function GetAssociatedIconHandle(FileName: string): HIcon;
{ == �������� ������ =========================================================== }
function CreateShortcut(const CmdLine, Args, WorkDir, LinkFile: string): Cardinal;
{ == ������ ������� ��������� � �������� �� ���������� ========================= }
function WinExec32(WorkDir, CmdLine: string; const ShowWindow: Integer;
  const WaitExit: Boolean; const CbWaitExitChk: TProcWaitCheck;
  const MaxWaitTime: Cardinal): Integer;
function WinExecWithLogon32(const CmdLine: string; const WorkDir: string;
 const Domain, UserName, Password: string; const LogonFlags, ShowWindow: Cardinal;
  const WaitExit: Boolean; const CbWaitExitChk: TProcWaitCheck;
  const MaxWaitTime: Cardinal): Integer;
function OpenFile32(VerbMode, FileName, Parameters: string; Visibility: Integer;
  const WaitExit: Boolean; const CbWaitExitChk: TProcWaitCheck;
  const MaxWaitTime: Cardinal): Integer;
{ == ����������� � ���������� ������� ������ =================================== }
function NetConnectionCreate(const TypeResource: Cardinal;
  const LocalName, RemoteName, UserName, Password: string;
  const SaveProfile: Boolean): LongInt;
function NetConnectionClose(const LocalName: string;
  const ForceMode, SaveProfile: Boolean): LongInt;
{ == ���������� � ������� ����� ================================================ }
procedure GetHDDInfo(Disk: string; var VolumeName, FileSystemName: string;
  var VolumeSerialNo, MaxComponentLength, FileSystemFlags: LongWord);
{ == �������� �� ������� ����������������� ���� � ������� ====================== }
function IsAdmin: Boolean;
{ == ��������� ���������� � ������� ============================================ }
function SetPrivilege(aPrivilegeName: string; aEnabled : Boolean): Boolean;
{ == ���������� ������ Windows ================================================= }
function ExitWindows(aParameters: Longword): Boolean;
{ == ��������� GIUD ============================================================ }
function CreateGUID: string;
function CreateUID(const sRepl: string = ''): string;
{ == ��������� ���������� ����� ����� ========================================== }
function GetTempFileName(const sExt: string): string;
function GetTempFilePath(const sExt: string): string;
{ == ����� ���������� ���������� =============================================== }
procedure OpenHelp(const HelpFile, Topic: string);
procedure OpenHelpChm(const ChmFile, Topic: string);
{ == ������� URL ������� ���������� ============================================ }
procedure OpenUrl(const sUrl: string);
{ == ������� ����������� ������ ���������� �� ��������� ======================== }
procedure CreateEMail(const sHeader: string);
{ == �������� ���������� ������ ����������� ����� ============================== }
function  CheckEMail(const sMail: string): Boolean;

implementation

uses
  Forms, StrUtils, ShlObj, ShellApi, ComObj, ActiveX, Registry,
  rDialogs;

type
  TCreateProcessWithLogonW =
    function(const lpUsername: PWideChar;
    const lpDomain: PWideChar; const lpPassword: PWideChar;
    dwLogonFlags: DWORD; const lpApplicationName: PWideChar;
    lpCommandLine: PWideChar; dwCreationFlags: DWORD;
    lpEnvironment: Pointer; const lpCurrentDirectory: PWideChar;
    lpStartupInfo: PStartupInfo;
    lpProcessInfo: PProcessInformation): Boolean; stdcall;

const
  SNotFound            = 'DIRECTORY_NOT_DEFINE';
  SAllUsers1           = 'All Users';
  SAllUsers2           = 'All Users.WINNT';
  SAllUsers3           = 'All Users.WINDOWS';
  SDefUser             = 'Default User';
  SAppData             = 'Application Data';

  dirTemp              = 'Temp';
  dirHelp              = 'Help';

  iniDirSettings       = 'DIRECTORIES';
  iniHelpDir           = 'HelpFiles';
  iniReportsDir        = 'ReportsForms';

  SKeyShellFolders     = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders';

  AdvApiDllName        = 'advapi32.dll';
  WinExecProcName      = 'CreateProcessWithLogonW';

  SFmtSystemOk         = '%s.';
  SFmtSystemError      = '"%s"!';
  SFmtSystemErrorExt   = 'SysError #%d: "%s"!';

resourcestring
  rsWaitExitBreak         = '�������� ���������� �������� (�����) "%s" ��������!';
  rsWaitExitTimeout       = '�������� ���������� �������� (�����) "%s" �������� � ����� � ����������� ������� ��������!';

  rsErrLoadLibrary        = '������ �������� ������������ ���������� ''%s''!';
  rsErrLoadLibraryEx      = '������ �������� ������������ ���������� ''%s'':'#13'%s!';
  rsErrFindProcedure      = '��������� ''%s'' �� ������� � ������������ ���������� ''%s''!';

{ == ��������� ��������� �� ������ ============================================= }

function GetSystemError(const SucFormat, ErrFormat: string; const ErrorCode: Integer): string;
begin
  if ErrorCode = NO_ERROR
  then Result := Format(SucFormat, [SysErrorMessage(ErrorCode)])
  else Result := Format(ErrFormat, [ErrorCode, SysErrorMessage(ErrorCode)]);
end;

function GetSystemError(const MsgFormat: string; const ErrorCode: Integer): string;
begin
  Result := Format(MsgFormat, [ErrorCode, SysErrorMessage(ErrorCode)]);
end;

function GetSystemError(const ErrorCode: Integer; const ShowCode: Boolean = True): string;
begin
  if ErrorCode = NO_ERROR
  then Result := Format(SFmtSystemOk, [SysErrorMessage(ErrorCode)])
  else begin
    if ShowCode
    then Result := Format(SFmtSystemErrorExt, [ErrorCode, SysErrorMessage(ErrorCode)])
    else Result := Format(SFmtSystemError, [SysErrorMessage(ErrorCode)]);
  end;
end;

function GetSystemError(const ShowCode: Boolean = True): string;
begin
  Result := GetSystemError(GetLastError, ShowCode);
end;

procedure RaiseSystemErrorFmt(const Msg: string; const ErrorCode: Integer);
begin
  if ErrorCode <> NO_ERROR then
    raise ESystemError.CreateFmt(Msg, [GetSystemError(ErrorCode)]);
end;

procedure RaiseSystemErrorFmt(const Msg: string);
begin
  RaiseSystemErrorFmt(Msg, GetLastError);
end;

procedure RaiseSystemError(const ErrorCode: Integer);
begin
  if ErrorCode <> NO_ERROR then
    raise ESystemError.Create(GetSystemError(ErrorCode));
end;

procedure RaiseSystemError;
begin
  RaiseSystemError(GetLastError);
end;

{ == ��������� ���� ������ � �������� ������� ���������� ======================= }

function GetApplicationFileName: TFileName;
var
  AppName: array[0..MAX_PATH] of Char;
begin
  if IsLibrary then
  begin
    FillChar(AppName, sizeof(AppName), #0);
    Windows.GetModuleFileName(MainInstance, AppName, SizeOf(AppName) - 1);
    Result := string(AppName);
  end
  else Result := Application.ExeName;
end;

function GetModuleFileName: TFileName;
var
  ModuleName : array[0..MAX_PATH] of Char;
begin
  FillChar(ModuleName, sizeof(ModuleName), #0);
  Windows.GetModuleFileName(hInstance, ModuleName, sizeof(ModuleName) - 1);
  Result := string(ModuleName);
end;

function GetExecuteDirectory: TFileName;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(GetApplicationFileName));
end;

function GetModuleDirectory: TFileName;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(GetModuleFileName));
end;

function GetTempDirectory: TFileName;
begin
  Result := IncludeTrailingPathDelimiter(GetExecuteDirectory + dirTemp);
  if not DirectoryExists(Result) then ForceDirectories(Result);
end;

function GetHelpDirectory: TFileName;
begin
  Result := IncludeTrailingPathDelimiter(GetExecuteDirectory + dirHelp);
end;

function GetApplicationIniFile: TFileName;
begin
  Result := ChangeFileExt(GetApplicationFileName, ssIniExtension);
end;

function GetModuleIniFile: TFileName;
begin
  Result := ChangeFileExt(GetModuleFileName, ssIniExtension);
end;

function GetApplicationFormFile: TFileName;
begin
  Result := ChangeFileExt(GetApplicationFileName, ssFormExtension);
end;

function GetModuleFormFile: TFileName;
begin
  Result := ChangeFileExt(GetModuleFileName, ssFormExtension);
end;

function GetApplicationDataFile: TFileName;
begin
  Result := ChangeFileExt(GetApplicationFileName, ssDataExtension);
end;

function GetApplicationVarFile(const AExtension: string): TFileName;
begin
  Result := ChangeFileExt(GetApplicationFileName, AExtension);
end;

function GetModuleVarFile(const AExtension: string): TFileName;
begin
  Result := ChangeFileExt(GetModuleFileName, AExtension);
end;

{ == �������� � ������� ������ � ��������� ===================================== }

function ChangeFileName(const SourceName, NewPart: string): string;
begin
  Result := ChangeFileExt(SourceName, '') + NewPart + ExtractFileExt(SourceName);
end;

function IsNetworkPath(const FileName: string): Boolean;
var
  Tmp: string;
begin
  Tmp := ExpandUNCFileName(FileName);
  Result := IsPathDelimiter(Tmp, 1) and IsPathDelimiter(Tmp, 2); 
end;

function CompressPath(const FileName: string; const EndParts: Integer = 2): string;
var
  i: Integer;
  DriveName, TempPath, LastName: string;
begin
  DriveName := IncludeTrailingPathDelimiter(ExtractFileDrive(FileName));
  TempPath := FileName;
  LastName := EmptyStr;
  for i := 1 to EndParts do
  begin
    LastName := PathDelim + ExtractFileName(TempPath) + LastName;
    TempPath := ExcludeTrailingPathDelimiter(ExtractFilePath(TempPath));
  end;
  if Length(DriveName + '...' + LastName) < Length(FileName) 
  then Result := DriveName + '...' + LastName
  else Result := FileName;
end;

function MinimizePath(const FileName: string; const MaxLength: Integer): string;
var
  Parts: Integer;
  Tmp: string;
begin
  Parts := 0;
  repeat
    Inc(Parts);
    Tmp := CompressPath(FileName, Parts);
  until (Length(Tmp) > MaxLength) or SameText(Tmp, FileName);
  if (Parts > 1) and (Length(Tmp) > MaxLength)
  then Result := CompressPath(FileName, Parts - 1)
  else Result := FileName;
end;

{ == ��������� ���� ���������� � �������� ������������ ========================= }

function GetComputerFullName: string;
var
  CN, UN: array[0..512] of char;
  CL: Cardinal;
begin
  CL := 512;
  GetComputerName(CN, CL);
  GetUserName(UN, CL);
  Result := string(CN) + '.' + string(UN);
end;

function GetComputerNetName: string;
var
  CN: array[0..512] of char;
  CL: Cardinal;
begin
  CL := 512;
  GetComputerName(CN, CL);
  Result := string(CN);
end;

function GetCurrentUserName: string;
var
  UN: array[0..512] of char;
  CL: Cardinal;
begin
  CL := 512;
  GetUserName(UN, CL);
  Result := string(UN);
end;

{ == ��������� ��������� ����� ================================================= }

function GetWindowsDir: string;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
  SetString(Result, Buffer, GetWindowsDirectory(Buffer, SizeOf(Buffer) - 1));
end;

function GetWindowsDirEx: string;
var
  Buffer: array[0..MAX_PATH] of Char;
  LenStr: Integer;
begin
  LenStr := GetWindowsDirectory(Buffer, SizeOf(Buffer) - 1);
  if LenStr > 0
  then SetString(Result, Buffer, LenStr)
  else RaiseSystemError;
end;

function GetTempDir: string;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
  SetString(Result, Buffer, GetTempPath(Sizeof(Buffer) - 1, Buffer));
end;

function GetTempDirEx: string;
var
  Buffer: array[0..MAX_PATH] of Char;
  LenStr: Integer;
begin
  LenStr := GetTempPath(Sizeof(Buffer) - 1, Buffer);
  if LenStr > 0
  then SetString(Result, Buffer, LenStr)
  else RaiseSystemError;
end;

function GetShellFolder(const CSIDL: Word; const fCreate: Boolean = True): string;
var
  Buff: array [0..MAX_PATH] of Char;
begin
  if SHGetSpecialFolderPath(Application.Handle, Buff, CSIDL, fCreate)
  then Result := string(Buff)
  else Result := EmptyStr;
end;

function GetShellFolderEx(const CSIDL: Word; const fCreate: Boolean = True): string;
var
  Buff: array [0..MAX_PATH] of Char;
begin
  if SHGetSpecialFolderPath(Application.Handle, Buff, CSIDL, fCreate)
  then Result := string(Buff)
  else raise ESystemError.Create(GetSystemError(GetLastError));
end;

function GetShellFolderLocation(const CSIDL: Word): string;
var
  Buff: array [0..MAX_PATH] of Char;
  IDList: PItemIDList;
begin
  if (SHGetSpecialFolderLocation(Application.Handle, CSIDL, IDList) = NO_ERROR)
  and SHGetPathFromIDList(IDList, Buff)
  then Result := string(Buff)
  else Result := EmptyStr;
end;

function GetShellFolderLocationEx(const CSIDL: Word): string;
var
  Buff: array [0..MAX_PATH] of Char;
  IDList: PItemIDList;
  RetCode: DWord;
begin
  RetCode := SHGetSpecialFolderLocation(Application.Handle, CSIDL, IDList);
  if RetCode = NO_ERROR then
  begin
    if SHGetPathFromIDList(IDList, Buff)
    then Result := string(Buff)
    else raise ESystemError.Create(GetSystemError(GetLastError));
  end
  else raise ESystemError.Create(GetSystemError(RetCode));
end;

{ == ���������� ������, ��������������� � ������ =============================== }
function GetAssociatedIconHandle(FileName: string): HIcon;
var
  R: TRegistry;
  Alias, IconPath: string;
  IconNum, QPos: Integer;
begin
  Result := 0;
  IconNum := 0;
  R := TRegistry.Create;
  try
    Alias := EmptyStr; IconPath := EmptyStr;
    R.RootKey := HKEY_CLASSES_ROOT;
    if R.OpenKey('\' + ExtractFileExt(FileName), False) then
       Alias := R.ReadString(EmptyStr);
    R.CloseKey;
    if Alias = EmptyStr then
    begin
      if R.OpenKey('\' + AnsiUpperCase(ExtractFileExt(FileName)), False) then
        Alias := R.ReadString(EmptyStr);
      R.CloseKey;
    end;
    if Alias <> EmptyStr then
    begin
      if R.OpenKey('\' + Alias + '\DefaultIcon', False) then
        IconPath := R.ReadString(EmptyStr);
      R.CloseKey;
    end;
    if IconPath <> EmptyStr then
    begin
      QPos := Pos(',', IconPath);
      if QPos > 0 then
      begin
        IconNum := StrToIntDef(Copy(IconPath, QPos + 1, 4), 1);
        IconPath := Copy(IconPath, 1, QPos - 1)
      end;
    end;
    if IconPath <> EmptyStr then
      Result := ExtractIcon(hInstance, PChar(IconPath), IconNum);
  finally
     R.Free;
  end;
end;

{ == �������� ������ =========================================================== }
function CreateShortcut(const CmdLine, Args, WorkDir, LinkFile: string): Cardinal;
var
  MyObject: IUnknown;
  MySLink: IShellLink;
  MyPFile: IPersistFile;
  WideFile: WideString;
begin
  MyObject := CreateComObject(CLSID_ShellLink);
  MySLink := MyObject as IShellLink;
  MyPFile := MyObject as IPersistFile;
  with MySLink do
  begin
    SetPath(PWideChar(CmdLine));
    SetArguments(PWideChar(Args));
    SetWorkingDirectory(PWideChar(WorkDir));
  end;
  WideFile := LinkFile;
  Result := MyPFile.Save(PWChar(WideFile), False);
end;

{ == ������ ������� ��������� � �������� �� ���������� ========================= }
function WinExec32(WorkDir, CmdLine: string; const ShowWindow: Integer;
  const WaitExit: Boolean; const CbWaitExitChk: TProcWaitCheck;
  const MaxWaitTime: Cardinal): Integer;
var
  zAppName: array[0..512] of char;
  zCurDir: array[0..255] of char;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  ExitCode: DWord;
  ExitWait: Boolean;
  WaitStart: Cardinal;
begin
  Result := 0;
  StrPCopy(zAppName, CmdLine);
  StrPCopy(zCurDir, WorkDir);
  FillChar(StartupInfo, Sizeof(StartupInfo), #0);
  StartupInfo.cb := Sizeof(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := ShowWindow;
  if CreateProcess(nil,
           zAppName,                      { ��������� ��������� ������ }
           nil,                           { ��������� �� ������� ��������� ������������ }
           nil,                           { ��������� �� ����� ��������� ������������ }
           false,                         { ���� ������������� ����������� }
           CREATE_NEW_CONSOLE or          { ���� �������� }
           NORMAL_PRIORITY_CLASS,
           nil,                           { ��������� �� ����� ����� �������� }
           zCurDir,                       { ��������� �� ��� ������� ���������� }
           StartupInfo,                   { ��������� �� STARTUPINFO }
           ProcessInfo)
  then begin
    if WaitExit then
    begin
      try
        ExitWait := False;
        WaitStart := GetTickCount;
        while GetExitCodeProcess(ProcessInfo.hProcess, ExitCode) and (ExitCode = STILL_ACTIVE) do
        begin
          Application.ProcessMessages;
          if Assigned(CbWaitExitChk) then
            CbWaitExitChk(ExitWait);
          if ExitWait then
            raise ESystemError.CreateFmt(rsWaitExitBreak, [ExtractFileName(CmdLine)])
          else Sleep(100);
          if MaxWaitTime > 0 then
          begin
            if (GetTickCount - WaitStart) > (MaxWaitTime * 1000) then
            begin
              TerminateProcess(ProcessInfo.hProcess, ExitCode);
              raise ESystemError.CreateFmt(rsWaitExitTimeout, [ExtractFileName(CmdLine)]);
            end;
          end;
        end;
        Result := ExitCode;
      finally
        CloseHandle(ProcessInfo.hProcess);
      end;
    end;
  end
  else RaiseSystemError;
end;

function WinExecWithLogon32(const CmdLine: string; const WorkDir: string;
  const Domain, UserName, Password: string; const LogonFlags, ShowWindow: Cardinal;
  const WaitExit: Boolean; const CbWaitExitChk: TProcWaitCheck;
  const MaxWaitTime: Cardinal): Integer;
var
  AdvApiDll: THandle;
  WinExecProc: TCreateProcessWithLogonW;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  wCommandLine: array[0..512] of WideChar;
  wCurrentDir: array[0..255] of WideChar;
  wDomain: array[0..64] of WideChar;
  wUserName: array[0..64] of WideChar;
  wPassword: array[0..64] of WideChar;
  ExitCode: DWord;
  ExitWait: Boolean;
  WaitStart: Cardinal;
begin
  Result := 0;
  @WinExecProc := nil;
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    AdvApiDll := LoadLibrary(AdvApiDllName);
    try
      if AdvApiDll <> INVALID_HANDLE_VALUE then
      begin
        @WinExecProc := GetProcAddress(AdvApiDll, WinExecProcName);
        if Assigned(WinExecProc) then
        begin
          FillChar(StartupInfo, SizeOf(StartupInfo), #0);
          StartupInfo.cb := SizeOf(StartupInfo);
          StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
          StartupInfo.wShowWindow := ShowWindow;
          if WinExecProc(
            StringToWideChar(UserName, wUserName, SizeOf(wUserName) div SizeOf(WideChar)),
            StringToWideChar(Domain, wDomain, SizeOf(wDomain) div SizeOf(WideChar)),
            StringToWideChar(Password, wPassword, SizeOf(wPassword) div SizeOf(WideChar)),
            LogonFlags,
            nil,
            StringToWideChar(CmdLine, wCommandLine, SizeOf(wCommandLine) div SizeOf(WideChar)),
            CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS,
            nil,
            StringToWideChar(WorkDir, wCurrentDir, SizeOf(wCurrentDir) div SizeOf(WideChar)),
            @StartupInfo,
            @ProcessInfo) then
          begin
            if WaitExit then
            begin
              ExitWait := False;
              WaitStart := GetTickCount;
              while GetExitCodeProcess(ProcessInfo.hProcess, ExitCode)
                and (ExitCode = STILL_ACTIVE) do
                begin
                  Application.ProcessMessages;
                  if Assigned(CbWaitExitChk) then
                    CbWaitExitChk(ExitWait);
                  if ExitWait then
                    raise ESystemError.CreateFmt(rsWaitExitBreak, [ExtractFileName(CmdLine)])
                  else Sleep(100);
                  if MaxWaitTime > 0 then
                  begin
                    if (GetTickCount - WaitStart) > (MaxWaitTime * 1000) then
                    begin
                      TerminateProcess(ProcessInfo.hProcess, ExitCode);
                      raise ESystemError.CreateFmt(rsWaitExitTimeout, [ExtractFileName(CmdLine)]);
                    end;
                  end;
                end;
              CloseHandle(ProcessInfo.hProcess);
              Result := ExitCode;
            end;
          end
          else RaiseSystemError;
        end
        else raise ESystemError.CreateFmt(rsErrFindProcedure, [WinExecProcName, AdvApiDllName]);
      end
      else raise ESystemError.CreateFmt(rsErrLoadLibrary, [GetSystemError(False)]);
    finally
      if Assigned(WinExecProc) then
        @WinExecProc := nil;
      if AdvApiDll <> INVALID_HANDLE_VALUE then
        FreeLibrary(AdvApiDll);
    end;
  end
  else RaiseSystemError(ERROR_CALL_NOT_IMPLEMENTED);
end;

function OpenFile32(VerbMode, FileName, Parameters: string; Visibility: Integer;
  const WaitExit: Boolean; const CbWaitExitChk: TProcWaitCheck;
  const MaxWaitTime: Cardinal): Integer;
var
  exInfo: TShellExecuteInfo;
  ExitCode: LongWord;
  ExitWait: Boolean;
  WaitStart: Cardinal;
begin
  Result := 0;
  FillChar(exInfo, Sizeof(exInfo), 0);
  with exInfo do
  begin
    cbSize:= SizeOf(exInfo);
    fMask := SEE_MASK_NOCLOSEPROCESS;
    Wnd   := Application.Handle;
    lpVerb:= PWideChar(VerbMode);
    lpFile:= PWideChar(FileName);
    lpParameters := PWideChar(Parameters);
    nShow := Visibility;
  end;
  if ShellExecuteEx(@exInfo) then
  begin
    if WaitExit then
    begin
      ExitWait := False;
      WaitStart := GetTickCount;
      while GetExitCodeProcess(exInfo.hProcess, ExitCode) and (ExitCode = STILL_ACTIVE) do
      begin
        Application.ProcessMessages;
        if Assigned(CbWaitExitChk) then
          CbWaitExitChk(ExitWait);
        if ExitWait then
          raise ESystemError.CreateFmt(rsWaitExitBreak, [ExtractFileName(FileName)])
        else Sleep(100);
        if MaxWaitTime > 0 then
        begin
          if (GetTickCount - WaitStart) > (MaxWaitTime * 1000) then
          begin
            TerminateProcess(exInfo.hProcess, ExitCode);
            raise ESystemError.CreateFmt(rsWaitExitTimeout, [ExtractFileName(FileName)]);
          end;
        end;
      end;
      CloseHandle(exInfo.hProcess);
      Result := ExitCode;
    end;
  end
  else RaiseSystemError;
end;

{ == ����������� � ���������� ������� ������ =================================== }
function NetConnectionCreate(const TypeResource: Cardinal;
  const LocalName, RemoteName, UserName, Password: string;
  const SaveProfile: Boolean): LongInt;
var
  NetResource: TNetResource;
  lpPassword: PWideChar;
  lpUserName: PWideChar;
  dwFlags: Cardinal;
begin
  NetResource.dwType := TypeResource;
  NetResource.lpLocalName := PWideChar(LocalName);
  NetResource.lpRemoteName := PWideChar(RemoteName);
  NetResource.lpProvider := '';
  if Trim(UserName) = EmptyStr then lpUserName := nil
  else lpUserName := PWideChar(Trim(UserName));
  if Trim(Password) = EmptyStr then lpPassword := nil
  else lpPassword := PWideChar(Trim(Password));
  dwFlags := 0;
  if SaveProfile then dwFlags := CONNECT_UPDATE_PROFILE;
  Result := WNetAddConnection2(NetResource, lpPassword, lpUserName, dwFlags);
end;

function NetConnectionClose(const LocalName: string;
  const ForceMode, SaveProfile: Boolean): LongInt;
var
  dwFlags: Cardinal;
begin
  dwFlags := 0;
  if SaveProfile then dwFlags := CONNECT_UPDATE_PROFILE;
  Result := WNetCancelConnection2(PWideChar(LocalName), dwFlags, ForceMode);
end;

{ == ���������� � ������� ����� ================================================ }
procedure GetHDDInfo(Disk: string; var VolumeName, FileSystemName: string;
  var VolumeSerialNo, MaxComponentLength, FileSystemFlags: LongWord);
var
  _VolumeName, _FileSystemName: array [0..MAX_PATH-1] of Char;
  _VolumeSerialNo, _MaxComponentLength,_FileSystemFlags: LongWord;
begin
  if GetVolumeInformation(PChar(Disk), _VolumeName, MAX_PATH, @_VolumeSerialNo,
    _MaxComponentLength, _FileSystemFlags, _FileSystemName, MAX_PATH) then
  begin
    VolumeName := _VolumeName;
    VolumeSerialNo := _VolumeSerialNo;
    MaxComponentLength := _MaxComponentLength;
    FileSystemFlags := _FileSystemFlags;
    FileSystemName := _FileSystemName;
  end
  else RaiseSystemError;
end;

{ == �������� �� ������� ����������������� ���� � ������� ====================== }
function IsAdmin: Boolean;
const
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
  SECURITY_BUILTIN_DOMAIN_RID = $00000020;
  DOMAIN_ALIAS_RID_ADMINS = $00000220;
var
  hAccessToken: THandle;
  ptgGroups: PTokenGroups;
  dwInfoBufferSize: DWORD;
  psidAdministrators: PSID;
  x: Integer;
  bSuccess: Boolean;
begin
  Result := False;
  bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, hAccessToken);
  if not bSuccess then
  begin
    if GetLastError = ERROR_NO_TOKEN then
      bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hAccessToken);
  end;
  if bSuccess then
  begin
    GetMem(ptgGroups, 1024);
    bSuccess := GetTokenInformation(hAccessToken, TokenGroups,
      ptgGroups, 1024, dwInfoBufferSize);
    CloseHandle(hAccessToken);
    if bSuccess then
    begin
      AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2,
        SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS,
        0, 0, 0, 0, 0, 0, psidAdministrators);
      {$R-}
      for x := 0 to ptgGroups.GroupCount - 1 do
        if EqualSid(psidAdministrators, ptgGroups.Groups[x].Sid) then
        begin
          Result := True;
          Break;
        end;
      {$R+}
      FreeSid(psidAdministrators);
    end;
    FreeMem(ptgGroups);
  end;
end;

{ == ��������� ���������� � ������� ============================================ }
function SetPrivilege(aPrivilegeName: string; aEnabled : Boolean): Boolean;
var
  TPPrev, TP: TTokenPrivileges;
  TokenHd: THandle;
  dwRetLen: DWord;
begin
  Result := False;
  OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, TokenHd);
  if LookupPrivilegeValue(nil, PChar(aPrivilegeName), TP.Privileges[0].LUID) then
  begin
    TP.PrivilegeCount := 1;
    if aEnabled
    then TP.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
    else TP.Privileges[0].Attributes:= 0;
    dwRetLen := 0;
    TPPrev := TP;
    Result := AdjustTokenPrivileges(TokenHd, False, TP, SizeOf(TPPrev), TPPrev, dwRetLen);
  end;
  CloseHandle(TokenHd);
end;

{ == ���������� ������ Windows ================================================= }
function ExitWindows(aParameters: Longword): Boolean;
begin
  Result := False;
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    if SetPrivilege(SE_SHUTDOWN_PRIV, True) then
    begin
      Result := ExitWindowsEx(aParameters, 0);
      SetPrivilege(SE_SHUTDOWN_PRIV, False);
    end;
  end
  else Result := ExitWindowsEx(aParameters, 0);
end;

{ == ��������� GIUD ============================================================ }
function CreateGUID: string;
var
  ID: TGUID;
begin
  Result := EmptyStr;
  if CoCreateGuid(ID) = S_OK then
    Result := GUIDToString(ID);
end;

function CreateUID(const sRepl: string = ''): string;
begin
  Result := CreateGUID;
  if Result <> '' then
  begin
    if sRepl = '-'
    then Result := Copy(Result, 2, Length(Result) - 2)
    else Result := AnsiReplaceStr(Copy(Result, 2, Length(Result) - 2), '-', sRepl);
  end;
end;

{ == ��������� ���������� ����� ����� ========================================== }

function GetTempFileName(const sExt: string): string;
begin
  Result := CreateGUID;
  Result := Copy(Result, 2, Length(Result) - 2);
  if sExt = ''
  then Result := ChangeFileExt(Result, '.tmp')
  else Result := ChangeFileExt(Result, sExt);
end;

function GetTempFilePath(const sExt: string): string;
begin
  Result := IncludeTrailingPathDelimiter(GetTempDirEx) + GetTempFileName(sExt);
end;

{ == ����� ���������� ���������� =============================================== }
procedure OpenHelp(const HelpFile, Topic: string);
begin
  if SameText(ExtractFileExt(HelpFile), '.chm') then
    OpenHelpChm(HelpFile, Topic)
  else
    OpenFile32('open', HelpFile, '', SW_SHOWDEFAULT, False, nil, 0);
end;

procedure OpenHelpChm(const ChmFile, Topic: string);
begin
  if Topic = EmptyStr
  then WinExec32(GetExecuteDirectory, IncludeTrailingPathDelimiter(GetWindowsDirEx) + 'hh.exe ' + ChmFile, SW_SHOW, False, nil, 0)
  else WinExec32(GetExecuteDirectory, IncludeTrailingPathDelimiter(GetWindowsDirEx) + 'hh.exe ' + ChmFile + '::/' + Topic, SW_SHOW, False, nil, 0);
end;

{ == ������� URL ������� ���������� ============================================ }
procedure OpenUrl(const sUrl: string);
begin
  if StartsText('http://', sUrl) or StartsText('https://', sUrl)
  or StartsText('ftp://', sUrl) or StartsText('ftps://', sUrl)
  then ShellExecute(0, nil, PWideChar(sUrl), nil, nil, 1)
  else ShellExecute(0, nil, PWideChar('http://' + sUrl), nil, nil, 1);
end;

{ == ������� ����������� ������ ���������� �� ��������� ======================== }
procedure CreateEMail(const sHeader: string);
begin
  if StartsText('mailto:', sHeader)
  then ShellExecute(0, nil, PWideChar(sHeader), nil, nil, 1)
  else ShellExecute(0, nil, PWideChar('mailto:' + sHeader), nil, nil, 1);
end;

{ == �������� ���������� ������ ����������� ����� ============================== }
function CheckEMail(const sMail: string): Boolean;

  function CheckUser(const sUser: string): Boolean;
  var
    i: Integer;
  begin
    Result := (Length(sUser) in [1..64])     // RFC 5321 ������������ ����� ����� ����� �� 64 ��������
          and (sUser[1] <> '.')              // ������ ������ �� .
          and (sUser[Length(sUser)] <> '.')  // ��������� ������ �� .
          and (Pos('..', sUser) = 0);        // ��������� ..

    // ��������� ������� �� ����������
    if Result then
    begin
      for i := 1 to Length(sUser) do
      begin
        if not CharInSet(sUser[i], ['a'..'z', 'A'..'Z', '0'..'9', '_', '-', '.']) then
        begin
          Result := False;
          Break;
        end;
      end;
    end;
  end;

  function CheckDomain(const sDomain: string): Boolean;
  var
    i: Integer;
  begin
    Result := (Length(sDomain) in [4..252])          // RFC 5321 ������������ ����� ������ �� 254 �������� ����� ����� �����
          and (Pos('.', sDomain) > 0)                // ����� ������ ���� �� ������� ���� ������� ������
          and (sDomain[1] <> '.')                    // ������ ������ �� .
          and (sDomain[Length(sDomain)] <> '.')      // ��������� ������ �� .
          and (sDomain[Length(sDomain) - 1] <> '.')  // ������������� ������ �� . (����� ��������� ������ >=2, ��. ����)
          and (Pos('..', sDomain) = 0);              // ��������� ..

    // ��������� ������� �� ����������
    if Result then
    begin
      for i := 1 to Length(sDomain) do
      begin
        if not CharInSet(sDomain[i], ['a'..'z', 'A'..'Z', '0'..'9', '_', '-', '.']) then
        begin
          Result := False;
          Break;
        end;
      end;
    end;

    // ����� �������� ������ ������ �������� ������ �� ����
    // � ���� �� ������ ���� �������� - ��� ��� ��������� ����
    if Result then
    begin
      for i := Length(sDomain) downto 1 do
      begin
        if sDomain[i] = '.' then Break
        else begin
          if not CharInSet(sDomain[i], ['a'..'z', 'A'..'Z']) then
          begin
            Result := False;
            Break;
          end;
        end;
      end;
    end;
  end;

var
  iEt: Integer;
begin
  // RFC 5321 ������������ ����� ������ �� 254 ��������
  Result := Length(sMail) in [6..254];

  if Result then
  begin
    iEt := Pos('@', sMail);
    if iEt > 0 then
    begin
      Result := CheckUser(Copy(sMail, 1, iEt - 1))
            and CheckDomain(Copy(sMail, iEt + 1, Length(sMail)));
    end
    else Result := False;
  end;
end;

end.
