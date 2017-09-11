/*
	Zuletzt gesendet Mails aus der Datenbank heraus
 */

SELECT 
  sti.send_request_date
, sti.sent_date
, sti.send_request_user
, sti.recipients
, sti.subject 
, sti.body
FROM msdb.dbo.sysmail_sentitems sti
WHERE sent_date >= DATEADD(dd, -7, getdate());