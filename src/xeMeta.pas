unit xeMeta;

interface

uses
  Classes, SysUtils, Generics.Collections, wbInterface, xeTypes, xeConflict;

type
  TDataFunction = function(const e: IInterface): String;
  TCardinalArray = array of Cardinal;

  {$region 'Native functions'}
  function Resolve(_id: Cardinal): IInterface;
  function ResolveNodes(_id: Cardinal): TDynViewNodeDatas;
  procedure StoreList(lst: TList; len: PInteger);
  procedure FilterResultArray;
  procedure SortResultArray;
  procedure GetSortedElements(const container: IwbContainer; var elements: TDynElements);
  procedure StoreIfAssigned(const x: IInterface; var _res: PCardinal; var Success: WordBool);
  function Store(const x: IInterface): Cardinal;
  function StoreNodes(nodes: TDynViewNodeDatas): Cardinal; overload;
  function xStrCopy(source: WideString; dest: PWideChar; maxLen: Integer): WordBool;
  procedure SetResultFromList(var sl: TStringList; len: PInteger);
  {$endregion}

  {$region 'API functions'}
  procedure InitXEdit; cdecl;
  procedure CloseXEdit; cdecl;
  function GetResultString(str: PWideChar; maxLen: Integer): WordBool; cdecl;
  function GetResultArray(_res: PCardinal; maxLen: Integer): WordBool; cdecl;
  function GetGlobal(key: PWideChar; len: PInteger): WordBool; cdecl;
  function GetGlobals(len: PInteger): WordBool; cdecl;
  function SetSortMode(_sortBy: Byte; _reverse: WordBool): WordBool; cdecl;
  function Release(_id: Cardinal): WordBool; cdecl;
  function ReleaseNodes(_id: Cardinal): WordBool; cdecl;
  function Switch(_id, _id2: Cardinal): WordBool; cdecl;
  function GetDuplicateHandles(_id: Cardinal; len: PInteger): WordBool; cdecl;
  function CleanStore: WordBool; cdecl;
  function ResetStore: WordBool; cdecl;
  {$endregion}

var
  _store: TInterfaceList;
  _releasedIDs: TList<Cardinal>;
  _nodesStore: TList<TDynViewNodeDatas>;
  nextID: Cardinal;
  resultStr: WideString;
  resultArray: TCardinalArray;
  SortBy: Byte;
  Reverse: Boolean;

implementation

uses
  wbImplementation,
  // xelib modules
  xeConfiguration, xeMessages, xeSetup, xeFiles, xeElementValues;

const
  sortByFormID = 1;
  sortByEditorID = 2;
  sortByName = 3;

{$region 'Native functions'}
function xStrCopy(source: WideString; dest: PWideChar; maxLen: Integer): WordBool;
var
  len: Integer;
begin
  Result := False;
  try
    len := Length(source);
    if len <> maxLen then
      raise Exception.Create(Format('Found buffer length %d, expected %d.', [maxLen, len]));
    Move(PWideChar(source)^, dest^, len * SizeOf(WideChar));
    Result := True;
  except
    on x: Exception do
      ExceptionHandler(Exception.Create(Format('Failed to allocate string buffer.  ' +
        'source: %s, maxLen: %d, error: %s', [source, maxLen, x.Message])));
  end;
end;

procedure SetResultFromList(var sl: TStringList; len: PInteger);
begin
  resultStr := sl.Text;
  Delete(resultStr, Length(resultStr) - 1, 2);
  len^ := Length(resultStr);
end;

function Resolve(_id: Cardinal): IInterface;
begin
  if _id = 0 then raise Exception.Create('ERROR: Cannot resolve NULL reference.');
  Result := _store[_id];
end;

function ResolveNodes(_id: Cardinal): TDynViewNodeDatas;
begin
  if _id = 0 then raise Exception.Create('ERROR: Cannot resolve NULL reference.');
  Result := _nodesStore[_id];
end;

procedure StoreList(lst: TList; len: PInteger);
var
  i: Integer;
begin
  SetLength(resultArray, lst.Count);
  for i := 0 to Pred(lst.Count) do
    resultArray[i] := Store(IInterface(lst[i]));
  len^ := Length(resultArray);
end;

procedure FilterResultArray;
var
  oldResults: TCardinalArray;
  i, index: Integer;
  element: IwbElement;
begin
  oldResults := Copy(resultArray, 0, MaxInt);
  index := 0;
  for i := Low(oldResults) to High(oldResults) do
    if Supports(_store[oldResults[i]], IwbElement, element)
    and (esFilterShow in element.ElementStates) then begin
      resultArray[index] := oldResults[i];
      Inc(index);
    end;
  SetLength(resultArray, index);
end;

function FormData(const e: IInterface): String;
var
  _file: IwbFile;
  group: IwbGroupRecord;
  rec: IwbMainRecord;
begin
  if Supports(e, IwbFile, _file) then
    Result := _file.DisplayName
  else if Supports(e, IwbGroupRecord, group) then
    Result := String(TwbSignature(group.GroupLabel))
  else if Supports(e, IwbMainRecord, rec) then
    Result := IntToHex(rec.LoadOrderFormID, 8)
  else
    Result := '';
end;

function EditorData(const e: IInterface): String;
var
  _file: IwbFile;
  group: IwbGroupRecord;
  rec: IwbMainRecord;
begin
  if Supports(e, IwbFile, _file) then
    Result := _file.Name
  else if Supports(e, IwbGroupRecord, group) then
    Result := group.ShortName
  else if Supports(e, IwbMainRecord, rec) then
    Result := rec.EditorID
  else
    Result := '';
end;

function NameData(const e: IInterface): String;
var
  _file: IwbFile;
  group: IwbGroupRecord;
  rec: IwbMainRecord;
begin
  if Supports(e, IwbFile, _file) then
    Result := _file.Name
  else if Supports(e, IwbGroupRecord, group) then
    Result := group.ShortName
  else if Supports(e, IwbMainRecord, rec) then begin
    if rec.ElementExists['FULL'] then
      Result := rec.FullName
    else if rec.ElementExists['NAME'] then
      Result := NativeName(rec.ElementByPath['NAME'].LinksTo)
  end
  else
    Result := '';
end;

procedure SortResultArray;
var
  sl: TFastStringList;
  i, count: Integer;
  dataFunction: TDataFunction;
begin
  if SortBy = 0 then exit;
  sl := TFastStringList.Create;
  try
    sl.Sorted := True;
    sl.Duplicates := dupAccept;
    case SortBy of
      sortByFormID: dataFunction := FormData;
      sortByEditorID: dataFunction := EditorData;
      sortByName: dataFunction := NameData;
      else exit;
    end;
    // add elements to stringlist to sort them
    for i := Low(resultArray) to High(resultArray) do
      sl.AddObject(dataFunction(_store[resultArray[i]]), TObject(resultArray[i]));
    // put elements back into the resultArray in sorted order
    count := sl.Count;
    if reverse then
      for i := Pred(count) downto 0 do
        resultArray[count - i - 1] := Cardinal(sl.Objects[i])
    else
      for i := 0 to Pred(count) do
        resultArray[i] := Cardinal(sl.Objects[i]);
  finally
    sl.Free;
  end;
end;

procedure GetSortedElements(const container: IwbContainer; var elements: TDynElements);
var
  sl: TFastStringList;
  i, count: Integer;
  dataFunction: TDataFunction;
begin
  if SortBy = 0 then begin
    SetLength(elements, container.ElementCount);
    for i := Low(elements) to High(elements) do
      elements[i] := container.Elements[i];
    exit;
  end;
  sl := TFastStringList.Create;
  try
    sl.Sorted := True;
    sl.Duplicates := dupAccept;
    case SortBy of
      sortByFormID: dataFunction := FormData;
      sortByEditorID: dataFunction := EditorData;
      sortByName: dataFunction := NameData;
      else exit;
    end;
    // add elements to stringlist to sort them
    for i := 0 to Pred(container.ElementCount) do
      sl.AddObject(dataFunction(container.Elements[i]), Pointer(container.Elements[i]));
    // put elements in elements array in sorted order
    count := sl.Count;
    SetLength(elements, count);
    if reverse then
      for i := Pred(count) downto 0 do
        elements[count - i - 1] := IwbElement(Pointer(sl.Objects[i]))
    else
      for i := 0 to Pred(count) do
        elements[i] := IwbElement(Pointer(sl.Objects[i]));
  finally
    sl.Free;
  end;
end;

procedure StoreIfAssigned(const x: IInterface; var _res: PCardinal; var Success: WordBool);
begin
  if Assigned(x) then begin
    _res^ := Store(x);
    Success := True;
  end;
end;

function Store(const x: IInterface): Cardinal;
var
  i: Integer;
begin
  if _releasedIDs.Count > 0 then begin
    i := _releasedIDs[0];
    _store[i] := x;
    _releasedIDs.Delete(0);
    Result := i;
  end
  else
    Result := _store.Add(x);
end;

function StoreNodes(nodes: TDynViewNodeDatas): Cardinal; overload;
begin
  Result := _nodesStore.Add(nodes);
end;
{$endregion}

{$region 'API functions'}
procedure InitXEdit; cdecl;
begin
  // initialize variables
  _store := TInterfaceList.Create;
  _nodesStore := TList<TDynViewNodeDatas>.Create;
  _releasedIDs := TList<Cardinal>.Create;
  _store.Add(nil);
  _nodesStore.Add(nil);
  resultStr := '';

  // add welcome message
  AddMessage('XEditLib v' + ProgramVersion);

  // store global values
  Globals.Values['ProgramPath'] := ExtractFilePath(ParamStr(0));
  Globals.Values['Version'] := ProgramVersion;
  Globals.Values['FileCount'] := '0';
end;

procedure CloseXEdit; cdecl;
begin
  _releasedIDs.Free;
  _store.Free;
  _nodesStore.Free;
  SetLength(xFiles, 0);
  xFiles := nil;
  wbFileForceClosed;
  if Assigned(wbContainerHandler) then
    wbContainerHandler._Release;
  RenameSavedFiles;
  SaveMessages;
end;

function GetResultString(str: PWideChar; maxLen: Integer): WordBool; cdecl;
begin
  Result := xStrCopy(resultStr, str, maxLen);
end;

{$POINTERMATH ON}
function GetResultArray(_res: PCardinal; maxLen: Integer): WordBool; cdecl;
var
  i: Integer;
begin
  Result := False;
  try
    for i := 0 to High(resultArray) do begin
      if i >= maxLen then break;
      _res[i] := resultArray[i];
    end;
    SetLength(resultArray, 0);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;
{$POINTERMATH OFF}

function GetGlobal(key: PWideChar; len: PInteger): WordBool; cdecl;
begin
  Result := False;
  try
    if Globals.IndexOfName(key) > -1 then begin
      resultStr := Globals.Values[key];
      len^ := Length(resultStr);
      Result := True;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetGlobals(len: PInteger): WordBool; cdecl;
begin
  Result := False;
  try
    resultStr := Globals.Text;
    len^ := Length(resultStr);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SetSortMode(_sortBy: Byte; _reverse: WordBool): WordBool; cdecl;
begin
  Result := False;
  try
    if _sortBy > sortByName then
      raise Exception.Create('Invalid sort mode.');
    SortBy := _sortBy;
    Reverse := _reverse;
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function Release(_id: Cardinal): WordBool; cdecl;
begin
  Result := False;
  try
    if (_id = 0) or (_id >= Cardinal(_store.Count))
    or (_store[_id] = nil) then exit;
    _store[_id] := nil;
    _releasedIDs.Add(_id);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function ReleaseNodes(_id: Cardinal): WordBool; cdecl;
begin
  Result := False;
  try
    _nodesStore[_id] := nil;
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function Switch(_id, _id2: Cardinal): WordBool; cdecl;
begin
  Result := False;
  try
    if (_id = 0) or (_id >= Cardinal(_store.Count))
    or (_id2 = 0) or (_id2 >= Cardinal(_store.Count)) then exit;
    _store[_id] := _store[_id2];
    _store[_id2] := nil;
    _releasedIDs.Add(_id2);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetDuplicateHandles(_id: Cardinal; len: PInteger): WordBool; cdecl;
var
  element, element2: IwbElement;
  i: Integer;
  lst: TList<Integer>;
begin
  Result := False;
  try
    if not Supports(Resolve(_id), IwbElement, element) then
      raise Exception.Create('Interface is not an element.');
    lst := TList<Integer>.Create;
    try
      for i := 1 to Pred(_store.Count) do
        if (i <> Integer(_id)) and Supports(_store[i], IwbElement, element2)
        and element.Equals(element2) then lst.Add(i);
      len^ := lst.Count;
      SetLength(resultArray, len^);
      for i := 0 to Pred(len^) do
        resultArray[i] := lst[i];
      Result := True;
    finally
      lst.Free;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function CleanStore: WordBool; cdecl;
var
  i: Integer;
begin
  Result := False;
  try
    i := Pred(_store.Count);
    _releasedIDs.Clear;
    while _store[i] = nil do begin
      _store.Delete(i);
      Dec(i);
    end;
    while i > 0 do begin
      if _store[i] = nil then
        _releasedIDs.Add(i);
      Dec(i);
    end;
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function ResetStore: WordBool; cdecl;
begin
  Result := False;
  try
    _store.Clear;
    _releasedIDs.Clear;
    _store.Add(nil);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;
{$endregion}

end.
