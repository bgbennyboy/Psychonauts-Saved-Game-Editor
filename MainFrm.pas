{
******************************************************
  Psychonauts Saved Game Editor
  Copyright (c) 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

{
BEFORE RELEASE:
    DISABLE ReportMemoryLeaksOnShutdown in project .dpr
    Change build configuration from debug to release
    Update readme
    Update ini in resource file
    Compress with UPX
}

{
  TODO:
  Dropdown width autosize?
}


unit MainFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, XPMan, StdCtrls, ComCtrls, VirtualTrees, strutils, jclstrings,
  ExtCtrls, JvExControls, JvComponent, JvSpeedButton, Menus, JvMenus,
  JvExStdCtrls, JvRichEdit, jclshell, htmcombo, ImgList, inifiles, uVistaFuncs,
  PngImageList, Buttons, PngSpeedButton, AdvGlowButton;

type
  TFormMain = class(TForm)
    OpenDialog1: TOpenDialog;
    XPManifest1: TXPManifest;
    tree: TVirtualStringTree;
    MemoLog: TJvRichEdit;
    pnlContainer: TPanel;
    EditFileName: TLabeledEdit;
    EditData: TLabeledEdit;
    comboboxTasks: THTMLComboBox;
    LabelTasks: TLabel;
    ComboBoxLevel: THTMLComboBox;
    LabelLevel: TLabel;
    PngImageList1: TPngImageList;
    btnOpen: TPngSpeedButton;
    btnSave: TPngSpeedButton;
    procedure ComboBoxLevelChange(Sender: TObject);
    procedure EditFileNameExit(Sender: TObject);
    procedure EditDataExit(Sender: TObject);
    procedure comboboxTasksDropDown(Sender: TObject);
    procedure ComboBoxLevelDropDown(Sender: TObject);
    procedure comboboxTasksChange(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure treeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean;
      var ImageIndex: Integer);
    procedure MemoLogURLClick(Sender: TObject; const URLText: string;
      Button: TMouseButton);
    procedure treeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure treeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure treeInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnOpenClick(Sender: TObject);
    procedure treeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
  private
    function CheckHeader: boolean;
    function GetCompleteDataString(Node: PVirtualNode): string;
    procedure ReadHeader;
    procedure ParseArray;
    procedure SelectNode(NodeCaption: string);
    procedure LoadTasksFromIni;
    procedure ExtractIni;
    { Private declarations }
  public
    { Public declarations }
  end;

const
  IniName = 'PsychoautsSavedGameEditor.ini';
  Levels: array[0..48] of string = (
    'BVWC', 'BVWD', 'BVWE', 'BVES', 'BVMA', 'BVRB', 'BVWT', 'NIBA', 'NIMP', 'BBA1', 'BBA2',
    'BBLT', 'CABU', 'ASLB', 'THFB', 'THCW', 'THMS', 'LLLL', 'LOCB', 'LOMA', 'MCTC', 'MCBB',
    'MIFL', 'MILL', 'MIMM', 'SACU', 'STMU', 'MMDM', 'MMI1', 'MMI2', 'ASGR', 'ASCO', 'ASRU',
    'ASUP', 'WWMA', 'CABH', 'CABH_NIGHT', 'CAMA', 'CAMA_NIGHT', 'CAJA', 'CAGP', 'CAGP_NIGHT',
    'CAKC', 'CAKC_NIGHT', 'CALI', 'CALI_NIGHT', 'CARE', 'CARE_NIGHT', 'CASA');
var
  FormMain: TFormMain;
  TheFile: tfilestream;
  NamesList: TstringList;
  ItemNum: integer;
  TaskNodeIndex: integer;
  ItemNamesArray: array of string;
  JunkDataArray: array[0..4] of string;

implementation

{$R *.dfm}
{$R uac.res}
{$R MainResources.res}

type
  PMyRec = ^TMyRec;
  TMyRec = record
    Caption: String;
    OriginalName: String;
    Value: String;
    ArrayIndex: Integer;
    TableParent: Boolean;
    TableChild: Boolean;
  end;

function ReadByte: byte;
begin
	TheFile.Read(result,1);
end;

function ReadWord: word;
begin
  TheFile.Read(result,2);
end;

function ReadDWord: longword;
begin
  TheFile.Read(result,4);
end;

function ReadBlockName: string;
begin
   result:=chr(ReadByte)+chr(ReadByte)+chr(ReadByte)+chr(ReadByte);
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  //SetDesktopIconFonts(Self.Font);
  NamesList:=TstringList.Create;
  Tree.NodeDataSize := SizeOf(TMyRec);
  EditData.Enabled:=false;
  EditData.EditLabel.Enabled:=true;
  EditFileName.Enabled:=false;
  EditFileName.EditLabel.Enabled:=true;
  ComboBoxTasks.Clear;

  ExtractIni;
  LoadTasksFromIni;
end;

procedure TFormMain.ExtractIni;
var
  res: tresourcestream;
begin
  if fileexists(extractfilepath(application.ExeName) + IniName)=true then
    exit;

  res:=TResourceStream.Create(0, 'INI', 'TEXT');
  try
    try
      res.SaveToFile(extractfilepath(application.ExeName) + IniName);
    except on efcreateerror do
      begin
        showmessage('Could not find or create ini file ' + #13 + 'It is possible that you are running from a read-only location, like a cd.');
        res.Free;
        application.Terminate;
      end;
    end;
  finally
    res.Free;
  end;
end;

procedure TFormMain.MemoLogURLClick(Sender: TObject; const URLText: string;
  Button: TMouseButton);
begin
  shellexec(0, 'open', URLText,'', '', SW_SHOWNORMAL);
end;

procedure TFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  NamesList.Free;
  ItemNamesArray:=nil;
end;

procedure TFormMain.btnOpenClick(Sender: TObject);
begin
  if opendialog1.Execute then
  begin
    ComboBoxTasks.Enabled:=false;
    ComboBoxLevel.Enabled:=false;
    ComboBoxLevel.ItemIndex:=-1;
    EditData.Enabled:=false;
    EditData.EditLabel.Enabled:=true;
    EditData.Text:='';
    EditFileName.Enabled:=false;
    EditFileName.EditLabel.Enabled:=true;

    memoLog.Lines.Clear;
    Tree.Clear;
    NamesList.Clear;
    EditFileName.Text:='';
    TheFile:=tfilestream.Create(Opendialog1.FileName, fmopenread);
    MemoLog.Lines.add('Opened file "' + OpenDialog1.FileName + '"');
    ItemNum:=-1;
  end
  else
    exit;

  try
    if CheckHeader=False then
    begin
      MemoLog.SelAttributes.Style:=[fsBold];
      MemoLog.Lines.add('Not a valid Psychonauts saved game file');
      Exit;
    end;

    NamesList.LoadFromStream(thefile);
    
    if NamesList.Count < 7 then
    begin
      MemoLog.SelAttributes.Style:=[fsBold];
      MemoLog.Lines.add('Not a valid Psychonauts saved game file');
      Exit;
    end;
      
    ReadHeader;
    ParseArray;
    ComboBoxTasks.ItemIndex:=-1;
    ComboBoxTasks.Enabled:=true;
    ComboBoxLevel.Enabled:=true;
    EditFileName.Enabled:=true;
  finally
    thefile.Free;
  end;

end;

procedure TFormMain.btnSaveClick(Sender: TObject);
var
  SaveFile: TFileStream;
  OneByte: byte;
  FourBytes: Longword;
  i, DialogResult: integer;
  FileName, LevelName, TempString: string;
  CurrNode, PrevNode: PVirtualNode;
begin
  //trigger editDataExit to update any changes made
  editData.OnExit(FormMain);

  if ComboBoxLevel.ItemIndex = -1 then
  begin
      MemoLog.SelAttributes.Style:=[fsBold];
      MemoLog.Lines.add('No level selected - please choose a level first.');
    exit;
  end;


  DialogResult:=MessageDlg('Save changes to file?',mtCustom, [mbYes,mbNo], 0);
  case DialogResult of
    mrYes: ;
    mrNo: exit;
  end;

  SaveFile:=TFileStream.Create(opendialog1.FileName, fmcreate);
  try
    //8 blank bytes;
    FourBytes:=0;
    SaveFile.Write(FourBytes, SizeOf(FourBytes));
    FourBytes:=0;
    SaveFile.Write(FourBytes, SizeOf(FourBytes));

    //FileName
    if editFileName.Text = '' then
      FileName:='No name! - 0:00'
    else
      FileName:=editFileName.Text;

    SaveFile.Write(Pointer(FileName)^, length(FileName));
    OneByte:=10; //0A
    SaveFile.write(OneByte, SizeOf(OneByte));

    //Level Name
    LevelName:=lowercase(Levels[ComboBoxLevel.itemindex]);
    SaveFile.Write(Pointer(LevelName)^, length(LevelName));
    OneByte:=10; //0A
    SaveFile.write(OneByte, SizeOf(OneByte));
    
    //Junk data
    for I := low(JunkDataArray) to High(JunkDataArray) do
    begin
      SaveFile.Write(Pointer(JunkDataArray[i])^, length(JunkDataArray[i]));
      OneByte:=10; //0A
      SaveFile.write(OneByte, SizeOf(OneByte));
    end;

    //Filestrings + data
    PrevNode:=Tree.GetFirst;
    TempString:=GetCompleteDataString(PrevNode);

    SaveFile.Write(Pointer(TempString)^, length(TempString));
    OneByte:=10; //0A
    SaveFile.write(OneByte, SizeOf(OneByte));

    for I := 0 to Tree.TotalCount - 2 do
    begin
      CurrNode:=Tree.GetNext(prevnode);
      prevnode:=CurrNode;

      TempString:=GetCompleteDataString(CurrNode);
      SaveFile.Write(Pointer(TempString)^, length(TempString));
      OneByte:=10; //0A
      SaveFile.write(OneByte, SizeOf(OneByte));
    end;

    MemoLog.Lines.Add('Saved changes to file');
  finally
    SaveFile.Free;
  end;

end;

function TFormMain.GetCompleteDataString(Node: PVirtualNode): string;
var
  Data: PMyRec;
begin
  Data := Tree.GetNodeData(Node);

  if Data.TableParent then
    result:='Table|' + Data.Caption
  else
  if Data.TableChild then
    result:=Data.Caption + '|' + Data.Value
  else
  if (Data.TableParent) and (Data.TableChild) = false then
    if data.Value='' then
      result:=Data.Caption
    else
      result:=data.Caption + '|' + data.Value;
      
end;

function TFormMain.CheckHeader: boolean;
begin
  thefile.Position:=0;

  if thefile.Size < 8 then
    result:=false
  else
  if (readdword = 0 ) and (readdword = 0) then
    result:=true
  else
    result:=false;
end;

procedure TFormMain.ComboBoxLevelChange(Sender: TObject);
begin
  MemoLog.Lines.Add('Level changed to: ' + ComboBoxLevel.Text);
end;

procedure TFormMain.ComboBoxLevelDropDown(Sender: TObject);
var
  i, itemwidth: Integer;
begin
  itemwidth:=0;
  comboboxLevel.DropWidth:=1;

  for I := 0 to comboboxLevel.Items.Count - 1 do
    if FormMain.Canvas.TextWidth(comboboxLevel.TextItems[i])  > ItemWidth then
      ItemWidth := FormMain.Canvas.TextWidth(comboboxLevel.textitems[i]);

  comboboxLevel.DropWidth:=itemwidth;
end;

procedure TFormMain.comboboxTasksChange(Sender: TObject);
begin
  if Tree.RootNodeCount=0 then exit;
  if ComboBoxTasks.Items.Count = 0 then exit;

  SelectNode(ItemNamesArray[ComboBoxTasks.itemindex]);
end;

procedure TFormMain.comboboxTasksDropDown(Sender: TObject);
var
  i, itemwidth: Integer;
begin
  itemwidth:=0;
  comboboxTasks.DropWidth:=1;

  for I := 0 to comboboxTasks.Items.Count - 1 do
    if FormMain.Canvas.TextWidth(comboboxTasks.TextItems[i])  > ItemWidth then
      ItemWidth := FormMain.Canvas.TextWidth(comboboxTasks.textitems[i]);

  comboboxTasks.DropWidth:=itemwidth;
end;

procedure TFormMain.EditDataExit(Sender: TObject);
var
  Data: PMyRec;
begin
  if tree.FocusedNode = nil then exit;
  if Tree.RootNodeCount=0 then exit;
  if editData.Enabled=false then exit; //If its a node with no value
  
  Data:=tree.GetNodeData(Tree.FocusedNode);
  if trim(editData.Text) <> Data.Value then
  begin
    MemoLog.Lines.Add('Changed: ' + Data.Caption + ' from: ' + Data.Value + ' to: ' + editData.Text);
    Data.Value:=trim(editData.Text);
  end;
end;

procedure TFormMain.EditFileNameExit(Sender: TObject);
begin
  EditFileName.Text:=trim(editFileName.Text);
end;

procedure TFormMain.ReadHeader;
var
  i, LevelIndex: integer;
begin
  //first 7 items arent table data

  //First item=File Name
  EditFileName.Text:=NamesList[0];

  //Second item = level
  LevelIndex:=StrIndex(NamesList[1], Levels);

  if LevelIndex = -1 then //not there
    ComboBoxLevel.itemindex:=-1
  else //is there
    ComboBoxLevel.ItemIndex:=LevelIndex;


  //Add the junk data to array for saving later
  JunkDataArray[0]:=NamesList[2];
  JunkDataArray[1]:=NamesList[3];
  JunkDataArray[2]:=NamesList[4];
  JunkDataArray[3]:=NamesList[5];
  JunkDataArray[4]:=NamesList[6];

  //delete those lines
  for i := 6 downto 0 do
    NamesList.Delete(i);
end;

procedure TFormMain.treeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  Data: PMyRec;
  CurrNode: PVirtualNode;
begin
  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;

  Data := Sender.GetNodeData(Node);
  //memo1.Lines.Add(Data.Value);
  editData.Text:=Data.Value;

  if Data.Value='' then
  begin
    editData.Text:='<No Value>';
    editData.Enabled:=false;
    editData.EditLabel.Enabled:=true;
  end
  else
    EditData.Enabled:=true;


  //Tasks combobox bit
  if ComboBoxTasks.ItemIndex > -1 then //somethings selected
  begin
    CurrNode:=Tree.FocusedNode;
    if integer(CurrNode.Index) <> TaskNodeIndex then
    begin
      ComboBoxTasks.ItemIndex:=-1;
      TaskNodeIndex:=-1;
    end;
  end;

end;

procedure TFormMain.treeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  Data: PMyRec;
begin
  Data := Sender.GetNodeData(Node);
  // Explicitely free the string, the VCL cannot know that there is one but needs to free
  // it nonetheless. For more fields in such a record which must be freed use Finalize(Data^) instead touching
  // every member individually.
  if Assigned(Data) then
    Finalize(Data^);
end;

procedure TFormMain.treeGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: Integer);
var
  Data: PMyRec;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then
    if Data.TableParent=true then
      ImageIndex:=0
    else
    if Data.TableChild=true then
      ImageIndex:=1
    else
    //Not part of a table structure
    if Data.Value = '' then
      ImageIndex:=2
    else
      ImageIndex:=1;
end;

procedure TFormMain.treeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  Data: PMyRec;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then
    CellText := Data.Caption;
end;

procedure TFormMain.treeInitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
var
  Data: PMyRec;
  ItemStartsWith: string;
  ValueIndex: integer;
begin
  inc(ItemNum); //Holds the index of the Current string in the NamesList array

  Data := Tree.GetNodeData(Node);
  Data.ArrayIndex:= ItemNum;
  Data.OriginalName:=NamesList[ItemNum];
  
  //Check if table in its name - if it is then its a parent table node
  //check if its a child node - if so then child
  //if not child and not table then normal
  if AnsiStartsStr('Table', NamesList[ItemNum]) then
    Data.TableParent:=true
  else
    Data.TableParent:=false;

  if Node.Parent = tree.RootNode then
    Data.TableChild:=false
  else
    Data.TableChild:=true;


  ItemStartsWith:=strbefore('|', NamesList[ItemNum]);


  //If any of these then data doesnt have a value
  if (ItemStartsWith='env') or (ItemStartsWith='movie') or (ItemStartsWith='vault') or (ItemStartsWith='concept') or (ItemStartsWith='Table') then
    Data.Value:=''
  else //extract the value
  begin
    ValueIndex:=StrILastPos('|', NamesList[ItemNum]) + 1;
    Data.Value:=StrRestOf(NamesList[ItemNum], ValueIndex);
  end;

  if Data.Value='' then
  begin
    if ItemStartsWith='Table' then //Remove the table bit from the string
      Data.Caption:=strafter('Table|', NamesList[ItemNum])
    else
      Data.Caption:=NamesList[ItemNum];
  end
  else //Remove the value from end of string
   Data.Caption:=strbefore('|' + Data.Value, NamesList[ItemNum]);

end;


procedure TFormMain.ParseArray;
var
  i, j: integer;
  ParentNode, PrevNode: pvirtualnode;
  IsTableParent, IsTableChild: boolean;
begin
  {for I := 0 to NamesList.Count - 1 do
  begin
    if NamesList[i][length(NamesList[i]) -1] = '|' then
      //memo1.Lines.Add('OIIII*****************************************************');
      memo1.Lines.add(copy(NamesList[i], 0, length(NamesList[i]) -2) + ' VALUE= ' + NamesList[i][length(NamesList[i])])
    else
      Memo1.Lines.add(nameslist[i]);
  end;}

  ParentNode:=nil;
  IsTableChild:=false;
  for I := 0 to NamesList.Count - 1 do
  begin
    if AnsiStartsStr('Table', NamesList[i]) then
    begin
      IsTableParent:=true;
      IsTableChild:=false;
    end
    else
      IsTableParent:=false;

    //Not a table header or inside a table
    if (IsTableParent = false) and (IsTableChild = false) then
      Tree.RootNodeCount:= Tree.RootNodeCount + 1
    else //Table Header
    if IsTableParent = true then
    begin
      //Add the parent node
      Tree.RootNodeCount:= Tree.RootNodeCount + 1;

      //Select the node so that child nodes can be added to it later
      PrevNode:=Tree.GetFirst;
      for j := 0 to Tree.TotalCount - 2 do
      begin
        ParentNode:=Tree.GetNext(prevnode);
        prevnode:=ParentNode;
      end;

      //Next node will be a table child
      IsTableChild:=true;
    end
    else //Inside a table
    if IsTableChild = true then
      tree.AddChild(ParentNode);

  end;

end;

procedure TFormMain.SelectNode(NodeCaption: string);
var
  CurrNode, PrevNode: pvirtualnode;
  i: integer;
  NodeText: string;
  Data: PMyRec;
begin
  PrevNode:=Tree.GetFirst;
  for I := 0 to Tree.TotalCount - 2 do
  begin
    CurrNode:=Tree.GetNext(prevnode);
    prevnode:=CurrNode;

    Data := Tree.GetNodeData(CurrNode);
    NodeText:=Data.Caption;

    if NodeCaption = NodeText then
    begin
      TaskNodeIndex:=CurrNode.Index;
      Tree.FocusedNode:=CurrNode;
      Tree.Selected[CurrNode]:=true;
      Tree.ScrollIntoView(CurrNode, true);
      break;
    end;
  end;


end;

procedure TFormMain.LoadTasksFromIni;
var
  Ini: Tmeminifile;
  Sections: Tstringlist;
  i: integer;
begin
  Ini:=TMemIniFile.Create( extractfilepath(application.ExeName) + IniName);
  try
    Sections:=tstringlist.Create;
    try
      ini.ReadSections(Sections);
      if Sections.count = 0 then
        exit;

      setlength(ItemNamesArray, Sections.Count);

      for I := 0 to Sections.Count - 1 do
      begin
        ComboBoxTasks.Items.Add(ini.ReadString(Sections[i],'Description', 'No description item in ini!'));
        ItemNamesArray[i]:=Ini.ReadString(Sections[i], 'ItemName', '');
      end;

    finally
      Sections.Free;
    end;

  finally
    ini.Free;
  end;
end;

end.
