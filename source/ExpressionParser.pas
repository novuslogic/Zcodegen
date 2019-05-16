unit ExpressionParser;

interface

uses
  Classes, SysUtils;

type
  //Parser error messages
  TParserEMessage=(pBadQuotes, pBadBrackets, pBadSyntax);

  //Parser error messages handler
  TParserException=class(Exception)
  public
    constructor CreatePE(VPEMessage : TParserEMessage);
  end;

  //Type of the result returned
  TRes = (trInt, trStr, trBool);

  //Result structure
  PPRes = ^TPRes;
  TPRes=record
    Res : TRes;
    Value : String;
  end;

  //Type of the token
  TTokenType=(ttDelimiter, ttNumber, ttQuote, ttString, ttFinished, ttBlank);

  //Main parser class
  TExpressionParser = class(Tobject)
  private
    fsErrorExpressionMessage: string;
    FExpr : String;
    FLExpr : Integer;
    FExprID : Integer;
    FToken : String;
    FTokenType : TTokenType;
    function IsQuote(C : Char) : Boolean;
    function IsDelim(C : Char) : Boolean;
    function IsDigit(C : Char) : Boolean;
    function IsAlpha(C : Char) : Boolean;
    function GetExpr : String;
    procedure SetExpr(const VExpr : String);
    procedure Get_Token;

    procedure Level1(Res : PPRes);
    procedure Level2(Res : PPRes);
    procedure Level3(Res : PPRes);
    procedure Level4(Res : PPRes);
    procedure Level5(Res : PPRes);
    procedure Level6(Res : PPRes);
    procedure Primitive(Res : PPRes);
    procedure LogOp(aOp : String; aRes, aRes2 : PPRes);
    procedure LogConOp(Op : String; Res, Res2 : PPRes);
    procedure ArithOp(Op : Char; Res, Res2 : PPRes);
    procedure UnaryOp(Op : Char; Res : PPRes);
    procedure PreparePRes(aRes: PPRes);
  protected
    //Method to be overridden by descendents to translate
    //a variable name (VName) into a value
    function ValueByName(VName : String) : String;virtual;
  public
    //The Expression to parse
    property Expr : String read GetExpr write SetExpr;
    //Interface to enumerate expression tokens
    procedure ListTokens(Str : TStrings);
    //Entry point
    function Execute : Boolean;

    property ErrorExpressionMessage: string
      read fsErrorExpressionMessage;
  end;

implementation

{ TExpressionParser }

const
  EndSymbol='~';
  STrue='1'; SFalse='0';
  PEMessageStr : array[TParserEMessage] of String=(
    'Bad quotes',
    'Bad brackets',
    'Bad Syntax'
  );


procedure TExpressionParser.ArithOp(Op: Char; Res, Res2: PPRes);
begin
  case Op of
    '+':try
          Res^.Value := FloatToStr(StrToFloat(Res^.Value)+StrToFloat(Res2^.Value))
        except
          Res^.Value := Res^.Value+Res2^.Value;
        end;
    '-':Res^.Value := FloatToStr(StrToFloat(Res^.Value)-StrToFloat(Res2^.Value));
    '*':Res^.Value := FloatToStr(StrToFloat(Res^.Value)*StrToFloat(Res2^.Value));
    '/':Res^.Value := FloatToStr(StrToFloat(Res^.Value)/StrToFloat(Res2^.Value));
  end;
end;

function TExpressionParser.GetExpr: String;
begin
  Result := FExpr;
end;




function TExpressionParser.Execute: Boolean;
var
  PRes : TPRes;
begin
  Get_Token;
  if FTokenType=ttFinished then
  begin
    Result := True;
    exit;
  end;
  Level1(@PRes);
  if PRes.Res<>trBool then
    begin
      Result := False;

      fsErrorExpressionMessage := PEMessageStr[pBadSyntax];

      Exit;
    end;
  Result := (PRes.Value=STrue);
end;



//Get next token
procedure TExpressionParser.Get_Token;
begin

  //Spaces
  while (FExpr[FExprID]=' ') and (FExprID<=FLExpr) do
     Inc(FExprID);

  // comma
  while (FExpr[FExprID]=',') and (FExprID<=FLExpr) do
     Inc(FExprID);

  // Semi Comma
  while (FExpr[FExprID]=';') and (FExprID<=FLExpr) do
     Inc(FExprID);

  while (FExpr[FExprID]='.') and (FExprID<=FLExpr) do
     Inc(FExprID);

  while (FExpr[FExprID]='%') and (FExprID<=FLExpr) do
     Inc(FExprID);


   //Check if End of Expression
  if FExpr[FExprID]=EndSymbol then
  begin
    FToken := '';
    FTokenType := ttFinished;
    exit;
  end;
  //Delimiters 1
  if Pos(FExpr[FExprID], '+-/*=<>!')<>0 then
  begin
    FToken := FExpr[FExprID];
    Inc(FExprID);

    if (FExpr[FExprID]<>EndSymbol) and //(Pos(FExpr[FExprID-1], '<>')<>0) and
       (Pos(FExpr[FExprID], '!=')<>0) then
    begin
      FToken := FToken+FExpr[FExprID];
      Inc(FExprID);
    end
    else
    if (FExpr[FExprID]<>EndSymbol) and (Pos(FExpr[FExprID-1], '<>')<>0) and
       (Pos(FExpr[FExprID], '=>')<>0) then
    begin
      FToken := FToken+FExpr[FExprID];
      Inc(FExprID);
    end;
    FTokenType := ttDelimiter;
    exit;
  end;
  //Delimiters 2
  if Pos(FExpr[FExprID], '()')<>0 then
  begin
    FToken := FExpr[FExprID];
    Inc(FExprID);

    FTokenType := ttDelimiter;
    exit;
  end;
  //Quotes
  if IsQuote(FExpr[FExprID]) then
  begin
    Inc(FExprID);
    FToken := '';
    if (FExpr[FExprID]<>EndSymbol) and //(Pos(FExpr[FExprID-1], '<>')<>0) and
       (Pos(FExpr[FExprID], '""')<>0) then
    begin
      FToken := '""';
      FTokenType := ttBlank;
      Inc(FExprID);
      Exit;
    end;

    while (not IsQuote(FExpr[FExprID])) and (FExpr[FExprID]<>EndSymbol) do
    begin
      FToken := FToken+FExpr[FExprID];
      Inc(FExprID);
    end;
    if FExpr[FExprID]=EndSymbol then
      raise TParserException.CreatePE(pBadQuotes);
    Inc(FExprID);
    FTokenType := ttQuote;
    exit;
  end;

  //Number
  if IsDigit(FExpr[FExprID]) then
  begin
    FToken := '';
    while (not IsDelim(FExpr[FExprID])) and (FExpr[FExprID]<>EndSymbol) and
       (FExpr[FExprID]<>';') do
    begin
      FToken := FToken+FExpr[FExprID];
      Inc(FExprID);
    end;
    FTokenType := ttNumber;

    exit;
  end;

  //Variable
  if (IsAlpha(FExpr[FExprID])) or (FExpr[FExprID] ='$') then
  begin
    FToken := '';
    while (not IsDelim(FExpr[FExprID])) and
         (Expr[FExprID]<>EndSymbol) and
         ((FExpr[FExprID]<>';')) do
    begin
      FToken := FToken+FExpr[FExprID];

      Inc(FExprID);

      if ((FExpr[FExprID] = '.') or
         (FExpr[FExprID] = '!'))
       then break;
    end;
    FTokenType := ttString;
    exit;
  end;
end;


function TExpressionParser.IsAlpha(C: Char): Boolean;
begin
  Result := C in ['A'..'Z', 'a'..'z'];
end;

function TExpressionParser.IsDelim(C: Char): Boolean;
begin
  Result := Pos(C, ' ,+-<>=/*%^()')<>0;
end;

function TExpressionParser.IsDigit(C: Char): Boolean;
begin
  Result := C in ['0'..'9','.']
end;

function TExpressionParser.IsQuote(C : Char) : Boolean;
begin
  Result := C in ['''','"']
end;

procedure TExpressionParser.Level1(Res: PPRes);
var
  Res2 : TPRes;
  Op : String;
begin
  Level2(Res);
  while (FToken='and') or (FToken='or') do
  begin
    Op := FToken;
    Get_Token;
    Level2(@Res2);
    LogConOp(Op, Res, @Res2);
  end;
end;


procedure TExpressionParser.Level2(Res: PPRes);
var
  Res2 : TPRes;
  Op : String;
begin
  Level3(Res);
  if (FToken='>') or (FToken='<') or
     (FToken='<=') or (FToken='>=') or (FToken='=') or (FToken='!=') then
  begin
    Op := FToken;
    Get_Token;
    Level3(@Res2);
    LogOp(Op, Res, @Res2);
  end;
end;

procedure TExpressionParser.Level3(Res: PPRes);
var
  Res2 : TPRes;
  Op : Char;
begin
  Level4(Res);
  while (FToken='+') or (FToken='-') do
  begin
    Op := FToken[1];
    Get_Token;
    Level4(@Res2);
    ArithOp(Op, Res, @Res2);
  end;
end;

procedure TExpressionParser.Level4(Res: PPRes);
var
  Res2 : TPRes;
  Op : Char;
begin
  Level5(Res);
  while (FToken='*') or (FToken='/') do
  begin
    Op := FToken[1];
    Get_Token;
    Level5(@Res2);
    ArithOp(Op, Res, @Res2);
  end;
end;
procedure TExpressionParser.Level5(Res: PPRes);
var
  Op : Char;
begin
  Op := #0;
  if (FTokenType=ttDelimiter) and ((FToken='+') or (FToken='-')) then
  begin
    Op := FToken[1];
    Get_Token;
  end;
  Level6(Res);
  if Op<>#0 then
    UnaryOp(Op, Res);
end;

procedure TExpressionParser.Level6(Res: PPRes);
begin
  if (FToken='(') and (FTokenType=ttDelimiter) then
  begin
    Get_Token;
    Level1(Res);
    if FToken<>')' then
      raise TParserException.CreatePE(pBadBrackets);
    Get_Token;
  end else
    Primitive(Res);
end;

procedure TExpressionParser.ListTokens(Str: TStrings);
begin
  while (FExprID<>-1) and (FExprID<=FLExpr) do
  begin
    FToken := '';

    Get_Token;
    if FTokenType=ttFinished then break;

    if FToken = '' then Continue;

    if FToken <> '' then
      Str.Add(FToken);
  end;
end;

procedure TExpressionParser.LogConOp(Op: String; Res, Res2: PPRes);
begin
  if (Res^.Res<>trBool) or (Res2^.Res<>trBool) then
    raise TParserException.CreatePE(pBadSyntax);
  if Op='and' then
  begin
    if (Res^.Value=STrue) and (Res2^.Value=STrue) then
      Res^.Value := STrue
    else
      Res^.Value := SFalse;
  end else if Op='or' then
  begin
    if (Res^.Value=STrue) or (Res2^.Value=STrue) then
      Res^.Value := STrue
    else
      Res^.Value := SFalse;
  end;
end;

procedure TExpressionParser.PreparePRes(aRes: PPRes);
begin
  if (CompareText(aRes^.Value, 'false') >= 0) then
    aRes^.Value := 'false'
  else
  if (CompareText(aRes^.Value, 'true') >= 0) then
    aRes^.Value := 'true';

end;


procedure TExpressionParser.LogOp(aOp: String; aRes, aRes2: PPRes);
begin
  aRes^.Res := trBool;

  PreparePRes(@aRes);
  PreparePRes(@aRes2);

  if aOp='=' then
  begin
   if aRes^.Value=aRes2^.Value then
      aRes^.Value := STrue
    else aRes^.Value := SFalse;
  end
  else
  if aOp='!=' then
  begin
    if aRes^.Value<>aRes2^.Value then
      aRes^.Value := STrue
    else aRes^.Value := SFalse;
  end
  else
  if aOp='>' then
  begin
    if StrToFloat(aRes^.Value)>StrToFloat(aRes2^.Value) then
      aRes^.Value := STrue
    else aRes^.Value := SFalse;
  end else if aOp='>=' then
  begin
    if StrToFloat(aRes^.Value)>=StrToFloat(aRes2^.Value) then
      aRes^.Value := STrue
    else aRes^.Value := SFalse;
  end else if aOp='<' then
  begin
    if StrToFloat(aRes^.Value)<StrToFloat(aRes2^.Value) then
      aRes^.Value := STrue
    else aRes^.Value := SFalse;
  end else if aOp='<=' then
  begin
    if StrToFloat(aRes^.Value)<=StrToFloat(aRes2^.Value) then
      aRes^.Value := STrue
    else aRes^.Value := SFalse;
  end;
end;

procedure TExpressionParser.Primitive(Res: PPRes);
begin
  if FTokenType=ttNumber then
  begin
    Res^.Value := FloatToStr(StrToFloat(FToken));
    Get_Token;
  end else if FTokenType=ttString then
  begin
    Res^.Value := ValueByName(FToken);
    Get_Token;
  end  else if FTokenType=ttQuote then
  begin
    Res^.Value := FToken;
    Get_Token;
  end;
end;

procedure TExpressionParser.SetExpr(const VExpr: String);
begin
  FExpr := VExpr+EndSymbol;
  FLExpr := Length(FExpr);
  FExprID := 1
end;

procedure TExpressionParser.UnaryOp(Op: Char; Res: PPRes);
begin
  if Op='-' then
    Res^.Value := FloatToStr(StrToFloat(Res^.Value)*(-1));
end;

function TExpressionParser.ValueByName(VName: String): String;
begin
  Result := VName;
end;

{ TParserException }

constructor TParserException.CreatePE(VPEMessage: TParserEMessage);
begin
  inherited Create(PEMessageStr[VPEMessage]);
end;



end.
