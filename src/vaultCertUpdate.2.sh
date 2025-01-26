#!/bin/bash

#########################################################################
## shellを実行する前提条件                      　                       ##
#########################################################################
## vault導入サーバで実行すること。(vault loginロジックを入れてないため。)   ##
## unseal keyを特定のディレクトリにファイルで保存しておくこと。　           ##
#########################################################################

CRT_PATH="/etc/pki/tls/certs/"
CRT_FILE="vault01.uws.lan.crt"
CRT_EXIST="FALSE"
PRIV_PATH="/etc/pki/tls/private/"
PRIV_FILE="vault01.uws.lan.key"
PRIV_EXIST="FALSE"
CERT=""

RENEW_BEFORE_EXPIRY=10
EXPIRY=""
UNX_CUR_DATE=""
UPDATE_LIMIT=""
MSG=""
CRT_UPD="FALSE"

# テストコード用変数

# certファイルの存在確認
if CERT=$(openssl x509 -noout -dates -in ${CRT_PATH}${CRT_FILE} 2> /dev/null); 
then
    CRT_EXIST="TRUE"
else
    touch ${CRT_PATH}${CRT_FILE}
fi

# privateファイルの存在確認
if ls ${PRIV_PATH}${PRIV_FILE} > /dev/null 2>&1; 
then
    if openssl rsa -text < ${PRIV_PATH}${PRIV_FILE} > /dev/null 2>&1;
    then
        PRIV_EXIST="TRUE"
    fi
else
    touch ${PRIV_PATH}${PRIV_FILE}
fi

# テストコード
if [ "$1" = "test" ]; then
    echo "CRT_EXIST is $CRT_EXIST"
    echo "PRIV_EXIST is $PRIV_EXIST"
    ls ${CRT_PATH}${CRT_FILE}
    ls ${PRIV_PATH}${PRIV_FILE}
fi

if [ "${CRT_EXIST}" = "TRUE" ] && [ "${PRIV_EXIST}" = "TRUE" ]; then

    EXPIRY=$(echo "$CERT" | grep "notAfter=" | awk -F'=' '{print $2}')
    UNX_EXPIRY=$(date -d "${EXPIRY}" +%s)
    UNX_CUR_DATE=$(date -d "$(date)" +%s)
    UPDATE_LIMIT=$(( UNX_EXPIRY - RENEW_BEFORE_EXPIRY * 24 * 60 * 60 ))

    if [ $((UPDATE_LIMIT)) -le $((UNX_CUR_DATE)) ]; then
        MSG="[vault certification]certificate needs update."
        CRT_UPD="TRUE"
    else
        MSG="[vault certification]certificate is not update yet."
    fi
else
    MSG="dummy"
fi

logger "${MSG}"

# テストコード
if [ "$1" = "test" ]; then
    echo "$MSG"
    echo "CRT_UPD is ${CRT_UPD}."
fi
