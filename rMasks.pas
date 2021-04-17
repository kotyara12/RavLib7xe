unit rMasks;

interface

uses System.SysUtils;

type
  EMaskException = class(Exception);

  TMask = class
  private type
    TMaskSet = array of WideChar;
    PMaskSet = ^TMaskSet;
    TMaskStates = (msLiteral, msAny, msSet);
    TMaskState = record
      SkipTo: Boolean;
      case State: TMaskStates of
        msLiteral: (Literal: WideChar);
        msAny: ();
        msSet: (
          Negate: Boolean;
          CharSet: PMaskSet);
    end;

  private
    FMaskStates: array of TMaskState;

  protected
    function CharInSet(const Char: WideChar; const List: TMaskSet): Boolean;
    procedure CharAdd(const Char: WideChar; var List: TMaskSet);
    function InitMaskStates(const Mask: string): Integer;
    procedure DoneMaskStates;
    function MatchesMaskStates(const Filename: string): Boolean;

  public
    constructor Create(const MaskValue: string);
    destructor Destroy; override;
    function Matches(const Filename: string): Boolean;
  end;


function MatchesMask(const Filename, Mask: string): Boolean;

implementation

uses System.RTLConsts, Dialogs;

const
  MaxCards = 255;

function TMask.CharInSet(const Char: WideChar; const List: TMaskSet): Boolean;
var
  i: Integer;
begin
  Result := False;
  if Length(List) > 0 then
  begin
    for i := Low(List) to High(List) do
    begin
      if List[i] = Char then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

procedure TMask.CharAdd(const Char: WideChar; var List: TMaskSet);
begin
  if not CharInSet(Char, List) then
  begin
    SetLength(List, Length(List) + 1);
    List[High(List)] := Char;
  end;
end;

function TMask.InitMaskStates(const Mask: string): Integer;
var
  I: Integer;
  SkipTo: Boolean;
  Literal: WideChar;
  P: PWideChar;
  Negate: Boolean;
  CharSet: TMaskSet;
  Cards: Integer;

  procedure InvalidMask;
  begin
    raise EMaskException.CreateResFmt(@SInvalidMask, [Mask,
      P - PWideChar(Mask) + 1]);
  end;

  procedure Reset;
  begin
    SkipTo := False;
    Negate := False;
    CharSet := [];
  end;

  procedure WriteScan(MaskState: TMaskStates);
  begin
    if I <= High(FMaskStates) then
    begin
      if SkipTo then
      begin
        Inc(Cards);
        if Cards > MaxCards then InvalidMask;
      end;
      FMaskStates[I].SkipTo := SkipTo;
      FMaskStates[I].State := MaskState;
      case MaskState of
        msLiteral: FMaskStates[I].Literal := Literal;
        msSet:
          begin
            FMaskStates[I].Negate := Negate;
            New(FMaskStates[I].CharSet);
            SetLength(FMaskStates[I].CharSet^, 0);
            FMaskStates[I].CharSet^ := CharSet;
          end;
      end;
    end;
    Inc(I);
    Reset;
  end;

  procedure ScanSet;
  var
    LastChar: WideChar;
    C: WideChar;
  begin
    Inc(P);
    if P^ = '!' then
    begin
      Negate := True;
      Inc(P);
    end;
    LastChar := #0;
    while not CharInSet(P^, [#0, ']']) do
    begin
      case P^ of
        '-':
          if LastChar = #0 then InvalidMask
          else
          begin
            Inc(P);
            for C := LastChar to P^ do
              CharAdd(C, CharSet);
          end;
      else
        LastChar := P^;
        CharAdd(LastChar, CharSet);
      end;
      Inc(P);
    end;
    if (P^ <> ']') or (Length(CharSet) = 0) then InvalidMask;
    WriteScan(msSet);
  end;

begin
  P := PWideChar(Mask);
  I := 0;
  Cards := 0;
  Reset;
  while P^ <> #0 do
  begin
    case P^ of
      '*': SkipTo := True;
      '?': if not SkipTo then WriteScan(msAny);
      '[': ScanSet;
    else
      Literal := P^;
      WriteScan(msLiteral);
    end;
    Inc(P);
  end;
  Literal := #0;
  WriteScan(msLiteral);
  Result := I;
end;

function TMask.MatchesMaskStates(const Filename: string): Boolean;
type
  TStackRec = record
    sP: PWideChar;
    sI: Integer;
  end;
var
  T: Integer;
  S: array of TStackRec;
  I: Integer;
  P: PWideChar;

  procedure Push(P: PWideChar; I: Integer);
  begin
    S[T].sP := P;
    S[T].sI := I;
    Inc(T);
  end;

  function Pop(var P: PWideChar; var I: Integer): Boolean;
  begin
    if T = 0 then
      Result := False
    else
    begin
      Dec(T);
      P := S[T].sP;
      I := S[T].sI;
      Result := True;
    end;
  end;

  function Matches(P: PWideChar; Start: Integer): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := Start to High(FMaskStates) do
    begin
      if FMaskStates[I].SkipTo then
      begin
        case FMaskStates[I].State of
          msLiteral:
            while (P^ <> #0) and (P^ <> FMaskStates[I].Literal) do Inc(P);
          msSet:
            while (P^ <> #0) and not (FMaskStates[I].Negate xor CharInSet(P^, FMaskStates[I].CharSet^)) do Inc(P);
        end;
        if P^ <> #0 then
          Push(@P, I);
      end;
      case FMaskStates[I].State of
        msLiteral: if P^ <> FMaskStates[I].Literal then Exit;
        msSet: if not (FMaskStates[I].Negate xor CharInSet(P^, FMaskStates[I].CharSet^)) then Exit;
        msAny:
          if P^ = #0 then
          begin
            Result := False;
            Exit;
          end;
      end;
      Inc(P);
    end;
    Result := True;
  end;

begin
  SetLength(S, MaxCards);
  Result := True;
  T := 0;
  P := PWideChar(Filename);
  I := Low(FMaskStates);
  repeat
    if Matches(P, I) then Exit;
  until not Pop(P, I);
  Result := False;
end;

procedure TMask.DoneMaskStates;
var
  I: Integer;
begin
  for I := Low(FMaskStates) to High(FMaskStates) do
    if FMaskStates[I].State = msSet then
    begin
      SetLength(FMaskStates[I].CharSet^, 0);
      Dispose(FMaskStates[I].CharSet);
    end;
end;

constructor TMask.Create(const MaskValue: string);
var
  Size: Integer;
begin
  SetLength(FMaskStates, 1);
  Size := InitMaskStates(MaskValue);
  DoneMaskStates;

  SetLength(FMaskStates, Size);
  InitMaskStates(MaskValue);
end;

destructor TMask.Destroy;
begin
  DoneMaskStates;
  SetLength(FMaskStates, 0);
end;

function TMask.Matches(const Filename: string): Boolean;
begin
  Result := MatchesMaskStates(Filename);
end;

function MatchesMask(const Filename, Mask: string): Boolean;
var
  CMask: TMask;
begin
  CMask := TMask.Create(UpperCase(Mask, loUserLocale));
  try
    Result := CMask.Matches(UpperCase(Filename, loUserLocale));
  finally
    CMask.Free;
  end;
end;

end.
