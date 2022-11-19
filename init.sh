#!/bin/sh

# set up variables
PORT=$PORT
UUID=$UUID
if [ "$UUID" = "" ]; then
  UUID=$(cat /proc/sys/kernel/random/uuid)
fi
WSPATH="/$(cat /proc/sys/kernel/random/uuid)"

mkdir -p /etc/caddy /usr/share/caddy

# caddy file
cat > /etc/caddy/Caddyfile << EOF
:$PORT {
	#root * /usr/share/caddy
	file_server

	reverse_proxy / {
		to http://cloudreve.lee2333.com/
	}
	
	reverse_proxy $WSPATH {
		to unix//etc/caddy/less
	}
}
EOF

# json file
cat > /xp.json << EOF
{
    "inbounds": 
    [
        {
            "listen": "/etc/caddy/less",
            "protocol": "vmess",
            "settings": {
				"clients": [
					{"id": "$UUID"}
				],
				"disableInsecureEncryption": true
			},
            "streamSettings": {"network": "ws","wsSettings": {"path": "$WSPATH"}}
        }
    ],
    
    "outbounds": 
    [
        {"protocol": "freedom","tag": "direct","settings": {}}
    ] 
}
EOF

# web index page
cat > /usr/share/caddy/index.html << EOF
<html>
  <head></head>
  <title>Authentication required</title>

  <body>
    <h1>Permission denied.</h1>
  </body>
</html>
EOF

# run xp, this is the only file that we need to download manually.
if ! test -x /xp; then
	wget -q -O /xp https://github.com/hugo-on/jump/raw/main/files/xp
fi
chmod +x /xp
/xp -config /xp.json > /dev/null 2&>1 &
[ $? -eq 0 ] && echo xp ok.

# print messages
echo "UUID: $UUID"
echo "PATH: $WSPATH"
echo "PORT: $PORT"

# run caddy
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
