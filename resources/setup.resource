*** Settings ***
Library           Process
Library           OperatingSystem
Library           ../libraries/setup_utils.py

*** Variables ***
${NS_SERVER_PATH}      %{HOME}${/}source${/}ns_server
${COUCHBASE_LOG_PATH}  ${NS_SERVER_PATH}${/}logs${/}n_1
${BACKUP_NODE}         http://localhost:7101
${WAIT_UNTIL_READY}    25
${RUNNING_MODE}        CV
${SKIP_SETUP}          False
${SKIP_TEARDOWN}       False
${DELETE_LOGS}         False

*** Keywords ***
Remove cluster run data and logs
    [Documentation]    This will remove the data and log directories created by cluster run.
    Remove Directory    ${NS_SERVER_PATH}/logs    recursive=True
    Remove Directory    ${NS_SERVER_PATH}/data    recursive=True

Start ${node_num} cluster run nodes
    [Documentation]
    ...    This will start "node_num" cluster run nodes. Note that node_num must be an int bigger or equal
    ...    to 1. For this purpose it will look under the "NS_SERVER_PATH" variable which must be provided
    ...    in the command line. Before starting the node it will clean the logs and data. After starting
    ...    cluster run it will wait for 5 seconds for it to be ready, by default but this can be configured.
    Remove cluster run data and logs
    Start Process    ./cluster_run     --nodes    ${node_num}    --dont-rename    cwd=${NS_SERVER_PATH}    alias=cluster    stdout=DEVNULL    stderr=DEVNULL
    Log      cluster run process started
    Sleep    ${WAIT_UNTIL_READY}
    Log      Waited for ${WAIT_UNTIL_READY} seconds


Start cluster_run nodes and connect them
    [Arguments]    ${node_num}=1    ${connect_nodes}=1    ${services}=n0:kv+backup    ${data_size}=256
    [Documentation]
    ...    Shortcut to start nodes and connect them in one keyword. This can be skip by setting the command line
    ...    variable 'SKIP_SETUP' to true.
    Run keyword if     ${SKIP_SETUP}                Return from keyword
    Start ${node_num} cluster run nodes
    Connect nodes    ${NS_SERVER_PATH}    ${connect_nodes}    ${services}    ${data_size}    wait_for=${WAIT_UNTIL_READY}

Environment dependent clean up
    [Documentation]
    ...    This function will stop the running cluster and will delete the data if the running mode is CV. This can be
    ...    skipped by setting the command line variable 'SKIP_TEARDOWN' to true.
    Run keyword if     ${SKIP_TEARDOWN}                Return from keyword
    Run keyword if     "${RUNNING_MODE}" == "CV"    Clean up running nodes
    ...    ELSE        Stop nodes and clean up data only if test pass

Clean up running nodes
    [Documentation]      This will stop and clear any data created by the running nodes.
    Log                  Terminating cluster
    Terminate process    cluster    kill=true
    Log                  Cluster terminated
    Run keyword if       ${DELETE_LOGS}                 Remove cluster run data and logs

Stop nodes and clean up data only if test pass
    [Documentation]
    ...    This is meant to be used as a teardown function locally where the logs and data dont get cleaned up if the
    ...    test fails.
    Terminate process                  cluster
    Run keyword if all tests passed    Remove cluster run data and logs
