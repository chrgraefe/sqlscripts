select * from syslogins sl
join 
sys.sql_logins sql
 on sl.sid=sql.sid
where is_disabled=1