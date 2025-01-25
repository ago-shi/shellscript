#!/bin/bash

#########################################################################
## shellを実行する前提条件                      　                       ##
#########################################################################
## vault導入サーバで実行すること。(vault loginロジックを入れてないため。)   ##
## unseal keyを特定のディレクトリにファイルで保存しておくこと。　           ##
#########################################################################

CRT_PATH="/etc/pki/tls/certs"
KEY_PATH="/etc/pki/tls/private"
RENEW_BEFORE_EXPIRY=10 #day
PKI_PATH="pki_int/issue/uws-dot-lan"
CMN_NAME="vault01.uws.lan"
HOSTNAME="vault01"
IPADDR="192.168.1.69"
RESTART=99
UNSEAL_FILE="/root/.vaultUnsealKey"

# 現在の証明書の有効期限確認
EXPIRY=$(openssl x509 -noout -dates -in ${CRT_PATH}/${CMN_NAME}.crt | \
  grep "notAfter=" | awk -F'=' '{print $2}')
UNX_EXPIRY=$(date -d "${EXPIRY}" +%s)

# 証明書の取得
UNX_CUR_DATE=$(date -d "$(date)" +%s)
UPDATE_LIMIT=$(${#UNX_EXPIRY} - ${RENEW_BEFORE_EXPIRY} \* 24 \* 60 \* 60)
if [ "${UPDATE_LIMIT}" -le "${UNX_CUR_DATE}" ]; then
  NEW_CRT_JSN=$(vault write -format=json ${PKI_PATH} \
    common_name=${CMN_NAME} \
    alt_names="DNS:${HOSTNAME},IP:${IPADDR}")
  RENEW=$?
else
  RENEW=99
fi

# 証明書の更新
if [ $RENEW -eq 0 ]; then
  rm -f ${CRT_PATH}/${CMN_NAME}.crt.old ${KEY_PATH}/${CMN_NAME}.key.old
  mv ${CRT_PATH}/${CMN_NAME}.crt ${CRT_PATH}/${CMN_NAME}.crt.old
  mv ${KEY_PATH}/${CMN_NAME}.key ${KEY_PATH}/${CMN_NAME}.key.old

  echo "${NEW_CRT_JSN}" | jq -r '.data.private_key' > ${KEY_PATH}/${CMN_NAME}.key
  echo "${NEW_CRT_JSN}" | jq -r '.data.certificate' > ${CRT_PATH}/${CMN_NAME}.crt
  echo "${NEW_CRT_JSN}" | jq -r '.data.issuing_ca' >> ${CRT_PATH}/${CMN_NAME}.crt

elif [ $RENEW -eq 99 ]; then
  MSG="[vault certification]CERTFILES is not update yet."
else
  MSG="[vault certification]Making NEW CERT is abnormal end."
fi

# vaultの再起動
if [ ${RENEW} -eq 0 ]; then
  systemctl restart vault >/dev/null 2>&1
  RESTART=$?
  if [ ${RESTART} -ne 0 ]; then
    MSG="[vault certification]vault.service restart is abnormal end."
  fi
fi

# vault unseal
CNT=0
if [ "${RENEW}" -eq 0 ] && [ ${RESTART} -eq 0 ]; then
  while IFS= read -r line
  do
    if [ "${CNT}" -lt 3 ]; then
      if ! vault operator unseal "${line}";
      then
        CNT=$(${#CNT} + 1)
      fi
    fi
  done < ${UNSEAL_FILE}

  if [ "${CNT}" -lt 3 ]; then
    MSG="[vault certification]vault unseal is abnormal end."
  else
    MSG="[vault certification]CERTFILES update is succeeded."
  fi
fi

logger "${MSG}"
