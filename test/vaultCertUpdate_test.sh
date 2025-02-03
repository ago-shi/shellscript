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

@test "case.1-1 正常系 - 有効期限到来" {
    ## input 
    # 証明書と鍵の両方が存在している
    # 証明書の有効期限が到来している(UPDATE_LIMIT < EPOC_DATE)
    cp -f "${TMP}${CERTF}" "${CERTP}${CERTF}"
    cp -f "${TMP}${PRIVF}" "${PRIVP}${PRIVF}"

    ## dummyデータ
    # 証明書の有効期限到来(UPDATE_LIMIT < EPOC_DATE)
    echo "2864000" >> "${MOCK_DIR}dumDate.txt"
    echo "2564000" >> "${MOCK_DIR}dumLimit.txt"
    # 証明書作成成功
    echo "0" > "${MOCK_DIR}dumRTN.txt"
    # vault restart成功
    echo "0" > "${MOCK_DIR}dumVaultRTN.txt"
    # vault unseal成功
    echo "0" > "${MOCK_DIR}dumUnsealRTN.txt"
    echo "3" > "${MOCK_DIR}dumCountRTN.txt"

    ## output
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

@test "case.1-2 正常系 - 有効期限未到来" {
    ## input 
    # 証明書と鍵の両方が存在している
    # 証明書の有効期限が到来していない(UPDATE_LIMIT > EPOC_DATE)
    cp -f "${TMP}${CERTF}" "${CERTP}${CERTF}"
    cp -f "${TMP}${PRIVF}" "${PRIVP}${PRIVF}"

    ## dummyデータ
    # 証明書の有効期限到来(UPDATE_LIMIT > EPOC_DATE)
    echo "1864000" >> "${MOCK_DIR}dumDate.txt"
    echo "2864000" >> "${MOCK_DIR}dumLimit.txt"

    ## output
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

@test "case.1-3-1 正常系 - 不正な証明書あり・不正な鍵あり" {
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

@test "case.1-3-2 正常系 - 不正な証明書あり・鍵なし" {
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

@test "case.1-3-3 正常系 - 証明書なし・鍵あり" {
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

@test "case.1-3-4 正常系 - 証明書なし・不正な鍵あり" {
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

@test "case.1-3-5 正常系 - 証明書なし・鍵なし" {
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

@test "case.2-1 異常系 - 証明書作成失敗 + 証明書有効期限チェック同値テスト" {
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

@test "case.2-2 異常系 - vault再起動失敗" {
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

@test "case.2-3 異常系 - vault unseal失敗" {
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
