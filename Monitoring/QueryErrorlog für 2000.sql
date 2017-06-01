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
--	[Text] <> 'Login succeeded for user ''SV\techni''. Connection made using Windows authentication. [CLIENT: <local machine>]'
--AND [Text] <> 'Login succeeded for user ''BKU\ChristianCGraefe''. Connection made using Windows authentication. [CLIENT: 172.24.209.92]'
--AND [Text] <> 'Login succeeded for user ''NT-AUTORITÄT\NETZWERKDIENST''. Connection made using Windows authentication. [CLIENT: <local machine>]'
--AND [Text] <> 'Login succeeded for user ''SV\SQL_C07_STANDARD''. Connection made using Windows authentication. [CLIENT: <local machine>]'
--AND [Text] <> 'Login succeeded for user ''CARGOMNZSR11\Administrator''. Connection made using Windows authentication. [CLIENT: <local machine>]'
--AND [Text] <> 'Login succeeded for user ''CARGOMNZSR11\Administrator''. Connection made using Windows authentication. [CLIENT: 172.24.52.7]'
----AND [Text] LIKE '%muss%'
;