# Serve local.scramble.io
# The application server (Go)
upstream app_scramble {
	server 127.0.0.1:8888;
}

# Handle SSL connections. Forward to the Scramble application server.
# Logs should be expired and securely deleted regularly
server {
	server_name local.scramble.io;

	listen 443;
	ssl on;
	ssl_certificate /etc/ssl/local.scramble.io.crt;
	ssl_certificate_key /etc/ssl/local.scramble.io.key;

	location / {
		proxy_pass http://app_scramble/;
		proxy_redirect off;
		proxy_set_header Host $host;
	}
}
# Redirect HTTP to HTTPS
server {
	server_name local.scramble.io;
	listen 80;
	return 301 https://$host$request_uri;
}
