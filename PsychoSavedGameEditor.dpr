{
******************************************************
  Psychonauts Saved Game Editor
  Copyright (c) 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

program PsychoSavedGameEditor;

uses
  Forms,
  MainFrm in 'MainFrm.pas' {FormMain};

//{$R *.res}

begin
  //ReportMemoryLeaksOnShutdown:=true;
  
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
