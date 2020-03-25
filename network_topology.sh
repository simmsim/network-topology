#!/bin/bash

function run_traceroute() {
    res=""
    while IFS= read -r line
    do
        while IFS= read -r out
        do  
            addr_ipv4="$(echo "$out" | awk '{print $2;}')"
            if [[ $addr_ipv4 =~ [0-9] && $addr_ipv4 == *[\.]* ]]; then
                res+="${addr_ipv4} "
            fi
        done <<<$(traceroute -4 -q 1 -n "$line")
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

    dot -T pdf -o router-topology-v4.dot.pdf "$1"
}

hostnames=$1
if [[ $# -eq 0 ]]; then
    echo "Invalid number of arguments supplied!"
    echo "Usage: ./network_topology.sh <filename>"
    exit 1
fi

traceroute_ipv4='traceroute_ipv4.txt'
traceroute_ipv6='traceroute_ipv6.txt'

processed_ipv4='router-topology-v4.dot'
processed_ipv6='router-topology-v6.dot'

traceroute_files=('traceroute_ipv4.txt' 'traceroute_ipv6.txt')
processed_files=('router-topology-v4.dot' 'router-topology-v6.dot')
address_files=('ipv4.txt' 'ipv6.txt')

#files=($traceroute_ipv4 $traceroute_ipv6 $processed_ipv4 $processed_ipv6 "${address_files[@]}")
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
run_traceroute $traceroute_ipv4 ${address_files[0]}

# Process IPv4 traceroute file
process_traceroute $processed_ipv4 $traceroute_ipv4

# Produce topology for IPv4 traceroute
produce_topology $processed_ipv4

# for i in "${!address_files[@]}"; do
#     run_traceroute ${traceroute_files[$i]} ${address_files[$i]}
#     process_traceroute "${processed_files[$i]}" "${traceroute_files[$i]}"
#     produce_topology "${processed_files[$i]}"
# done


