#!/bin/bash

#########################################################################
## shellを実行する前提条件                      　                       ##
#########################################################################
## vault導入サーバで実行すること。(vault loginロジックを入れてないため。)   ##
## unseal keyを特定のディレクトリにファイルで保存しておくこと。　           ##
#########################################################################

CRT_PATH="/etc/pki/tls/certs/"
CRT_FILE="vault01.uws.lan.crt"
CRT_EXISTS="FALSE"
PRIV_PATH="/etc/pki/tls/private/"
PRIV_FILE="vault01.uws.lan.key"
PRIV_EXISTS="FALSE"

# certファイルの存在確認
if [ -e ${CRT_PATH}${CRT_FILE} ];then
    CRT_EXISTS="TRUE"
fi

# privateファイルの存在確認
if [ -e ${PRIV_PATH}${PRIV_FILE} ]; then
    PRIV_EXISTS="TRUE"
fi
