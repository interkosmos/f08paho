! publish.f90
!
! Example that shows how to connect to an MQTT message broker and publish to a
! topic.
!
! Author:   Philipp Engel
! Licence:  ISC
program main
    use, intrinsic :: iso_c_binding
    use :: paho
    implicit none

    character(len=*), parameter :: ADDRESS   = 'tcp://localhost:1883'
    character(len=*), parameter :: CLIENT_ID = 'FortranPubClient'
    character(len=*), parameter :: TOPIC     = 'fortran'
    character(len=*), parameter :: TEXT      = 'Hello, World!'
    integer,          parameter :: QOS       = 1
    integer,          parameter :: TIMEOUT   = 10000

    type(c_ptr)                       :: client
    type(mqtt_client_connect_options) :: conn_opts = MQTT_CLIENT_CONNECT_OPTIONS_INITIALIZER
    type(mqtt_client_message)         :: pub_msg   = MQTT_CLIENT_MESSAGE_INITIALIZER
    integer                           :: token
    integer                           :: rc

    ! The payload string.
    character(len=len(TEXT) + 1, kind=c_char), target :: payload = TEXT // c_null_char

    ! Create MQTT client.
    rc = mqtt_client_create(client, &
                            ADDRESS // c_null_char, &
                            CLIENT_ID // c_null_char, &
                            MQTTCLIENT_PERSISTENCE_NONE, &
                            c_null_ptr)

    conn_opts%keep_alive_interval = 20
    conn_opts%clean_session       = 1

    ! Connect to MQTT message broker.
    rc = mqtt_client_connect(client, conn_opts)

    if (rc /= MQTTCLIENT_SUCCESS) then
        print '(a, i0)', 'Failed to connect, return code ', rc
        stop
    end if

    pub_msg%payload     = c_loc(payload)
    pub_msg%payload_len = len(payload)
    pub_msg%qos         = QOS
    pub_msg%retained    = 0

    rc = mqtt_client_publish_message(client, TOPIC // c_null_char, pub_msg, token)
    print '(a, i0, 7a)', 'Waiting for up to ', TIMEOUT / 1000, ' second(s) for publication of "', &
                         trim(payload), '" on topic "', TOPIC, '" for client with client id "', &
                         CLIENT_ID, '"'

    rc = mqtt_client_wait_for_completion(client, token, int(TIMEOUT, kind=8))
    print '(a, i0, a)', 'Message with delivery token ', token, ' delivered'

    rc = mqtt_client_disconnect(client, TIMEOUT)
    call mqtt_client_destroy(client)
end program main
