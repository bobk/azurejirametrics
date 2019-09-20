set SQLOUT=.\sqlout.sql
cmd.exe /c "mssql-scripter --connection-string %AZUREJIRAMETRICS_CONNSTRING% --script-drop-create --include-objects dbo.jira_issues    >> %SQLOUT%"
cmd.exe /c "mssql-scripter --connection-string %AZUREJIRAMETRICS_CONNSTRING% --script-drop-create --include-objects dbo.jira_history   >> %SQLOUT%"
cmd.exe /c "mssql-scripter --connection-string %AZUREJIRAMETRICS_CONNSTRING% --script-drop-create --include-objects dbo.jira_metrics   >> %SQLOUT%"

cmd.exe /c "mssql-scripter --connection-string %AZUREJIRAMETRICS_CONNSTRING% --script-drop-create --include-objects dbo.metrics_calcISSUESNOTUPDATEDNDAYS   >> %SQLOUT%"
cmd.exe /c "mssql-scripter --connection-string %AZUREJIRAMETRICS_CONNSTRING% --script-drop-create --include-objects dbo.metrics_calcISSUESREQUIRINGREWORK   >> %SQLOUT%"
cmd.exe /c "mssql-scripter --connection-string %AZUREJIRAMETRICS_CONNSTRING% --script-drop-create --include-objects dbo.metrics_calcISSUESTAKINGNDAYS       >> %SQLOUT%"
cmd.exe /c "mssql-scripter --connection-string %AZUREJIRAMETRICS_CONNSTRING% --script-drop-create --include-objects dbo.metrics_calcLEADTIMEAVG             >> %SQLOUT%"
cmd.exe /c "mssql-scripter --connection-string %AZUREJIRAMETRICS_CONNSTRING% --script-drop-create --include-objects dbo.metrics_calcWIPMAX                  >> %SQLOUT%"
