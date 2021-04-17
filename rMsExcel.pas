unit RMsExcel;

interface

uses
  Classes, Graphics, rVclUtils;
  
{ == Получение OLE - имени MsExcel ============================================= }
function  GetMsExcelOleName: string;
{ == Открываем MsExcel через OLE =============================================== }
function  ConnectToMsExcel: Boolean;
{ == Показать скрытый Excel ==================================================== }
procedure ShowMsExcel;
{ == Показать скрытый Excel и отключить связь ================================== }
procedure ShowMsExcelAndDiconnect;
{ == Закрыть копию Excel и отключить связь ===================================== }
procedure CloseMsExcelAndDiconnect;
{ == Создать новую книгу ======================================================= }
function  AddWorkbook: Variant;
{ == Создать новую книгу по умолчанию ========================================== }
function  SetDefaultWorkbook: Boolean;
{ == Открыть книгу из файла ==================================================== }
function  OpenWorkbook(const FileName: string): Variant;
{ == Сохранить книгу в файле =================================================== }
procedure SaveWorkbook(Wb: Variant; const FileName: string);
{ == Сохранить книгу по умолчанию в файле ====================================== }
procedure SaveDefaultWorkbook(const FileName: string);
{ == Форматирование имени листа ================================================ }
function  CorrectSheetName(const AStr: string): string;
{ == Создать лист ============================================================== }
function  AddSheet(Wb: Variant; const ACaption: string): Variant;
{ == Открыть или создать лист ================================================== }
function  OpenSheet(Wb: Variant; const ANumber: Integer; const ACaption: string): Variant;
{ == Открыть или создать лист по умолчанию ===================================== }
function  OpenSheetCW(const ANumber: Integer; const ACaption: string): Variant;
{ == Открыть существующий лист по имени ======================================== }
function  OpenSheetOnName(Wb: Variant; const AName: string): Variant;
{ == Установка ориентации страницы ============================================= }
procedure SetPageOrientation(Sheet: Variant; const AValue: Integer; const HideError: Boolean = False);
{ == Преобразование констант выравнивания ====================================== }
function  AlignmentToExcelH(DelphiAlignment: Integer): Integer; overload;
function  AlignmentToExcelH(DelphiAlignment: TAlignment): Integer; overload;
{ == Преобразование буквенной нумерации столбцов в цифровую ==================== }
function ColumnStrToNumber(const sCol: string): Integer;
{ == Установка тонких границ вокруг ячейки ===================================== }
procedure SetSingleBorders(Range: Variant; const AWeight: Integer);
procedure SetCustomBorders(Range: Variant; const AType, AWeight: Integer);
procedure SetOutsideBorders(Range: Variant; const AWeight: Integer);
procedure SetInsideBorders(Range: Variant; const AWeight: Integer);
procedure SetTotalBorders(Range: Variant; const AWeight: Integer);
{ == Установка параметров столбца ============================================== }
procedure SetColumnParams(Column: Variant; const Width: Real;
  const HAlignment, VAlignment, FontSize: Integer; const NumberFormat: string);
{ == Объединить ячейки ========================================================= }
procedure RangeMerge(Sheet: Variant; const RowStart, RowEnd, ColStart, ColEnd: Integer;
  const Value: Variant; const FontSize: Integer; const FontStyle: TFontStyles;
  const BordersWeight: Integer; const HAlignment, VAlignment: Integer;
  const WordWrap: Boolean);
{ == Вывод текста в ячейку ===================================================== }
procedure CellTextDefault(Cell: Variant; const Text: string; const BordersWeight: Integer);
procedure CellText(Cell: Variant; const Text: string;
  const FontSize: Integer; const FontStyle: TFontStyles;
  const BordersWeight: Integer; const HAlignment, VAlignment: Integer;
  const WordWrap: Boolean; const Format: string);

procedure CellValueDefault(Cell: Variant; const Value: Variant; const BordersWeight: Integer);
procedure CellValue(Cell: Variant; const Value: Variant;
  const FontSize: Integer; const FontStyle: TFontStyles;
  const BordersWeight: Integer; const HAlignment, VAlignment: Integer;
  const WordWrap: Boolean; const Format: string);

procedure CellFormulaDefault(Cell: Variant; const Formula: string; const BordersWeight: Integer);
procedure CellFormula(Cell: Variant; const Formula: string;
  const FontSize: Integer; const FontStyle: TFontStyles;
  const BordersWeight: Integer; const HAlignment, VAlignment: Integer;
  const WordWrap: Boolean; const Format: string);

procedure RangeTextDefault(Sheet: Variant; const RowStart, RowEnd, ColStart, ColEnd: Integer;
  const Values: Variant; const BordersWeight: Integer);
procedure RangeText(Sheet: Variant; const RowStart, RowEnd, ColStart, ColEnd: Integer;
  const Values: Variant; const FontSize: Integer; const FontStyle: TFontStyles;
  const BordersWeight: Integer; const HAlignment, VAlignment: Integer; const WordWrap: Boolean);

{ == Выборка данных ============================================================ }
function GetCellFloat(Sheet: Variant; const iRow, iCol: Integer): Double;

resourcestring
  SMsgExportExcel           = 'Экспорт в Excel';
  SMsgOpenExcel             = 'Вызов Microsoft Excel...';
  SMsgOpenWorkbook          = 'Создание рабочей книги...';
  SMsgOpenWorksheet         = 'Создание листа...';
  SMsgFormatPage            = 'Форматирование листа...';
  SMsgPrepareData           = 'Подготовка данных для экспорта...';
  SMsgTransferData          = 'Передача данных в Microsoft Excel...';
  SMsgReportDate            = 'Отчет построен: %s.';
  SMsgExportComplete        = 'Экспорт данных в Microsoft Excel завершен!';

  SWrnSizeExport            = 'Предупреждение! Выгружены будут только первые %d записей!';

  SErrExportExcel           = 'Ошибка экспорта данных в Microsoft Excel!';
  SErrIncorrectNumber       = 'Некорректный номер столбца: %s!';

const
  MaxSheetNameLen           = 31;
  MaxRowCount               = High(Word);
  WidthGridToExcel          = 8;
  WidthFieldToExcel         = 1.3;
  WidthColumnToExcel        = 8;

var
  MsExcel, Workbook: Variant;

implementation

uses
  Registry, Windows, Variants, ComObj, SysUtils,
  rxStrUtilsE, ExcelConst, RDialogs;

const
  ExcelOleNameDefault       = 'Excel.Application';
  ExcelOleNameRegistryKey   = '\Excel.Application\CurVer';

resourcestring
  SErrConnectMsExcel        = 'Ошибка подключения к Microsoft Excel!';
  SErrCreateWorkbook        = 'Ошибка создания книги Microsoft Excel!';
  SErrOpenWorkbook          = 'Ошибка чтения книги из файла "%s"!';
  SErrSaveWorkbook          = 'Ошибка сохранения книги в файле "%s"!';
  SErrCreateSheet           = 'Ошибка создания листа Microsoft Excel!';
  SErrOpenSheet             = 'Ошибка открытия (создания) листа #%d!';
  SErrOpenSheetName         = 'Ошибка открытия листа "%s"!';
  SErrSetPageOrientation    = 'Ошибка установки ориентации страницы Microsoft Excel!';
  SErrWorkbookNull          = 'Рабочая книга Microsoft Excel не создана или не активна';
  SErrSheetNotFound         = 'Лист "%s" не найден!';

{ == Получение OLE - имени MsExcel ============================================= }
function GetMsExcelOleName: string;
var
  RegData: TRegistry;
begin
  Result := ExcelOleNameDefault;
  RegData := TRegistry.Create;
  RegData.RootKey := HKEY_CLASSES_ROOT;
  try
    if RegData.OpenKey(ExcelOleNameRegistryKey, False)
    then
      begin
        Result := RegData.ReadString('');
        RegData.CloseKey;
      end;
  finally
    RegData.Free;
  end;
end;

{ == Открываем MsExcel через OLE =============================================== }
function ConnectToMsExcel: Boolean;
begin
  try
    if not VarIsEmpty(MsExcel) then ShowMsExcelAndDiconnect;
    try
      MsExcel := CreateOleObject(GetMsExcelOleName);
      if not VarIsEmpty(MsExcel) then MsExcel.Application.EnableEvents := False;
    except
      on E: Exception do
        ErrorBox(SErrConnectMsExcel + #13#13 + E.Message);
    end;
  finally
    Result := not VarIsEmpty(MsExcel);
  end;
end;

{ == Показать скрытый Excel ==================================================== }
procedure ShowMsExcel;
begin
  if not VarIsEmpty(MsExcel) then
  begin
    MsExcel.Application.EnableEvents := True;
    MsExcel.Visible := True;
    // MsExcel.BringToFront;
  end;
end;

{ == Показать скрытый Excel и отключить связь ================================== }
procedure ShowMsExcelAndDiconnect;
begin
  ShowMsExcel;
  VarClear(Workbook);
  VarClear(MsExcel);
end;

{ == Закрыть копию Excel и отключить связь ===================================== }
procedure CloseMsExcelAndDiconnect;
begin
  if not VarIsEmpty(MsExcel) then
    MsExcel.Quit;
  VarClear(Workbook);
  VarClear(MsExcel);
end;

{ == Создать новую книгу ======================================================= }
function AddWorkbook: Variant;
begin
  VarClear(Result);
  if not VarIsEmpty(MsExcel) or ConnectToMsExcel
  then begin
    try
      Result := MsExcel.Workbooks.Add;
    except
      on E: Exception do
      begin
        VarClear(Result);
        ErrorBox(SErrCreateWorkbook + #13#13 + E.Message);
      end;
    end;
  end;
end;

{ == Создать новую книгу по умолчанию ========================================== }
function SetDefaultWorkbook: Boolean;
begin
  try
    Workbook := AddWorkbook;
  finally
    Result := not VarIsEmpty(Workbook);
  end;
end;

{ == Открыть книгу из файла ==================================================== }
function OpenWorkbook(const FileName: string): Variant;
begin
  VarClear(Result);
  if not VarIsEmpty(MsExcel) or ConnectToMsExcel
  then begin
    try
      Result := MsExcel.Workbooks.Open(Filename := FileName);
    except
      on E: Exception do
      begin
        VarClear(Result);
        ErrorBox(Format(SErrOpenWorkbook, [FileName]) + #13#13 + E.Message);
      end;
    end;
  end;
end;

{ == Сохранить книгу в файле =================================================== }
procedure SaveWorkbook(Wb: Variant; const FileName: string);
begin
  try
    if FileExists(FileName) then
      DeleteFile(FileName);
      
    Wb.SaveAs(Filename := FileName);
  except
    on E: Exception do
      ErrorBox(Format(SErrSaveWorkbook, [FileName]) + #13#13 + E.Message);
  end;
end;

{ == Сохранить книгу по умолчанию в файле ====================================== }
procedure SaveDefaultWorkbook(const FileName: string);
begin
  SaveWorkbook(Workbook, FileName);
end;

{ == Форматирование имени листа ================================================ }
function CorrectSheetName(const AStr: string): string;
begin
  Result := DelChars(AStr, '"');
  Result := DelChars(Result, '''');
  Result := DelChars(Result, '*');
  Result := ReplaceStr(Result, '/', '-');
  Result := ReplaceStr(Result, '\', '-');
  Result := ReplaceStr(Result, '[', '(');
  Result := ReplaceStr(Result, ']', ')');
  Result := DelChars(Result, '?');
  Result := DelChars(Result, ':');
  Result := Trim(Copy(Result, 1, MaxSheetNameLen));
end;

{ == Создать лист ============================================================== }
function AddSheet(Wb: Variant; const ACaption: string): Variant;
begin
  VarClear(Result);
  try
    if not VarIsEmpty(Wb) then
    begin
      if Wb.Sheets.Count = 0 then
        Result := Wb.Sheets.Add
      else
        Result := Wb.Sheets.Add(After := Wb.Sheets[Wb.Sheets.Count]);
      if not VarIsEmpty(Result) and (ACaption <> EmptyStr)
      then Result.Name := CorrectSheetName(ACaption);
    end
    else raise Exception.Create(SErrWorkbookNull);
  except
    on E: Exception do
    begin
      VarClear(Result);
      ErrorBox(SErrCreateSheet + #13#13 + E.Message);
    end;
  end;
end;

{ == Открыть существующий лист по имени ======================================== }
function OpenSheetOnName(Wb: Variant; const AName: string): Variant;
var
  i: Integer;
begin
  VarClear(Result);
  try
    if not VarIsEmpty(Wb) then
    begin
      for i := 1 to Wb.Sheets.Count do
      if SameText(Wb.Sheets[i].Name, AName) then
      begin
        Result := Wb.Sheets[i];
        Break;
      end;
      if VarIsEmpty(Wb) then
        raise Exception.CreateFmt(SErrSheetNotFound, [AName]);
    end
    else raise Exception.Create(SErrWorkbookNull);
  except
    on E: Exception do
    begin
      VarClear(Result);
      ErrorBox(Format(SErrOpenSheetName, [AName]) + #13#13 + E.Message);
    end;
  end;
end;

{ == Открыть или создать лист ================================================== }
function OpenSheet(Wb: Variant; const ANumber: Integer; const ACaption: string): Variant;
begin
  VarClear(Result);
  try
    if not VarIsEmpty(Wb) then
    begin
      try
        Result := Wb.Sheets[ANumber];
        if not VarIsEmpty(Result) and (ACaption <> EmptyStr)
        then Result.Name := CorrectSheetName(ACaption);
      except
        Result := AddSheet(Wb, ACaption);
      end;
    end
    else raise Exception.Create(SErrWorkbookNull);
  except
    on E: Exception do
    begin
      VarClear(Result);
      ErrorBox(Format(SErrOpenSheet, [ANumber]) + #13#13 + E.Message);
    end;
  end;
end;

{ == Открыть или создать лист по умолчанию ===================================== }
function OpenSheetCW(const ANumber: Integer; const ACaption: string): Variant;
begin
  Result := OpenSheet(Workbook, ANumber, ACaption);
end;

{ == Установка ориентации страницы ============================================= }
procedure SetPageOrientation(Sheet: Variant; const AValue: Integer; const HideError: Boolean = False);
begin
  try
    Sheet.PageSetup.Orientation := AValue;
  except
    on E: Exception do
      ErrorBox(SErrSetPageOrientation + #13#13 + E.Message);
  end;
end;

{ == Преобразование констант выравнивания ====================================== }
function AlignmentToExcelH(DelphiAlignment: Integer): Integer;
begin
  case DelphiAlignment of
    Integer(taRightJustify): Result := xlHAlignRight;
    Integer(taCenter): Result := xlHAlignCenter;
    else Result := xlHAlignLeft;
  end;
end;

function AlignmentToExcelH(DelphiAlignment: TAlignment): Integer;
begin
  case DelphiAlignment of
    taRightJustify: Result := xlHAlignRight;
    taCenter: Result := xlHAlignCenter;
    else Result := xlHAlignLeft;
  end;
end;

{ == Преобразование буквенной нумерации столбцов в цифровую ==================== }
function ColumnStrToNumber(const sCol: string): Integer;
var
  i, iLen: Integer;
  cCurr: Char;
begin
  Result := 0;
  iLen := Length(sCol);
  for i := 1 to iLen do
  begin
    cCurr := UpperCase(sCol)[i];
    if not CharInSet(cCurr, ['A'..'Z']) then
      raise Exception.CreateFmt(SErrIncorrectNumber, [sCol]);
    Result := Result * (Ord('Z') - Ord('A') + 1) + (Ord(cCurr) - Ord('A') + 1);
  end;
end;

{ == Установка параметров столбца ============================================== }
procedure SetColumnParams(Column: Variant; const Width: Real;
  const HAlignment, VAlignment, FontSize: Integer; const NumberFormat: string);
begin
  if Width < High(Byte)
  then Column.ColumnWidth := Width
  else Column.ColumnWidth := High(Byte);
  Column.Font.Size := FontSize;
  Column.HorizontalAlignment := HAlignment;
  Column.VerticalAlignment := VAlignment;
  Column.NumberFormat := NumberFormat;
end;

{ == Установка тонких границ вокруг ячейки ===================================== }
procedure SetSingleBorders(Range: Variant; const AWeight: Integer);
begin
  Range.Borders.LineStyle := xlLinearTrend;
  Range.Borders.Weight := AWeight;
  Range.Borders.ColorIndex := xlColorIndexAutomatic;
end;

procedure SetCustomBorders(Range: Variant; const AType, AWeight: Integer);
begin
  Range.Borders[AType].LineStyle := xlContinuous;
  Range.Borders[AType].Weight := AWeight;
  Range.Borders[AType].ColorIndex := xlColorIndexAutomatic;
end;

procedure SetOutsideBorders(Range: Variant; const AWeight: Integer);
begin
  SetCustomBorders(Range, xlEdgeTop, AWeight);
  SetCustomBorders(Range, xlEdgeLeft, AWeight);
  SetCustomBorders(Range, xlEdgeRight, AWeight);
  SetCustomBorders(Range, xlEdgeBottom, AWeight);
end;

procedure SetInsideBorders(Range: Variant; const AWeight: Integer);
begin
  SetCustomBorders(Range, xlInsideHorizontal, AWeight);
  SetCustomBorders(Range, xlInsideVertical, AWeight);
end;

procedure SetTotalBorders(Range: Variant; const AWeight: Integer);
begin
  SetOutsideBorders(Range, AWeight);
  SetInsideBorders(Range, AWeight);
end;

{ == Вывод текста в ячейку ===================================================== }
procedure CellText(Cell: Variant; const Text: string;
  const FontSize: Integer; const FontStyle: TFontStyles;
  const BordersWeight: Integer; const HAlignment, VAlignment: Integer;
  const WordWrap: Boolean; const Format: string);
begin
  Cell.Value := Text;
  Cell.Font.Size := FontSize;
  Cell.Font.Bold := fsBold in FontStyle;
  Cell.Font.Italic := fsItalic in FontStyle;
  Cell.Font.Underline := fsUnderline in FontStyle;
  Cell.Font.Strikethrough := fsStrikeOut in FontStyle;
  if BordersWeight > 0 then SetSingleBorders(Cell, BordersWeight);
  Cell.HorizontalAlignment := HAlignment;
  Cell.VerticalAlignment := VAlignment;
  Cell.WrapText := WordWrap;
  if Format <> EmptyStr then
    Cell.NumberFormat := Format;
end;

procedure CellValue(Cell: Variant; const Value: Variant;
  const FontSize: Integer; const FontStyle: TFontStyles;
  const BordersWeight: Integer; const HAlignment, VAlignment: Integer;
  const WordWrap: Boolean; const Format: string);
begin
  Cell.Value := Value;
  Cell.Font.Size := FontSize;
  Cell.Font.Bold := fsBold in FontStyle;
  Cell.Font.Italic := fsItalic in FontStyle;
  Cell.Font.Underline := fsUnderline in FontStyle;
  Cell.Font.Strikethrough := fsStrikeOut in FontStyle;
  if BordersWeight > 0 then SetSingleBorders(Cell, BordersWeight);
  Cell.HorizontalAlignment := HAlignment;
  Cell.VerticalAlignment := VAlignment;
  Cell.WrapText := WordWrap;
  if Format <> EmptyStr then
    Cell.NumberFormat := Format;
end;

procedure CellFormula(Cell: Variant; const Formula: string;
  const FontSize: Integer; const FontStyle: TFontStyles;
  const BordersWeight: Integer; const HAlignment, VAlignment: Integer;
  const WordWrap: Boolean; const Format: string);
begin
  Cell.Formula := Formula;
  Cell.Font.Size := FontSize;
  Cell.Font.Bold := fsBold in FontStyle;
  Cell.Font.Italic := fsItalic in FontStyle;
  Cell.Font.Underline := fsUnderline in FontStyle;
  Cell.Font.Strikethrough := fsStrikeOut in FontStyle;
  if BordersWeight > 0 then SetSingleBorders(Cell, BordersWeight);
  Cell.HorizontalAlignment := HAlignment;
  Cell.VerticalAlignment := VAlignment;
  Cell.WrapText := WordWrap;
  if Format <> EmptyStr then
    Cell.NumberFormat := Format;
end;

procedure CellTextDefault(Cell: Variant; const Text: string; const BordersWeight: Integer);
begin
  Cell.Value := Text;
  if BordersWeight > intDisable then SetSingleBorders(Cell, BordersWeight);
end;

procedure CellValueDefault(Cell: Variant; const Value: Variant; const BordersWeight: Integer);
begin
  Cell.Value := Value;
  if BordersWeight > intDisable then SetSingleBorders(Cell, BordersWeight);
end;

procedure CellFormulaDefault(Cell: Variant; const Formula: string; const BordersWeight: Integer);
begin
  Cell.Value := Formula;
  if BordersWeight > intDisable then SetSingleBorders(Cell, BordersWeight);
end;

procedure RangeMerge(Sheet: Variant; const RowStart, RowEnd, ColStart, ColEnd: Integer;
  const Value: Variant; const FontSize: Integer; const FontStyle: TFontStyles;
  const BordersWeight: Integer; const HAlignment, VAlignment: Integer;
  const WordWrap: Boolean);
begin
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Merge;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Value := Value;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Font.Size := FontSize;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Font.Bold := fsBold in FontStyle;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Font.Italic := fsItalic in FontStyle;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Font.Underline := fsUnderline in FontStyle;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Font.Strikethrough := fsStrikeOut in FontStyle;
  if BordersWeight > 0 then
    SetSingleBorders(Sheet.Range[Sheet.Cells[RowStart, ColStart],
      Sheet.Cells[RowEnd, ColEnd]], BordersWeight);
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].HorizontalAlignment := HAlignment;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].VerticalAlignment := VAlignment;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].WrapText := WordWrap;
end;

procedure RangeText(Sheet: Variant; const RowStart, RowEnd, ColStart, ColEnd: Integer;
  const Values: Variant; const FontSize: Integer; const FontStyle: TFontStyles;
  const BordersWeight: Integer; const HAlignment, VAlignment: Integer; const WordWrap: Boolean);
begin
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Value := Values;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Font.Size := FontSize;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Font.Bold := fsBold in FontStyle;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Font.Italic := fsItalic in FontStyle;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Font.Underline := fsUnderline in FontStyle;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Font.Strikethrough := fsStrikeOut in FontStyle;
  if BordersWeight > 0 then
    SetSingleBorders(Sheet.Range[Sheet.Cells[RowStart, ColStart],
      Sheet.Cells[RowEnd, ColEnd]], BordersWeight);
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].HorizontalAlignment := HAlignment;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].VerticalAlignment := VAlignment;
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].WrapText := WordWrap;
end;

procedure RangeTextDefault(Sheet: Variant; const RowStart, RowEnd, ColStart, ColEnd: Integer;
  const Values: Variant; const BordersWeight: Integer);
begin
  Sheet.Range[Sheet.Cells[RowStart, ColStart], Sheet.Cells[RowEnd, ColEnd]].Value := Values;
  if BordersWeight > 0 then
    SetSingleBorders(Sheet.Range[Sheet.Cells[RowStart, ColStart],
      Sheet.Cells[RowEnd, ColEnd]], BordersWeight);
end;

{ == Выборка данных ============================================================ }
function GetCellFloat(Sheet: Variant; const iRow, iCol: Integer): Double;
begin
  Result := 0;

  try
    if not VarIsEmpty(Sheet)
    and not VarIsEmpty(Sheet.Cells[iRow, iCol])
    and not VarIsNull(Sheet.Cells[iRow, iCol]) then
    begin
      Result := Sheet.Cells[iRow, iCol];
    end;
  except
    Result := 0;
  end;
end;

begin
  // Инициализация переменных
  VarClear(MsExcel);
  VarClear(Workbook);
end.
