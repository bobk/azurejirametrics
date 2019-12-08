
# http://github.com/bobk/azurejirametrics
#
# sample python code that demonstrates:
#    - basic use of jira-python library https://github.com/pycontribs/jira
#    - basic use of pyodbc library https://github.com/mkleehammer/pyodbc
#    - storage of multiple Jira servers, credentials and projects in simple SQL DB tables
#    - iteration through those Jira projects to collect various basic data sets
#    - execution of SQL SPs that create useful metrics based on those data sets
#    - conversion of timestamps as needed
#    - check the above repo for further documentation, DDL and SP scripts, and related Azure ARM templates
#

from jira import JIRA 
import pyodbc
import time
from datetime import datetime
import os 

def CSVformat(str_in):
	"""
	removes certain characters from fields returned by Jira requests, in order to facilitate insertion into SQL tables
	would need to be written differently for a production application, to handle escape characters etc. more intelligently

	parameters:
	str_in (string): the string from Jira that needs characters removed

	returns:
	string: the string with characters removed
	"""
	str_out = str(str_in).strip().replace(",", "\\,")

	return str_out

def JIRATOSQLdatetimeformat(datetime_in):
	"""
	removes certain characters from fields returned by Jira requests, in order to facilitate insertion into SQL tables
	would need to be written differently for a production application, to handle escape characters etc. more intelligently

	parameters:
	str_in (string): the string from Jira that needs characters removed

	returns:
	string: the string with characters removed
	"""
	datetime_out = datetime.strptime(datetime_in, "%Y-%m-%dT%H:%M:%S.%f%z").strftime("%Y-%m-%d %H:%M:%S")

	return datetime_out

#   the following environment variable needs to be defined prior to executing the script
#   using SQL authentication was done simply for demo purposes
#
#   examples (for Windows):
#       set AZUREJIRAMETRICS_CONNSTRING="DRIVER={ODBC Driver 17 for SQL Server};SERVER=myserver;DATABASE=mydatabase;UID=myuid;PWD=mypwd"
#
#   the above envvar is also used by the sqlout.cmd script that applies SQL schema changes to the target DB as part of Azure deployment
#
#   TODO: this method of storing credentials is not the best - SQL integrated authentication is a better choice
connstring = "DRIVER={ODBC Driver 17 for SQL Server};" + os.environ["AZUREJIRAMETRICS_CONNSTRING"]

#   connect to the SQL DB in order to retrieve Jira server/project info - that info should have 
#   already been populated manually into those tables (jira_servers and jira_projects)
#   TODO: add simple error checking/exception handling for blank/invalid values for the above
cnxn = pyodbc.connect(connstring)

#   now first start iterating through list of servers (contain 'ACTIVE' in jira_server_status column)
#   TODO: add error checking for blank/missing values, or servers that do not exist, etc. 
servercursor = cnxn.cursor()
servercursor.execute("SELECT * from jira_servers where (jira_server_status in ('ACTIVE'))")
serverrows = servercursor.fetchall()
for serverrow in serverrows:

#   for each Jira target server, create a connection object
	options = { "server":serverrow.jira_server_url }
	jira = JIRA(options, basic_auth=(serverrow.jira_server_username, serverrow.jira_server_apitoken))    # a username/password tupl
#	for Jira Cloud, it's a user email plus an API token generated under that user (for Jira Cloud you can't use login names)
#   for Jira Server, it's a login name plus the password for that login (Jira Server does not support API tokens)
	print("connecting to server " + serverrow.jira_server_url + " as " + serverrow.jira_server_username)

#   then get the list of the (identified) projects on that server, and iterate through each project	
	projectcursor = cnxn.cursor()
	projectcursor.execute("SELECT * from jira_projects where (jira_server_id = " + str(serverrow.jira_server_id) + ")")
	projectrows = projectcursor.fetchall()
	for projectrow in projectrows:

#   for each Jira project, first get all the issues for that project (default behavior of .search_issues() is to get all issues, in batches, due to Jira REST requirements)
#   can be overridden with maxResults=N
		issues = jira.search_issues("project=" + projectrow.jira_project_name, expand="changelog",startAt=0)

#	once we have that list of issues for that project, delete all of the existing issues and history in the DB tables, for that project
#   TODO: error checking around "did we actually retrieve a valid set of issues, before we delete existing?"
		tablecursor = cnxn.cursor()
		tablecursor.execute("DELETE from dbo.jira_issues where (issue_project_name=\'" + projectrow.jira_project_name + "\' and issue_server_id=\'" + str(serverrow.jira_server_id) + "\')")
		cnxn.commit()
		tablecursor.execute('DELETE from dbo.jira_history where (history_project_name=\'' + projectrow.jira_project_name + '\' and history_server_id=\'' + str(serverrow.jira_server_id) + '\')')
		cnxn.commit()

#   now iterate through all issues, printing the fields for each one (TODO: replace print statements with calls to logging.* later)
		for issue in issues:
			print("  " + CSVformat(issue.fields.project), end=",")
			print(CSVformat(issue), end=",")
			print(CSVformat(issue.fields.issuetype), end=",")
			print(CSVformat(issue.fields.summary), end=",")
			print(CSVformat(issue.fields.status), end=",")
			print(CSVformat(issue.fields.priority), end=",")
			
			print(CSVformat(issue.fields.assignee), end=",")
			print(CSVformat(issue.fields.creator), end=",")
			print(CSVformat(issue.fields.reporter), end=",")

			print(CSVformat(issue.fields.duedate), end=",")
			print(CSVformat(issue.fields.resolution), end=",")
			print(CSVformat(issue.fields.resolutiondate), end=",")

#   here we need to convert from the returned Jira ISO8601 datetime format that includes a T and a timezone offset, to a local datetime, to match datetime2 (yes SQL has datetimeoffset I know)
			created = JIRATOSQLdatetimeformat(issue.fields.created)
			print(str(created), end=",")
			updated = JIRATOSQLdatetimeformat(issue.fields.updated)
			print(str(updated))

#	insert each issue into target SQL DB using standard SQL DML INSERT
#   assumes a CONVERT()able SQL date format like datetimeoffset
#	TODO: replace this with pyodbc .executemany() later
			tablecursor.execute('INSERT into dbo.jira_issues values (' + str(serverrow.jira_server_id) + ',\'' + projectrow.jira_project_name + '\',\'' + CSVformat(issue) + '\',\'' + 
			                                                             CSVformat(issue.fields.status) + '\',\'' + CSVformat(issue.fields.assignee) + '\',\'' + CSVformat(issue.fields.summary) + '\',\'' + str(created) + '\',\'' + str(updated) + '\')')
			cnxn.commit()

#   now iterate through all history records for that issue (jira-python calls the root object ".changelog")
			changelog = issue.changelog
			for history in changelog.histories:
				for item in history.items:
#   again printing the key fields for each one (TODO: replace print statements with calls to logging.* later)
#	since DESCRIPTION can sometimes get messy, only print the from and to values for fields other than DESCRIPTION
					print('    ' + JIRATOSQLdatetimeformat(history.created) + ':   ' + str(history.author.name) + ' changed ' + item.field.upper(), end="")
					if (item.field.upper() != 'DESCRIPTION'):
						print(' from ' + str(item.fromString)[:100] + ' to ' + str(item.toString)[:100], end="")
					print()
					tablecursor.execute('INSERT into dbo.jira_history values (' + str(serverrow.jira_server_id) + ',\'' + CSVformat(issue.fields.project) + '\',\'' + 
																				  str(history.id) + '\',\'' + CSVformat(history.author.name) + '\',\'' + CSVformat(issue) + '\',\'' + JIRATOSQLdatetimeformat(history.created) + '\',\'' + 
																				  CSVformat(item.field.upper()) + '\',\'' + CSVformat(str(item.fromString)[:100]) + '\',\'' + 
																				  CSVformat(str(item.fromString)) + '\',\'' + CSVformat(str(item.to)) + '\',\''+CSVformat(str(item.toString) + '\')')
#   and then insert it																				  
					cnxn.commit()

		tablecursor.close()

	projectcursor.close()

#   we now have all the Jira data we need from that server and are done talking to it
#	be a good citizen and close the Jira connection to that server, before we open another one to the next
	jira.close()

#   now completely clear the metrics table
#   TODO: add a flag or variable to the code and to the SPs that lets me tell each SP whether to clear its own metrics first, from jira_metrics
servercursor.execute('DELETE from dbo.jira_metrics');cnxn.commit()
#   and then call each SQL SP that calculates metrics - each SP will write the metrics it calculates to the jira_metrics table on its own
servercursor.execute('{CALL metrics_calcWIPMAX}')
cnxn.commit()
servercursor.execute('{CALL metrics_calcISSUESREQUIRINGREWORK}')
cnxn.commit()
servercursor.execute('{CALL metrics_calcISSUESTAKINGNDAYS}')
cnxn.commit()
servercursor.execute('{CALL metrics_calcISSUESNOTUPDATEDNDAYS}')
cnxn.commit()
servercursor.execute('{CALL metrics_calcLEADTIMEAVG}')
cnxn.commit()

cnxn.close()
