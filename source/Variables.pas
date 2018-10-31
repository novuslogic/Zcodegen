unit Variables;

interface

Uses Variants, NovusList, SysUtils, Output, NovusGUIDEx;

Type
  TVariable = class(TObject)
  protected
     fsVariableName: String;
     FValue: Variant;
     FObject: tObject;
  private
  public
    constructor Create; virtual;
    destructor Destroy; override;

    property VariableName: String
      read fsVariableName
      write fsVariableName;

    property oObject: Tobject
      read fObject
      write fObject;

    property Value: Variant
      read FValue
      Write FValue;

    function AsString: String;
    function IsObject: Boolean;
  end;

  TVariables = class(TObject)
  protected
    fVariableList: tNovusList;
  private
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function AddVariableObject(aObject: Tobject; aObjectTypeName: String = ''): String;
    procedure AddVariable(AVariableName: String;AValue: Variant);
    function VariableExistsIndex(AVariableName: String): Integer;
    function GetVariableByIndex(AIndex: Integer): TVariable;
    function GetVariableByName(aVariableName: String): TVariable;


    class function CleanVariableName(AVariableName: String): String;

  end;


implementation

// TVariables

constructor TVariables.Create;
begin
  inherited Create;

  fVariableList := tNovusList.Create(TVariable);
end;

destructor TVariables.Destroy;
begin
  fVariableList.Free;

  inherited;
end;


function TVariables.AddVariableObject(aObject: Tobject; aObjectTypeName: string): String;
Var
  FVariable: TVariable;
begin
  FVariable := TVariable.Create;

  FVariable.VariableName := '@@' + TGuidExUtils.NewGuidNoBracketsString + '.' + aObjectTypeName;

  if aObjectTypeName = '' then
    FVariable.Value := 'TObject'
  else
    FVariable.Value := aObjectTypeName;

  FVariable.oObject := aObject;

  FVariableList.Add(FVariable);

  Result := FVariable.VariableName;
end;


procedure TVariables.AddVariable(AVariableName: String;AValue: Variant);
Var
  FVariable: TVariable;
begin
  FVariable := TVariable.Create;

  FVariable.VariableName := AVarIableName;

  FVariable.Value := AValue;

  FVariableList.Add(FVariable);
end;


function TVariables.VariableExistsIndex(AVariableName: String): Integer;
Var
  I: Integer;
  FVariable: TVariable;
begin
  Result := -1;

  for I := 0 to fVariableList.Count - 1 do
    begin
      FVariable := TVariable(fVariableList.Items[i]);

      if Uppercase(FVariable.VariableName) = Uppercase(AVariableName) then
        begin
          Result := i;

          break;
        end;
    end;
end;

function TVariables.GetVariableByIndex(AIndex: Integer): TVariable;
begin
  Try
    Result := TVariable(fVariableList.Items[AIndex]);
  Except
    Result := NIL;
  End;
end;

function TVariables.GetVariableByName(aVariableName: String): TVariable;
Var
  liIndex: Integer;
begin
  Result := NIL;

  liIndex := VariableExistsIndex(aVariableName);
  if LiIndex = -1 then Exit;
  Result :=  GetVariablebyIndex(LiIndex);
end;

class function TVariables.CleanVariableName(AVariableName: String): String;
begin
  If Copy(AVariableName, 1, 2) = '$$' then
    result := Copy(AVariableName, 3, Length(AVariableName))
  else
  If Copy(AVariableName, 1, 1) = '$' then
    Result := Copy(AVariableName, 2, Length(AVariableName))
  else
    Result := Trim(AVariableName);
end;


//  TVariable
constructor TVariable.Create;
begin
  inherited Create;

  FObject := NIL;
end;

destructor TVariable.Destroy;
begin
  if Assigned(fObject) then FObject.Free;
  
  inherited;
end;

function TVariable.AsString: String;
begin
  Result := VartoStr(FValue);
end;

function TVariable.IsObject: Boolean;
begin
  Result := False;
  if Assigned(fObject) then Result := True;
end;




end.
