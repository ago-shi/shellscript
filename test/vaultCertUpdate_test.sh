#!/usr/bin/env bats

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    TGT_SHELL="vaultCertUpdate.2.sh test"
    CERTP="/etc/pki/tls/certs/"
    CERTF="vault01.uws.lan.crt"
    PRIVP="/etc/pki/tls/private/"
    PRIVF="vault01.uws.lan.key"
    TMP="/tmp/"

    DIR="/bats/shell/test/"
    PATH="$DIR/../src/:$PATH"
}

teardown() {
    rm -f "${CERTP}${CERTF}"
    rm -f "${PRIVP}${PRIVF}"
}

@test "case.0 シェルスクリプトが実行可能" {
    $TGT_SHELL
}

@test "case.1-1-1 証明書ある & 鍵ある" {
    cp -f "${TMP}${CERTF}" "${CERTP}${CERTF}"
    cp -f "${TMP}${PRIVF}" "${PRIVP}${PRIVF}"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is TRUE" ]
    [ "${lines[1]}" = "PRIV_EXIST is TRUE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
}

@test "case.1-1-2 証明書ある & 鍵ない & 鍵と同名ファイルある" {
    cp -f "${TMP}${CERTF}" "${CERTP}${CERTF}"
    touch "${PRIVP}${PRIVF}"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is TRUE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
}

@test "case.1-1-3 証明書ある & 鍵ない & 鍵と同名ファイルない" {
    cp -f "${TMP}${CERTF}" "${CERTP}${CERTF}"
    rm -f "${PRIVP}${PRIVF}"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is TRUE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
}

@test "case.1-2-1 証明書ない & 証明書と同名ファイルある & 鍵ある" {
    touch "${CERTP}${CERTF}"
    cp -f "${TMP}${PRIVF}" "${PRIVP}${PRIVF}"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is TRUE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
}

@test "case.1-2-2 証明書ない & 証明書と同名ファイルある & 鍵ない & 鍵と同盟ファイルある" {
    touch "${CERTP}${CERTF}"
    touch "${PRIVP}${PRIVF}"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
}

@test "case.1-2-3 証明書ない & 証明書と同名ファイルある & 鍵ない & 鍵と同盟ファイルない" {
    touch "${CERTP}${CERTF}"
    rm -f "${PRIVP}${PRIVF}"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
}

@test "case.1-3-1 証明書ない & 証明書と同名ファイルない & 鍵ある" {
    rm -f "${CERTP}${CERTF}"
    cp -f "${TMP}${PRIVF}" "${PRIVP}${PRIVF}"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is TRUE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
}

@test "case.1-3-2 証明書ない & 証明書と同名ファイルない & 鍵ない & 鍵と同盟ファイルある" {
    rm -f "${CERTP}${CERTF}"
    touch "${PRIVP}${PRIVF}"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
}

@test "case.1-3-3 証明書ない & 証明書と同名ファイルない & 鍵ない & 鍵と同盟ファイルない" {
    rm -f "${CERTP}${CERTF}"
    rm -f "${PRIVP}${PRIVF}"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
}
