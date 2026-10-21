*** Settings ***
Library           SSHLibrary
Suite Setup       Connect to Node
Suite Teardown    Close All Connections

*** Variables ***
${SSH_KEYFILE}    %{HOME}/.ssh/id_rsa
${NODE_ADDR}      127.0.0.1

*** Keywords ***
Connect to Node
    Open Connection   ${NODE_ADDR}
    Login With Public Key    root    ${SSH_KEYFILE}
