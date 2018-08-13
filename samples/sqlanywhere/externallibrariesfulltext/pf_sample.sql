// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability
// of any kind.
//
// You may use, reproduce, modify and distribute this sample code
// without limitation, on the condition that you retain the foregoing
// copyright notice and disclaimer as to the original code.
//
// *******************************************************************

DROP TABLE IF EXISTS dba.text_sample_table
go

if exists (select * from SYS.SYSTEXTCONFIG tc
	    join SYS.SYSUSER u ON (tc.creator = u.user_id)
	where text_config_name = 'prefilter_config'
	and user_name = 'DBA') then
    DROP TEXT CONFIGURATION dba.prefilter_config;
end if
go

CREATE TABLE dba.text_sample_table(
    pk INTEGER DEFAULT AUTOINCREMENT PRIMARY KEY,
    value LONG VARCHAR )
go

GRANT SELECT, INSERT, UPDATE, DELETE ON dba.text_sample_table TO PUBLIC
go

CREATE TEXT CONFIGURATION dba.prefilter_config FROM SYS.default_char
go

ALTER TEXT CONFIGURATION dba.prefilter_config
    PREFILTER EXTERNAL NAME 
	'tag_filter@pf_sample.dll;Unix:tag_filter@libpf_sample.so'
go

CREATE TEXT INDEX sample_tind ON dba.text_sample_table( value )
    CONFIGURATION dba.prefilter_config
go
