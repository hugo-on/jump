#!/bin/sh

# set up variables
PORT=$PORT

UUID=$UUID
if [ "$UUID" = "" ]; then
  UUID=$(cat /proc/sys/kernel/random/uuid)
fi
WSPATH=$WSPATH
if [ "$WSPATH" = "" ]; then
  WSPATH="/$(cat /proc/sys/kernel/random/uuid)"
fi

mkdir -p /etc/caddy /usr/share/caddy

# caddy file
cat > /etc/caddy/Caddyfile << EOF
:$PORT {
	root * /usr/share/caddy
	file_server

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
<!DOCTYPE html>
<html>
<head>
  <title>Webtools</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://cdn.staticfile.org/twitter-bootstrap/5.1.1/css/bootstrap.min.css" rel="stylesheet">
  <script src="https://cdn.staticfile.org/twitter-bootstrap/5.1.1/js/bootstrap.bundle.min.js"></script>
</head>
<body>

<div class="container mt-3">
  <h2>Login</h2>
	<form action="/" method="post">
	  <div class="mb-3 mt-3">
		<label for="email" class="form-label">Email:</label>
		<input type="email" class="form-control" id="email" placeholder="Enter email" name="email">
	  </div>
	  <div class="mb-3">
		<label for="pwd" class="form-label">Password:</label>
		<input type="password" class="form-control" id="pwd" placeholder="Enter password" name="pswd">
	  </div>
	  <div class="form-check mb-3">
		<label class="form-check-label">
		  <input class="form-check-input" type="checkbox" name="remember"> Remember me
		</label>
	  </div>
	  <button type="submit" class="btn btn-primary">Submit</button>
	</form>
</div>

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
