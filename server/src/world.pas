{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit world;

interface

type
   TPerilWorld = class
    public
     constructor Create(const FileName: AnsiString);
   end;

implementation

uses
   fileutils, json;

constructor TPerilWorld.Create(const FileName: AnsiString);
var
   ParsedData: TJSON;
begin
   ParsedData := ParseJSON(ReadTextFile(FileName));
   
end;

end.