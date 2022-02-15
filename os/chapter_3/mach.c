#include <mach/mach.h>

struct message {
    mach_msg_header_t header;
    int data;
};

mach_port_t client;
mach_port_t server;

int main(void)
{
    /* client */
    struct message message_client;
    message_client.header.msgh_size = sizeof(message_client);
    message_client.header.msgh_remote_port = server;
    message_client.header.msgh_local_port = client;

    mach_msg(
        &message_client.header, // 메시지 헤더
        MACH_SEND_MSG, // 메시지 송신
        sizeof(message_client), // 송신 메시지의 크기
        0, // 수신 메시지의 최대 크기 - 필요 없음
        MACH_PORT_NULL, // 수신 포트의 이름 포트 없음 - 필요 없음
        MACH_MSG_TIMEOUT_NONE, // 타임아웃 설정 없음
        MACH_PORT_NULL // 포트 없음
    );

    /* server */
    struct message message_server;

    mach_msg(
            &message_server.header, // 메시지 헤더
            MACH_RCV_MSG, // 메시지 수신
            0, // 송신 메시지의 크기
            sizeof(message_server), // 수신 메시지의 최대 크기
            server, // 수신 포트의 이름
            MACH_MSG_TIMEOUT_NONE, // 타임아웃 설정 없음
            MACH_PORT_NULL // 포트 없음
    );
}
