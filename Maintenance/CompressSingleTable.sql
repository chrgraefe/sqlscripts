USE Lfg;
GO

ALTER TABLE LFG.T_PROD_STATUS_TAGE_ALL REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE); 