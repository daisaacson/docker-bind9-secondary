#!/bin/bash
set -eo pipefail

# If forwarders were present, create forwarders directive
function generate_forwarders (){
	if [[ "$1" ]]; then
		echo -en "forwarders { $1 };\n\tforward only;"
	fi
}

# If keys were supplied, create keys and servers directives
function generate_keys (){
	if [[ "$1" ]]; then
		# Initial variables
		KEYS=""
		SERVERS=""
		# Arrays for keeping track of what has been created
		declare -a KEYSCREATED=()
		declare -a SERVERSCREATED=()
		
		# Loop through each string of passed in to parse
		IFS='|' read -ra keys <<< "$1"
		for key in "${keys[@]}"; do
			# Read each variable
			IFS=',' read -r server name algo secret <<< "$key"
			# Test if key has been created yet
			if [[ ! ${KEYSCREATED["$name"]} ]]; then
				KEYS+="key \"${name}\" {\n\talgorithm ${algo};\n\tsecret \"${secret}\";\n};\n"
				KEYSCREATED["$name"]=1
			fi
			# Test if server has been created yet
			if [[ ! ${SERVERSCREATED["${server//./0}"]} ]]; then
				SERVERS+="server ${server} { keys ${name}; };\n"
				SERVERSCREATED["${server//./0}"]=1
			fi
		done
		echo -en "$KEYS\n$SERVERS"
	fi
}

# If recursion list supplied, create recursion directives
function generate_recursion (){
        if [[ "$1" ]]; then
		echo -en "recursion yes;\n\tallow-recursion { $1 };"
	else
		echo -en "recursion no;\n\tallow-recursion { none; };"
	fi
}

# Create secondary zone directives
function generate_secondary_zones (){
	if [[ "$1" ]]; then	
		RETURN=""
		IFS='|' read -ra secondaries <<< "$1"
		for secondary in "${secondaries[@]}"; do
			IFS=',' read -r zone primary <<< "$secondary"
			RETURN+="zone \"${zone}\" {\n\ttype slave;\n\tmasters { ${primary} };\n\tfile \"/var/bind/sec/${zone}\";\n};\n"

		done
		echo -en "$RETURN"
	fi
}

_LISTEN_ON_=${LISTEN_ON:=any;}
_ALLOW_QUERY_=${ALLOW_QUERY:=any;}
_QUERYLOG_=${QUERYLOG:=no;}
_SECONDARY_ZONES_=$(generate_secondary_zones $SECONDARY_ZONES)
_KEYS_=$(generate_keys $KEYS)
_RECURSION_=$(generate_recursion $RECURSION) 
_FORWARDERS_=$(generate_forwarders $FORWARDERS)


mkdir /etc/bind/slaves

cat > /etc/bind/named.conf <<EOF
options {
        directory "/var/bind";

        // Configure the IPs to listen on here.
        listen-on { $_LISTEN_ON_ };
        listen-on-v6 { none; };

        // If you want to allow only specific hosts to use the DNS server:
        allow-query { $_ALLOW_QUERY_ };

        // Specify a list of IPs/masks to allow zone transfers to here.
        //
        // You can override this on a per-zone basis by specifying this inside a zone
        // block.
        //
        // Warning: Removing this block will cause BIND to revert to its default
        //          behaviour of allowing zone transfers to any host (!).
        allow-transfer {
                none;
        };

	querylog $_QUERYLOG_

        // If you have problems and are behind a firewall:
        //query-source address * port 53;

        pid-file "/var/run/named/named.pid";

	$_FORWARDERS_

        // Changing this is NOT RECOMMENDED; see the notes above and in
        // named.conf.recursive.
	$_RECURSION_

	auth-nxdomain no;
};

$_KEYS_

$_SECONDARY_ZONES_

// You can include files:
//include "/etc/bind/example.conf";
EOF

exec "$@"
