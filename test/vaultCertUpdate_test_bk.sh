#!/usr/bin/env bats

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-mock/stub'

    HOSTNAME="vault01"
    CMN_NAME="${HOSTNAME}.uws.lan"
    TGT_SHELL="vaultCertUpdate.2.sh test"
    CERTP="/etc/pki/tls/certs/"
    CERTF="${CMN_NAME}.crt"
    PRIVP="/etc/pki/tls/private/"
    PRIVF="${CMN_NAME}.key"
    TMP="/tmp/"
    TMP_JSN="${TMP}dum${HOSTNAME}.json"
    UNSEAL_KEY=".vaultUnsealKey"
    TMP_KEY="${TMP}${UNSEAL_KEY}"
    ROOT_KEY="/root/$UNSEAL_KEY"

    MOCK_DIR="/bats/shell/test/mock/"
    cp -f "$TMP_JSN" "${MOCK_DIR}"
    cp -f "$TMP_KEY" "$ROOT_KEY"

    DIR="/bats/shell/test/"
    PATH="$DIR/../src/:$PATH"
}

teardown() {
    # dummy certificate & key
    rm -f "${CERTP}${CERTF}"
    rm -f "${PRIVP}${PRIVF}"
    rm -f "$ROOT_KEY"

    # dummy date data
    rm -f "${MOCK_DIR}"dum*.txt
    rm -f "${MOCK_DIR}"dum*.json
}

@test "case.0 シェルスクリプトが実行可能" {
    skip
    $TGT_SHELL
}

@test "case.1-1-1 証明書ある & 鍵ある & 証明書更新成功" {
    skip "case.2-1-1 ~ 2-1-2にマージ"
    cp -f "${TMP}${CERTF}" "${CERTP}${CERTF}"
    cp -f "${TMP}${PRIVF}" "${PRIVP}${PRIVF}"

    echo "1864000" > "${MOCK_DIR}dumDate.txt"
    echo "1864000" > "${MOCK_DIR}dumLimit.txt"
    echo "0" > "${MOCK_DIR}dumRTN.txt"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is TRUE" ]
    [ "${lines[1]}" = "PRIV_EXIST is TRUE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate needs update." ]
    [ "${lines[5]}" = "CRT_UPD is TRUE." ]
    [ "${lines[6]}" = "0" ]
    [ "${lines[7]}" = "[vault certification]cerfification update is succeeded." ]
}

@test "case.1-1-2 証明書ある & 鍵ない & 鍵と同名ファイルある & 証明書更新失敗" {
    cp -f "${TMP}${CERTF}" "${CERTP}${CERTF}"
    touch "${PRIVP}${PRIVF}"

    echo "1" > "${MOCK_DIR}dumRTN.txt"

    run $TGT_SHELL
    [ "${status}" -eq 5 ]
    [ "${lines[0]}" = "CRT_EXIST is TRUE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate needs creating." ]
    [ "${lines[5]}" = "CRT_UPD is TRUE." ]
    [ "${lines[6]}" = "5" ]
    [ "${lines[7]}" = "[vault certification]cerfification update is abnormal end." ]
}

@test "case.1-1-3 証明書ある & 鍵ない & 鍵と同名ファイルない & vaultリスタート失敗" {
    cp -f "${TMP}${CERTF}" "${CERTP}${CERTF}"
    rm -f "${PRIVP}${PRIVF}"

    echo "0" > "${MOCK_DIR}dumRTN.txt"
    echo "1" > "${MOCK_DIR}dumVaultRTN.txt"

    run $TGT_SHELL
    [ "${status}" -eq 100 ]
    [ "${lines[0]}" = "CRT_EXIST is TRUE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate needs creating." ]
    [ "${lines[5]}" = "CRT_UPD is TRUE." ]
    [ "${lines[6]}" = "notExit" ]
    [ "${lines[7]}" = "[vault certification]cerfification update is succeeded." ]
    [ "${lines[8]}" = "100" ]
    [ "${lines[9]}" = "[vault certification]vault restart is abnormal end." ]
}

@test "case.1-2-1 証明書ない & 証明書と同名ファイルある & 鍵ある" {
    touch "${CERTP}${CERTF}"
    cp -f "${TMP}${PRIVF}" "${PRIVP}${PRIVF}"

    echo "0" > "${MOCK_DIR}dumRTN.txt"
    echo "0" > "${MOCK_DIR}dumVaultRTN.txt"
    echo "1" > "${MOCK_DIR}dumUnsealRTN.txt"
    echo "0" > "${MOCK_DIR}dumCountRTN.txt"

    run $TGT_SHELL
    [ "${status}" -eq 101 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is TRUE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate needs creating." ]
    [ "${lines[5]}" = "CRT_UPD is TRUE." ]
    [ "${lines[6]}" = "notExit" ]
    [ "${lines[7]}" = "[vault certification]cerfification update is succeeded." ]
    [ "${lines[8]}" = "notExit" ]
    [ "${lines[9]}" = "[vault certification]vault is restarted." ]
    [ "${lines[10]}" = "COUNT is 0." ]
    [ "${lines[11]}" = "[vault certification]vault unseal is abnormal end." ]

}

@test "case.1-2-2 証明書ない & 証明書と同名ファイルある & 鍵ない & 鍵と同名ファイルある" {
    touch "${CERTP}${CERTF}"
    touch "${PRIVP}${PRIVF}"

    echo "0" > "${MOCK_DIR}dumRTN.txt"
    echo "0" > "${MOCK_DIR}dumVaultRTN.txt"
    echo "0" > "${MOCK_DIR}dumUnsealRTN.txt"
    echo "3" > "${MOCK_DIR}dumCountRTN.txt"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate needs creating." ]
    [ "${lines[5]}" = "CRT_UPD is TRUE." ]
}

@test "case.1-2-3 証明書ない & 証明書と同名ファイルある & 鍵ない & 鍵と同名ファイルない" {
    touch "${CERTP}${CERTF}"
    rm -f "${PRIVP}${PRIVF}"

    echo "0" > "${MOCK_DIR}dumRTN.txt"
    echo "0" > "${MOCK_DIR}dumVaultRTN.txt"
    echo "0" > "${MOCK_DIR}dumUnsealRTN.txt"
    echo "3" > "${MOCK_DIR}dumCountRTN.txt"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate needs creating." ]
    [ "${lines[5]}" = "CRT_UPD is TRUE." ]
}

@test "case.1-3-1 証明書ない & 証明書と同名ファイルない & 鍵ある" {
    rm -f "${CERTP}${CERTF}"
    cp -f "${TMP}${PRIVF}" "${PRIVP}${PRIVF}"

    echo "0" > "${MOCK_DIR}dumRTN.txt"
    echo "0" > "${MOCK_DIR}dumVaultRTN.txt"
    echo "0" > "${MOCK_DIR}dumUnsealRTN.txt"
    echo "3" > "${MOCK_DIR}dumCountRTN.txt"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is TRUE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate needs creating." ]
    [ "${lines[5]}" = "CRT_UPD is TRUE." ]
}

@test "case.1-3-2 証明書ない & 証明書と同名ファイルない & 鍵ない & 鍵と同名ファイルある" {
    rm -f "${CERTP}${CERTF}"
    touch "${PRIVP}${PRIVF}"

    echo "0" > "${MOCK_DIR}dumRTN.txt"
    echo "0" > "${MOCK_DIR}dumVaultRTN.txt"
    echo "0" > "${MOCK_DIR}dumUnsealRTN.txt"
    echo "3" > "${MOCK_DIR}dumCountRTN.txt"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate needs creating." ]
    [ "${lines[5]}" = "CRT_UPD is TRUE." ]
}

@test "case.1-3-3 証明書ない & 証明書と同名ファイルない & 鍵ない & 鍵と同名ファイルない" {
    rm -f "${CERTP}${CERTF}"
    rm -f "${PRIVP}${PRIVF}"

    echo "0" > "${MOCK_DIR}dumRTN.txt"
    echo "0" > "${MOCK_DIR}dumVaultRTN.txt"
    echo "0" > "${MOCK_DIR}dumUnsealRTN.txt"
    echo "3" > "${MOCK_DIR}dumCountRTN.txt"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is FALSE" ]
    [ "${lines[1]}" = "PRIV_EXIST is FALSE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate needs creating." ]
    [ "${lines[5]}" = "CRT_UPD is TRUE." ]
}

@test "case.2-1-1 証明書ある・鍵ある & (UPDATE_LIMIT < UNX_CUR_DATE) & 証明書更新成功 & vault restart/unseal成功" {
    cp -f "${TMP}${CERTF}" "${CERTP}${CERTF}"
    cp -f "${TMP}${PRIVF}" "${PRIVP}${PRIVF}"

    echo "2864000" >> "${MOCK_DIR}dumDate.txt"
    echo "2564000" >> "${MOCK_DIR}dumLimit.txt"
    echo "0" > "${MOCK_DIR}dumRTN.txt"
    echo "0" > "${MOCK_DIR}dumVaultRTN.txt"
    echo "0" > "${MOCK_DIR}dumUnsealRTN.txt"
    echo "3" > "${MOCK_DIR}dumCountRTN.txt"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is TRUE" ]
    [ "${lines[1]}" = "PRIV_EXIST is TRUE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate needs update." ]
    [ "${lines[5]}" = "CRT_UPD is TRUE." ]
    [ "${lines[6]}" = "notExit" ]
    [ "${lines[7]}" = "[vault certification]cerfification update is succeeded." ]
    [ "${lines[8]}" = "notExit" ]
    [ "${lines[9]}" = "[vault certification]vault is restarted." ]
    [ "${lines[10]}" = "COUNT is 3." ]
    [ "${lines[11]}" = "[vault certification]vault unseal is normal end." ]
}

@test "case.2-1-2 証明書ある・鍵ある & (UPDATE_LIMIT = UNX_CUR_DATE) & 証明書更新失敗" {
    cp -f "${TMP}${CERTF}" "${CERTP}${CERTF}"
    cp -f "${TMP}${PRIVF}" "${PRIVP}${PRIVF}"

    echo "1864000" >> "${MOCK_DIR}dumDate.txt"
    echo "1864000" >> "${MOCK_DIR}dumLimit.txt"
    echo "1" > "${MOCK_DIR}dumRTN.txt"

    run $TGT_SHELL
    [ "${status}" -eq 5 ]
    [ "${lines[0]}" = "CRT_EXIST is TRUE" ]
    [ "${lines[1]}" = "PRIV_EXIST is TRUE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate needs update." ]
    [ "${lines[5]}" = "CRT_UPD is TRUE." ]
    [ "${lines[6]}" = "5" ]
    [ "${lines[7]}" = "[vault certification]cerfification update is abnormal end." ]
}

@test "case.2-1-3 証明書ある・鍵ある & (UPDATE_LIMIT > UNX_CUR_DATE)" {
    cp -f "${TMP}${CERTF}" "${CERTP}${CERTF}"
    cp -f "${TMP}${PRIVF}" "${PRIVP}${PRIVF}"

    echo "1864000" >> "${MOCK_DIR}dumDate.txt"
    echo "2864000" >> "${MOCK_DIR}dumLimit.txt"

    run $TGT_SHELL
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "CRT_EXIST is TRUE" ]
    [ "${lines[1]}" = "PRIV_EXIST is TRUE" ]
    [ "${lines[2]}" = "${CERTP}${CERTF}" ]
    [ "${lines[3]}" = "${PRIVP}${PRIVF}" ]
    [ "${lines[4]}" = "[vault certification]certificate is not update yet." ]
    [ "${lines[5]}" = "CRT_UPD is FALSE." ]
    [ "${lines[6]}" = "0" ]
    [ "${lines[7]}" = "[vault certification]cerfification update process is end." ]
}

@test "case.2-2-1 証明書ない・鍵ない" {
    skip "case.1-3-3にマージ"
}
