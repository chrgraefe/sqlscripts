IF OBJECT_ID('tempdb..#LOGINS') IS NOT NULL
	DROP TABLE #LOGINS
;

CREATE TABLE #LOGINS
(
 ERRORLOG VARCHAR(4000)
,ContinuationRow INT
);

INSERT INTO #LOGINS
EXEC xp_readerrorlog;

SELECT
*
FROM #LOGINS
--WHERE
--	[Text] <> 'Login succeeded for user ''SV\t123''. Connection made using Windows authentication. [CLIENT: <local machine>]'
--AND [Text] <> 'Login succeeded for user ''AD\123''. Connection made using Windows authentication. [CLIENT: ]'
--AND [Text] <> 'Login succeeded for user ''NT-AUTORIT�T\NETZWERKDIENST''. Connection made using Windows authentication. [CLIENT: <local machine>]'
--AND [Text] <> 'Login succeeded for user ''SV\SQL_C07_STANDARD''. Connection made using Windows authentication. [CLIENT: <local machine>]'
--AND [Text] <> 'Login succeeded for user ''dummy\Administrator''. Connection made using Windows authentication. [CLIENT: <local machine>]'
--AND [Text] <> 'Login succeeded for user ''dummy\Administrator''. Connection made using Windows authentication. []'
----AND [Text] LIKE '%muss%'
;