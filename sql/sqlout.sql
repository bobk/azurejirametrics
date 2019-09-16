USE [azurejirametrics]
GO
/****** Object:  StoredProcedure [dbo].[metrics_calcWIPMAX]    Script Date: 9/16/2019 2:44:29 PM ******/
DROP PROCEDURE [dbo].[metrics_calcWIPMAX]
GO
/****** Object:  StoredProcedure [dbo].[metrics_calcLEADTIMEAVG]    Script Date: 9/16/2019 2:44:29 PM ******/
DROP PROCEDURE [dbo].[metrics_calcLEADTIMEAVG]
GO
/****** Object:  StoredProcedure [dbo].[metrics_calcISSUESTAKINGNDAYS]    Script Date: 9/16/2019 2:44:29 PM ******/
DROP PROCEDURE [dbo].[metrics_calcISSUESTAKINGNDAYS]
GO
/****** Object:  StoredProcedure [dbo].[metrics_calcISSUESREQUIRINGREWORK]    Script Date: 9/16/2019 2:44:29 PM ******/
DROP PROCEDURE [dbo].[metrics_calcISSUESREQUIRINGREWORK]
GO
/****** Object:  StoredProcedure [dbo].[metrics_calcISSUESNOTUPDATEDNDAYS]    Script Date: 9/16/2019 2:44:29 PM ******/
DROP PROCEDURE [dbo].[metrics_calcISSUESNOTUPDATEDNDAYS]
GO
/****** Object:  Table [dbo].[jira_servers]    Script Date: 9/16/2019 2:44:29 PM ******/
DROP TABLE [dbo].[jira_servers]
GO
/****** Object:  Table [dbo].[jira_projects]    Script Date: 9/16/2019 2:44:29 PM ******/
DROP TABLE [dbo].[jira_projects]
GO
/****** Object:  Table [dbo].[jira_metrics]    Script Date: 9/16/2019 2:44:29 PM ******/
DROP TABLE [dbo].[jira_metrics]
GO
/****** Object:  Table [dbo].[jira_issues]    Script Date: 9/16/2019 2:44:29 PM ******/
DROP TABLE [dbo].[jira_issues]
GO
/****** Object:  Table [dbo].[jira_history]    Script Date: 9/16/2019 2:44:29 PM ******/
DROP TABLE [dbo].[jira_history]
GO
/****** Object:  Table [dbo].[jira_history]    Script Date: 9/16/2019 2:44:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[jira_history](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[history_server_id] [int] NOT NULL,
	[history_project_name] [nvarchar](50) NOT NULL,
	[history_id] [int] NOT NULL,
	[history_author] [nvarchar](50) NOT NULL,
	[history_issuekey] [nvarchar](50) NOT NULL,
	[history_datecreated] [datetime2](7) NOT NULL,
	[history_field] [nvarchar](50) NOT NULL,
	[history_from] [nvarchar](500) NOT NULL,
	[history_fromstring] [nvarchar](500) NOT NULL,
	[history_to] [nvarchar](500) NOT NULL,
	[history_tostring] [nvarchar](500) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[jira_issues]    Script Date: 9/16/2019 2:44:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[jira_issues](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[issue_server_id] [int] NOT NULL,
	[issue_project_name] [nvarchar](50) NOT NULL,
	[issue_issuekey] [nvarchar](50) NOT NULL,
	[issue_status] [nvarchar](50) NOT NULL,
	[issue_assignee] [nvarchar](50) NOT NULL,
	[issue_summary] [nvarchar](500) NOT NULL,
	[issue_datecreated] [datetime2](7) NOT NULL,
	[issue_dateupdated] [datetime2](7) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[jira_metrics]    Script Date: 9/16/2019 2:44:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[jira_metrics](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[metrics_customer_name] [nvarchar](50) NULL,
	[metrics_name1] [nvarchar](50) NOT NULL,
	[metrics_name2] [nvarchar](50) NULL,
	[metrics_key1] [nvarchar](50) NOT NULL,
	[metrics_key2] [nvarchar](50) NULL,
	[metrics_value1] [nvarchar](50) NOT NULL,
	[metrics_value2] [nvarchar](50) NULL,
	[metrics_date] [datetime2](7) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[jira_projects]    Script Date: 9/16/2019 2:44:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[jira_projects](
	[jira_server_id] [int] NOT NULL,
	[jira_project_name] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[jira_servers]    Script Date: 9/16/2019 2:44:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[jira_servers](
	[jira_server_id] [int] IDENTITY(1,1) NOT NULL,
	[jira_server_url] [nvarchar](500) NOT NULL,
	[jira_server_status] [nvarchar](50) NOT NULL,
	[jira_server_customer_name] [nvarchar](50) NOT NULL,
	[jira_server_username] [nvarchar](50) NOT NULL,
	[jira_server_apitoken] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[metrics_calcISSUESNOTUPDATEDNDAYS]    Script Date: 9/16/2019 2:44:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[metrics_calcISSUESNOTUPDATEDNDAYS] 
(@num_issues as int = 3, @num_days as int = 14)

AS
BEGIN
    SET NOCOUNT ON;
	
--  print @num_issues oldest non-Done issues (for each customer_name) that have not been updated in the last @num_days calendar days

--  first, select all issues using a CTE, using row numbering and grouping to get "non-Done" issues ordered by issue_dateupdated, last @num_days for each customer group

	with cte as
    (
        select JS.jira_server_customer_name as jira_server_customer_name, JI.issue_assignee, JI.issue_issuekey, JI.issue_dateupdated,
            ROW_NUMBER() OVER (PARTITION BY JS.jira_server_customer_name ORDER BY JI.issue_dateupdated ASC) as rn,
            DATEDIFF(day, JI.issue_dateupdated, CURRENT_TIMESTAMP) as last_update_days
		from jira_servers JS, jira_issues JI
        where 
			(JS.jira_server_id = JI.issue_server_id) and
			(JI.issue_status in ('To Do', 'In Progress')) and
            (DATEDIFF(day, JI.issue_dateupdated, CURRENT_TIMESTAMP) >= @num_days)
    )
--  that then feeds an INSERT into the metrics table
    insert into jira_metrics (metrics_customer_name, metrics_name1, metrics_name2, metrics_key1, metrics_key2, metrics_value1, metrics_value2, metrics_date)
        select jira_server_customer_name, 'Hygiene:ISSUESNOTUPDATEDNDAYS', NULL, issue_assignee, issue_issuekey, issue_dateupdated, last_update_days, CURRENT_TIMESTAMP from cte
    where (rn <= @num_issues)

END
GO
/****** Object:  StoredProcedure [dbo].[metrics_calcISSUESREQUIRINGREWORK]    Script Date: 9/16/2019 2:44:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE    PROCEDURE [dbo].[metrics_calcISSUESREQUIRINGREWORK] 
(@num_days_back as int = 14)

AS
BEGIN
	SET NOCOUNT ON;

	with cte as
    (
	select JS.jira_server_customer_name as jira_server_customer_name, JI.issue_assignee, JI.issue_issuekey, JI.issue_dateupdated
		from jira_servers JS, jira_issues JI
		where 
            (JS.jira_server_id = JI.issue_server_id) and
            exists 
            (select JH.* from jira_history JH
				where (JH.history_issuekey = JI.issue_issuekey) and
				      ((JH.history_fromstring = 'Done') and (JH.history_tostring = 'In Progress')) and
                      (DATEDIFF(day, JH.history_datecreated, CURRENT_TIMESTAMP) <= @num_days_back)
			)
    )
--  that then feeds an INSERT into the metrics table
    insert into jira_metrics (metrics_customer_name, metrics_name1, metrics_name2, metrics_key1, metrics_key2, metrics_value1, metrics_value2, metrics_date)
        select jira_server_customer_name, 'Hygiene:ISSUESREQUIRINGREWORK', NULL, issue_assignee, issue_issuekey, issue_dateupdated, NULL, CURRENT_TIMESTAMP from cte

END

GO
/****** Object:  StoredProcedure [dbo].[metrics_calcISSUESTAKINGNDAYS]    Script Date: 9/16/2019 2:44:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[metrics_calcISSUESTAKINGNDAYS] 
(@num_issues as int = 3, @num_days as int = 5)

AS
BEGIN
    SET NOCOUNT ON;
	
--  print M oldest non-Done issues (for each customer_name) that have not been updated in the last N calendar days

--  first, select all issues using CTE that then feeds an INSERT into the metrics table

	with cte as
    (
        select JS.jira_server_customer_name as jira_server_customer_name, JI.issue_assignee, JI.issue_issuekey, JI.issue_datecreated,
            ROW_NUMBER() OVER (PARTITION BY JS.jira_server_customer_name ORDER BY JI.issue_datecreated ASC) as rn,
            DATEDIFF(day, JI.issue_datecreated, CURRENT_TIMESTAMP) as last_update_days
		from jira_servers JS, jira_issues JI
        where 
			(JS.jira_server_id = JI.issue_server_id) and
			(JI.issue_status in ('In Progress')) and
            (DATEDIFF(day, JI.issue_datecreated, CURRENT_TIMESTAMP) >= @num_days)
    )
--  for storage
    insert into jira_metrics (metrics_customer_name, metrics_name1, metrics_name2, metrics_key1, metrics_key2, metrics_value1, metrics_value2, metrics_date)
        select jira_server_customer_name, 'Hygiene:ISSUESTAKINGNDAYS', NULL, issue_assignee, issue_issuekey, issue_datecreated, last_update_days, CURRENT_TIMESTAMP from cte
    where (rn <= @num_issues)

END
GO
/****** Object:  StoredProcedure [dbo].[metrics_calcLEADTIMEAVG]    Script Date: 9/16/2019 2:44:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE      PROCEDURE [dbo].[metrics_calcLEADTIMEAVG] 
(@num_days_back as int = 30)

AS
BEGIN
	SET NOCOUNT ON;

--  here we use SUBSELECTs in a cte SELECT to get columns with 
--    the most recent datetime of insertion into a sprint
--    and also the datetime of the same issue being moved to Done
--    only looking at issues whose lastupdate (of any field) was in last @num_days_back days

    with cte as
    (
        select JS.jira_server_customer_name, JI.issue_project_name, JI.issue_issuekey, JI.issue_summary, JI.issue_assignee,
            (           select MAX(JH.history_datecreated) from jira_history JH where 
                        (JH.history_field = 'SPRINT') and
                        (JH.history_fromstring = '') and
                        (JH.history_tostring <> '') and
                        (JI.issue_issuekey = JH.history_issuekey) and
                        (JI.issue_server_id = JH.history_server_id) 
            ) as issue_sprint_insertion,
            (           select MAX(JH.history_datecreated) from jira_history JH where 
                        (JH.history_field = 'STATUS') and
                        (JH.history_fromstring = 'In Progress') and
                        (JH.history_tostring = 'Done') and
                        (JI.issue_issuekey = JH.history_issuekey) and
                        (JI.issue_server_id = JH.history_server_id)
            ) as issue_done

            from jira_servers JS, jira_issues JI
            where 
                (JS.jira_server_id = JI.issue_server_id)
                and (JI.issue_status = 'Done')
                and (DATEDIFF(day, JI.issue_dateupdated, CURRENT_TIMESTAMP) <= @num_days_back)
    )
--  that then feeds an INSERT into the metrics table
    insert into jira_metrics (metrics_customer_name, metrics_name1, metrics_name2, metrics_key1, metrics_key2, metrics_value1, metrics_value2, metrics_date)
        select jira_server_customer_name, 'Hygiene:LEADTIMEAVG', NULL, issue_assignee, issue_issuekey, DATEDIFF(day, issue_sprint_insertion, issue_done), NULL, CURRENT_TIMESTAMP from cte


END
GO
/****** Object:  StoredProcedure [dbo].[metrics_calcWIPMAX]    Script Date: 9/16/2019 2:44:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[metrics_calcWIPMAX] 
(@num_top as int = 1)

AS
BEGIN
    SET NOCOUNT ON;
	
--  print the @num_top Assignees (by customer_name) who have the most WIP

--  first, select all issues using CTE that then feeds an INSERT into the metrics table

	with cte as
    (
        select JS.jira_server_customer_name as jira_server_customer_name, JI.issue_assignee, COUNT(JI.issue_assignee) as count,
            ROW_NUMBER() OVER (PARTITION BY JS.jira_server_customer_name ORDER BY COUNT(JI.issue_assignee) DESC) as rn
--            DATEDIFF(day, JI.issue_dateupdated, CURRENT_TIMESTAMP) as last_update_days
		from jira_servers JS, jira_issues JI
        where 
			(JS.jira_server_id = JI.issue_server_id) and
			(JI.issue_status in ('In Progress')) 
--            (DATEDIFF(day, JI.issue_dateupdated, CURRENT_TIMESTAMP) >= @num_days)
       group by jira_server_customer_name, JI.issue_assignee
    )
--  for storage
    insert into jira_metrics (metrics_customer_name, metrics_name1, metrics_name2, metrics_key1, metrics_key2, metrics_value1, metrics_value2, metrics_date)
        select jira_server_customer_name, 'Hygiene:WIPMAX', NULL, issue_assignee, NULL, count, NULL, CURRENT_TIMESTAMP from cte
      where (rn <= @num_top)

END
GO
