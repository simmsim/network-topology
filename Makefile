CC = gcc
CFLAGS = -g

all: dnslookup network_topology
.PHONY: all

dnslookup: dnslookup.c
	$(CC) $(CFLAGS) -o dnslookup dnslookup.c

network_topology: 
	./network_topology.sh url_list.txt

clean:
	rm -f dnslookup traceroute_ipv* ipv* router* 