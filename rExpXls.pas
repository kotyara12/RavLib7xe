unit rExpXls;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TmplDialogSimple, StdCtrls, Buttons, ExtCtrls, ComCtrls, Spin, Db, DbGrids,
  Grids, rGrids, Menus, ImgList, ActnList;

{ == Экспорт данных из TListView в Excel ======================================= }
function ExportListViewToExcel(LV: TListView;
  const ATitle, ASheetName, ACopyright, AComment: string;
  const Orientation: Integer; const UseIniFile: Boolean = True): Boolean;

{ == Экспорт данных из TStringGrid в Excel ======================================= }
function ExportGridToExcel(SG: TStringGrid;
  const ATitle, ASheetName, ACopyright, AComment: string;
  const Orientation: Integer; const UseIniFile: Boolean = True): Boolean; overload;
function ExportGridToExcel(SG: TROwnerDrawGrid;
  const ATitle, ASheetName, ACopyright, AComment: string;
  const Orientation: Integer; const UseIniFile: Boolean = True): Boolean; overload;

{ == TFormExpExcel ============================================================= }

type
  TFormExpExcel = class(TDialogSTemplate)
    PageControl: TPageControl;
    PageTabSheet: TTabSheet;
    FieldsTabSheet: TTabSheet;
    TitleEditLabel: TLabel;
    NotesEditLabel: TLabel;
    edTitle: TEdit;
    edNotes: TEdit;
    DateCreateCheckBox: TCheckBox;
    PageGroupBox: TGroupBox;
    OrientationComboBoxLabel: TLabel;
    FontSpinEditLabel: TLabel;
    PageEditLabel: TLabel;
    edOrientation: TComboBox;
    edFontSize: TSpinEdit;
    edPageName: TEdit;
    lblFileds: TLabel;
    lvFields: TListView;
    SaveCheckBox: TCheckBox;
    FileBtn: TBitBtn;
    ActionList: TActionList;
    ImageList: TImageList;
    FilePopupMenu: TPopupMenu;
    ListPopupMenu: TPopupMenu;
    OpenFile: TAction;
    SaveFile: TAction;
    itemOpenFile: TMenuItem;
    itemSaveFile: TMenuItem;
    MoveUpBtn: TBitBtn;
    MoveDownBtn: TBitBtn;
    RenameBtn: TBitBtn;
    MoveUp: TAction;
    MoveDown: TAction;
    Rename: TAction;
    itemMoveUp: TMenuItem;
    itemMoveDown: TMenuItem;
    divN1: TMenuItem;
    itemRename: TMenuItem;
    SendModeGroupBox: TGroupBox;
    edSendMode: TComboBox;
    edRecNum: TStaticText;
    SendModeComboBoxLabel: TLabel;
    procedure FileBtnClick(Sender: TObject);
    procedure OpenFileUpdate(Sender: TObject);
    procedure OpenFileExecute(Sender: TObject);
    procedure SaveFileUpdate(Sender: TObject);
    procedure SaveFileExecute(Sender: TObject);
    procedure MoveUpUpdate(Sender: TObject);
    procedure MoveUpExecute(Sender: TObject);
    procedure MoveDownUpdate(Sender: TObject);
    procedure MoveDownExecute(Sender: TObject);
    procedure RenameUpdate(Sender: TObject);
    procedure RenameExecute(Sender: TObject);
    procedure lvFieldsDblClick(Sender: TObject);
    procedure lvFieldsKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lvFieldsClick(Sender: TObject);
    procedure lvFieldsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure edSendModeChange(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    ItemChecked: TListItem;
  public
    FormName: string;
    DataName: string;
    TotalRows: Integer;
    SelectedRows: Integer;
    // procedure LoadList_Fields(DS: TDataSet; DG: TDbGrid);
    procedure LoadList_Columns(LV: TListView);
    procedure LoadGrid_Columns(SG: TDrawGrid);
    procedure LoadExportParameters(const FileName: string; const LoadState, LoadTitle: Boolean);
    procedure SaveExportParameters(const FileName: string; const SaveState: Boolean);
  end;

implementation

{$R *.dfm}

uses
  IniFiles, rxStrUtilsE, ExcelConst,
  rVclUtils, rExpXlsParam, rFrmStore, rMsExcel, rMsgStd, rSysUtils,
  rListView, rDialogs, rProgress;

resourcestring
  sErrLoadExportParameters  = 'Ошибка загрузки параметров экспорта из файла "%s"!';
  sErrSaveExportParameters  = 'Ошибка сохранения параметров экспорта в файле "%s"!';
  sErrLoadFieldParameters   = 'Ошибка загрузки параметров экспортируемого поля ID="%d"!';
  sErrExportExcel           = 'Ошибка экспорта данных в Microsoft Excel!'#13'%s';
  // SErrStringNotCorrected    = 'Некорректная строка параметров экспортируемого поля: "%s"';
  // SErrParamsNotFound        = 'Параметры экспорта для "%s" в файле "%s" не найдены!';
  // SErrFieldNotFound         = 'Поле "%s" (ID="%d") в списке экспортируемых полей "%s" не найдено!';

  sDlgFilter                = 'Файлы параметров экспорта (*.exp)|*.exp|Все файлы (*.*)|*.*';
  sDlgDefaultExt            = 'exp';

const
  iniSectionName            = 'EXPORT_EXCEL_%s.%s';
  iniTitle                  = 'Title';
  iniNotes                  = 'Notes';
  iniPageName               = 'SheetName';
  iniTimeCreate             = 'ShowCreateTime';
  iniOrientation            = 'PageOrientation';
  iniBaseFontSize           = 'BaseFontSize';
  iniState                  = 'RestoreParameters';
  iniItem                   = 'Item_%d';
  iniValue                  = '%d;%s;%s;%s;%d;%s';
  chDelims                  = [';'];

  PrepareSteps              = 5;
  DefaultFontSize           = 8;
  DefaultColumnWidth        = 10;
  DefaultNumberFormat       = '';           

  siAlignment               = 0;
  siWidth                   = 1;
  siFieldName               = 2;

{ == Экспорт данных из TListView в Excel ======================================= }
function ExportListViewToExcel(LV: TListView; const ATitle, ASheetName,
  ACopyright, AComment: string; const Orientation: Integer;
  const UseIniFile: Boolean = True): Boolean;
var
  Sheet, Row: Variant;
  i, iCount, j, jCount, iColNum, X, Y, BaseY, SizeX, SizeY: Integer;
  CopyRightOffcet, CommentOffcet: Integer;
begin
  Result := False;
  with TFormExpExcel.Create(Application.MainForm) do
  begin
    try
      // Подготовка формы
      StartWait;
      try
        DataName := LV.Name;
        FormName := LV.Owner.Name;
        // Заполняем поля параметров экспорта
        edTitle.Text := ATitle;
        edNotes.Text := AComment;
        edOrientation.ItemIndex := Orientation;
        edFontSize.Value := DefaultFontSize;
        edPageName.Text := ASheetName;
        SaveCheckBox.Enabled := UseIniFile;
        SaveCheckBox.Checked := UseIniFile;
        FileBtn.Visible := UseIniFile;
        // Мультиобработка: 2007-09-13
        TotalRows := LV.Items.Count;
        if LV.MultiSelect and (LV.SelCount > 1) then
        begin
          SelectedRows := LV.SelCount;
          edSendMode.ItemIndex := 1;
        end
        else begin
          SelectedRows := 1;
          edSendMode.ItemIndex := 0;
        end;
        edSendModeChange(nil);
        // Загружаем список полей
        LoadList_Columns(LV);
        // Восстанавливаем параметры экспорта из INI-файла
        if UseIniFile then
          LoadExportParameters(GetModuleIniFile, True, False);
        // Выталкиваем наверх отмеченные поля
        MoveUpCheckedItems(lvFields);
        // Выделяем верхний элемент
        if lvFields.Items.Count > 0 then lvFields.Selected := lvFields.Items[0];
      finally
        StopWait;
      end;
      // Показываем форму
      if ShowModal = mrOk then
      begin
        // Экспорт данных
        StartWait;
        try
          // Сохраняем параметры экспорта в INI-файле
          if UseIniFile then
            SaveExportParameters(GetModuleIniFile, True);
          // Считаем число записей
          SizeY := TotalRows;
          if edSendMode.ItemIndex = 1 then
            SizeY := SelectedRows;
          // Начинаем экспорт
          ShowProgress(SMsgOpenExcel, SizeY + lvFields.Items.Count * 2 + PrepareSteps);
          try
            // Подключение к Excel-ю
            if ConnectToMsExcel then
            begin
              try
                try
                  // Создаем книгу
                  UpdateProgressMessage(SMsgOpenWorkbook);
                  UpdateProgressStep(1);
                  if SetDefaultWorkbook then
                  begin
                    // Открываем книгу и создаем лист
                    UpdateProgressMessage(SMsgOpenWorksheet);
                    UpdateProgressStep(1);
                    Sheet := OpenSheetCW(1, edPageName.Text);
                    // Форматируем страницу
                    if not VarIsEmpty(Sheet) then
                    begin
                      UpdateProgressMessage(SMsgFormatPage);
                      // Устанавливаем вертикальные смещения
                      CopyRightOffcet := 0; CommentOffcet := 0;
                      if ACopyright <> EmptyStr then Inc(CopyRightOffcet, 2);
                      if Trim(edNotes.Text) <> EmptyStr then Inc(CommentOffcet, 1);
                      if DateCreateCheckBox.Checked then Inc(CommentOffcet, 1);
                      BaseY := CopyRightOffcet + CommentOffcet + 3;
                      // Установка ориентации страницы
                      if edOrientation.ItemIndex > 0
                      then SetPageOrientation(Sheet, edOrientation.ItemIndex);
                      UpdateProgressStep(1);
                      // Форматируем столбцы
                      X := 0; SizeX := 0;
                      iCount := lvFields.Items.Count - 1;
                      for i := 0 to iCount do
                      begin
                        if lvFields.Items[i].Checked then
                        begin
                          Inc(X); Inc(SizeX);
                          SetColumnParams(Sheet.Columns[X],
                            RStrToFloatDef(lvFields.Items[i].SubItems[siWidth], DefaultColumnWidth),
                            AlignmentToExcelH(TKindId(lvFields.Items[i].Data)^.Kind),
                            xlVAlignCenter, edFontSize.Value, DefaultNumberFormat);
                        end;
                        UpdateProgressStep(1);
                      end;
                      // Выводим заголовок страницы
                      if ACopyright <> EmptyStr then
                        CellText(Sheet.Cells[1, 1], ACopyright,
                          edFontSize.Value - 2, [fsItalic], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      CellText(Sheet.Cells[CopyRightOffcet + 1, 1], edTitle.Text,
                        edFontSize.Value + 4, [fsBold], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      if Trim(edNotes.Text) <> EmptyStr then
                        CellText(Sheet.Cells[CopyRightOffcet + 2, 1], edNotes.Text,
                          edFontSize.Value, [fsBold], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      if DateCreateCheckBox.Checked then
                        CellText(Sheet.Cells[CopyRightOffcet + CommentOffcet + 1, 1],
                          Format(SMsgReportDate, [DateTimeToStr(Now)]),
                          edFontSize.Value, [fsItalic], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      UpdateProgressStep(1);
                      // Выводим заголовки столбцов
                      Row := VarArrayCreate([1, 1, 1, SizeX], varVariant);
                      // Генерируем массив данных
                      X := 0;
                      iCount := lvFields.Items.Count - 1;
                      for i := 0 to iCount do
                      begin
                        if lvFields.Items[i].Checked then
                        begin
                          Inc(X);
                          Row[1, X] := lvFields.Items[i].Caption;
                        end;
                        UpdateProgressStep(1);
                      end;
                      // Передаем массив в Excel
                      RangeText(Sheet, BaseY, BaseY, 1, SizeX, Row,
                        edFontSize.Value, [], 3, xlHAlignCenter, xlVAlignCenter, True);
                      // Экспорт данных
                      UpdateProgressMessage(SMsgPrepareData);
                      Inc(BaseY);
                      // Выделяем память под диапазон
                      Row := VarArrayCreate([BaseY, BaseY + SizeY - 1, 1, SizeX], varVariant);
                      // Генерируем массив данных
                      Y := BaseY;
                      jCount := LV.Items.Count - 1;
                      for j := 0 to jCount do
                      begin
                        if (edSendMode.ItemIndex = 0)
                        or (LV.MultiSelect and LV.Items[j].Selected)
                        or (not LV.MultiSelect and (LV.Items[j] = LV.Selected)) then
                        begin
                          X := 0;
                          iCount := lvFields.Items.Count - 1;
                          for i := 0 to iCount do
                          begin
                            if lvFields.Items[i].Checked then
                            begin
                              Inc(X);

                              iColNum := TKindId(lvFields.Items[i].Data)^.Id;
                              if iColNum = 0
                              then Row[Y, X] := LV.Items[j].Caption
                              else begin
                                if iColNum <= LV.Items[j].SubItems.Count
                                then Row[Y, X] := LV.Items[j].SubItems[iColNum - 1]
                                else Row[Y, X] := '';
                              end;
                            end;
                          end;
                          Inc(Y);
                          UpdateProgressStep(1);
                        end;
                      end;
                      // Передаем массив в Excel
                      UpdateProgressMessage(SMsgTransferData);
                      RangeTextDefault(Sheet, BaseY, BaseY + SizeY - 1, 1, SizeX, Row, 2);
                      UpdateProgressStep(1);
                    end;
                  end;
                  // Возвращаем флаг успешного завершения
                  Result := True;
                finally
                  // Показываем скрытую копию Excel и отключаемся
                  ShowMsExcelAndDiconnect;
                end;
              except
                on E: Exception do
                  ErrorBox(Format(sErrExportExcel, [E.Message]));
              end;
            end;
          finally
            CloseProgress;
          end;
        finally
          StopWait;
        end;
      end;
    finally
      Free;
    end;
  end;
end;

{ == Экспорт данных из TStringGrid в Excel ======================================= }
function ExportGridToExcel(SG: TStringGrid;
  const ATitle, ASheetName, ACopyright, AComment: string;
  const Orientation: Integer; const UseIniFile: Boolean = True): Boolean;
var
  Sheet, Row: Variant;
  i, iCount, j, jCount, iColNum, X, Y, BaseY, SizeX, SizeY: Integer;
  CopyRightOffcet, CommentOffcet: Integer;
begin
  Result := False;
  with TFormExpExcel.Create(Application.MainForm) do
  begin
    try
      // Подготовка формы
      StartWait;
      try
        DataName := SG.Name;
        FormName := SG.Owner.Name;
        // Заполняем поля параметров экспорта
        edTitle.Text := ATitle;
        edNotes.Text := AComment;
        edOrientation.ItemIndex := Orientation;
        edFontSize.Value := DefaultFontSize;
        edPageName.Text := ASheetName;
        SaveCheckBox.Enabled := UseIniFile;
        SaveCheckBox.Checked := UseIniFile;
        FileBtn.Visible := UseIniFile;
        // Мультиобработка
        TotalRows := SG.RowCount - 1;
        if (SG.Selection.Bottom > SG.Selection.Top) and (SG.Selection.Top > 1) then
        begin
          SelectedRows := SG.Selection.Bottom - SG.Selection.Top + 1;
          edSendMode.ItemIndex := 1;
        end
        else begin
          SelectedRows := 1;
          edSendMode.ItemIndex := 0;
        end;
        edSendModeChange(nil);
        // Загружаем список полей
        LoadGrid_Columns(SG);
        // Восстанавливаем параметры экспорта из INI-файла
        if UseIniFile then
          LoadExportParameters(GetModuleIniFile, True, False);
        // Выталкиваем наверх отмеченные поля
        MoveUpCheckedItems(lvFields);
        // Выделяем верхний элемент
        if lvFields.Items.Count > 0 then lvFields.Selected := lvFields.Items[0];
      finally
        StopWait;
      end;
      // Показываем форму
      if ShowModal = mrOk then
      begin
        // Экспорт данных
        StartWait;
        try
          // Сохраняем параметры экспорта в INI-файле
          if UseIniFile then
            SaveExportParameters(GetModuleIniFile, True);
          // Считаем число записей
          SizeY := TotalRows;
          if edSendMode.ItemIndex = 1 then
            SizeY := SelectedRows;
          // Начинаем экспорт
          ShowProgress(SMsgOpenExcel, SizeY + lvFields.Items.Count * 2 + PrepareSteps);
          try
            // Подключение к Excel-ю
            if ConnectToMsExcel then
            begin
              try
                try
                  // Создаем книгу
                  UpdateProgressMessage(SMsgOpenWorkbook);
                  UpdateProgressStep(1);
                  if SetDefaultWorkbook then
                  begin
                    // Открываем книгу и создаем лист
                    UpdateProgressMessage(SMsgOpenWorksheet);
                    UpdateProgressStep(1);
                    Sheet := OpenSheetCW(1, edPageName.Text);
                    // Форматируем страницу
                    if not VarIsEmpty(Sheet) then
                    begin
                      UpdateProgressMessage(SMsgFormatPage);
                      // Устанавливаем вертикальные смещения
                      CopyRightOffcet := 0; CommentOffcet := 0;
                      if ACopyright <> EmptyStr then Inc(CopyRightOffcet, 2);
                      if Trim(edNotes.Text) <> EmptyStr then Inc(CommentOffcet, 1);
                      if DateCreateCheckBox.Checked then Inc(CommentOffcet, 1);
                      BaseY := CopyRightOffcet + CommentOffcet + 3;
                      // Установка ориентации страницы
                      if edOrientation.ItemIndex > 0
                      then SetPageOrientation(Sheet, edOrientation.ItemIndex);
                      UpdateProgressStep(1);
                      // Форматируем столбцы
                      X := 0; SizeX := 0;
                      iCount := lvFields.Items.Count - 1;
                      for i := 0 to iCount do
                      begin
                        if lvFields.Items[i].Checked then
                        begin
                          Inc(X); Inc(SizeX);
                          SetColumnParams(Sheet.Columns[X],
                            RStrToFloatDef(lvFields.Items[i].SubItems[siWidth], DefaultColumnWidth),
                            AlignmentToExcelH(TKindId(lvFields.Items[i].Data)^.Kind),
                            xlVAlignCenter, edFontSize.Value, DefaultNumberFormat);
                        end;
                        UpdateProgressStep(1);
                      end;
                      // Выводим заголовок страницы
                      if ACopyright <> EmptyStr then
                        CellText(Sheet.Cells[1, 1], ACopyright,
                          edFontSize.Value - 2, [fsItalic], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      CellText(Sheet.Cells[CopyRightOffcet + 1, 1], edTitle.Text,
                        edFontSize.Value + 4, [fsBold], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      if Trim(edNotes.Text) <> EmptyStr then
                        CellText(Sheet.Cells[CopyRightOffcet + 2, 1], edNotes.Text,
                          edFontSize.Value, [fsBold], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      if DateCreateCheckBox.Checked then
                        CellText(Sheet.Cells[CopyRightOffcet + CommentOffcet + 1, 1],
                          Format(SMsgReportDate, [DateTimeToStr(Now)]),
                          edFontSize.Value, [fsItalic], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      UpdateProgressStep(1);
                      // Выводим заголовки столбцов
                      Row := VarArrayCreate([1, 1, 1, SizeX], varVariant);
                      // Генерируем массив данных
                      X := 0;
                      iCount := lvFields.Items.Count - 1;
                      for i := 0 to iCount do
                      begin
                        if lvFields.Items[i].Checked then
                        begin
                          Inc(X);
                          Row[1, X] := lvFields.Items[i].Caption;
                        end;
                        UpdateProgressStep(1);
                      end;
                      // Передаем массив в Excel
                      RangeText(Sheet, BaseY, BaseY, 1, SizeX, Row,
                        edFontSize.Value, [], 3, xlHAlignCenter, xlVAlignCenter, True);
                      // Экспорт данных
                      UpdateProgressMessage(SMsgPrepareData);
                      Inc(BaseY);
                      // Выделяем память под диапазон
                      Row := VarArrayCreate([BaseY, BaseY + SizeY - 1, 1, SizeX], varVariant);
                      // Генерируем массив данных
                      Y := BaseY;
                      jCount := SG.RowCount - 1;
                      for j := 1 to jCount do
                      begin
                        if (edSendMode.ItemIndex = 0)
                        or ((j >= SG.Selection.Top) and (j <= SG.Selection.Bottom)) then
                        begin
                          X := 0;
                          iCount := lvFields.Items.Count - 1;
                          for i := 0 to iCount do
                          begin
                            if lvFields.Items[i].Checked then
                            begin
                              Inc(X);

                              iColNum := TKindId(lvFields.Items[i].Data)^.Id;
                              Row[Y, X] := SG.Cells[iColNum, j];
                            end;
                          end;
                          Inc(Y);
                          UpdateProgressStep(1);
                        end;
                      end;
                      // Передаем массив в Excel
                      UpdateProgressMessage(SMsgTransferData);
                      RangeTextDefault(Sheet, BaseY, BaseY + SizeY - 1, 1, SizeX, Row, 2);
                      UpdateProgressStep(1);
                    end;
                  end;
                  // Возвращаем флаг успешного завершения
                  Result := True;
                finally
                  // Показываем скрытую копию Excel и отключаемся
                  ShowMsExcelAndDiconnect;
                end;
              except
                on E: Exception do
                  ErrorBox(Format(sErrExportExcel, [E.Message]));
              end;
            end;
          finally
            CloseProgress;
          end;
        finally
          StopWait;
        end;
      end;
    finally
      Free;
    end;
  end;
end;

function ExportGridToExcel(SG: TROwnerDrawGrid;
  const ATitle, ASheetName, ACopyright, AComment: string;
  const Orientation: Integer; const UseIniFile: Boolean = True): Boolean;
var
  Sheet, Row: Variant;
  i, iCount, j, jCount, iColNum, X, Y, BaseY, SizeX, SizeY: Integer;
  CopyRightOffcet, CommentOffcet: Integer;
begin
  Result := False;
  with TFormExpExcel.Create(Application.MainForm) do
  begin
    try
      // Подготовка формы
      StartWait;
      try
        DataName := SG.Name;
        FormName := SG.Owner.Name;
        // Заполняем поля параметров экспорта
        edTitle.Text := ATitle;
        edNotes.Text := AComment;
        edOrientation.ItemIndex := Orientation;
        edFontSize.Value := DefaultFontSize;
        edPageName.Text := ASheetName;
        SaveCheckBox.Enabled := UseIniFile;
        SaveCheckBox.Checked := UseIniFile;
        FileBtn.Visible := UseIniFile;
        // Мультиобработка
        TotalRows := SG.RowCount - 1;
        if (SG.Selection.Bottom > SG.Selection.Top) and (SG.Selection.Top > 1) then
        begin
          SelectedRows := SG.Selection.Bottom - SG.Selection.Top + 1;
          edSendMode.ItemIndex := 1;
        end
        else begin
          SelectedRows := 1;
          edSendMode.ItemIndex := 0;
        end;
        edSendModeChange(nil);
        // Загружаем список полей
        LoadGrid_Columns(SG);
        // Восстанавливаем параметры экспорта из INI-файла
        if UseIniFile then
          LoadExportParameters(GetModuleIniFile, True, False);
        // Выталкиваем наверх отмеченные поля
        MoveUpCheckedItems(lvFields);
        // Выделяем верхний элемент
        if lvFields.Items.Count > 0 then lvFields.Selected := lvFields.Items[0];
      finally
        StopWait;
      end;
      // Показываем форму
      if ShowModal = mrOk then
      begin
        // Экспорт данных
        StartWait;
        try
          // Сохраняем параметры экспорта в INI-файле
          if UseIniFile then
            SaveExportParameters(GetModuleIniFile, True);
          // Считаем число записей
          SizeY := TotalRows;
          if edSendMode.ItemIndex = 1 then
            SizeY := SelectedRows;
          // Начинаем экспорт
          ShowProgress(SMsgOpenExcel, SizeY + lvFields.Items.Count * 2 + PrepareSteps);
          try
            // Подключение к Excel-ю
            if ConnectToMsExcel then
            begin
              try
                try
                  // Создаем книгу
                  UpdateProgressMessage(SMsgOpenWorkbook);
                  UpdateProgressStep(1);
                  if SetDefaultWorkbook then
                  begin
                    // Открываем книгу и создаем лист
                    UpdateProgressMessage(SMsgOpenWorksheet);
                    UpdateProgressStep(1);
                    Sheet := OpenSheetCW(1, edPageName.Text);
                    // Форматируем страницу
                    if not VarIsEmpty(Sheet) then
                    begin
                      UpdateProgressMessage(SMsgFormatPage);
                      // Устанавливаем вертикальные смещения
                      CopyRightOffcet := 0; CommentOffcet := 0;
                      if ACopyright <> EmptyStr then Inc(CopyRightOffcet, 2);
                      if Trim(edNotes.Text) <> EmptyStr then Inc(CommentOffcet, 1);
                      if DateCreateCheckBox.Checked then Inc(CommentOffcet, 1);
                      BaseY := CopyRightOffcet + CommentOffcet + 3;
                      // Установка ориентации страницы
                      if edOrientation.ItemIndex > 0
                      then SetPageOrientation(Sheet, edOrientation.ItemIndex);
                      UpdateProgressStep(1);
                      // Форматируем столбцы
                      X := 0; SizeX := 0;
                      iCount := lvFields.Items.Count - 1;
                      for i := 0 to iCount do
                      begin
                        if lvFields.Items[i].Checked then
                        begin
                          Inc(X); Inc(SizeX);
                          SetColumnParams(Sheet.Columns[X],
                            RStrToFloatDef(lvFields.Items[i].SubItems[siWidth], DefaultColumnWidth),
                            AlignmentToExcelH(TKindId(lvFields.Items[i].Data)^.Kind),
                            xlVAlignCenter, edFontSize.Value, DefaultNumberFormat);
                        end;
                        UpdateProgressStep(1);
                      end;
                      // Выводим заголовок страницы
                      if ACopyright <> EmptyStr then
                        CellText(Sheet.Cells[1, 1], ACopyright,
                          edFontSize.Value - 2, [fsItalic], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      CellText(Sheet.Cells[CopyRightOffcet + 1, 1], edTitle.Text,
                        edFontSize.Value + 4, [fsBold], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      if Trim(edNotes.Text) <> EmptyStr then
                        CellText(Sheet.Cells[CopyRightOffcet + 2, 1], edNotes.Text,
                          edFontSize.Value, [fsBold], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      if DateCreateCheckBox.Checked then
                        CellText(Sheet.Cells[CopyRightOffcet + CommentOffcet + 1, 1],
                          Format(SMsgReportDate, [DateTimeToStr(Now)]),
                          edFontSize.Value, [fsItalic], intDisable, xlHAlignLeft, xlVAlignCenter, False, EmptyStr);
                      UpdateProgressStep(1);
                      // Выводим заголовки столбцов
                      Row := VarArrayCreate([1, 1, 1, SizeX], varVariant);
                      // Генерируем массив данных
                      X := 0;
                      iCount := lvFields.Items.Count - 1;
                      for i := 0 to iCount do
                      begin
                        if lvFields.Items[i].Checked then
                        begin
                          Inc(X);
                          Row[1, X] := lvFields.Items[i].Caption;
                        end;
                        UpdateProgressStep(1);
                      end;
                      // Передаем массив в Excel
                      RangeText(Sheet, BaseY, BaseY, 1, SizeX, Row,
                        edFontSize.Value, [], 3, xlHAlignCenter, xlVAlignCenter, True);
                      // Экспорт данных
                      UpdateProgressMessage(SMsgPrepareData);
                      Inc(BaseY);
                      // Выделяем память под диапазон
                      Row := VarArrayCreate([BaseY, BaseY + SizeY - 1, 1, SizeX], varVariant);
                      // Генерируем массив данных
                      Y := BaseY;
                      jCount := SG.RowCount - 1;
                      for j := 1 to jCount do
                      begin
                        if (edSendMode.ItemIndex = 0)
                        or ((j >= SG.Selection.Top) and (j <= SG.Selection.Bottom)) then
                        begin
                          X := 0;
                          iCount := lvFields.Items.Count - 1;
                          for i := 0 to iCount do
                          begin
                            if lvFields.Items[i].Checked then
                            begin
                              Inc(X);

                              iColNum := TKindId(lvFields.Items[i].Data)^.Id;
                              Row[Y, X] := SG.Cells[iColNum, j];
                            end;
                          end;
                          Inc(Y);
                          UpdateProgressStep(1);
                        end;
                      end;
                      // Передаем массив в Excel
                      UpdateProgressMessage(SMsgTransferData);
                      RangeTextDefault(Sheet, BaseY, BaseY + SizeY - 1, 1, SizeX, Row, 2);
                      UpdateProgressStep(1);
                    end;
                  end;
                  // Возвращаем флаг успешного завершения
                  Result := True;
                finally
                  // Показываем скрытую копию Excel и отключаемся
                  ShowMsExcelAndDiconnect;
                end;
              except
                on E: Exception do
                  ErrorBox(Format(sErrExportExcel, [E.Message]));
              end;
            end;
          finally
            CloseProgress;
          end;
        finally
          StopWait;
        end;
      end;
    finally
      Free;
    end;
  end;
end;

{ == Процедуры диалогового окна ================================================ }

procedure TFormExpExcel.FormCreate(Sender: TObject);
begin
  inherited;

  reg_LoadListColumns(Self, lvFields, True);

  PageControlChange(nil);
end;

procedure TFormExpExcel.FormDestroy(Sender: TObject);
begin
  reg_SaveListColumns(Self, lvFields, True);

  inherited;
end;

procedure TFormExpExcel.PageControlChange(Sender: TObject);
begin
  if Visible then
  begin
    case PageControl.ActivePageIndex of
      0: edTitle.SetFocus;
      1: lvFields.SetFocus;
    end;
  end;
end;

procedure TFormExpExcel.FileBtnClick(Sender: TObject);
var
  CursorPos: TPoint;
begin
  CursorPos.X := FileBtn.Left;
  CursorPos.Y := FileBtn.Top + FileBtn.Height;
  CursorPos := ButtonsMovedPanel.ClientToScreen(CursorPos);
  FilePopupMenu.Popup(CursorPos.X, CursorPos.Y);
end;

(*
// Загрузка списка полей набора данных -----------------------------------------
procedure TFormExpExcel.LoadList_Fields(DS: TDataSet; DG: TDbGrid);
var
  i, iCount: Integer;
  Id: TKindId;
begin
  lvFields.Items.BeginUpdate;
  try
    lvFields.Items.Clear;
    // Загружаем список полей TDbGrid
    if Assigned(DG) then
    begin
      iCount := DG.Columns.Count - 1;
      for i := 0 to iCount do
        with lvFields.Items.Add do
        begin
          Caption := DG.Columns[i].Title.Caption;
          Checked := True;
          Subitems.Add(SAlignments[DG.Columns[i].Alignment]);
          Subitems.Add(FloatToStrF(DG.Columns[i].Width / WidthColumnToExcel, ffFixed, 10, 2));
          Subitems.Add(DG.Columns[i].Field.FieldName);
          New(Id);
          Id^.Id := DG.Columns[i].Field.Index;
          Id^.Kind := Integer(DG.Columns[i].Alignment);
          Data := Id;
        end;
    end;
    // Загружаем оставшиеся поля
    iCount := DS.FieldCount - 1;
    for i := 0 to iCount do
      if LV_FindKindId(lvFields, DS.Fields[i].Index) = nil then
        with lvFields.Items.Add do
        begin
          Caption := DS.Fields[i].DisplayName;
          Checked := DS.Fields[i].Visible and not Assigned(DG);
          Subitems.Add(SAlignments[DS.Fields[i].Alignment]);
          Subitems.Add(FloatToStrF(DS.Fields[i].DisplayWidth / WidthFieldToExcel, ffFixed, 10, 2));
          Subitems.Add(DS.Fields[i].FieldName);
          New(Id);
          Id^.Id := DS.Fields[i].Index;
          Id^.Kind := Integer(DS.Fields[i].Alignment);
          Data := Id;
        end;
  finally
    lvFields.Items.EndUpdate;
  end;
end;
*)

// Загрузка списка столбцов TlvFields ------------------------------------------
procedure TFormExpExcel.LoadList_Columns(LV: TListView);
var
  i, iCount: Integer;
  Id: TKindId;
begin
  lvFields.Items.BeginUpdate;
  try
    lvFields.Items.Clear;
    iCount := LV.Columns.Count - 1;
    for i := 0 to iCount do
      with lvFields.Items.Add do
      begin
        Caption := LV.Columns[i].Caption;
        Checked := True;
        Subitems.Add(GetNameAlignments(LV.Columns[i].Alignment));
        Subitems.Add(FloatToStrF(LV.Columns[i].Width / WidthColumnToExcel, ffFixed, 10, 2));
        Subitems.Add(LV.Columns[i].Caption);
        New(Id);
        Id^.Id := i;
        Id^.Kind := Integer(LV.Columns[i].Alignment);
        Data := Id;
      end;
  finally
    lvFields.Items.EndUpdate;
  end;
end;

procedure TFormExpExcel.LoadGrid_Columns(SG: TDrawGrid);
var
  i, iCount: Integer;
  Id: TKindId;
begin
  lvFields.Items.BeginUpdate;
  try
    lvFields.Items.Clear;
    iCount := SG.ColCount - 1;
    for i := 0 to iCount do
      with lvFields.Items.Add do
      begin
        if SG is TStringGrid then Caption := TStringGrid(SG).Cells[i, 0];
        if SG is TROwnerDrawGrid then Caption := TROwnerDrawGrid(SG).Cells[i, 0];
        Checked := True;
        Subitems.Add(GetNameAlignments(taLeftJustify));
        Subitems.Add(FloatToStrF(SG.ColWidths[i] / WidthColumnToExcel, ffFixed, 10, 2));
        if SG is TStringGrid then Subitems.Add(TStringGrid(SG).Cells[i, 0]);
        if SG is TROwnerDrawGrid then Subitems.Add(TROwnerDrawGrid(SG).Cells[i, 0]);
        New(Id);
        Id^.Id := i;
        Id^.Kind := Integer(taLeftJustify);
        Data := Id;
      end;
  finally
    lvFields.Items.EndUpdate;
  end;
end;

// Открыть файл ----------------------------------------------------------------
procedure TFormExpExcel.LoadExportParameters(const FileName: string; const LoadState, LoadTitle: Boolean);
var
  Ini: TMemIniFile;
  Item: TListItem;
  SectionName, ItemStr, FieldName: string;
  i, iCount, FieldId: Integer;
begin
  StartWait;
  try
    try
      SectionName := Format(iniSectionName, [AnsiUpperCase(FormName), AnsiUpperCase(DataName)]);
      Ini := TMemIniFile.Create(FileName);
      try
        if Ini.SectionExists(SectionName) then
        begin
          if LoadState
          then SaveCheckBox.Checked := Ini.ReadBool(SectionName, iniState, SaveCheckBox.Checked);
          if not LoadState or SaveCheckBox.Checked then
          begin
            // Считываем параметры листа
            if LoadTitle or (Trim(edTitle.Text) = EmptyStr)
            then edTitle.Text := Ini.ReadString(SectionName, iniTitle, edTitle.Text);
            if Trim(edNotes.Text) = EmptyStr
            then edNotes.Text := Ini.ReadString(SectionName, iniNotes, edNotes.Text);
            DateCreateCheckBox.Checked := Ini.ReadBool(SectionName, iniTimeCreate, DateCreateCheckBox.Checked);
            edPageName.Text := Ini.ReadString(SectionName, iniPageName, edPageName.Text);
            edOrientation.ItemIndex := Ini.ReadInteger(SectionName, iniOrientation, edOrientation.ItemIndex);
            edFontSize.Value := Ini.ReadInteger(SectionName, iniBaseFontSize, edFontSize.Value);
            // Считываем столбцы
            iCount := lvFields.Items.Count - 1;
            for i := 0 to iCount do
            begin
              ItemStr := Ini.ReadString(SectionName, Format(iniItem, [i]), EmptyStr);
              try
                if ItemStr <> EmptyStr then
                begin
                  if WordCount(ItemStr, chDelims) = 6 then
                  begin
                    FieldId := StrToIntDef(Trim(ExtractWord(1, ItemStr, chDelims)), intDisable);
                    FieldName := Trim(ExtractWord(2, ItemStr, chDelims));
                    Item := LV_FindKindId(lvFields, FieldId);
                    if Assigned(Item) and SameText(Item.SubItems[siFieldName], FieldName) then
                    begin
                      if Item.Index <> i then Item := MoveItemTo(lvFields, Item, i);
                      Item.Caption := ExtractWord(3, ItemStr, chDelims);
                      Item.Checked := StrToBoolDef(Trim(ExtractWord(4, ItemStr, chDelims)), Item.Checked);
                      TKindId(Item.Data)^.Kind := StrToIntDef(Trim(ExtractWord(5, ItemStr, chDelims)), TKindId(Item.Data)^.Kind);
                      Item.SubItems[siAlignment] := rsAlignments[TAlignment(TKindId(Item.Data)^.Kind)];
                      Item.SubItems[siWidth] := Trim(ExtractWord(6, ItemStr, chDelims));
                    end
                    else begin
                      Ini.DeleteKey(SectionName, Format(iniItem, [i]));
                      // raise Exception.CreateFmt(SErrFieldNotFound, [FieldName, FieldId, SectionName]);
                    end
                  end
                  else begin
                    Ini.DeleteKey(SectionName, Format(iniItem, [i]));
                    // raise Exception.CreateFmt(SErrStringNotCorrected, [ItemStr]);
                  end;
                end;
              except
                on E: Exception do
                  ErrorBox(Format(SErrLoadFieldParameters, [i]));
              end;
            end;
          end;
        end;
        // else if not LoadState then raise Exception.CreateFmt(SErrParamsNotFound, [DataName, FileName]);
      finally
        Ini.Free;
      end;
    except
      on E: Exception do
        ErrorBox(Format(SErrLoadExportParameters, [FileName]));
    end;
  finally
    StopWait;
  end;
end;

procedure TFormExpExcel.OpenFileUpdate(Sender: TObject);
begin
  OpenFile.Enabled := IsNotWait and SaveCheckBox.Enabled;
end;

procedure TFormExpExcel.OpenFileExecute(Sender: TObject);
var
  Dialog: TOpenDialog;
begin
  Dialog := TOpenDialog.Create(Self);
  try
    Dialog.Filter := SDlgFilter;
    Dialog.DefaultExt := SDlgDefaultExt;
    Dialog.Options := [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing];
    Dialog.InitialDir := ExtractFilePath(GetApplicationFileName);
    if Dialog.Execute then LoadExportParameters(Dialog.FileName, False, True);
  finally
    Dialog.Free;
  end;
end;

// Сохранить в файле -----------------------------------------------------------
procedure TFormExpExcel.SaveExportParameters(const FileName: string; const SaveState: Boolean);
var
  Ini: TMemIniFile;
  SectionName: string;
  i, iCount: Integer;
begin
  StartWait;
  try
    try
      SectionName := Format(iniSectionName, [AnsiUpperCase(FormName), AnsiUpperCase(DataName)]);
      Ini := TMemIniFile.Create(FileName);
      try
        // Удаляем секцию
        Ini.EraseSection(SectionName);
        // Сохраняем параметры листа
        if SaveState then Ini.WriteBool(SectionName, iniState, SaveCheckBox.Checked);
        Ini.WriteString(SectionName, iniTitle, edTitle.Text);
        Ini.WriteString(SectionName, iniNotes, edNotes.Text);
        Ini.WriteBool(SectionName, iniTimeCreate, DateCreateCheckBox.Checked);
        Ini.WriteString(SectionName, iniPageName, edPageName.Text);
        Ini.WriteInteger(SectionName, iniOrientation, edOrientation.ItemIndex);
        Ini.WriteInteger(SectionName, iniBaseFontSize, edFontSize.Value);
        // Сохраняем поля
        iCount := lvFields.Items.Count - 1;
        for i := 0 to iCount do
          Ini.WriteString(SectionName,
            Format(iniItem, [i]),
            Format(iniValue,
              [TKindId(lvFields.Items[i].Data)^.Id,
               Trim(lvFields.Items[i].SubItems[siFieldName]),
               lvFields.Items[i].Caption,
               BoolToStr(lvFields.Items[i].Checked),
               TKindId(lvFields.Items[i].Data)^.Kind,
               lvFields.Items[i].SubItems[siWidth]]));
      finally
        Ini.UpdateFile;
        Ini.Free;
      end;
    except
      on E: Exception do
        ErrorBox(Format(SErrSaveExportParameters, [FileName]));
    end;
  finally
    StopWait;
  end;
end;

procedure TFormExpExcel.SaveFileUpdate(Sender: TObject);
begin
  SaveFile.Enabled := IsNotWait and SaveCheckBox.Enabled;
end;

procedure TFormExpExcel.SaveFileExecute(Sender: TObject);
var
  Dialog: TSaveDialog;
begin
  Dialog := TSaveDialog.Create(Self);
  try
    Dialog.Filter := SDlgFilter;
    Dialog.DefaultExt := SDlgDefaultExt;
    Dialog.Options := [ofHideReadOnly, ofPathMustExist, ofCreatePrompt, ofShareAware, ofEnableSizing];
    Dialog.InitialDir := ExtractFilePath(Application.ExeName);
    if Dialog.Execute then SaveExportParameters(Dialog.FileName, False);
  finally
    Dialog.Free;
  end;
end;

// Вверх -----------------------------------------------------------------------
procedure TFormExpExcel.MoveUpUpdate(Sender: TObject);
begin
  MoveUp.Enabled := IsNotWait and Assigned(lvFields.Selected)
    and (lvFields.Selected.Index > 0);
end;

procedure TFormExpExcel.MoveUpExecute(Sender: TObject);
begin
  StartWait;
  try
    MoveSelectedItemUp(lvFields);
    MoveUpCheckedItems(lvFields);
    lvFields.SetFocus;
  finally
    StopWait;
  end;
end;

// Вниз ------------------------------------------------------------------------
procedure TFormExpExcel.MoveDownUpdate(Sender: TObject);
begin
  MoveDown.Enabled := IsNotWait and Assigned(lvFields.Selected)
    and (lvFields.Selected.Index < lvFields.Items.Count - 1);
end;

procedure TFormExpExcel.MoveDownExecute(Sender: TObject);
begin
  StartWait;
  try
    MoveSelectedItemDown(lvFields);
    MoveUpCheckedItems(lvFields);
    lvFields.SetFocus;
  finally
    StopWait;
  end;
end;

procedure TFormExpExcel.lvFieldsMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Item: TListItem;
  HitTest: THitTests;
begin
  Item := lvFields.GetItemAt(x, y);
  HitTest := lvFields.GetHitTestInfoAt(x, y);
  if Assigned(Item) and (htOnStateIcon in HitTest)
  then ItemChecked := Item
  else ItemChecked := nil;
end;

procedure TFormExpExcel.lvFieldsClick(Sender: TObject);
begin
  if Assigned(ItemChecked) then
  begin
    StartWait;
    try
      lvFields.Selected := ItemChecked;
      MoveUpCheckedItems(lvFields);
      ScrollToSelectedItem(lvFields);
      ItemChecked := nil;
    finally
      StopWait;
    end;
  end;
end;

procedure TFormExpExcel.lvFieldsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 32 then
  begin
    StartWait;
    try
      MoveUpCheckedItems(lvFields);
      ScrollToSelectedItem(lvFields);
    finally
      StopWait;
    end;
  end;
end;

// Свойства --------------------------------------------------------------------
procedure TFormExpExcel.RenameUpdate(Sender: TObject);
begin
  Rename.Enabled := IsNotWait and Assigned(lvFields.Selected);
end;

procedure TFormExpExcel.RenameExecute(Sender: TObject);
begin
  with TFormExpExcelParam.Create(Self) do
  begin
    try
      StartWait;
      try
        edAlign.Items.BeginUpdate;
        try
          edAlign.Items.Clear;
          edAlign.Items.Add(rsAlignmentLeft);
          edAlign.Items.Add(rsAlignmentRight);
          edAlign.Items.Add(rsAlignmentCenter);
        finally
          edAlign.Items.EndUpdate;
        end;
        edCaption.Text := lvFields.Selected.Caption;
        edAlign.ItemIndex := TKindId(lvFields.Selected.Data)^.Kind;
        edWidth.Value := RStrToFloatDef(lvFields.Selected.SubItems[siWidth], DefaultColumnWidth);
      finally
        StopWait;
      end;
      if ShowModal = mrOk then
      begin
        StartWait;
        try
          lvFields.Selected.Caption := edCaption.Text;
          TKindId(lvFields.Selected.Data)^.Kind := edAlign.ItemIndex;
          lvFields.Selected.SubItems[siAlignment] := edAlign.Text;
          lvFields.Selected.SubItems[siWidth] := FloatToStrF(edWidth.Value, ffFixed, 10, 2)
        finally
          StopWait;
        end;
      end;
    finally
      Free;
    end;
  end;
end;

procedure TFormExpExcel.lvFieldsDblClick(Sender: TObject);
begin
  if Rename.Enabled then RenameExecute(Sender);
end;

procedure TFormExpExcel.edSendModeChange(Sender: TObject);
begin
  case edSendMode.ItemIndex of
    0: edRecNum.Caption := IntToStr(TotalRows);
    1: edRecNum.Caption := IntToStr(SelectedRows);
  end;
end;

end.
