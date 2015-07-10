{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit players;

interface

uses
   hashfunctions, hashtable, genericutils;

type
   TPlayerID = String[10];
   TPlayer = class
    protected
     FName: UTF8String;
     FID: TPlayerID;
    public
     constructor Create(const Name: UTF8String; const ID: TPlayerID);
     property Name: UTF8String read FName;
     property ID: TPlayerID read FID;
   end;

type
   TPlayerIDUtils = specialize DefaultUtils <TPlayerID>;

   TPlayerIDHashTable = class (specialize THashTable <TPlayerID, TPlayer, TPlayerIDUtils>)
      constructor Create(PredictedCount: THashTableSizeInt = 2);
   end;

   generic TPlayerHashTable <T> = class (specialize THashTable <TPlayer, T, TObjectUtils>) // TPlayer => T
      constructor Create(PredictedCount: THashTableSizeInt = 1);
   end;

function TPlayerHash32(const Key: TPlayer): DWord;

implementation

constructor TPlayer.Create(const Name: UTF8String; const ID: TPlayerID);
begin
   FName := Name;
   FID := ID;
end;


function TPlayerIDHash32(const Key: TPlayerID): DWord;
var
   Index: Cardinal;
begin
   {$PUSH}
   {$RANGECHECKS OFF}
   {$OVERFLOWCHECKS OFF}
   {$HINTS OFF}
   // djb2 from http://www.cse.yorku.ca/~oz/hash.html:
   Result := 5381;
   if (Length(Key) > 0) then
      for Index := 1 to Length(Key) do
         Result := Result shl 5 + Result + Ord(Key[Index]);
   {$POP}
end;

constructor TPlayerIDHashTable.Create(PredictedCount: THashTableSizeInt = 2);
begin
   inherited Create(@TPlayerIDHash32, PredictedCount);
end;


function TPlayerHash32(const Key: TPlayer): DWord;
begin
   Result := ObjectHash32(Key);
end;

constructor TPlayerHashTable.Create(PredictedCount: THashTableSizeInt = 1);
begin
   inherited Create(@TPlayerHash32, PredictedCount);
end;

end.