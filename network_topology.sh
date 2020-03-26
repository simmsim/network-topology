#!/bin/bash

function run_traceroute() {
    res=""
    while IFS= read -r line
    do
        while IFS= read -r out
        do  
            addr="$(echo "$out" | awk '{print $2;}')"
            if [[ $addr =~ [0-9] && $addr == *[\.]* || $addr == *[:]* ]]; then
                res+="${addr} "
            fi
        done <<<$(traceroute -$3 -q 1 -n "$line")
        echo ${res} >> "$1"
        echo -e >> "$1"
        res=""
    done < $2
}

function process_traceroute() {
    while IFS= read -r line
    do
        line_len="$(echo "$line" | wc -w)"
        for ((i = 1; i < $line_len; i++)); do
            out="$(echo "$line" | cut -d " " -f $i)"
            j=$(($i+1))
            in="$(echo "$line" | cut -d " " -f $j)"
            first="\"${out}\" -- \"${in}\""
            echo "$first" >> "$1"
        done
    done < $2
}

function produce_topology() {
    echo "$(sort "$1" | uniq)" > "$1"
    sed -i '1i graph routertopology {' "$1"
    echo "}" >> "$1"

    dot -T pdf -o "$2" "$1"
}

hostnames=$1
if [[ $# -eq 0 ]]; then
    echo "Invalid number of arguments supplied!"
    echo "Usage: ./network_topology.sh <filename>"
    exit 1
fi

traceroute_files=('traceroute_ipv4.txt' 'traceroute_ipv6.txt')
processed_files=('router-topology-v4.dot' 'router-topology-v6.dot')
address_files=('ipv4.txt' 'ipv6.txt')
graph_files=('router-topology-v4.dot.pdf' 'router-topology-v6.dot.pdf')

files=("${traceroute_files[@]}" "${processed_files[@]}" "${address_files[@]}")

#Remove files from previous run
for i in "${files[@]}"; do
    if [[ -e $i ]]; then
        rm $i
    fi
done

# Read hostnames from file and for each run dnslookup
while IFS= read -r line
do
    ./dnslookup "$line" |
        while IFS= read -r out
        do  
            addr="$(echo "$out" | awk '{print $3;}')"
            if [[ $(echo "$out" | awk '{print $2;}') == "IPv4" ]]; then
                echo ${addr} >> "${address_files[0]}"
            elif [[ $(echo "$out" | awk '{print $2;}') == "IPv6" ]]; then
                echo ${addr} >> "${address_files[1]}"
            fi
        done
done < "$hostnames"

# For IPv4
run_traceroute ${traceroute_files[0]} ${address_files[0]} 4

# Process IPv4 traceroute file
process_traceroute ${processed_files[0]} ${traceroute_files[0]}

# Produce topology for IPv4 traceroute
produce_topology ${processed_files[0]} ${graph_files[0]}

# For Ipv6 (check first, not all ISPs provide IPv6 connection)
ping6 ipv6.google.com 2> /dev/null

if [[ $? -eq 0 ]]; then
    run_traceroute ${traceroute_files[1]} $traceroute_ipv6 ${address_files[1]} 6
    process_traceroute ${processed_files[1]} ${traceroute_files[1]}
    produce_topology ${processed_files[1]} ${graph_files[1]}
else
    echo "IPv6 traceroute could not be performed. Check for IPv6 connection support."
fi



