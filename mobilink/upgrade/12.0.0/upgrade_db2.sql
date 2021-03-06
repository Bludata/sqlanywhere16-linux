
--
-- Upgrade the MobiLink Server system tables and stored procedures in
-- an IBM DB2 UDB consolidated database.
--


--
-- Fill in your own connection info in the following connect statement.
--
connect to DB2Database~

--
-- Add new tables for user authentication using LDAP servers
--
create table ml_ldap_server (
    ldsrv_id		integer		not null generated by default as identity
			(start with 1, increment by 1),
    ldsrv_name		varchar( 128 )	not null unique,
    search_url		varchar( 1024 )	not null,
    access_dn		varchar( 1024 )	not null,
    access_dn_pwd	varchar( 256 )	not null,
    auth_url		varchar( 1024 )	not null,
    num_retries		smallint	default 3,
    timeout		integer		default 10,
    start_tls		smallint	default 0,
    primary key ( ldsrv_id ) ) 
~

create table ml_trusted_certificates_file (
    file_name		varchar( 1024 ) not null ) 
~

create table ml_user_auth_policy (
    policy_id			integer		not null generated by default as identity
				(start with 1, increment by 1),
    policy_name			varchar( 128 )	not null unique,
    primary_ldsrv_id		integer		not null,
    secondary_ldsrv_id		integer,
    ldap_auto_failback_period	integer		default 900,
    ldap_failover_to_std	smallint	default 1,
    foreign key( primary_ldsrv_id ) references ml_ldap_server( ldsrv_id ),
    foreign key( secondary_ldsrv_id ) references ml_ldap_server( ldsrv_id ),
    primary key( policy_id ) ) 
~

--
-- Alter the ml_user table to add two new columns
--
alter table ml_user add policy_id integer null
    references ml_user_auth_policy( policy_id )
~ 

alter table ml_user add user_dn varchar( 1024 )
~ 

--
-- Alter the ml_database table to add two new columns
--
alter table ml_database add seq_id varchar(16) for bit data
~

alter table ml_database add seq_uploaded integer not null default 0
~

--
-- Add new stored procedures for user authentication using LDAP servers
--
create procedure ml_add_ldap_server ( 
    in p_ldsrv_name	varchar( 128 ),
    in p_search_url    	varchar( 1024 ),
    in p_access_dn    	varchar( 1024 ),
    in p_access_dn_pwd	varchar( 256 ),
    in p_auth_url	varchar( 1024 ),
    in p_conn_retries	smallint,
    in p_conn_timeout	smallint,
    in p_start_tls	smallint ) 
MODIFIES SQL DATA 
CALLED ON NULL INPUT
LANGUAGE SQL
COMMIT ON RETURN NO
begin
    declare v_sh_url	varchar( 1024 );
    declare v_as_dn	varchar( 1024 );
    declare v_as_pwd	varchar( 256 );
    declare v_au_url	varchar( 1024 );
    declare v_timeout	smallint;
    declare v_retries	smallint;
    declare v_tls	smallint;
    declare v_count	integer;
    declare v_ldsrv_id	integer;
    if p_ldsrv_name is not null then
	if p_search_url is null and
	    p_access_dn is null and
	    p_access_dn_pwd is null and
	    p_auth_url is null and
	    p_conn_timeout is null and
	    p_conn_retries is null and
	    p_start_tls is null then
	    
	    -- delete the server if it is not used
	    if not exists ( select * from ml_ldap_server s, ml_user_auth_policy p
		    where ( s.ldsrv_id = p.primary_ldsrv_id or
			    s.ldsrv_id = p.secondary_ldsrv_id ) and
			    s.ldsrv_name = p_ldsrv_name ) then
		delete from ml_ldap_server where ldsrv_name = p_ldsrv_name; 
	    end if;
	else
	    if not exists ( select * from ml_ldap_server
				where ldsrv_name = p_ldsrv_name ) then
		-- add a new ldap server
		if p_conn_timeout is null then
		    set v_timeout = 10;
		else
		    set v_timeout = p_conn_timeout;
		end if;
		if p_conn_retries is null then
		    set v_retries = 3;
		else
		    set v_retries = p_conn_retries;
		end if;
		if p_start_tls is null then
		    set v_tls = 0;
		else
		    set v_tls = p_start_tls;
		end if;
		
		insert into ml_ldap_server ( ldsrv_name, search_url,
			access_dn, access_dn_pwd, auth_url,
			timeout, num_retries, start_tls )
		    values( p_ldsrv_name, p_search_url,
			    p_access_dn, p_access_dn_pwd,
			    p_auth_url, v_timeout, v_retries, v_tls );
	    else
		-- update the ldat server info
		select search_url, access_dn, access_dn_pwd,
			auth_url, timeout, num_retries, start_tls
			into
			v_sh_url, v_as_dn, v_as_pwd,
			v_au_url, v_timeout, v_retries, v_tls
		    from ml_ldap_server where ldsrv_name = p_ldsrv_name;
		    
		if p_search_url is not null then
		    set v_sh_url = p_search_url;
		end if;
		if p_access_dn is not null then
		    set v_as_dn = p_access_dn;
		end if;
		if p_access_dn_pwd is not null then
		    set v_as_pwd = p_access_dn_pwd;
		end if;
		if p_auth_url is not null then
		    set v_au_url = p_auth_url;
		end if;
		if p_conn_timeout is not null then
		    set v_timeout = p_conn_timeout;
		end if;
		if p_conn_retries is not null then
		    set v_retries = p_conn_retries;
		end if;
		if p_start_tls is not null then
		    set v_tls = p_start_tls;
		end if;
		    
		update ml_ldap_server set
			search_url = v_sh_url,
			access_dn = v_as_dn,
			access_dn_pwd = v_as_pwd,
			auth_url = v_au_url,
			timeout = v_timeout,
			num_retries = v_retries,
			start_tls = v_tls
		where ldsrv_name = p_ldsrv_name;
	    end if;
	end if;
    end if;
end
~

create procedure ml_add_certificates_file (
    in p_file_name	varchar( 1024 ) )
MODIFIES SQL DATA 
CALLED ON NULL INPUT
LANGUAGE SQL
COMMIT ON RETURN NO
begin
    if p_file_name is not null then
	delete from ml_trusted_certificates_file;
	insert into ml_trusted_certificates_file ( file_name )
	    values( p_file_name );
    end if;
end
~

create procedure ml_add_user_auth_policy (
    in p_policy_name			varchar( 128 ),
    in p_primary_ldsrv_name		varchar( 128 ),
    in p_secondary_ldsrv_name		varchar( 128 ),
    in p_ldap_auto_failback_period	integer,
    in p_ldap_failover_to_std		integer )
MODIFIES SQL DATA 
CALLED ON NULL INPUT
LANGUAGE SQL
COMMIT ON RETURN NO
begin
    declare v_pldsrv_id	integer;
    declare v_sldsrv_id	integer;
    declare v_pid	integer;
    declare v_sid	integer;
    declare v_period	integer;
    declare v_failover	integer;
    declare v_error	integer;
    declare v_msg	varchar( 1024 );
    
    if p_policy_name is not null then
	if p_primary_ldsrv_name is null and 
	    p_secondary_ldsrv_name is null and 
	    p_ldap_auto_failback_period is null and 
	    p_ldap_failover_to_std is null then
	    
	    -- delete the policy name if not used
	    if not exists ( select * from ml_user u, ml_user_auth_policy p
				where u.policy_id = p.policy_id and
				      p.policy_name = p_policy_name ) then
		delete from ml_user_auth_policy
		    where policy_name = p_policy_name;
	    end if;
	elseif p_primary_ldsrv_name is null then
	    -- error
	    set v_msg = 'The primary LDAP server cannot be NULL.';
	    signal SQLSTATE '76001' set MESSAGE_TEXT = v_msg;
	else
	    set v_error = 0;
	    if p_primary_ldsrv_name is not null then
		select ldsrv_id into v_pldsrv_id from ml_ldap_server
				where ldsrv_name = p_primary_ldsrv_name;
		if v_pldsrv_id is null then
		    set v_error = 1;
		    set v_msg = 'Primary LDAP server "' CONCAT p_primary_ldsrv_name CONCAT '" is not defined.';
		    signal SQLSTATE '76002' set MESSAGE_TEXT = v_msg;
		end if;
	    else
		set v_pldsrv_id = null;
	    end if;
	    if p_secondary_ldsrv_name is not null then
		select ldsrv_id into v_sldsrv_id from ml_ldap_server
				where ldsrv_name = p_secondary_ldsrv_name;
		if v_sldsrv_id is null then
		    set v_error = 1;
		    set v_msg = 'Secondary LDAP server "' CONCAT p_secondary_ldsrv_name CONCAT '" is not defined.';
		    signal SQLSTATE '76003' set MESSAGE_TEXT = v_msg;
		end if;
	    else
		set v_sldsrv_id = null;
	    end if;
	    if v_error = 0 then
		if not exists ( select * from ml_user_auth_policy
				where policy_name = p_policy_name ) then
		    if p_ldap_auto_failback_period is null then
			set v_period = 900;
		    else
			set v_period = p_ldap_auto_failback_period;
		    end if;
		    if p_ldap_failover_to_std is null then
			set v_failover = 1;
		    else
			set v_failover = p_ldap_failover_to_std;
		    end if;
		    
		    -- add a new user auth policy
		    insert into ml_user_auth_policy
			( policy_name, primary_ldsrv_id, secondary_ldsrv_id,
			  ldap_auto_failback_period, ldap_failover_to_std )
			values( p_policy_name, v_pldsrv_id, v_sldsrv_id,
				v_period, v_failover );
		else
		    select primary_ldsrv_id, secondary_ldsrv_id,
			    ldap_auto_failback_period, ldap_failover_to_std
			    into
			    v_pid, v_sid, v_period, v_failover
			from ml_user_auth_policy where policy_name = p_policy_name;
    
		    if v_pldsrv_id is not null then
			set v_pid = v_pldsrv_id;
		    end if;
		    if v_sldsrv_id is not null then
			set v_sid = v_sldsrv_id;
		    end if;
		    if p_ldap_auto_failback_period is not null then
			set v_period = p_ldap_auto_failback_period;
		    end if;
		    if p_ldap_failover_to_std is not null then
			set v_failover = p_ldap_failover_to_std;
		    end if;

		    -- update the user auth policy
		    update ml_user_auth_policy set
				primary_ldsrv_id = v_pid,
				secondary_ldsrv_id = v_sid,
				ldap_auto_failback_period = v_period,
				ldap_failover_to_std = v_failover
			where policy_name = p_policy_name;
		end if;
	    end if;
	end if;
    end if;
end
~

--
-- Recreate the ml_add_user stored procedure
--
drop procedure ml_add_user
~

create procedure ml_add_user (
    in p_user		varchar( 128 ),
    in p_password	varchar( 32 ) for bit data,
    in p_policy_name	varchar( 128 ) ) 
MODIFIES SQL DATA 
CALLED ON NULL INPUT
LANGUAGE SQL
COMMIT ON RETURN NO
begin
    declare v_user_id	integer;
    declare v_policy_id	integer;
    declare v_error	integer;
    declare v_msg	varchar( 1024 );
    
    if p_user is not null then
	set v_error = 0;
	if p_policy_name is not null then
	    select policy_id into v_policy_id from ml_user_auth_policy
				where policy_name = p_policy_name;
	    if v_policy_id is null then
		set v_msg = 'Unable to find the user authentication policy: "' CONCAT p_policy_name CONCAT '".';
		signal SQLSTATE '76004' set MESSAGE_TEXT = v_msg;
		set v_error = 1;
	    end if;
	else 
	    set v_policy_id = null;
	end if;
	if v_error = 0 then
	    select user_id into v_user_id from ml_user where name = p_user;
	    if v_user_id is null then
		insert into ml_user ( name, hashed_password, policy_id )
		    values ( p_user, p_password, v_policy_id );
	    else
		update ml_user set hashed_password = p_password,
				    policy_id = v_policy_id
		    where user_id = v_user_id;
	    end if;
	end if;
    end if;
end
~

--
-- Add a stored procedure for retrieving locking/blocking information
--
-- Create a stored procedure to get the connections
-- that are currently blocking the connections given
-- by p_appl_ids for more than p_block_time seconds

create procedure ml_create_get_blocked_info_proc()
BEGIN
    declare	v_exist	integer;
    declare	v_sql	varchar(2000);

    select 1 into v_exist from table( sysproc.env_get_inst_info() ) where upper(service_level) like 'DB2 V10.%';
    if v_exist = 1 then
	set v_sql =
	    'create procedure ml_get_blocked_info( in p_appl_ids varchar(2000), in p_block_time integer ) ' ||
	    'MODIFIES SQL DATA  CALLED ON NULL  INPUT LANGUAGE SQL  COMMIT ON RETURN NO  DYNAMIC RESULT SETS 1 ' ||
	    'BEGIN declare v_sel varchar( 2000 ); declare crsr cursor with return to client for dynstmt; ' ||
	    'set v_sel = ''select s1.appl_id,s2.appl_id,l.lock_wait_elapsed_time,1,rtrim(l.tabschema) || ''''.'''' || rtrim(l.tabname)''; ' ||
	    'set v_sel = concat( v_sel, '' from sysibmadm.mon_lockwaits l, table(snapshot_appl_info(NULL,NULL)) s1, table(snapshot_appl_info(NULL,NULL)) s2 '' ); ' ||
	    'set v_sel = concat( v_sel, '' where s1.agent_id = l.req_application_handle and s2.agent_id = l.hld_application_handle and l.lock_wait_elapsed_time > '' ); ' ||
	    'set v_sel = concat( v_sel, p_block_time ); ' ||
	    'set v_sel = concat( v_sel, '' and s1.appl_id in ( '' ); ' ||
	    'set v_sel = concat( v_sel, p_appl_ids ); ' ||
	    'set v_sel = concat( v_sel, '' ) order by 1'' ); ' ||
	    'prepare dynstmt from v_sel; open crsr; END ';
    else
	set v_sql =
	    'create procedure ml_get_blocked_info( in p_appl_ids varchar(2000), in p_block_time integer ) ' ||
	    'MODIFIES SQL DATA  CALLED ON NULL INPUT  LANGUAGE SQL  COMMIT ON RETURN NO  DYNAMIC RESULT SETS 1 ' ||
	    'BEGIN declare v_sel varchar( 1000 ); declare v_ids varchar( 50 ); declare v_ord varchar( 50 ); declare v_sql varchar( 2100 ); ' ||
	    'declare crsr cursor with return to client for dynstmt; ' ||
	    'set v_sel = ''select s.appl_id,l.appl_id_holding_lk,timestampdiff(2,char(l.snapshot_timestamp-l.lock_wait_start_time)),1,concat(concat(rtrim(l.db_name),''''.''''), rtrim(l.tabname)) from sysibmadm.lockwaits l,table(snapshot_appl_info(CAST(NULL AS VARCHAR(128)),-1)) s where l.agent_id=s.agent_id and timestampdiff(2,char(l.snapshot_timestamp-l.lock_wait_start_time)) > ''; ' ||
	    'set v_ids = '' and s.appl_id in ( ''; ' ||
	    'set v_ord = '' ) order by 1''; ' ||
	    'set v_sql = CONCAT( CONCAT( CONCAT( CONCAT( v_sel, CHAR(p_block_time) ), v_ids ), p_appl_ids ), v_ord ); ' ||
	    'prepare dynstmt from v_sql; open crsr; END';
    end if;
    execute immediate v_sql;
END
~

call ml_create_get_blocked_info_proc()
~

drop procedure ml_create_get_blocked_info_proc
~


--
-- Recreate the ml_reset_sync_state stored procedure
--
drop procedure ml_reset_sync_state
~

create procedure ml_reset_sync_state( in p_user_name	varchar( 128 ),
				      in p_remote_id	varchar( 128 ) ) 
    MODIFIES SQL DATA 
    CALLED ON NULL INPUT
    LANGUAGE SQL
    COMMIT ON RETURN NO
    BEGIN
      declare v_uid integer default null;
      declare v_rid integer default null;
      
      IF p_user_name is null THEN
        set v_uid = NULL;
      ELSE 
        select user_id into v_uid from ml_user
	     where name = p_user_name;
      END IF;
      IF p_remote_id is null THEN
        set v_rid = NULL;
      ELSE
        select rid into v_rid from ml_database
	     where remote_id = p_remote_id;
      END IF;
      IF p_user_name is not null AND p_remote_id is not null THEN
         IF v_uid is not null AND v_rid is not null THEN
	    update ml_subscription
	       set progress = 0,
	           last_upload_time = '1900-01-01-00.00.00',
		   last_download_time = '1900-01-01-00.00.00'
	       where user_id = v_uid and rid = v_rid;
	 END IF;
      ELSEIF p_user_name is not null THEN
         IF v_uid is not null THEN 
	    update ml_subscription
	       set progress = 0,
	           last_upload_time = '1900-01-01-00.00.00',
		   last_download_time = '1900-01-01-00.00.00'
	       where user_id = v_uid;
	 END IF;
      ELSEIF p_remote_id is not null THEN
         IF v_rid is not null THEN
	    update ml_subscription
	       set progress = 0,
	           last_upload_time = '1900-01-01-00.00.00',
		   last_download_time = '1900-01-01-00.00.00'
	       where rid = v_rid;
	 END IF;
      END IF;	       	   	       	    	       	   
      update ml_database
	 set sync_key = NULL,
	    seq_id = NULL,
	    seq_uploaded = 0,
	    script_ldt = '1900-01-01-00.00.00'
	 where remote_id = p_remote_id;
    END
~

--
-- Changes for ML Remote administration
--

alter table ml_ra_task add random_delay_interval integer default 0 not null
~

create procedure ml_share_all_scripts( 
    in p_version	varchar( 128 ),
    in p_other_version	varchar( 128 ) )
MODIFIES SQL DATA 
CALLED ON NULL INPUT
LANGUAGE SQL
COMMIT ON RETURN NO
begin
    declare v_version_id	integer;
    declare v_other_version_id	integer;
    
    select version_id into v_version_id from ml_script_version 
		where name = p_version;
    select version_id into v_other_version_id from ml_script_version 
		where name = p_other_version;

    IF v_version_id is null THEN
      select max( version_id ) + 1 into v_version_id 
	  from ml_script_version;
      IF v_version_id is null THEN
	 set v_version_id = 1;
      END IF;
      insert into ml_script_version( version_id, name )
		  values( v_version_id, p_version );
    END IF;

    insert into ml_table_script( version_id, table_id, event, script_id )
	select v_version_id, table_id, event, script_id from ml_table_script 
	    where version_id = v_other_version_id;
    
    insert into ml_connection_script( version_id, event, script_id )
	select v_version_id, event, script_id from ml_connection_script 
	    where version_id = v_other_version_id;
end
~

create procedure ml_ra_ss_download_task2(
    in p_taskdb_remote_id	varchar( 128 ) )
modifies SQL data
called on NULL input
language SQL
commit on return no
dynamic result sets 1
begin atomic
    declare crsr cursor with return to client for
	select task_instance_id, task_name, ml_ra_task.schema_name,
	    max_number_of_attempts, delay_between_attempts,
	    max_running_time, ml_ra_task.flags,
	    case dt.state 
		when 'P' then 'A'
		when 'CP' then 'C'
	    end,
	    cond, remote_event, random_delay_interval
	from ml_database task_db
	    join ml_ra_agent on ml_ra_agent.taskdb_rid = task_db.rid
	    join ml_ra_deployed_task dt on dt.aid = ml_ra_agent.aid
	    join ml_ra_task on dt.task_id = ml_ra_task.task_id
	where task_db.remote_id = p_taskdb_remote_id
	    and ( dt.state = 'CP' or dt.state = 'P' );
    open crsr;
end
~

/* Updated Script for 12.0.1 */
call ml_share_all_scripts( 'ml_ra_agent_12_1', 'ml_ra_agent_12' )
~
call ml_add_table_script( 'ml_ra_agent_12_1', 'ml_ra_agent_task', 'download_cursor', 
   'call ml_ra_ss_download_task2( {ml s.remote_id} )' )
~

--
-- Remove QAnywhere objects
--
delete from ml_property where property_set_name = 'Notifier(QAnyNotifier_client)'
~
delete from ml_property where property_set_name = 'Notifier(QAnyLWNotifier_client)'
~

call ml_add_connection_script( 'ml_qa_3', 'handle_error', null )
~
call ml_add_java_connection_script( 'ml_qa_3', 'begin_publication', null )
~
call ml_add_java_connection_script( 'ml_qa_3', 'nonblocking_download_ack', null )
~
call ml_add_java_connection_script( 'ml_qa_3', 'prepare_for_download', null )
~
call ml_add_java_connection_script( 'ml_qa_3', 'begin_download', null )
~
call ml_add_java_connection_script( 'ml_qa_3', 'modify_next_last_download_timestamp', null )
~

call ml_add_table_script( 'ml_qa_3', 'ml_qa_repository_client', 'upload_insert', null )
~
call ml_add_table_script( 'ml_qa_3', 'ml_qa_repository_client', 'download_delete_cursor', null )
~
call ml_add_table_script( 'ml_qa_3', 'ml_qa_repository_client', 'download_cursor', null )
~
call ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'upload_insert', null )
~
call ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'upload_update', null )
~
call ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'download_delete_cursor', null )
~
call ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'download_cursor', null )
~
call ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'upload_insert', null )
~
call ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'upload_update', null )
~
call ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'upload_delete', null )
~
call ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'download_delete_cursor', null )
~
call ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'download_cursor', null )
~

drop procedure ml_qa_stage_status_from_client
~
drop procedure ml_qa_staged_status_for_client
~
drop table ml_qa_repository_staging
~
drop table ml_qa_status_staging
~

drop trigger ml_qa_delivery_i_t
~
drop trigger ml_qa_delivery_u_t
~
drop trigger ml_qa_gbl_prop_i_t
~
drop trigger ml_qa_gbl_prop_u_t
~
drop procedure ml_qa_add_delivery
~
drop procedure ml_qa_add_message
~
drop procedure ml_qa_handle_error
~
drop procedure ml_qa_upsert_global_prop
~

drop view ml_qa_messages
~
drop view ml_qa_messages_archive
~

drop table ml_qa_global_props
~
drop table ml_qa_delivery
~
drop table ml_qa_status_history
~
drop table ml_qa_repository_props
~
drop table ml_qa_repository
~
drop table ml_qa_notifications
~

drop table ml_qa_delivery_archive
~
drop table ml_qa_status_history_archive
~
drop table ml_qa_repository_props_archive
~
drop table ml_qa_repository_archive
~

delete from ml_script_version where name = 'ml_qa_3'
~

commit
~

quit
~
