#!/bin/bash
## Script: escti_backup_rman_full.sh
## Proposito: Fazer backup FULL do banco de dados ONLINE
## Modificado: Thiago E. de Albuquerque (dba@escti.net)
## Data última modificação: 26/10/2022
## Utilização:
# 11
# ./escti_backup_rman_full.sh SID BKPDIR
# 12
# ./escti_backup_rman_full.sh SID BKPDIR PDB

# Variaveis

. ~/.bash_profile

export ORAENV_ASK=NO
SID=${1}
DIR=${2}
PDB=${3}
RETENCAO=0


export ORACLE_SID="$SID"
. oraenv

DATA=`date --date="0 days ago" +%Y%m%d%H%M%S`
BKPDIR=$DIR/$SID/rman
RESUMO=$BKPDIR/log/resumo_full_$SID_$(date  +%d-%m-%Y).log

mkdir -p $BKPDIR/log;
echo  ----------------------- RESUMO $(date  +%d-%m-%Y) -------------------- >> $RESUMO
echo  ---------------------------- START ---------------------------  >> $RESUMO
echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - Iniciando procedimento: >> $RESUMO
echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - Local do backup: $BKPDIR >> $RESUMO

# Lock no arquivo para impedir execucao dupla
LOCK=$BKPDIR/.backup_arch_$SID.lck

if [ -f $LOCK ]; then
echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - arquivo de lock presente. Finalizando... >> $RESUMO
    exit 1
fi

touch $LOCK

echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - Início do backup FULL >> $RESUMO

#RMAN FULL
rman target / LOG=$BKPDIR/log/log_bkp_rman_$SID_$DATA.log <<EOF
run
{
SET COMMAND ID TO '1bkp_SP-$SID';
sql "create pfile = ''$BKPDIR/PF_$SID_$DATA.ora'' from spfile";
sql "ALTER DATABASE BACKUP CONTROLFILE TO ''$BKPDIR/CF_$SID_$DATA.bkp''";
crosscheck archivelog all;
SET COMMAND ID TO '2bkp_FL-$SID';
backup as compressed backupset database
tag '$DATA'
filesperset 5
format '$BKPDIR/db_%d_%s_%p.bkp'
plus archivelog
format '$BKPDIR/arch_%d_%s_%p.bkp'
delete all input;
SET COMMAND ID TO '3bkp_CF-$SID';
copy current controlfile to '$BKPDIR/currentCF_$SID_$DATA.bkp';
crosscheck backup;
SET COMMAND ID TO '4bkp_DL-$SID';
DELETE NOPROMPT OBSOLETE;
}
EOF
STATUS_BKP=$?

case $STATUS_BKP in
  0) echo "EX_SUCC $STATUS_BKP"
     ESTADO="SUCESSO"
     ;;
  5) echo "EX_SUCC_ERR"
     ESTADO="INCOMPLETO"
     ;;
  1) echo "EX_FAIL"
     ESTADO="FALHA"
     ;;
  *) echo "INVALID NUMBER!"
 ESTADO="FALHA"
     ;;
esac

echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - backup finalizado >> $RESUMO
echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - Resultado do Backup: $ESTADO. >> $RESUMO

# Remove backups antigos fora do período de rentenção
echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - removendo arquivos fora da retenção >> $RESUMO

rman target / LOG=$BKPDIR/log/log_cleanup_rman_$SID_$DATA.log <<EOF
run
{
SET COMMAND ID TO 'clean_old_$SID';
crosscheck archivelog all;
crosscheck backupset;
crosscheck backup ;
crosscheck copy ;
crosscheck datafilecopy all;
delete noprompt obsolete;
delete noprompt expired archivelog all;
delete noprompt expired backup;
}
EOF

# Remove arquivos de logs do backup rman com mais de 30 dias de criação
echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - removendo logs antigos >> $RESUMO
find $BKPDIR/log -name "log_bkp_rman_*.log" -mtime +29 -exec rm  {} \;

echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - fim do procedimento. >> $RESUMO
echo  ---------------------------------------------------- >> $RESUMO

# Remove o arquivo de LOCK
rm $LOCK

cat $RESUMO
