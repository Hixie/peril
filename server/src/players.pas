{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit players;

interface

type
   TPlayer = class
    protected
     FName: UTF8String;
    public
     constructor Create(const Name: UTF8String);
   end;

implementation

constructor TPlayer.Create(const Name: UTF8String);
begin
   FName := Name;
end;

end.