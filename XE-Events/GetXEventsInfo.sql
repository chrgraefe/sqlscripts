SELECT 
  p.name AS package
, c.event
, k.keyword
, c.channel
, c.description
FROM
(
	SELECT 
	  event_package=o.package_guid
	, o.description
	, event=c.object_name
	, channel=v.map_value
	FROM sys.dm_xe_objects o
		   LEFT JOIN sys.dm_xe_object_columns c ON o.name = c.object_name
		   INNER JOIN sys.dm_xe_map_values v ON c.type_name = v.name
				  AND c.column_value = cast(v.map_key AS nvarchar)
	WHERE object_type='event' AND (c.name = 'channel' OR c.name IS NULL)
) c left join
(
       SELECT event_package=c.object_package_guid, event=c.object_name,
              keyword=v.map_value
       FROM sys.dm_xe_object_columns c INNER JOIN sys.dm_xe_map_values v
       ON c.type_name = v.name AND c.column_value = v.map_key
              AND c.type_package_guid = v.object_package_guid
       INNER JOIN sys.dm_xe_objects o ON o.name = c.object_name
              AND o.package_guid=c.object_package_guid
       WHERE object_type='event' AND c.name = 'keyword'
) k
ON
k.event_package = c.event_package AND (k.event = c.event OR k.event IS NULL)
INNER JOIN sys.dm_xe_packages p ON p.guid=c.event_package
WHERE (p.capabilities IS NULL OR p.capabilities & 1 = 0)
ORDER BY 1, 2