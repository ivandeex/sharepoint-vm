use master
go

if db_id('spCentralAdministration') is not null
begin
    alter database spCentralAdministration set single_user with rollback immediate
    drop  database spCentralAdministration
end
go

if db_id('spFarmConfiguration') is not null
begin
    alter database spFarmConfiguration set single_user with rollback immediate
    drop  database spFarmConfiguration
end
go

select substring(name,1,32) as name, substring(state_desc,1,16) as state from sys.databases
go
