#!/bin/bash

set -euC

function parse_args() {
    if [[ $# -ne 1 ]]; then
        echo "argument is incorrect."
        exit 10
    fi
    readonly ARG1="$1"
}

function _common_parm() {
    readonly USER="root"
    readonly GROUP="root"
    readonly DIR_MODE="500"
    readonly FILE_MODE="400"
    readonly KEY_DIR="/tmp/key"
    readonly TMP_KEY_DIR="${KEY_DIR}/tmp"
    readonly PRIVATE_KEY_FILE="${KEY_DIR}/decrypt.key"
    readonly PUB_KEY_BASE_FILE="encrypt"
    readonly ENCRYPT_SECRET_DIR="/tmp/enc"
    readonly ENCRYPT_SECRET_FILE="${ENCRYPT_SECRET_DIR}/secret.txt.enc"
    PUB_KEY_FILE=""
}

function mock_vault_kv_get_secret() {
    echo $ARG1
}

function create_encrypt_key() {
    # ディレクトリ作成
    if [[ ! -e $KEY_DIR ]]; then
        mkdir -p $KEY_DIR
    fi

    # 鍵置き場へのアクセス権強制設定
    chown ${USER}:${GROUP} $KEY_DIR
    chmod $DIR_MODE $KEY_DIR

    # 秘密鍵生成
    if [[ ! -e ${PRIVATE_KEY_FILE} ]]; then
        touch $PRIVATE_KEY_FILE
    fi
    chmod $FILE_MODE $PRIVATE_KEY_FILE
    openssl genrsa -out $PRIVATE_KEY_FILE 4096

    # 公開鍵生成
    PUB_KEY_FILE=$(mktemp -u ${PUB_KEY_BASE_FILE}-XXXXX.key)
    PUB_KEY_FILE=${TMP_KEY_DIR}/${PUB_KEY_FILE}

    if [[ ! -e ${TMP_KEY_DIR} ]]; then
        mkdir -p $TMP_KEY_DIR
    fi

    chown ${USER}:${GROUP} $TMP_KEY_DIR
    chmod $DIR_MODE $TMP_KEY_DIR

    touch $PUB_KEY_FILE
    chmod $FILE_MODE $PUB_KEY_FILE
    openssl rsa -pubout -in $PRIVATE_KEY_FILE -out $PUB_KEY_FILE

    return 0
}

function encrypt() {
    # ディレクトリ作成
    if [[ ! -e $ENCRYPT_SECRET_DIR ]]; then
        mkdir -p $ENCRYPT_SECRET_DIR
    fi

    # シークレット置き場へのアクセス権強制設定
    chown ${USER}:${GROUP} $ENCRYPT_SECRET_DIR
    chmod $DIR_MODE $ENCRYPT_SECRET_DIR

    # secret取得
    local -r _plain_secret=$(mock_vault_kv_get_secret)

    # secret暗号化
    touch $ENCRYPT_SECRET_FILE
    chmod $FILE_MODE $ENCRYPT_SECRET_FILE
    echo $_plain_secret | openssl pkeyutl -encrypt -inkey $PUB_KEY_FILE -pubin -out $ENCRYPT_SECRET_FILE

    return 0
}

function clean_up() {
    rm -rf $TMP_KEY_DIR
    return 0
}

function main() {
    _common_parm
    create_encrypt_key
    encrypt
    clean_up

    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_args "$@"
    main 
fi
