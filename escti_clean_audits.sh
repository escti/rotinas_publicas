#!/bin/bash
## Script: escti_clean_audits.sh
## Proposito: Realiza a limpeza dos arquivos de auditoria padrões do ORACLE
## Autor: Thiago E. de Albuquerque (dba@escti.net)
## Data última modificação: 26/10/2022
## 59 05  * * * /home/oracle/escti/scripts/rotinas/escti_clean_audits.sh SID 30
## !ATENCAO! Substituir o caminho de acordo com o existente no ambiente !ATENCAO!

# Variaveis
export ORAENV_ASK=NO
SID=${1}
RETENCAO=${2}
export ORACLE_SID=$SID
. oraenv

## NON-RAC
# Banco 
find $ORACLE_BASE/admin/$ORACLE_SID/adump -name '*.aud' -daystart -mtime +$RETENCAO -exec rm -f '{}' ';'
#find $ORACLE_BASE/admin/$ORACLE_SID/bdump -name '*.aud' -daystart -mtime +$RETENCAO -exec rm -f '{}' ';'
#find $ORACLE_BASE/admin/$ORACLE_SID/cdump -name '*.aud' -daystart -mtime +$RETENCAO -exec rm -f '{}' ';'
#find $ORACLE_BASE/admin/$ORACLE_SID/dpdump -name '*.aud' -daystart -mtime +$RETENCAO -exec rm -f '{}' ';'
#find $ORACLE_BASE/diag/rdbms/$ORACLE_UNQNAME/$ORACLE_SID/trace -name '*.trc' -daystart -mtime +$RETENCAO -exec rm -f '{}' ';'
#find $ORACLE_BASE/diag/rdbms/$ORACLE_UNQNAME/$ORACLE_SID/trace -name '*.trm' -daystart -mtime +$RETENCAO -exec rm -f '{}' ';'
find $ORACLE_BASE/diag/rdbms/$SID/$ORACLE_SID/trace -name '*.trc' -daystart -mtime +$RETENCAO -exec rm -f '{}' ';'
find $ORACLE_BASE/diag/rdbms/$SID/$ORACLE_SID/trace -name '*.trm' -daystart -mtime +$RETENCAO -exec rm -f '{}' ';'


#Listener
find $ORACLE_BASE/diag/tnslsnr/$HOSTNAME/listener/alert -name '*.xml' -daystart -mtime +$RETENCAO -exec rm -f '{}' ';'
