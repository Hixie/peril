{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit world;

interface

type
   TPerilWorld = class
    protected
     function CountProvinces(): Cardinal;
    public
     constructor Create(const FileName: AnsiString);
     property ProvinceCount: Cardinal read CountProvinces;
   end;

implementation

uses
   fileutils, json;

constructor TPerilWorld.Create(const FileName: AnsiString);
var
   ParsedData, ProvinceData: TJSON;
begin
   ParsedData := ParseJSON(ReadTextFile(FileName));
   try
      for ProvinceData in ParsedData['provinces'] do
      begin
         Writeln();
      end;
   finally
      ParsedData.Free();
   end;
end;

function TPerilWorld.CountProvinces(): Cardinal;
begin
   Result := 0;
end;

end.