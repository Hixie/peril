{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit players;

interface

uses
   cardinalhashtable, hashfunctions, hashtable, genericutils;

type
   TPlayer = class
    protected
     FName: UTF8String;
     FID: Cardinal;
    public
     constructor Create(const Name: UTF8String);
     procedure SetID(const NewID: Cardinal);
     property Name: UTF8String read FName;
     property ID: Cardinal read FID;
   end;

type
   TPlayerIDHashTable = specialize TCardinalHashTable <TPlayer>; // cardinal -> TPlayer

   generic TPlayerHashTable <T> = class (specialize THashTable <TPlayer, T, TObjectUtils>) // TPlayer => T
      constructor Create(PredictedCount: THashTableSizeInt = 1);
   end;

function TPlayerHash32(const Key: TPlayer): DWord;

implementation

constructor TPlayer.Create(const Name: UTF8String);
begin
   FName := Name;
end;

procedure TPlayer.SetID(const NewID: Cardinal);
begin
   FID := NewID;
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