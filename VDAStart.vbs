'Get OU of the computer object
Const HKEY_LOCAL_MACHINE = &H80000002 
Set objSysInfo = CreateObject("ADSystemInfo")
strComputer = objSysInfo.ComputerName

Set objComputer = GetObject("LDAP://" & strComputer)

arrOUs = Split(objComputer.Parent, ",")
arrMainOU = Split(arrOUs(0), "=")

'Wscript.Echo arrMainOU(1)
'Set list of DDC values based on OU name
'Standard Windows 7 is production site
If arrMainOU(1) = "StandardW7" Then

	strComputer = "."
	
	Set objRegistry = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")
	
	strKeyPath = "SOFTWARE\Citrix\VirtualDesktopAgent"
	strValueName = "ListOfDDCs"
	strData = "DDC01.domain.com DDC02.domain.com"
	
	objRegistry.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strData
	
	StartService ".", "BrokerAgent"
End If
'DR W7 is DR site
If arrMainOU(1) = "DRW7" Then
	strComputer = "."
	
	Set objRegistry = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")
	
	strKeyPath = "SOFTWARE\Citrix\VirtualDesktopAgent"
	strValueName = "ListOfDDCs"
	strData = "DDCDR01.domain.com DDCDR02.domain.com"
	
	objRegistry.SetStringValue HKEY_LOCAL_MACHINE, strKeyPath, strValueName, strData
	
	StartService ".", "BrokerAgent"
'wscript.Echo "XenDesktop 7.5"
End If

Sub  RestartServices(Computer, ServiceNames)
	Dim ServiceName, Counter, aServiceNames
	
	'Get the array of service names  
	aServiceNames = Split(ServiceNames, ",")
	  
	'loop services from beginning, stop them 
	For Each ServiceName In aServiceNames 
		StopService Computer, ServiceName, True
	Next 
	
	'loop services from end, start them 
	For  Counter = UBound(aServiceNames) To 0 Step - 1 
		StartService Computer, aServiceNames(Counter), True 
	Next 
End Sub

Sub  StopService(Computer, ServiceName, Wait)
	Dim cimv2, oService, Result
	
	'Get the WMI administration object    
	Set cimv2 = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & _
	Computer & "\root\cimv2")
	
	'Get the service object
	Set oService = cimv2.Get("Win32_Service.Name='" & ServiceName & "'")
	  
	'Check base properties
	If Not oService.Started Then
		' the service is Not started
		'wscript.echo "The service " & ServiceName & " is Not started"
		exit Sub
	End If
	
	If Not oService.AcceptStop Then
		' the service does Not accept stop command
		'wscript.echo "The service " & ServiceName & " does Not accept stop command"
		exit Sub
	End If
	  
	'wscript.echo oService.getobjecttext_
	
	'Stop the service
	Result = oService.StopService
	If 0 <> Result Then
		'wscript.echo "Stop " & ServiceName & " error: " & Result
		exit Sub 
	End If 
	  
	Do While  oService.Started And Wait
		'get the current service state
		Set oService = cimv2.Get("Win32_Service.Name='" & ServiceName & "'")
		
		'wscript.echo Now, "StopService", ServiceName, oService.Started, _
		'oService.State, oService.Status
		Wscript.Sleep 200
	Loop   
End Sub


Sub  StartService(Computer, ServiceName, Wait)
	Dim cimv2, oService, Result
	
	'Get the WMI administration object    
	Set cimv2 = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & _
	Computer & "\root\cimv2")
	
	'Get the service object
	Set oService = cimv2.Get("Win32_Service.Name='" & ServiceName & "'")
	  
	  
	'Path = "winmgmts:{impersonationLevel=impersonate}!\\" & Computer & _
	'  "\root\cimv2:Win32_Service.Name='" & ServiceName & "'" 
	
	'Get the WMI administration object of the service    
	'Set oService = GetObject(Path)
	
	'Check base properties
	If oService.Started Then
		' the service is Not started
		'wscript.echo "The service " & ServiceName & " is started."
		exit Sub
	End If
	  
	'Start the service
	Result = oService.StartService
	If 0 <> Result Then
		'wscript.echo "Start " & ServiceName & " error:" & Result
		exit Sub 
	End If 
	  
	Do While  InStr(1, oService.State, "running", 1) = 0 And Wait 
		'get the current service state
		Set oService = cimv2.Get("Win32_Service.Name='" & ServiceName & "'")
		    
		'wscript.echo Now, "StartService", ServiceName, oService.Started, _
		'oService.State, oService.Status
		Wscript.Sleep 200
	Loop   
End Sub
