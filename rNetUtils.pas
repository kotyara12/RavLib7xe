unit RNetUtils;

interface

function GetAdapterMacAddress(const Lana: AnsiChar; out AdapterType: AnsiChar): string;
function GetMacAddresses(const AdType: Integer; const Divider: string): string;
function GetMacAddress: string;

implementation

uses
  SysUtils, RDialogs, Nb30;

function GetAdapterMacAddress(const Lana: AnsiChar; out AdapterType: AnsiChar): string;
var
  Adapter: TAdapterStatus;
  NCB: TNCB;
begin
  Result := EmptyStr;
  FillChar(NCB, SizeOf(NCB), 0);
  NCB.ncb_command := Char(NCBRESET);
  NCB.ncb_lana_num := Lana;
  if Netbios(@NCB) = Char(NRC_GOODRET) then
  begin
    FillChar(NCB, SizeOf(NCB), 0);
    NCB.ncb_command := Char(NCBASTAT);
    NCB.ncb_lana_num := Lana;
    NCB.ncb_callname := '*';
    FillChar(Adapter, SizeOf(Adapter), 0);
    NCB.ncb_buffer := @Adapter;
    NCB.ncb_length := SizeOf(Adapter);
    if Netbios(@NCB) = Char(NRC_GOODRET) then
    begin
      AdapterType := Adapter.adapter_type;
      Result := AnsiLowerCase(Format('%.2x%.2x%.2x%.2x%.2x%.2x',
        [Byte(Adapter.adapter_address[0]),
         Byte(Adapter.adapter_address[1]),
         Byte(Adapter.adapter_address[2]),
         Byte(Adapter.adapter_address[3]),
         Byte(Adapter.adapter_address[4]),
         Byte(Adapter.adapter_address[5])]));
    end;
  end;
end;

function GetMacAddresses(const AdType: Integer; const Divider: string): string;
var
  AdapterList: TLanaEnum;
  NCB: TNCB;
  i: Byte;
  ResAdType: AnsiChar;
  MacAddr: string;
begin
  Result := EmptyStr;
  FillChar(NCB, SizeOf(NCB), 0);
  NCB.ncb_command := Char(NCBENUM);
  NCB.ncb_buffer := @AdapterList;
  NCB.ncb_length := SizeOf(AdapterList);
  Netbios(@NCB);
  for i := 0 to Byte(AdapterList.length) - 1 do
  begin
    MacAddr := GetAdapterMacAddress(AdapterList.Lana[i], ResAdType);
    if (MacAddr <> EmptyStr) and (Pos(MacAddr, Result) = 0)
    and ((Byte(ResAdType) = Byte(AdType)) or (AdType < 0))then
    begin
      if Result = EmptyStr
      then Result := MacAddr
      else Result := Result + Divider + MacAddr;
    end;
  end;
end;

function GetMacAddress: string;
begin
  Result := GetMacAddresses(0, '; ');
end;

end.
