{$MODE OBJFPC} { -*- delphi -*- }
{$INCLUDE settings.inc}
unit players;

interface

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

implementation

constructor TPlayer.Create(const Name: UTF8String);
begin
   FName := Name;
end;

procedure TPlayer.SetID(const NewID: Cardinal);
begin
   FID := NewID;
end;

end.