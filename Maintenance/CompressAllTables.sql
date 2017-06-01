EXEC sp_MSforeachtable 
     @command1="PRINT 'Starting compressing ' + CONVERT(VARCHAR(MAX), GETDATE(), 120) + ' ?'" 
    ,@command2="PRINT 'Compressing table....' ALTER TABLE ? REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)" 
    ,@command3="PRINT 'Finished compressing ' + CONVERT(VARCHAR(MAX), GETDATE(), 120) + ' ?'"