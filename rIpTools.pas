unit rIpTools;

interface

type
  RIpAddr = record
    case Byte of
      0: (Socket: Cardinal);
      1: (Oktets: array [0..3] of Byte);
  end;

  PIpData = ^RIpData;
  RIpData = record
    Address: RIpAddr;
    Net: RIpAddr;
    Mask: RIpAddr;
    Gateway: RIpAddr;
  end;

  Bits    = array [0..7] of Boolean;

function ByteToBits(const B: Byte): Bits;
function ByteToBinStr(const B: Byte): string;
function StrToIpAddr(AddrStr: string): RIpAddr;
function IntToIpAddr(const Value: Integer): RIpAddr;
function IpAddrToStr(Addr: RIpAddr): string;
function IpAddrToBinStr(Addr: RIpAddr): string;
function GetHostLength(Mask: RIpAddr): Cardinal;
function GetIpSubnet(const Net, Mask: RIpAddr; out FirstIp, LastIp: RIpAddr): Cardinal;

function IsIpAddress(const S: string): Boolean;

function GetIPAddressOnName(NetName: string): string;
function GetNameOnIPAddress(IPAddr: string): string;

function LengthToMask(const MaskLen: Byte): Cardinal;
function MaskToLength(const Mask: Cardinal): Byte;
function AddrToLength(const Addr: Cardinal): Byte;
function RoundMaskLength(const MinLen: Byte): Byte;

const
  IpDelim                   = '.';
  IpDelims                  = ['.'];
  fmtIpAddr                 = '%u.%u.%u.%u';
  WINSOCK_VERSION           = $0101;

implementation

uses
  rxStrUtilsE, SysUtils, WinSock, RDialogs;

function ByteToBits(const B: Byte): Bits;
var
  i, v: Byte;
begin
  v := B;
  for i := 7 downto 0 do
  begin
    Result[i] := (v and 1) > 0;
    v := v shr 1;
  end;
end;

function ByteToBinStr(const B: Byte): string;
var
  i, v: Byte;
begin
  v := B;
  SetLength(Result, 8);
  for i := 8 downto 1 do
  begin
    Result[i] := chr($30 + (v and 1));
    v := v shr 1;
  end;
end;

function StrToIpAddr(AddrStr: string): RIpAddr;
begin
  Result.Oktets[3] := StrToIntDef(Trim(ExtractWord(1, AddrStr, IpDelims)), 0);
  Result.Oktets[2] := StrToIntDef(Trim(ExtractWord(2, AddrStr, IpDelims)), 0);
  Result.Oktets[1] := StrToIntDef(Trim(ExtractWord(3, AddrStr, IpDelims)), 0);
  Result.Oktets[0] := StrToIntDef(Trim(ExtractWord(4, AddrStr, IpDelims)), 0);
end;

function IntToIpAddr(const Value: Integer): RIpAddr;
begin
  Result.Socket := Value;
end;

function IpAddrToStr(Addr: RIpAddr): string;
begin
  Result := Format(fmtIpAddr, [Addr.Oktets[3], Addr.Oktets[2],
                               Addr.Oktets[1], Addr.Oktets[0]]);
end;

function IpAddrToBinStr(Addr: RIpAddr): string;
begin
  Result := ByteToBinStr(Addr.Oktets[3]) + IpDelim +
            ByteToBinStr(Addr.Oktets[2]) + IpDelim +
            ByteToBinStr(Addr.Oktets[1]) + IpDelim +
            ByteToBinStr(Addr.Oktets[0]);
end;

function GetHostLength(Mask: RIpAddr): Cardinal;
var
  i, j: Byte;
  Bin: Bits;
begin
  Result := 0;
  for i := 0 to 3 do
    if Mask.Oktets[i] = 0
    then Result := Result + 8
    else begin
      Bin := ByteToBits(Mask.Oktets[i]);
      for j := 7 downto 0 do
        if Bin[j] then Break else Result := Result + 1;
      Break;
    end;
end;

function GetIpSubnet(const Net, Mask: RIpAddr; out FirstIp, LastIp: RIpAddr): Cardinal;
begin
  if (not Mask.Socket and Net.Socket) > 0 then
  begin
    Result := 0;
    FirstIp.Socket := 0;
    LastIp.Socket := 0;
  end
  else begin
    Result := not Mask.Socket - 1;
    FirstIp.Socket := (Net.Socket and Mask.Socket) + 1;
    LastIp.Socket := FirstIp.Socket + Result - 1;
  end;
end;

function IsIpAddress(const S: string): Boolean;
var
  Okt1, Okt2, Okt3, Okt4: Integer;
begin
  Result := WordCount(S, IpDelims) = 4;
  if Result then
  begin
    try
      Okt1 := StrToInt(Trim(ExtractWord(1, S, IpDelims)));
      Okt2 := StrToInt(Trim(ExtractWord(2, S, IpDelims)));
      Okt3 := StrToInt(Trim(ExtractWord(3, S, IpDelims)));
      Okt4 := StrToInt(Trim(ExtractWord(4, S, IpDelims)));
      Result := (Okt1 in [0..255]) and (Okt2 in [0..255])
            and (Okt3 in [0..255]) and (Okt4 in [0..255]);
    except
      Result := False;
    end;
  end;
end;

function GetIPAddressOnName(NetName: string): string;
var
  WSAData: TWSAData;
  HE: PHostEnt;
begin
  Result := '';
  WSAStartup(WINSOCK_VERSION, WSAData);
  try
    HE := GetHostByName(PAnsiChar(AnsiString(NetName)));
    if HE <> nil then Result := string(Inet_ntoa(PInAddr(HE.h_addr_list^)^));
  finally
    WSACleanup;
  end;
end;

function GetNameOnIPAddress(IPAddr: string): string;
var
  SockAddrIn: TSockAddrIn;
  HE: PHostEnt;
  WSAData: TWSAData;
begin
  Result := '';
  WSAStartup(WINSOCK_VERSION, WSAData);
  try
    SockAddrIn.sin_addr.s_addr:= inet_addr(PAnsiChar(AnsiString(IPAddr)));
    HE:= GetHostByAddr(@SockAddrIn.sin_addr.S_addr, 4, AF_INET);
    if HE <> nil then
    begin
      Result := string(HE^.h_name);
      { DONE : Удалять из доменного имени суффикс домена }
      if Pos('.', Result) > 0 then Result := Copy(Result, 1, Pos('.', Result) - 1);
    end;
  finally
    WSACleanup;
  end;
end;

function LengthToMask(const MaskLen: Byte): Cardinal;
var
  IntLen, i: Byte;
begin
  Result := 0;
  if MaskLen > 31 then IntLen := 31 else IntLen := MaskLen;
  for i := 1 to IntLen do
    Result := Result + (1 shl (32 - i));
end;

function MaskToLength(const Mask: Cardinal): Byte;
var
  i: Byte;
  M: Cardinal;
begin
  Result := 0;
  M := Mask;
  for i := 32 downto 1 do
  begin
    if (M and 1) > 0 then Inc(Result);
    M := M shr 1;
  end;
end;

function AddrToLength(const Addr: Cardinal): Byte;
var
  i: Byte;
  M: Cardinal;
begin
  Result := 32;
  M := Addr;
  for i := 32 downto 1 do
  begin
    if (M and 1) = 0 then Dec(Result) else Break;
    M := M shr 1;
  end;
  if Result < 8 then Result := 8;
end;

function RoundMaskLength(const MinLen: Byte): Byte;
begin
  if MinLen <= 8 then Result := 8
  else if MinLen <= 16 then Result := 16
       else if MinLen <= 24 then Result := 24 else Result := MinLen;
end;

end.

