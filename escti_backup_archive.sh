#!/bin/bash
## Script: escti_backup_archive.sh
## Proposito: Fazer backup ARCHIVE do banco de dados ONLINE
## Modificado: Thiago E. de Albuquerque (dba@escti.net)
## Data última modificação: 26/10/2022
## Utilização:
# 11
# ./escti_backup_archive.sh SID BKPDIR
# 12
# ./escti_backup_archive.sh SID BKPDIR PDB

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
RESUMO=$BKPDIR/log/resumo_archivelog_$SID_$(date  +%d-%m-%Y).log

# INICIO
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

# RMAN ARCHIVELOG
echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - Início do backup de archivelog >> $RESUMO

rman target / LOG=$BKPDIR/log/log_bkp_arch_$SID_$DATA.log <<EOF
run
{
allocate channel c1 type disk;
SET COMMAND ID TO '1bkp_arch_$SID';
backup as compressed backupset archivelog all
format '$BKPDIR/arch_%d_%s_%p.bkp'
delete all input;
release channel c1;
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

rm $LOCK

echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - Fim do backup >> $RESUMO
echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - Resultado do Backup: $ESTADO. >> $RESUMO
echo  LOG: $(date  +%d-%m-%Y_%H:%M:%S) - Excluindo logs antigos >> $RESUMO

# Remove arquivos de logs do backup archive com mais de 30 dias de criação
find $BKPDIR/log -name "log_bkp_arch_*.log" -mtime +29 -exec rm  {} \;

#remove manualmente backups com mais de D+1
#find $BKPDIR/ -name '*.bkp' -daystart -mtime +1 -exec rm -f '{}' ';'

echo LOG: $(date  +%d-%m-%Y_%H:%M:%S) - Fim do procedimento. >> $RESUMO
echo  ---------------------------- FINISH ---------------------------  >> $RESUMO

cat $RESUMO
