unit uAppPluginContext;

interface

uses
  uIAppliationContext, uIBeanFactory;


/// <summary>
///   获取IApplictionContext接口, 由beanMananger提供，单实例
///     负责创建和管理bean
/// </summary>
function appPluginContext: IApplicationContext; stdcall; external
    'beanManager.dll';

/// <summary>
///    执行清理工作
///     在app退出的时候调用
/// </summary>
procedure appContextCleanup; stdcall; external 'beanManager.dll';

/// <summary>
///   注册beanFactory到appPluginContext中，
///     可以在没有的DLL情况下也可以使用插件功能
/// </summary>
function registerFactoryObject(const pvBeanFactory:IBeanFactory;
  const pvNameSapce:PAnsiChar): Integer; stdcall; external 'beanManager.dll';


/// <summary>
///   主程序调用，其他插件请勿调用,封装成函数调用避免临时引用接口
/// </summary>
procedure applicationContextIntialize(pvLoadLib:Boolean);

/// <summary>
///   主程序调用，其他插件请勿调用,封装成函数调用避免临时引用接口
/// </summary>
procedure applicationContextFinalize;

implementation

procedure applicationContextIntialize(pvLoadLib:Boolean);
begin
  appPluginContext.checkInitialize(pvLoadLib);
end;

procedure applicationContextFinalize;
var
  lvIntf:IApplicationContext;
begin
  lvIntf := appPluginContext;
  lvIntf.checkFinalize;
  lvIntf := nil;
  appContextCleanup;
end;


end.
