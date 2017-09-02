library XEditLib;

uses
  ShareMem,
  xeTypes in 'src\xeTypes.pas',
  xeMessages in 'src\xeMessages.pas',
  xeConfiguration in 'src\xeConfiguration.pas',
  xeMeta in 'src\xeMeta.pas',
  xeSetup in 'src\xeSetup.pas',
  xeFiles in 'src\xeFiles.pas',
  xeMasters in 'src\xeMasters.pas',
  xeElements in 'src\xeElements.pas',
  xeElementValues in 'src\xeElementValues.pas',
  xeErrors in 'src\xeErrors.pas',
  xeRecords in 'src\xeRecords.pas',
  xeSerialization in 'src\xeSerialization.pas',
  mteHelpers in 'lib\mte\mteHelpers.pas',
  mteConflict in 'lib\mte\mteConflict.pas',
  CRC32 in 'lib\mte\CRC32.pas',
  RttiIni in 'lib\mte\RttiIni.pas',
  wbImplementation in 'lib\xedit\wbImplementation.pas',
  wbInterface in 'lib\xedit\wbInterface.pas',
  wbBSA in 'lib\xedit\wbBSA.pas',
  wbSort in 'lib\xedit\wbSort.pas',
  wbDefinitionsFNV in 'lib\xedit\wbDefinitionsFNV.pas',
  wbDefinitionsFO3 in 'lib\xedit\wbDefinitionsFO3.pas',
  wbDefinitionsFO4 in 'lib\xedit\wbDefinitionsFO4.pas',
  wbDefinitionsTES3 in 'lib\xedit\wbDefinitionsTES3.pas',
  wbDefinitionsTES4 in 'lib\xedit\wbDefinitionsTES4.pas',
  wbDefinitionsTES5 in 'lib\xedit\wbDefinitionsTES5.pas',
  wbHelpers in 'lib\xedit\wbHelpers.pas',
  wbLocalization in 'lib\xedit\wbLocalization.pas',
  wbStreams in 'lib\xedit\wbStreams.pas',
  Argo in 'lib\Argo\Argo.pas',
  ArgoTypes in 'lib\Argo\ArgoTypes.pas';

{$R *.RES}
{$MAXSTACKSIZE 2097152}

const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;

exports
  // META METHODS
  InitXEdit, CloseXEdit, GetResultString, GetResultArray, GetGlobal, GetGlobals,
  SetSortMode, Release, ReleaseNodes, Switch, GetDuplicateHandles, ResetStore,
  // MESSAGE METHODS
  GetMessagesLength, GetMessages, ClearMessages, GetExceptionMessageLength,
  GetExceptionMessage,
  // LOADING AND SET UP METHODS
  GetGamePath, SetGamePath, SetLanguage, SetBackupPath, SetGameMode, GetLoadOrder,
  GetActivePlugins, LoadPlugins, LoadPlugin, BuildReferences, GetLoaderStatus,
  UnloadPlugin,
  // FILE HANDLING METHODS
  AddFile, FileByIndex, FileByLoadOrder, FileByName, FileByAuthor, RenameFile,
  SaveFile, OverrideRecordCount, MD5Hash, CRCHash, SortEditorIDs, SortNames,
  // MASTER HANDLING METHODS
  CleanMasters, SortMasters, AddMaster, AddMasters, GetMasters, GetRequiredBy,
  // ELEMENT HANDLING METHODS
  HasElement, GetElement, AddElement, RemoveElement, RemoveElementOrParent,
  SetElement, GetElements, GetDefNames, GetAddList, GetContainer, GetElementFile,
  GetElementRecord, GetLinksTo, ElementCount, ElementEquals, ElementMatches,
  HasArrayItem, GetArrayItem, AddArrayItem, RemoveArrayItem, MoveArrayItem,
  CopyElement, GetSignatureAllowed, GetIsModified, GetIsEditable, GetIsRemoveable,
  GetCanAdd, SortKey, ElementType, DefType, SmashType, ValueType, IsSorted,
  // ERROR CHECKING METHODS
  CheckForErrors, GetErrorThreadDone, GetErrors,
  // SERIALIZATION METHODS
  ElementToJson, ElementFromJson,
  // ELEMENT VALUE METHODS
  Name, LongName, DisplayName, Path, Signature, GetValue, SetValue, GetIntValue,
  SetIntValue, GetUIntValue, SetUIntValue, GetFloatValue, SetFloatValue,
  GetFlag, SetFlag, GetEnabledFlags, SetEnabledFlags, GetAllFlags, GetEnumOptions,
  SignatureFromName, NameFromSignature, GetSignatureNameMap,
  // RECORD HANDLING METHODS
  GetFormID, SetFormID, GetRecords, GetOverrides, GetReferencedBy, GetMaster,
  FindNextRecord, FindPreviousRecord, FindValidReferences, ExchangeReferences,
  IsMaster, IsInjected, IsOverride, IsWinningOverride, GetNodes, GetConflictData,
  GetNodeElements;

begin
  IsMultiThread := True;
end.


