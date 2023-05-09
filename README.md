# credit-engine-db-migration
Credit Engine database repository which includes clean install (full set of db schema) and migration using Flyway and Docker.

## Documentation on how Flyway Migration for database works
https://flywaydb.org/documentation/concepts/migrations.html

## Instructions on how to run the project locally
> git clone git@github.com:lsqlabs/credit-engine-db-migration.git

or 
> go get github.com/lsqlabs/credit-engine-db-migration

### ---------- docker run using config file -------------------------------------------------

Using Flyway docker base image flyway/flyway to run "flyway migrate" command using sql scipts in /sql folder and config file in /conf folder
```
docker run --rm -v /absolute_path_to_a_docker_mapped_host_folder/credit-engine-db-migration/migration/sql:/flyway/sql -v /absolute_path_to_a_docker_mapped_host_folder/credit-engine-db-migration/migration/conf:/flyway/conf flyway/flyway migrate
```
Example using config file (on Windows)
```
docker run --rm -v /C/Git/credit-engine-db-migration/migration/sql:/flyway/sql -v /C/Git/credit-engine-db-migration/migration/conf:/flyway/conf flyway/flyway migrate
```
### Note
The above command will create the new db "credit_engine" if it does not exist. If the db exists already and haven't run any migration before, run the below command 
"flyway baseline" to create the flyway_schema_history table first, then run the "flyway migrate" as above for the actual migration.
```
docker run --rm -v /absolute_path_to_a_docker_mapped_host_folder/credit-engine-db-migration/migration/sql:/flyway/sql -v /absolute_path_to_a_docker_mapped_host_folder/credit-engine-db-migration/migration/conf:/flyway/conf flyway/flyway baseline
```
### ---------- docker run without config file (using parameters in command line) ------

Using Flyway docker base image flyway/flyway to run "flyway migrate" command using scipts in /sql folder with direct parameters (without conf file)
```
docker run --rm -v /absolute_path_to_a_docker_mapped_host_folder/credit-engine-db-migration/migration/sql:/flyway/sql flyway/flyway -url=url_to_db -user=my_user_name -password=my_password migrate
```
Example run on Windows (on Linux the syntax could be different) 
the below example assumes C:\ is mapped in docker - (usually happens by default when installing Docker)
```
docker run --rm -v /C/Git/credit-engine-db-migration/migration/sql:/flyway/sql flyway/flyway -url=jdbc:mariadb://192.168.1.210:3306/credit_engine -user=my_user_name -password=my_password migrate
```
Example run on Mac - the below example assumes /Users is mapped in docker - (usually happens by default when installing Docker)
```
docker run --rm -v /Users/ntzaprev/code/db/credit-engine-db-migration/migration/sql:/flyway/sql flyway/flyway -url=jdbc:mariadb://192.168.1.4:3306/credit_engine -user=root -password=mypass migrate
```
### Note: for above command to run successfully
(1)The db url has to be the actual IP address of the db server, using 'localhost' does not work.
   Update my.cnf file (on Mac /usr/local/etc/my.cnf) to comment out this line (so it allows connection not only by localhost):
   localhost 127.0.0.1
   On MySQL/MariaDB change the user (in "Users and Privileges") to have "Limits to Hosts Matching" on "%" (instead of just "localhost").
(2)The user used to connect to db ("root" or other user)needs to have a non-empty password.
(2)C drive needs to be shared with Docker (through Docker Settings\Shared Drives).
(3)The -v option for volume has to be absolute file path on the host. The above command will mount the directory C:\Git\credit-engine-db-migration\migration\sql folder on the host as /flyway/sql volume on the Docker container. Remember to use the correct syntax here (no colon : after C drive name, use / instead of \ for the path)

### Undo migration in case of migraion error 
In case of migration error:
(1)Run "Flyway repair". This will remove the failed migration entries from flway_schema_history table(only for databases that do NOT support DDL transactions like MySQL/MariaDB), realign the checksums, descriptions, and types of the applied migrations with the ones of the available migrations.
```
docker run --rm -v /absolute_path_to_a_docker_mapped_host_folder/credit-engine-db-migration/migration/sql:/flyway/sql -v /absolute_path_to_a_docker_mapped_host_folder/credit-engine-db-migration/migration/conf:/flyway/conf flyway/flyway repair
```
(2)Specify the target version that you want to rollbak to in /credit-engine-db-migration/migration/conf/flyway.conf file, for example rollback to the first version 1.1 
```
flyway.target=1.1
```
(3)Now run the "flyway undo". This will run the U__ scripts which correspond to the V__ script in the reverse order to bring back db to the state before current migration.
```
docker run --rm -v /absolute_path_to_a_docker_mapped_host_folder/credit-engine-db-migration/migration/sql:/flyway/sql -v /absolute_path_to_a_docker_mapped_host_folder/credit-engine-db-migration/migration/conf:/flyway/conf flyway/flyway undo
```
### Note on flyway undo 
(1)By default, Flyway always wraps the execution of an entire migration within a single transaction.
Alternatively you can also configure Flyway to wrap the entire execution of all migrations of a single migration run within a single transaction by setting the group property to true.
If Flyway detects that a specific statement cannot be run within a transaction due to technical limitations of your database, it won’t run that migration within a transaction. Instead it will be marked as non-transactional.

(2)MySQL/MariaDB does not support rollback on DDL (Data Defintion Language) statement like Create table, Add column, etc in case of transaction failure. These DDL statement are implicit transactions and will do implicit commit. So we can not rely on db engine for the transaction rollback, we need to use explicit "undo" sql scripts to do the rollback.

(3)The undo scripts are in the /undo folder inside each versioned folders V1, V2,... 
The regular migration file: V1.1__create_table_company.sql
The undo migration file:    U1.1__create_table_company.sql
The file version/name/desription are the same, except for V and U prefix (Although the undo file content is drop table company, the file name is still U1.1_Create_table_company). This is for Flyway to be able to match them as a pair when running undo.

## Check in instructions for DB SQL scripts:

(1) /install folder is for clean install. This is currently NOT used by any tool, only for our easy reference when we want to see the full set of db schema at any given time (without going through all incremental changes in migration folder).

(2) /migration folder contains versioned incremental changes and is used by Flyway for db migration (upgrade). The /conf folder contains configuration file for different environments, /sql folder contains the actual sql scripts to be run by Flyway.

The design idea for migration folder structure is to have folder names correspond to major releases, and each individual file within a folder correspond to changes on a db object. For example, if we create a brand new db with 5 tables initially, then we create a V1 folder with V1.1, V1.2, V1.3, V1.4, V1.5, V1.6 scripts in it (1.1 for db, 1.2 through 1.6 for tables). Once V1 is released, we create V2 folder for new development work and bug fixed, etc. The cycle goes on. 
There is no much difference for the end result if we do folder structure vs flat files for all scripts. I think Flyway looks at the file name level to determine the order for executing the scripts. The folder structure is more for logic grouping and easier manage of release/deployment. 
When an object (table in most cases) is checked in and released, we have to create new script file for incremental changes (adding column or indexes, etc) on the same object. This is more flexible when they are still in Dev environment, say, if we need to fix a typo or use a better name for a column in the existing script, it makes more sense to edit that existing file than creating another "alter_table_XX_" script in the same folder.  In our local machine we can simply drop the db and re-run flyway to create the db from scratch if we don't care about the data, if we need to keep the data, run Flyway.repair followed by Flyway.migrate. On cloud, the CycleCI pipeline will run Flyway.repair on error if we modify an existing script (which has been deployed already) and run the new version of the same script again. 

(3) The naming conversion for sql scripts: 

    The subfolder under /sql is named by version: V1, V2, ...
    The sql file format: Vmajorversion.minorversion__description.sql
       Except for "V", everything else is lowercase
       Make sure file suffix is .sql, not .txt 
       example: V1.1__create_table_company
       
 (4)When you check in a migration script V__my_migration_script.sql, please make sure to update the /install folder and have a corresponding U__my_migration_script.sql as well.

 