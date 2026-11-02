*** Settings ***
Library    SSHLibrary

*** Test Cases ***
Check if vaultwarden is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Check if vaultwarden can be configured
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host":"vault.example.org","http2https":false,"lets_encrypt":false,"admin_enabled":true}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if vaultwarden configuration can be read
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/get-configuration
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{config} =    Evaluate    json.loads('''${output}''')    modules=json
    Should Be Equal As Strings    ${config.host}    vault.example.org
    Should Be Equal    ${config.admin_enabled}    ${True}

Check if vaultwarden works as expected
    Wait Until Keyword Succeeds    30 sec    3 sec
    ...    Execute Command    curl -f -H "Host: vault.example.org" http://127.0.0.1/alive
    ${rc} =    Execute Command    curl -f -H "Host: vault.example.org" http://127.0.0.1/alive
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if vaultwarden is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
