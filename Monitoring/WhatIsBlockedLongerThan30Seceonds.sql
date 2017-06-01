SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	Waits.wait_duration_ms / 1000 AS WaitInSeconds
	, Blocking.session_id as BlockingSessionId
	, Sess.login_name AS BlockingUser
	, Sess.host_name AS BlockingLocation
	, BlockingSQL.text AS BlockingSQL
	, Blocked.session_id AS BlockedSessionId
	, BlockedSess.login_name AS BlockedUser
	, BlockedSess.host_name AS BlockedLocation
	, BlockedSQL.text AS BlockedSQL
	, DB_NAME(Blocked.database_id) AS DatabaseName
FROM sys.dm_exec_connections AS Blocking
INNER JOIN sys.dm_exec_requests AS Blocked
	ON Blocking.session_id = Blocked.blocking_session_id
INNER JOIN sys.dm_exec_sessions Sess
	ON Blocking.session_id = sess.session_id
INNER JOIN sys.dm_tran_session_transactions st
	ON Blocking.session_id = st.session_id
LEFT OUTER JOIN sys.dm_exec_requests er
	ON st.session_id = er.session_id
		AND er.session_id IS NULL
INNER JOIN sys.dm_os_waiting_tasks AS Waits
	ON Blocked.session_id = Waits.session_id
CROSS APPLY sys.dm_exec_sql_text(Blocking.most_recent_sql_handle) AS BlockingSQL
INNER JOIN sys.dm_exec_requests AS BlockedReq
	ON Waits.session_id = BlockedReq.session_id
INNER JOIN sys.dm_exec_sessions AS BlockedSess
	ON Waits.session_id = BlockedSess.session_id
CROSS APPLY sys.dm_exec_sql_text(Blocked.sql_handle) AS BlockedSQL
WHERE Waits.wait_duration_ms > 30000
ORDER BY WaitInSeconds
