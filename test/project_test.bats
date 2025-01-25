setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    DIR="/bats/shell/test/"
    PATH="$DIR/../src/:$PATH"
}

teardown() {
#    rm -f /tmp/bats-tutorial-project-ran
    :
}

@test "case.1-2 Show welcome message on first invocation" {
    if [[ -e /tmp/bats-tutorial-project-ran ]]; then
        skip 'The FIRST_RUN_FILE already exists'
    fi

    run project.sh
    assert_output --partial 'Welcome to our project!'

    run project.sh
    refute_output --partial 'Welcome to our project!'
}