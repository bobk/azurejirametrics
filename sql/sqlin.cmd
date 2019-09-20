rem TODO: change this to work with an ODBC-style connection string, how?
set SQLOUT=.\sqlout.sql
sqlcmd.exe --connection-string %AZUREJIRAMETRICS_CONNSTRING% -i %SQLOUT%
