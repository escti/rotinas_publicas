#!/bin/bash

## Script: escti_kill_inativas.sh
## Proposito: Fazer limpeza de conexões que estão inativas sem query pendente
## Modificado: Thiago E. de Albuquerque (dba@escti.net)
## Data última modificação: 26/10/2022
## Utilização:
# 11
# ./escti_kill_inativas.sh SID 
# 12
# ./escti_kill_inativas.sh SID PDB

# Variaveis

. ~/.bash_profile

export ORAENV_ASK=NO
SID=${1}
PDB=${2}

export ORACLE_SID="$SID"
. oraenv

DATA=`date --date="0 days ago" +%Y%m%d%H%M%S`
export ORACLE_PDB_SID="$PDB"

sqlplus -s / as sysdba <<EOF
set trim on
set trims on
set feedback off
SET UND off
set lines 10000 pages 5000
spo _inativas.txt;

SELECT
    'ALTER SYSTEM DISCONNECT SESSION '''
    || sid
    || ','
    || serial#
    || ',@'
    || INST_ID
    || '''IMMEDIATE;'
FROM
    gv\$session
WHERE
        status = 'INACTIVE'
    AND taddr IS NULL
    and LAST_CALL_ET >='300'
    AND username NOT IN ( 'ORACLE', 'SYS' );
	
spo off

select count (*) FROM V\$SESSION WHERE STATUS = 'INACTIVE' and USERNAME not in ('ORACLE','SYS');
@_inativas.txt
select count (*) FROM V\$SESSION WHERE STATUS = 'INACTIVE' and USERNAME not in ('ORACLE','SYS');
exit
EOF
