#include <errno.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>

int main(int argc, char *argv[])
{
    struct addrinfo hints, *ai, *ai0;
    int status;
    int fd;
    char ipstr[INET6_ADDRSTRLEN];

    if (argc < 2) 
    {
        printf("Usage (with one or more hostnames): %s <hostname> \n", argv[0]);
        return 1;
    }

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    int i;
    for(i = 1; i < argc; i++)
    {
        if((status = getaddrinfo(argv[i], "5000", &hints, &ai0)) != 0) 
        {
            printf("Unable to look up IP address: %s", gai_strerror(status));
            return 2;
        }
      
        for (ai = ai0; ai != NULL; ai = ai->ai_next)
        {
            char *ipver;
            void *addr;

            if (ai->ai_family == AF_INET)
            {
                // IPv4
                addr = &((struct sockaddr_in *) ai->ai_addr)->sin_addr;
                ipver = "IPv4";
            } else 
            {
                // IPv6
                addr = &((struct sockaddr_in6 *) ai->ai_addr)->sin6_addr;
                ipver = "IPv6";
            }

            printf("%s ", argv[i]);
            inet_ntop(ai->ai_family, addr, ipstr, sizeof(ipstr));
            printf("%s %s\n", ipver, ipstr);
        }
    }
    freeaddrinfo(ai0);

    return 0;
}