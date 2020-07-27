*** Settings ***
Documentation    Test that all allowed profile realted actions via the REST API work as intended.
Force Tags       positive    profile
Library          Collections
Library          REST    ${BACKUP_HOST}
Library          RequestsLibrary
Library         ../libraries/rest_utils.py
Library         ../libraries/utils.py
Suite setup     Create REST session and auth

*** Variables  ***
${BACKUP_HOST}    http://localhost:7101/api/v1


*** Test Cases ***
Add an empty profile
    [Tags]   post
    [Documentation]    Attempt to add a profile with name 'empty' that has no tasks or description.
    POST        /profile/empty      {}    headers=${BASIC_AUTH}
    Integer     response status     200
    GET         /profile/empty      headers=${BASIC_AUTH}
    Object      response body       required=["name"]    properties={"name":{"type":"string","const":"empty"},"description":{"type":"null"},"tasks":{"type":"null"}}

Try add profile with short name
    [Tags]    post
    Add profile and confirm addition    aa     ""    []    []

Try add profile with alphanumeric name
    [Tags]    post
    Add profile and confirm addition    alpha-numeric_1     ""    []    []

Try add profile with long name and description
    [Tags]    post
    ${name}=           Generate random string    50
    ${description}=    Generate random string    120
    Add profile and confirm addition    ${name}     "${description}"    []    []

*** Keywords ***
Set basic auth
    [Arguments]        ${username}=Administrator    ${password}=asdasd
    [Documentation]    Sets a suite variable BASIC_AUTH with the encoded basic auth to use in request headers.
    ${auth}=              Get basic auth        ${username}    ${password}
    Set suite variable    ${BASIC_AUTH}         {"authorization":"${auth}"}

Add profile and confirm addition
    [Arguments]        ${name}    ${description}=None    ${services}=None    ${tasks}=None
    [Documentation]    Adds a new profile.
    POST               /profile/${name}    {"description":${description},"services":${services},"tasks":${tasks}}
    ...                headers=${BASIC_AUTH}
    Integer            response status     200
    ${resp}=           Get request         backup_service    /profile/${name}
    Status should be   200                 ${resp}
    Dictionaries should be equal    ${resp.json()}    {"name":"${name}","description":${description},"services":${services},"tasks":${tasks}}

Create REST session
    [Arguments]        ${user}    ${password}
    [Documentation]    Creates a client that can be used to communicate to the client instead of creating one per test.
    ${auth}=           Create List             ${user}                 ${password}
    Create session     backup_service          ${BACKUP_HOST}          auth=${auth}

Create REST session and auth
    [Arguments]        ${username}=Administrator    ${password}=asdasd
    Set basic auth         ${username}    ${password}
    Create REST session    ${username}    ${password}
