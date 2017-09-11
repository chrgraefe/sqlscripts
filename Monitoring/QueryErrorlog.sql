IF OBJECT_ID('tempdb..#LOGINS') IS NOT NULL
	DROP TABLE #LOGINS
;

CREATE TABLE #LOGINS
(
LogDate DATETIME
,ProcessInfo VARCHAR(4000)
,[Text] VARCHAR(4000)
);
INSERT INTO #LOGINS
EXEC xp_readerrorlog 0, 1, 'Login';

SELECT
*
FROM #LOGINS
WHERE
	[Text] <> 'Login succeeded for user ''AD\techni''. Connection made using Windows authentication. [CLIENT: <local machine>]'
AND [Text] <> 'Login succeeded for user ''NT-AUTORIT�T\NETZWERKDIENST''. Connection made using Windows authentication. [CLIENT: <local machine>]'
AND [Text] <> 'Login succeeded for user ''AD\SQL_C07_STANDARD''. Connection made using Windows authentication. [CLIENT: <local machine>]'
AND [Text] <> 'Login succeeded for user ''dummy\Administrator''. Connection made using Windows authentication. [CLIENT: <local machine>]'
AND [Text] <> 'Login succeeded for user ''dummy\Administrator''. Connection made using Windows authentication. [CLIENT: 172.24.52.7]'

EXCEPT

SELECT
*
FROM #LOGINS
WHERE
	[Text] LIKE '%QSS_Admin%'
OR  [Text] LIKE '%KV_Admin%'
OR  [Text] LIKE '%Zoll_Admin%'
OR  [Text] LIKE '%AS\dummy%'
;