unit txSerialization;

interface

  // SERIALIZATION METHODS
  function ElementToJson(_id: Cardinal; json: PWideChar; len: Integer): WordBool; cdecl;

  // PUBLIC TESTING INTERFACE
  procedure BuildSerializationTests;

implementation

procedure BuildSerializationTests;
begin

end;

end.
