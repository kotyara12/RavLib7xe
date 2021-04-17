unit rMsgStd;

interface

uses
  Classes;

resourcestring
  rsMsgInitApplication    = '������������� ����������...';
  rsMsgInitDataForm       = '������������� ���� ������...';
  rsMsgDoneApplication    = '���������� ������ ����������...';
  rsMsgConnDatabase       = '��������� ���������� � ����� ������...';
  rsMsgReconnDatabase     = '�������������� ���������� � ����� ������...';
  rsMsgCloseDatabase      = '���������� ���������� � ����� ������...';
  rsMsgConfigureConnect   = '�� ��������� ��������� ����������� � ���� ������!'#13'�������� ���� ''����'' - ''��������� ���������� � ��'' � ���������� ��������� �����������.';
  rsMsgDbChangeNextTime   = '��������� ���������� ����� �������� ��� ��������� �������� ���������!';
  rsMsgSetStyles          = '��������� ���� ����������...';
  rsMsgChangeStyles       = '��������� ���� ����������...';
  rsMsgCheckDbVersion     = '�������� ������ ���� ������...';
  rsMsgUpdateCreate       = '�������� ����� ���� ������...';
  rsMsgUpdateDatabase     = '���������� ���� ������...';
  rsMsgUpdateDbStep       = '���������� ���� ������ #%d...';
  rsMsgSaveDbVersion      = '���������� ������ ���� ������...';
  rsMsgLoadSystemParams   = '�������� ���������� �������...';
  rsMsgLoadData           = '�������� ������...';
  rsMsgLoadDataWait       = '�������� ������. ��������� ����������...';
  rsMsgLoadDataServer     = '�������� ������ � �������...';
  rsMsgLoadDataFile       = '�������� ������ �� �����...';
  rsMsgLoadDataFormEx     = '�������� ���������� %s...';
  rsMsgScanDirectory      = '������������ ��������...';
  rsMsgSaveData           = '���������� ������...';
  rsMsgSaveDataWait       = '���������� ������. ��������� ����������...';
  rsMsgSaveDataServer     = '���������� ������ �� �������...';
  rsMsgSaveDataFile       = '���������� ������ � �����...';
  rsMsgSaveDataForm       = '���������� ���������� ����...';
  rsMsgSaveDataFormEx     = '���������� ���������� %s...';
  rsMsgPrintingWait       = '���� ������...';
  rsMsgImportDataWait     = '������ ������. ��������� ����������...';
  rsMsgExportDataWait     = '��c���� ������. ��������� ����������...';
  rsMsgDeleteDataWait     = '�������� ������. ��������� ����������...';
  rsMsgCancelChanges      = '������ ��������� ���������...';
  rsMsgWorkingWait        = '��������� ����������...';
  rsMsgWait               = '��������� ����������...';
  rsMsgGetSelection       = '����������������...';
  rsMsgSetSelection       = '��������� ����������...';
  rsMsgFindData           = '����� ������...';
  rsMsgFindFiles          = '����� ������...';
  rsMsgReplaceData        = '������ ������...';
  rsMsgSortData           = '���������� ������...';
  rsMsgCreateNewRecord    = '�������� ����� ������...';
  rsMsgGenerateReport     = '��������� ������...';
  rsMsgGeneratePage       = '��������� �������� %d �� %d...';
  rsMsgGenerateSheet      = '��������� ����� "%s"...';
  rsMsgPrepareOperation   = '���������� ��������...';
  rsMsgOperationComplete  = '�������� ��������� �������!';
  rsMsgRepaceCount        = '����� ����������� %d �����!';
  rsMsgRefreshData        = '���������� ������...';
  rsMsgCloneSubData       = '����������� ��������� ������...';

  rsPrmFind               = '������';
  rsPrmFilter             = '�������';
  rsPrmOrder              = '����������';
  rsPrmGridTuner          = '�������';

  rsTextFilterSelected    = '�� ���������';    

  rsWrnNotEnoughRights    = '������������ ���� ��� ���������� ��������!';

  rsQueryCloseProgram     = '��������� ������ � ����������?';
  rsQueryBreakOperation   = '�������� ������� ��������?';
  rsQueryResetColumns     = '������� ���������������� ��������� �������� �������?';
  rsQueryVisibleFields    = '������� ���������� ���� ��������� �������, ������� ���������?';
  rsQueryCreateNewDoc     = '������� ����� ��������?';
  rsQuerySaveChanges      = '��������� �� ���������! ��������� ��������� ���������?';
  rsQueryDescardChanges   = '��� ��������� ��������� ����� ��������! ����������?';
  rsQuerySetDefault       = '�� ������������� ������ ���������� �������� "�� ���������"?';
  rsQueryCloseConnect     = '��� ���������� ����������� �������� ���������� ������� ��� ���� � ���������� � ����� ������. ����������?';
  rsQueryReconnect        = '��������� ��������������� � ���� ������ � ������ �����������?';

  rsSelectDirectory       = '�������� �������';
  rsSelectFile            = '�������� ����';

  rsDataSetNil            = '����� ������ �� ������';
  rsDataSetInactive	 = '����� ������ ������';    // Dataset is closed, so its data is unavailable.
  rsDataSetBrowse	 = '��������';               // Data can be viewed, but not changed. This is the default state of an open dataset.
  rsDataSetEdit	         = '��������������';         // Active record can be modified.
  rsDataSetInsert	 = '����� ������';           // The active record is a newly inserted buffer that has not been posted. This record can be modified and then either posted or discarded.
  rsDataSetSetKey	 = '������...';              // TTable and TClientDataSet only. Record searching is enabled, or a SetRange operation is under way. A restricted set of data can be viewed, and no data can be edited or inserted.
  rsDataSetCalcFields	 = '��������� ��������...';  // An OnCalcFields event is in progress. Noncalculated fields cannot be edited, and new records cannot be inserted.
  rsDataSetFilter	 = '������...';              // An OnFilterRecord event is in progress. A restricted set of data can be viewed. No data can edited or inserted.
  rsDataSetNewValue	 = '��������������...';      // Temporary state used internally when a field component�s NewValue property is accessed.
  rsDataSetOldValue	 = '��������������...';      // Temporary state used internally when a field component�s OldValue property is accessed.
  rsDataSetCurValue	 = '��������������...';      // Temporary state used internally when a field component�s CurValue property is accessed.
  rsDataSetBlockRead	 = '������ ������...';       // Data-aware controls are not updated and events are not triggered when moving to the next record.
  rsDataSetInternalCalc	 = '��������� ��������...';  // Temporary state used internally when values need to be calculated for a field that has a FieldKind of fkInternalCalc.
  rsDataSetOpening	 = '�������� ������...';     // DataSet is in the process of opening but has not finished. This state occurs when the dataset is opened for asynchronous fetching.

  rsFieldRequired         = '���� ''%s'' ������ ���� ���������!';
  rsFieldRefEmpty         = '��� ���� ''%s'' �� �������� ���������� ��������!';
  rsFieldNotListed        = '���� ''%s'' �� ���������� � ������ ��������!';

  rsSortTreeNone          = '�������� �� �����������';
  rsSortTreeId            = '�������� ����������� �� �������������� ������';
  rsSortTreeTypeId        = '�������� ����������� �� ���� � ��������������';
  rsSortTreeName          = '�������� ����������� �� ������������ ������';
  rsSortTreeTypeName      = '�������� ����������� �� ���� � ������������';

  rsLogDbVersionWarning   = '%s: �� ��������� ������ ���� ������ (DB ver: %d) � ������������ ����������� (DB ver: %d)!';
  rsLogDbVersionUpdate    = '%s: ����������� ���������� ���� ������, ��������������� ��� DB ver: %d �� ����� "%s".';
  rsLogDbVersionSaveNum   = '%s: �������� ������ ���� ������ (DB ver: %d).';

  rsDbVersionFilter       = '���� �������� ���������� #%0:d|%1:s';
  rsDbVersionSelFile      = '������� ���� �������� ����������';
  rsDbVersionScrNotFound  = '�� ������ ���� �������� ���������� "%s"!';
  rsDbVersionSqlText      = '> %s';
  rsDbVersionSqlOk        = 'OK'#13#10;
  rsDbVersionSqlError     = '#ERROR#: %s';

  rsDbVersionChkError     = '�� ������� ��������� ������������ ������ ���� ������!';
  rsDbVersionQryError     = '���������� ���������� �������� ����������?';

  rsDbVersionWrnNewer     = '����� ������ ���� ������ (DB ver: %d) ���� ������ �� (DB ver: %d)!'#13#13 +
                           '���������� ��������� ���������� ������������ �����������.'#13#13 +
                           '�� ������ ���������� ������ � ������ ������� ������������ �����������?';
  rsDbVersionWrnOlder     = '����� ������ ���� ������ (DB ver: %d) ���� ������ �� (DB ver: %d)!'#13#13 +
                           '���������� ��������� ���������� ���� ������.'#13#13 +
                           '�� ������ ���������� ������ � ������ ������� ������������ �����������?';
  rsDbVersionQryCreate    = '������ ���� ������ �� ����������������.'#13#13 +
                           '��������� �������� �������� ����� ���� ������?';
  rsDbVersionQryUpdate    = '����� ������ ���� ������ (DB ver: %d) ���� ������ �� (DB ver: %d)!'#13#13 +
                           '��������� ���������� ���� ������ ������?';
  rsDbVersionWrnCancel    = '�� ������� ��������� ���������� ���� ������!'#13#13 +
                           '�� ������ ���������� ������ � ������ ������� ������������ �����������?';

  rsDbVersionQryResque    = '������� ��������� ����� ���� ������ ����� ����������� ���������� (�������������)?';
  rsDbVersionWrnResque    = '����� ������� ���������� ������������ ������������� ������� ��������� ����� ������� ������ ���� ������ (���������� ����)!'#13 +
                           '��������� ���������� ���� ������ ������?';


  rsErrAssertError        = '���������� ������!!! ���������� � ������������!';
  rsErrLoadLibrary        = '������ �������� ������������ ���������� ''%s''!';
  rsErrLoadLibraryEx      = '������ �������� ������������ ���������� ''%s'':'#13'%s!';
  rsErrFindProcedure      = '��������� ''%s'' �� ������� � ������������ ���������� ''%s''!';
  rsErrWindowsError       = '��������� ������!';
  rsErrWindowsCode        = '��� ������: %d!';
  rsErrSystemError        = '������ #%d: "%s"!';
  rsErrBadConnectionType  = '����� ���������� � ����� ������ ''%s'' �� ������������� ������ ������ ������ ''%s''!';
  rsErrDataSetNull        = '������ ������ �� ������ ��� �� ��������������� (''null'')!';
  rsErrInitForm           = '������ ������������� ����!';
  rsErrDoneForm           = '������ ���������� �������������� �������� ����!';
  rsErrLoadFormPlacement  = '������ �������� � �������������� ���������� ����!';
  rsErrSaveFormPlacement  = '������ ���������� ���������� ����!';
  rsErrChangeStyle        = '������ ��������� ������ ����������!';
  rsErrBadOperationTag    = '������������ ��� ��������: %d.';
  rsErrSetStyles          = '������ ��������� ���� ����������!';
  rsDataModuleNotCreated  = '������ ���������� � ����� ������ �� ���������������!';
  rsErrNotDbConnect       = '���������� � ����� ������ �� �����������!';
  rsErrBadDbCfgFile       = '���� ������������ ����������� � ���� ������ "%s" �� ������!'#13'��������� ��������� ����������� � ���� ������ ����� ���� "����" - "��������� ���������� � ��".';
  rsErrConnDatabase       = '������ ���������� � ����� ������!';
  rsErrReconnDatabase     = '�� ������� ������������ ����������� � ���� ������ �� ���������� �����!'#13'��������� ����� �������.';
  rsErrConfDatabase       = '������ ��������� ������������ ���� ������!';
  rsErrCopyDatabase       = '������ �������� ��������� ����� ���� ������!';
  rsErrRestDatabase       = '������ �������������� ���� ������ �� ��������� �����!';
  rsErrBackupDisabled     = '��������� ����������� ���� ������ �� ���������!';
  rsErrCheckDbVersion     = '������ �������� ������ ���� ������!';
  rsErrReadDbVersion      = '������ ������ ������ ���� ������!';
  rsErrSaveDbVersion      = '������ ���������� ������ ���� ������!';
  rsErrUpdateDatabase     = '������ ���������� ���� ������!';
  rsErrLoadSystemParams   = '������ �������� ���������� ������� �� ���� ������!';
  rsErrOpenDataSet        = '������ �������� ������ �� ���� ������: ������ ''%s''!';
  rsErrRefreshDataSet     = '������ ���������� ������� �� ���� ������: ������ ''%s''!';
  rsErrPostError          = '������ ���������� ��������� � ���� ������: ������ ''%s''!';
  rsErrDeleteError        = '������ �������� ������ � ���� ������: ������ ''%s''!'#13'�������� ��� ������ �������� ��-�� ����, ��� � ������ �������� ���������� ������, ����������� �� ������ ������.';
  rsErrGetRecordCount     = '������ ����������� ���������� ������� � ������� ''%s''!';
  rsErrLoadData           = '������ �������� ������!';
  rsErrLoadTree           = '������ �������� ��������� ������!';
  rsErrReloadTree         = '������ ������������ ��������� ��������� ��� ����������� ��������!';
  rsErrRecordInsert       = '������ ���������� ������!';
  rsErrRecordImport       = '������ ������� ������!';
  rsErrRecordEdit         = '������ �������������� ������!';
  rsErrRecordDelete       = '������ �������� ������!';
  rsErrRecordMultiprocess = '������ ���������������!';
  rsErrFindError          = '������ ���������� ������� ��� ������� ''%s''!';
  rsErrTreeDSNil          = '�� ��������� ����� ������ ��� �������� ������������� ���������!';
  rsErrNoSelectedItem     = '�� ������ ������ ��� ���������� ��������!';
  rsErrDataSetIsEmpty     = '��� ������ ��� ���������� ��������!';
  rsErrIdNotFound         = '������ � id=%d � ��������� ������ �� ������!';
  rsErrIdNotFoundS        = '������ � id="%s" � ��������� ������ �� ������!';
  rsErrDSIdNotFound       = '������ � id=%d � ������ ������ "%s" �� �������!';
  rsErrDSNameNotFound     = '������ "%s" � ������ ������ "%s" �� �������!';
  rsErrDSFieldNotFound    = '���� "%s" � ������ ������ "%s" �� �������!';
  rsErrStrNotFound        = '������ "%s" �� �������!';
  rsErrFileNotFound       = '���� "%s" �� ������!';
  rsErrDirNotFound        = '������� "%s" �� ������!';
  rsErrPathNotFound       = '���� "%s" �� ������!';
  rsErrFileDelete         = '������ �������� ����� "%s": %s!';
  rsErrCreateRecReport    = '������ ��������� ������ ��� ������� ������!';
  rsErrCreateReport       = '������ ��������� ������!';
  rsErrCreatePage         = '������ �������� �������� "%s"!';
  rsErrMoveRecord         = '������ ����������� ������ � ��������� ������ / �����!';
  rsErrInitDataModule     = '������ ������������� ������ %s!';
  rsErrLoadFile           = '������ �������� �����: "%s"!';
  rsErrSaveFile           = '������ ������ � ����: "%s"!';
  rsErrImportFile         = '������ �������� ������ �� �����: "%s"!';
  rsErrExportFile         = '������ �������� ������ � ����: "%s"!';
  rsErrLoadReport         = '������ �������� ������ "%s" �� ���� ������!';
  rsErrSaveReport         = '������ ���������� ������ "%s" � ���� ������!';
  rsErrGenerateReport     = '������ �������� ������!';
  rsErrNotRightsForOper   = '������������ ���� ��� ���������� �������� "%s"!';
  rsErrCancelDisabled     = '���������� ������� ���� � ������� ��������� ���������, ��� ��� ������� ��������� � ����������� ���������!';

  rsCopyrightsStr         = '%s: %s. Copyright by %s';
  rsFmtNotConnected       = 'Not connected';
  rsFmtConnDatabase       = 'Db: %s';
  rsFmtEditorCaption      = '%s: %s';
  rsViewNotEnabled        = '< ������ >';
  rsRecordInactive        = '��� ������';
  rsRecordNum             = '%d';
  rsRecordCount           = '%d';
  rsRecordNumCount        = '%d:%d';
  rsFileNoName            = '��� ����� %d';
  rsCaptionRecordNum      = '������: %d';
  rsCaptionRecordCount    = '����� �������: %d';
  rsCaptionRecordNumCount = '������: %d �� %d';
  rsCaptionState          = '�����: "%s"';
  rsFoundFilesCount       = '������� ������: %d';
  rsItemsCount            = '��������: %d';
  rsRecordsCount          = '�������: %d';
  rsSortDisableName       = '��� ����������';
  rsSortDisableHint       = '��������� ���������� ������';
  rsSortItemName          = '�� ������� ''%s''';
  rsSortItemHint          = '����������� ������ �� ������� ''%s''';
  rsBooleanOn             = '��������';
  rsBooleanOff            = '���������';
  rsDots                  = '...';
  rsAllFilesFilter        = '��� ����� (*.*)|*.*';
  rsAlignmentLeft         = '�� ������ ����';
  rsAlignmentRight        = '�� ������� ����';
  rsAlignmentCenter       = '�� ������';

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



