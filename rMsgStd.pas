unit rMsgStd;

interface

uses
  Classes;

resourcestring
  rsMsgInitApplication    = 'Инициализация приложения...';
  rsMsgInitDataForm       = 'Инициализация окна данных...';
  rsMsgDoneApplication    = 'Завершение работы приложения...';
  rsMsgConnDatabase       = 'Установка соединения с базой данных...';
  rsMsgReconnDatabase     = 'Восстановление соединения с базой данных...';
  rsMsgCloseDatabase      = 'Завершение соединения с базой данных...';
  rsMsgConfigureConnect   = 'Не настроены параметры подключения к базе данных!'#13'Выберите меню ''Файл'' - ''Настройка соединения с БД'' и установите параметры подключения.';
  rsMsgDbChangeNextTime   = 'Параметры соединения будут изменены при следующей загрузке программы!';
  rsMsgSetStyles          = 'Установка темы оформления...';
  rsMsgChangeStyles       = 'Настройка темы оформления...';
  rsMsgCheckDbVersion     = 'Проверка версии базы данных...';
  rsMsgUpdateCreate       = 'Создание новой базы данных...';
  rsMsgUpdateDatabase     = 'Обновление базы данных...';
  rsMsgUpdateDbStep       = 'Обновление базы данных #%d...';
  rsMsgSaveDbVersion      = 'Обновление версии базы данных...';
  rsMsgLoadSystemParams   = 'Загрузка параметров системы...';
  rsMsgLoadData           = 'Загрузка данных...';
  rsMsgLoadDataWait       = 'Загрузка данных. Подождите пожалуйста...';
  rsMsgLoadDataServer     = 'Загрузка данных с сервера...';
  rsMsgLoadDataFile       = 'Загрузка данных из файла...';
  rsMsgLoadDataFormEx     = 'Загрузка параметров %s...';
  rsMsgScanDirectory      = 'Сканирование каталога...';
  rsMsgSaveData           = 'Сохранение данных...';
  rsMsgSaveDataWait       = 'Сохранение данных. Подождите пожалуйста...';
  rsMsgSaveDataServer     = 'Сохранение данных на сервере...';
  rsMsgSaveDataFile       = 'Сохранение данных в файле...';
  rsMsgSaveDataForm       = 'Сохранение параметров окна...';
  rsMsgSaveDataFormEx     = 'Сохранение параметров %s...';
  rsMsgPrintingWait       = 'Идет печать...';
  rsMsgImportDataWait     = 'Импорт данных. Подождите пожалуйста...';
  rsMsgExportDataWait     = 'Экcпорт данных. Подождите пожалуйста...';
  rsMsgDeleteDataWait     = 'Удаление данных. Подождите пожалуйста...';
  rsMsgCancelChanges      = 'Отмена внесенных изменений...';
  rsMsgWorkingWait        = 'Подождите пожалуйста...';
  rsMsgWait               = 'Подождите пожалуйста...';
  rsMsgGetSelection       = 'Позиционирование...';
  rsMsgSetSelection       = 'Подождите пожалуйста...';
  rsMsgFindData           = 'Поиск данных...';
  rsMsgFindFiles          = 'Поиск файлов...';
  rsMsgReplaceData        = 'Замена данных...';
  rsMsgSortData           = 'Сортировка данных...';
  rsMsgCreateNewRecord    = 'Создание новой записи...';
  rsMsgGenerateReport     = 'Генерация отчета...';
  rsMsgGeneratePage       = 'Генерация страницы %d из %d...';
  rsMsgGenerateSheet      = 'Генерация листа "%s"...';
  rsMsgPrepareOperation   = 'Подготовка операции...';
  rsMsgOperationComplete  = 'Операция выполнена успешно!';
  rsMsgRepaceCount        = 'Всего произведено %d замен!';
  rsMsgRefreshData        = 'Обновление данных...';
  rsMsgCloneSubData       = 'Копирование вложенных данных...';

  rsPrmFind               = 'поиска';
  rsPrmFilter             = 'фильтра';
  rsPrmOrder              = 'сортировки';
  rsPrmGridTuner          = 'таблицы';

  rsTextFilterSelected    = 'По выделению';    

  rsWrnNotEnoughRights    = 'Недостаточно прав для выполнения операции!';

  rsQueryCloseProgram     = 'Завершить работу с программой?';
  rsQueryBreakOperation   = 'Прервать текущую операцию?';
  rsQueryResetColumns     = 'Удалить пользовательские настройки столбцов таблицы?';
  rsQueryVisibleFields    = 'Вывести содержимое всех стролбцов таблицы, включая невидимые?';
  rsQueryCreateNewDoc     = 'Создать новый документ?';
  rsQuerySaveChanges      = 'Изменения не сохранены! Сохранить внесенные изменения?';
  rsQueryDescardChanges   = 'Все внесенные изменения будут потеряны! Продолжить?';
  rsQuerySetDefault       = 'Вы действительно хотите установить значения "по умолчанию"?';
  rsQueryCloseConnect     = 'Для выполнения запрошенной операции необходимо закрыть все окна и соединение с базой данных. Продолжить?';
  rsQueryReconnect        = 'Выполнить переподключение к базе данных с новыми параметрами?';

  rsSelectDirectory       = 'Выберите каталог';
  rsSelectFile            = 'Выберите файл';

  rsDataSetNil            = 'Набор данных не найден';
  rsDataSetInactive	 = 'Набор данных закрыт';    // Dataset is closed, so its data is unavailable.
  rsDataSetBrowse	 = 'Просмотр';               // Data can be viewed, but not changed. This is the default state of an open dataset.
  rsDataSetEdit	         = 'Редактирование';         // Active record can be modified.
  rsDataSetInsert	 = 'Новая запись';           // The active record is a newly inserted buffer that has not been posted. This record can be modified and then either posted or discarded.
  rsDataSetSetKey	 = 'Фильтр...';              // TTable and TClientDataSet only. Record searching is enabled, or a SetRange operation is under way. A restricted set of data can be viewed, and no data can be edited or inserted.
  rsDataSetCalcFields	 = 'Генерация значений...';  // An OnCalcFields event is in progress. Noncalculated fields cannot be edited, and new records cannot be inserted.
  rsDataSetFilter	 = 'Фильтр...';              // An OnFilterRecord event is in progress. A restricted set of data can be viewed. No data can edited or inserted.
  rsDataSetNewValue	 = 'Редактирование...';      // Temporary state used internally when a field component’s NewValue property is accessed.
  rsDataSetOldValue	 = 'Редактирование...';      // Temporary state used internally when a field component’s OldValue property is accessed.
  rsDataSetCurValue	 = 'Редактирование...';      // Temporary state used internally when a field component’s CurValue property is accessed.
  rsDataSetBlockRead	 = 'Чтение данных...';       // Data-aware controls are not updated and events are not triggered when moving to the next record.
  rsDataSetInternalCalc	 = 'Генерация значений...';  // Temporary state used internally when values need to be calculated for a field that has a FieldKind of fkInternalCalc.
  rsDataSetOpening	 = 'Загрузка данных...';     // DataSet is in the process of opening but has not finished. This state occurs when the dataset is opened for asynchronous fetching.

  rsFieldRequired         = 'Поле ''%s'' должно быть заполнено!';
  rsFieldRefEmpty         = 'Для поля ''%s'' не настроен справочник значений!';
  rsFieldNotListed        = 'Поле ''%s'' не подключено к списку значений!';

  rsSortTreeNone          = 'Элементы не упорядочены';
  rsSortTreeId            = 'Элементы упорядочены по идентификатору записи';
  rsSortTreeTypeId        = 'Элементы упорядочены по типу и идентификатору';
  rsSortTreeName          = 'Элементы упорядочены по наименованию записи';
  rsSortTreeTypeName      = 'Элементы упорядочены по типу и наименованию';

  rsLogDbVersionWarning   = '%s: не совпадают версии базы данных (DB ver: %d) и программного обеспечения (DB ver: %d)!';
  rsLogDbVersionUpdate    = '%s: выполненено обновление базы данных, предназначенное для DB ver: %d из файла "%s".';
  rsLogDbVersionSaveNum   = '%s: изменена версия базы данных (DB ver: %d).';

  rsDbVersionFilter       = 'Файл сценария обновления #%0:d|%1:s';
  rsDbVersionSelFile      = 'Укажите файл сценария обновления';
  rsDbVersionScrNotFound  = 'Не найден файл сценария обновления "%s"!';
  rsDbVersionSqlText      = '> %s';
  rsDbVersionSqlOk        = 'OK'#13#10;
  rsDbVersionSqlError     = '#ERROR#: %s';

  rsDbVersionChkError     = 'Не удалось проверить соответствие версии базы данных!';
  rsDbVersionQryError     = 'Продолжить выполнение сценария обновления?';

  rsDbVersionWrnNewer     = 'Номер версии базы данных (DB ver: %d) выше версии ПО (DB ver: %d)!'#13#13 +
                           'Необходимо выполнить обновление программного обеспечения.'#13#13 +
                           'Вы хотите продолжить работу с данной версией программного обеспечения?';
  rsDbVersionWrnOlder     = 'Номер версии базы данных (DB ver: %d) ниже версии ПО (DB ver: %d)!'#13#13 +
                           'Необходимо выполнить обновление базы данных.'#13#13 +
                           'Вы хотите продолжить работу с данной версией программного обеспечения?';
  rsDbVersionQryCreate    = 'Версия базы данных не идентифицирована.'#13#13 +
                           'Выполнить сценарий создания новой базы данных?';
  rsDbVersionQryUpdate    = 'Номер версии базы данных (DB ver: %d) ниже версии ПО (DB ver: %d)!'#13#13 +
                           'Выполнить обновление базы данных сейчас?';
  rsDbVersionWrnCancel    = 'Не удалось выполнить обновление базы данных!'#13#13 +
                           'Вы хотите продолжить работу с данной версией программного обеспечения?';

  rsDbVersionQryResque    = 'Создать резервную копию базы данных перед выполнением обновления (рекомендуется)?';
  rsDbVersionWrnResque    = 'Перед началом обновления настоятельно рекомендуется создать резервную копии текущей версии базы данных (средствами СУБД)!'#13 +
                           'Выполнить обновление базы данных сейчас?';


  rsErrAssertError        = 'Внутренняя ошибка!!! Обратитесь к разработчику!';
  rsErrLoadLibrary        = 'Ошибка загрузки динамической библиотеки ''%s''!';
  rsErrLoadLibraryEx      = 'Ошибка загрузки динамической библиотеки ''%s'':'#13'%s!';
  rsErrFindProcedure      = 'Процедура ''%s'' не найдена в динамической библиотеке ''%s''!';
  rsErrWindowsError       = 'Системная ошибка!';
  rsErrWindowsCode        = 'Код ошибки: %d!';
  rsErrSystemError        = 'Ошибка #%d: "%s"!';
  rsErrBadConnectionType  = 'Класс соединения с базой данных ''%s'' не соответствует классу набора данных ''%s''!';
  rsErrDataSetNull        = 'Объект данных не указан или не инициализирован (''null'')!';
  rsErrInitForm           = 'Ошибка инициализации окна!';
  rsErrDoneForm           = 'Ошибка выполнения заключительных операций окна!';
  rsErrLoadFormPlacement  = 'Ошибка загрузки и восстановления параметров окна!';
  rsErrSaveFormPlacement  = 'Ошибка сохранения параметров окна!';
  rsErrChangeStyle        = 'Ошибка изменения стилей приложения!';
  rsErrBadOperationTag    = 'Некорректный тэг операции: %d.';
  rsErrSetStyles          = 'Ошибка установки темы оформления!';
  rsDataModuleNotCreated  = 'Модуль соединения с базой данных не инициализирован!';
  rsErrNotDbConnect       = 'Соединение с базой данных не установлено!';
  rsErrBadDbCfgFile       = 'Файл конфигурации подключения к базе данных "%s" не найден!'#13'Выполните настройки подключения к базе данных черем меню "Файл" - "Настройка соединения с БД".';
  rsErrConnDatabase       = 'Ошибка соединения с базой данных!';
  rsErrReconnDatabase     = 'Не удалось восстановить подключение к базе данных за отведенное время!'#13'Программа будет закрыта.';
  rsErrConfDatabase       = 'Ошибка изменения конфигурации базы данных!';
  rsErrCopyDatabase       = 'Ошибка создания резервной копии базы данных!';
  rsErrRestDatabase       = 'Ошибка восстановления базы данных из резервной копии!';
  rsErrBackupDisabled     = 'Резервное копирование базы данных не настроено!';
  rsErrCheckDbVersion     = 'Ошибка проверки версии базы данных!';
  rsErrReadDbVersion      = 'Ошибка чтения версии базы данных!';
  rsErrSaveDbVersion      = 'Ошибка сохранения версии базы данных!';
  rsErrUpdateDatabase     = 'Ошибка обновления базы данных!';
  rsErrLoadSystemParams   = 'Ошибка загрузки параметров системы из базы данных!';
  rsErrOpenDataSet        = 'Ошибка загрузки данных из базы данных: объект ''%s''!';
  rsErrRefreshDataSet     = 'Ошибка обновления таблицы из базы данных: объект ''%s''!';
  rsErrPostError          = 'Ошибка сохранения изменений в базе данных: объект ''%s''!';
  rsErrDeleteError        = 'Ошибка удаления записи в базе данных: объект ''%s''!'#13'Возможно эта ошибка возникла из-за того, что в других таблицах существуют записи, ссылающиеся на данную запись.';
  rsErrGetRecordCount     = 'Ошибка определения количества записей в таблице ''%s''!';
  rsErrLoadData           = 'Ошибка загрузки данных!';
  rsErrLoadTree           = 'Ошибка загрузки структуры данных!';
  rsErrReloadTree         = 'Ошибка перезагрузки вложенной структуры для выделенного элменета!';
  rsErrRecordInsert       = 'Ошибка добавления записи!';
  rsErrRecordImport       = 'Ошибка импорта записи!';
  rsErrRecordEdit         = 'Ошибка редактирования записи!';
  rsErrRecordDelete       = 'Ошибка удаления записи!';
  rsErrRecordMultiprocess = 'Ошибка мультиобработки!';
  rsErrFindError          = 'Ошибка применения фильтра для условия ''%s''!';
  rsErrTreeDSNil          = 'Не определен набор данных для загрузки иерарихческой структуры!';
  rsErrNoSelectedItem     = 'Не выбран объект для выполнения операции!';
  rsErrDataSetIsEmpty     = 'Нет данных для выполнения операции!';
  rsErrIdNotFound         = 'Объект с id=%d в структуре данных не найден!';
  rsErrIdNotFoundS        = 'Объект с id="%s" в структуре данных не найден!';
  rsErrDSIdNotFound       = 'Запись с id=%d в наборе данных "%s" не найдена!';
  rsErrDSNameNotFound     = 'Запись "%s" в наборе данных "%s" не найдена!';
  rsErrDSFieldNotFound    = 'Поле "%s" в наборе данных "%s" не найдено!';
  rsErrStrNotFound        = 'Строка "%s" не найдена!';
  rsErrFileNotFound       = 'Файл "%s" не найден!';
  rsErrDirNotFound        = 'Каталог "%s" не найден!';
  rsErrPathNotFound       = 'Путь "%s" не найден!';
  rsErrFileDelete         = 'Ошибка удаления файла "%s": %s!';
  rsErrCreateRecReport    = 'Ошибка генерация отчета для текущей записи!';
  rsErrCreateReport       = 'Ошибка генерация отчета!';
  rsErrCreatePage         = 'Ошибка создания страницы "%s"!';
  rsErrMoveRecord         = 'Ошибка перемещения записи в выбранную группу / папку!';
  rsErrInitDataModule     = 'Ошибка инициализации модуля %s!';
  rsErrLoadFile           = 'Ошибка загрузки файла: "%s"!';
  rsErrSaveFile           = 'Ошибка записи в файл: "%s"!';
  rsErrImportFile         = 'Ошибка загрузки данных из файла: "%s"!';
  rsErrExportFile         = 'Ошибка экспорта данных в файл: "%s"!';
  rsErrLoadReport         = 'Ошибка загрузки отчета "%s" из базы данных!';
  rsErrSaveReport         = 'Ошибка сохранения отчета "%s" в базе данных!';
  rsErrGenerateReport     = 'Ошибка создания отчета!';
  rsErrNotRightsForOper   = 'Недостаточно прав для выполнения операции "%s"!';
  rsErrCancelDisabled     = 'Невозможно закрыть окно с отменой внесенных изменений, так как внесены изменения в подчиненные структуры!';

  rsCopyrightsStr         = '%s: %s. Copyright by %s';
  rsFmtNotConnected       = 'Not connected';
  rsFmtConnDatabase       = 'Db: %s';
  rsFmtEditorCaption      = '%s: %s';
  rsViewNotEnabled        = '< СКРЫТО >';
  rsRecordInactive        = 'Нет данных';
  rsRecordNum             = '%d';
  rsRecordCount           = '%d';
  rsRecordNumCount        = '%d:%d';
  rsFileNoName            = 'Без имени %d';
  rsCaptionRecordNum      = 'Запись: %d';
  rsCaptionRecordCount    = 'Всего записей: %d';
  rsCaptionRecordNumCount = 'Запись: %d из %d';
  rsCaptionState          = 'Режим: "%s"';
  rsFoundFilesCount       = 'Найдено файлов: %d';
  rsItemsCount            = 'Объектов: %d';
  rsRecordsCount          = 'Записей: %d';
  rsSortDisableName       = 'без сортировки';
  rsSortDisableHint       = 'Отключить сортировку данных';
  rsSortItemName          = 'по столбцу ''%s''';
  rsSortItemHint          = 'Упорядочить данные по столбцу ''%s''';
  rsBooleanOn             = 'Включено';
  rsBooleanOff            = 'Выключено';
  rsDots                  = '...';
  rsAllFilesFilter        = 'Все файлы (*.*)|*.*';
  rsAlignmentLeft         = 'по левому краю';
  rsAlignmentRight        = 'по правому краю';
  rsAlignmentCenter       = 'по центру';

const
  rsAlignments: array [TAlignment] of string =
    (rsAlignmentLeft, rsAlignmentRight, rsAlignmentCenter);

function GetNameAlignments(const iAlignment: TAlignment): string;

implementation

function GetNameAlignments(const iAlignment: TAlignment): string;
begin
  case iAlignment of
    taLeftJustify: Result := rsAlignmentLeft;
    taRightJustify: Result := rsAlignmentRight;
    taCenter: Result := rsAlignmentCenter;
  end;
end;

end.



