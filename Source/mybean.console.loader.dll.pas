(*
 *	 Unit owner: D10.天地弦
 *	   blog: http://www.cnblogs.com/dksoft
 *
 *   v0.1.1(2014-11-06 21:27:40)
 *     修正checkIsValidLib- bug, 释放时判断是否BPL，bpl按照BPL释放的方式
 *
 *   v0.1.0(2014-08-29 13:00)
 *     修改加载方式(beanMananger.dll-改造)
 *
 *	 v0.0.1(2014-05-17)
 *     + first release
 *
 *
 *)
 
unit mybean.console.loader.dll;

interface

uses
  Windows, SysUtils, Classes, mybean.core.intf, superobject, uSOTools,
  mybean.console.loader;

type
  /// <summary>
  ///   DLL文件管理
  /// </summary>
  TLibFactoryObject = class(TBaseFactoryObject)
  private
    FLibHandle:THandle;
    FlibFileName: String;
  private
    procedure doInitalizeBeanFactory;

    procedure doCreatePluginFactory;

    procedure doInitialize;
    procedure SetlibFileName(const Value: String);
  public
    procedure checkInitialize; override;

    procedure cleanup;override;

    function checkIsValidLib:Boolean; override;

    /// <summary>
    ///   根据beanID获取插件
    /// </summary>
    function getBean(pvBeanID:string): IInterface; override;

    /// <summary>
    ///   释放Dll句柄
    /// </summary>
    procedure doFreeLibrary;

    /// <summary>
    ///   加载dll文件
    /// </summary>
    function checkLoadLibrary(pvRaiseIfNil: Boolean = true): Boolean;

    /// <summary>
    ///   DLL文件
    /// </summary>
    property libFileName: String read FlibFileName write SetlibFileName;
  end;

implementation

procedure TLibFactoryObject.doCreatePluginFactory;
var
  lvFunc:function:IBeanFactory; stdcall;
begin
  @lvFunc := GetProcAddress(FLibHandle, PChar('getBeanFactory'));
  if (@lvFunc = nil) then
  begin
    raise Exception.CreateFmt('非法的Plugin模块文件(%s),找不到入口函数(getBeanFactory)', [self.FlibFileName]);
  end;
  FBeanFactory := lvFunc;
end;

procedure TLibFactoryObject.doFreeLibrary;
begin
  FBeanFactory := nil;
  if FLibHandle <> 0 then
  begin
    if LowerCase(ExtractFileExt(FlibFileName)) = '.bpl' then
    begin
      UnloadPackage(FLibHandle);
    end else
    begin
      FreeLibrary(FLibHandle);
    end;

  end;
end;

procedure TLibFactoryObject.doInitalizeBeanFactory;
var
  lvFunc:procedure(appContext: IApplicationContext; appKeyMap: IKeyMap); stdcall;
begin
  @lvFunc := GetProcAddress(FLibHandle, PChar('initializeBeanFactory'));
  if (@lvFunc = nil) then
  begin
    raise Exception.CreateFmt(
      '非法的Plugin模块文件(%s),找不到入口函数(initializeBeanFactory)',
      [self.FlibFileName]);
  end;
  lvFunc(appPluginContext, applicationKeyMap);
end;

procedure TLibFactoryObject.doInitialize;
begin
  doInitalizeBeanFactory;
  doCreatePluginFactory;
  FbeanFactory.checkInitalize;
end;

procedure TLibFactoryObject.checkInitialize;
var
  lvConfigStr, lvBeanID:AnsiString;
  lvBeanConfig:ISuperObject;
  i: Integer;
begin
  if FbeanFactory = nil then
  begin
    checkLoadLibrary;

    //将配置传入到beanFactory中
    for i := 0 to FConfig.A['list'].Length-1 do
    begin
      lvBeanConfig := FConfig.A['list'].O[i];
      lvBeanID := AnsiString(lvBeanConfig.S['id']);
      lvConfigStr := AnsiString(lvBeanConfig.AsJSon(false, false));

      //配置单个bean
      FbeanFactory.configBean(PAnsiChar(lvBeanID), PAnsiChar(lvConfigStr));
    end;
  end;

  //避免提前释放
  lvConfigStr := '';
  lvBeanID:= '';
end;

function TLibFactoryObject.checkIsValidLib: Boolean;
var
  lvFunc:procedure(appContext: IApplicationContext; appKeyMap: IKeyMap); stdcall;
  lvLibHandle:THandle;
  lvIsBpl:Boolean;
begin
  if FLibHandle = 0 then
  begin
    lvIsBpl :=LowerCase(ExtractFileExt(FlibFileName)) = '.bpl';
    if lvIsBpl then
    begin
      lvLibHandle := LoadPackage(FlibFileName);
    end else
    begin
      lvLibHandle := LoadLibrary(PChar(FlibFileName));
    end;


    if lvLibHandle <> 0 then
    begin
      try
        @lvFunc := GetProcAddress(lvLibHandle, PChar('initializeBeanFactory'));
        result := (@lvFunc <> nil);
      finally
        if lvIsBpl then
        begin
          UnloadPackage(lvLibHandle);
        end else
        begin
          FreeLibrary(lvLibHandle);
        end;
      end;
    end else
    begin
      Result := false;
    end;
  end else
  begin   // 已经成功加载
    Result := true;
  end;
end;

function TLibFactoryObject.checkLoadLibrary(pvRaiseIfNil: Boolean = true):
    Boolean;
begin
  if FLibHandle <> 0 then
  begin
    Result := true;
    Exit;
  end;
  if not FileExists(FlibFileName) then
  begin
    if pvRaiseIfNil then
    begin
      raise Exception.Create('文件[' + FlibFileName + ']未找到!');
    end;
    Result := false;
  end else
  begin
    if LowerCase(ExtractFileExt(FlibFileName)) = '.bpl' then
    begin
      FLibHandle := LoadPackage(FlibFileName);
    end else
    begin
      FLibHandle := LoadLibrary(PChar(FlibFileName));
    end;

    Result := FLibHandle <> 0;
    if not Result then RaiseLastOSError;

    if Result then doInitialize;
  end;
end;

procedure TLibFactoryObject.cleanup;
begin
  doFreeLibrary;
end;

function TLibFactoryObject.getBean(pvBeanID:string): IInterface;
begin
  result := inherited getBean(pvBeanID);
end;

procedure TLibFactoryObject.SetlibFileName(const Value: String);
begin
  FlibFileName := Value;
  Fnamespace := FlibFileName;
end;

end.
