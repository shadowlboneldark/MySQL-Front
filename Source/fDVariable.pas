unit fDVariable;

interface {********************************************************************}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  Forms_Ext, StdCtrls_Ext,
  fSession,
  fBase;

type
  TDVariable = class (TForm_Ext)
    FBCancel: TButton;
    FBOk: TButton;
    FGlobal: TRadioButton;
    FLModify: TLabel;
    FLValue: TLabel;
    FSession: TRadioButton;
    FValue: TEdit;
    GroupBox: TGroupBox_Ext;
    PSQLWait: TPanel;
    procedure FBOkButtonEnable(Sender: TObject);
    procedure FGlobalClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FSessionClick(Sender: TObject);
    procedure FormHide(Sender: TObject);
  private
    procedure FormSessionEvent(const Event: TSSession.TEvent);
    procedure CMChangePreferences(var Message: TMessage); message CM_CHANGEPREFERENCES;
  public
    Session: TSSession;
    Variable: TSVariable;
    function Execute(): Boolean;
  end;

function DVariable(): TDVariable;

implementation {***************************************************************}

{$R *.dfm}

uses
  fPreferences;

var
  FVariable: TDVariable;

function DVariable(): TDVariable;
begin
  if (not Assigned(FVariable)) then
  begin
    Application.CreateForm(TDVariable, FVariable);
    FVariable.Perform(CM_CHANGEPREFERENCES, 0, 0);
  end;

  Result := FVariable;
end;

{ TDVariable ******************************************************************}

procedure TDVariable.CMChangePreferences(var Message: TMessage);
begin
  PSQLWait.Caption := Preferences.LoadStr(882);

  GroupBox.Caption := Preferences.LoadStr(342);
  FLValue.Caption := Preferences.LoadStr(343) + ':';
  FLModify.Caption := Preferences.LoadStr(344) + ':';
  FGlobal.Caption := Preferences.LoadStr(345);
  FSession.Caption := Preferences.LoadStr(346);

  FBOk.Caption := Preferences.LoadStr(29);
  FBCancel.Caption := Preferences.LoadStr(30);
end;

function TDVariable.Execute(): Boolean;
begin
  ShowModal();
  Result := ModalResult = mrOk;
end;

procedure TDVariable.FBOkButtonEnable(Sender: TObject);
begin
  FBOk.Enabled := True;
end;

procedure TDVariable.FGlobalClick(Sender: TObject);
begin
  if (FGlobal.Checked) then FSession.Checked := False;
  FBOkButtonEnable(Sender);
end;

procedure TDVariable.FormSessionEvent(const Event: TSSession.TEvent);
begin
  if ((Event.EventType in [ceItemAltered]) and (Event.CItem is TSVariable)) then
    ModalResult := mrOk
  else if ((Event.EventType = ceAfterExecuteSQL) and (Event.Session.ErrorCode <> 0)) then
  begin
    GroupBox.Visible := True;
    PSQLWait.Visible := not GroupBox.Visible;
  end;
end;

procedure TDVariable.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
  NewVariable: TSVariable;
  UpdateModes: TSVariable.TUpdateModes;
begin
  if ((ModalResult = mrOk) and GroupBox.Visible) then
  begin
    NewVariable := TSVariable.Create(Session.Variables);
    if (Assigned(Variable)) then
      NewVariable.Assign(Variable);

    NewVariable.Value := Trim(FValue.Text);

    UpdateModes := [];
    if (FGlobal.Checked) then Include(UpdateModes, vuGlobal);
    if (FSession.Checked) then Include(UpdateModes, vuSession);

    CanClose := Session.UpdateVariable(Variable, NewVariable, UpdateModes);

    NewVariable.Free();

    GroupBox.Visible := CanClose;
    PSQLWait.Visible := not GroupBox.Visible;
    if (not CanClose) then
      ModalResult := mrNone;

    FBOk.Enabled := False;
  end;
end;

procedure TDVariable.FormHide(Sender: TObject);
begin
  Session.UnRegisterEventProc(FormSessionEvent);
end;

procedure TDVariable.FormShow(Sender: TObject);
begin
  Session.RegisterEventProc(FormSessionEvent);

  Caption := Preferences.LoadStr(842, Variable.Name);

  FValue.Text := Variable.Value;
  FGlobal.Checked := False;
  FSession.Checked := True;

  FGlobal.Visible := Session.ServerVersion >= 40003;
  FSession.Visible := Session.ServerVersion >= 40003;

  FGlobal.Enabled := not Assigned(Session.UserRights) or Session.UserRights.RSuper;

  GroupBox.Visible := True;
  PSQLWait.Visible := not GroupBox.Visible;

  FBOk.Enabled := False;

  ActiveControl := FBCancel;
  ActiveControl := FValue;
end;

procedure TDVariable.FSessionClick(Sender: TObject);
begin
  if (FSession.Checked) then FGlobal.Checked := False;
  FBOkButtonEnable(Sender);
end;

initialization
  FVariable := nil;
end.
