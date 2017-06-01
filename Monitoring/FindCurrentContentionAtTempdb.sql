With Tasks As 
(
	Select 
	 session_id
	,wait_type
	,wait_duration_ms
	,blocking_session_id
	,resource_description
	,Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) PageID
    From sys.dm_os_waiting_tasks
    Where 
		wait_type Like 'PAGE%LATCH_%'
    And resource_description Like '2:%'
)
Select 
 session_id
,wait_type
,wait_duration_ms
,blocking_session_id
,resource_description
,Case
	When PageID = 1 Or PageID % 8088 = 0 Then 'Is PFS Page'
    When PageID = 2 Or PageID % 511232 = 0 Then 'Is GAM Page'
    When PageID = 3 Or (PageID - 1) % 511232 = 0 Then 'Is SGAM Page'
    Else 'Is Not PFS, GAM, or SGAM page'
 End ResourceType 
From Tasks;