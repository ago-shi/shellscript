#!/bin/bash

#########################################################################
## shellを実行する前提条件                      　                       ##
#########################################################################
## vault導入サーバで実行すること。(vault loginロジックを入れてないため。)   ##
## unseal keyを特定のディレクトリにファイルで保存しておくこと。　           ##
#########################################################################

# サーバのパラメータ
HOSTNAME="vault01"
IPADDR="192.168.1.69"

# hashicorp vaultのパラメータ
PKI_PATH="pki_int/issue/uws-dot-lan"
CMN_NAME="${HOSTNAME}.uws.lan"

# 証明書、秘密鍵の変数
CRT_PATH="/etc/pki/tls/certs/"
CRT_FILE="${CRT_PATH}${CMN_NAME}.crt"
CRT_OLD="${CRT_FILE}.old"
CRT_EXIST="FALSE"
PRIV_PATH="/etc/pki/tls/private/"
PRIV_FILE="${PRIV_PATH}${CMN_NAME}.key"
PRIV_OLD="${PRIV_FILE}.old"
PRIV_EXIST="FALSE"
CERT=""
ALT_NAMES="DNS:${HOSTNAME},IP:${IPADDR}"

RENEW_BEFORE_EXPIRY=10
EXPIRY=""
EPOC_DATE=""
UPDATE_LIMIT=""
MSG=""
CRT_UPD="FALSE"
CRT_JSN=""
EXIT="0"
COUNT=0
UNSEAL="/root/.vaultUnsealKey"

# certファイルの存在確認
if CERT=$(openssl x509 -noout -dates -in ${CRT_FILE} 2> /dev/null); 
then
    CRT_EXIST="TRUE"
else
    touch ${CRT_FILE}
fi

# privateファイルの存在確認
if ls ${PRIV_FILE} > /dev/null 2>&1; 
then
    if openssl rsa -text < ${PRIV_FILE} > /dev/null 2>&1;
    then
        PRIV_EXIST="TRUE"
    fi
else
    touch ${PRIV_FILE}
fi

# テストコード
if [ "$1" = "test" ]; then
    echo "CRT_EXIST is $CRT_EXIST"
    echo "PRIV_EXIST is $PRIV_EXIST"
    ls ${CRT_FILE}
    ls ${PRIV_FILE}
fi

if [ "${CRT_EXIST}" = "TRUE" ] && [ "${PRIV_EXIST}" = "TRUE" ]; then
    EXPIRY=$(echo "$CERT" | grep "notAfter=" | awk -F'=' '{print $2}')
    EPOC_EXPIRY=$(date -d "${EXPIRY}" +%s)
    EPOC_DATE=$(date -d "$(date)" +%s)
    UPDATE_LIMIT=$((EPOC_EXPIRY - RENEW_BEFORE_EXPIRY * 24 * 60 * 60))

    # テストコード
    if [ "$1" = "test" ]; then
        EPOC_DATE="$(cat ./test/mock/dumDate.txt)"
        UPDATE_LIMIT="$(cat ./test/mock/dumLimit.txt)"
    fi

    if [ $((UPDATE_LIMIT)) -le $((EPOC_DATE)) ]; then
        MSG="[vault certification]certificate needs update."
        CRT_UPD="TRUE"
    else
        MSG="[vault certification]certificate is not update yet."
        CRT_UPD="FALSE"
    fi
else
    MSG="[vault certification]certificate needs creating."
    CRT_UPD="TRUE"
fi

# テストコード
if [ "$1" = "test" ]; then
    echo "$MSG"
    echo "CRT_UPD is $CRT_UPD."
fi

logger "$MSG"

if [ $CRT_UPD = "TRUE" ]; then
    # 本番環境用コード
    if [ "$1" != "test" ]; then
        CRT_JSN=$(vault write -format=json "$PKI_PATH" \
        common_name="$CMN_NAME" alt_names="$ALT_NAMES")
        RTN="$?"
    # テストコード
    else
        CRT_JSN=$(cat "./test/mock/dum${HOSTNAME}.json")
        RTN=$(cat "./test/mock/dumRTN.txt")
    fi

    if [ "$RTN" = "0" ]; then
        rm -f "$CRT_OLD" "$PRIV_OLD"
        mv "$CRT_FILE" "$CRT_OLD"
        mv "$PRIV_FILE" "$PRIV_OLD"

        echo "$CRT_JSN" | jq -r '.data.private_key' > $PRIV_FILE
        echo "$CRT_JSN" | jq -r '.data.certificate' > $CRT_FILE
        echo "$CRT_JSN" | jq -r '.data.issuing_ca' >> $CRT_FILE

        MSG="[vault certification]cerfification update is succeeded."
        EXIT="notExit"
    else
        MSG="[vault certification]cerfification update is abnormal end."
        EXIT="5"
    fi
else
    MSG="[vault certification]cerfification update process is end."
    EXIT="0"
fi

logger "$MSG"

# テストコード
if [ "$1" = "test" ]; then
    echo "$EXIT"
    echo "$MSG"
fi

if [ "$EXIT" != "notExit" ]; then
    exit $((EXIT))
fi

# 本番用コード
if [ "$1" != "test" ]; then
    systemctl restart vault >/dev/null 2>&1
    RTN="$?"
# テストコード
else
    RTN=$(cat "./test/mock/dumVaultRTN.txt")
fi

if [ "$RTN" = "0" ]; then 
    MSG="[vault certification]vault is restarted."
    EXIT="notExit"
else
    MSG="[vault certification]vault restart is abnormal end."
    EXIT="100"
fi

logger "$MSG"

# テストコード line[8] & line[9]
if [ "$1" = "test" ]; then
    echo "$EXIT"
    echo "$MSG"
fi

if [ "$EXIT" != "notExit" ]; then
    exit $((EXIT))
fi

COUNT=0
while IFS= read -r line
do
    if [ $((COUNT)) -lt 3 ]; then
        # 本番用コード
        if [ "$1" != "test" ]; then
            vault operator unseal "$line"
            RTN="$?"
        # テストコード
        else
            RTN=$(cat "./test/mock/dumUnsealRTN.txt")
        fi

        if [ "$RTN" = "0" ]; then
            ((++COUNT))
        else
            logger "[vault certification]warning vault unseal is failed.(line=$COUNT)"
        fi
    fi
done < $UNSEAL 

# テストコード line[10]
if [ "$1" = "test" ]; then
    echo "COUNT is ${COUNT}."
    COUNT=$(cat "./test/mock/dumCountRTN.txt")
fi

if [ $((COUNT)) -eq 3 ]; then
    MSG="[vault certification]vault unseal is normal end."
    EXIT="0"
else
    MSG="[vault certification]vault unseal is abnormal end."
    EXIT="101"
fi

logger "$MSG"

# テストコード line[11]
if [ "$1" = "test" ]; then
    echo "$MSG"
fi

exit $((EXIT))
