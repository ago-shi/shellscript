#!/usr/bin/env bats

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    DIR="/bats/shell/test/"
    PATH="$DIR/../src/:$PATH"
}

teardown() {
    rm -f /etc/pki/tls/certs/vault01.uws.lan.crt
    rm -f /etc/pki/tls/private/vault01.uws.lan.key
}
@test "case.0 シェルスクリプトが実行可能" {
    vaultCertUpdate.2.sh
}

@test "case.1-1 証明書ある & 鍵ある" {
    touch /etc/pki/tls/certs/vault01.uws.lan.crt
    touch /etc/pki/tls/private/vault01.uws.lan.key

    run vaultCertUpdate.2.sh
    [ "$status" -eq 0 ]
    [[ "$CRT_EXISTS" == "TRUE" ]]
    [[ "$PRIV_EXISTS" == "TRUE" ]]

    rm -f /etc/pki/tls/certs/vault01.uws.lan.crt
    rm -f /etc/pki/tls/private/vault01.uws.lan.key
}
