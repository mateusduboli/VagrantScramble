;
;	Bind data file for local.scramble.io
;
$TTL	604800
@	IN	SOA	local.scramble.io.	root.local.scramble.io. (
	4	; Serial
604800	; Refresh
86400	; Retry
60		; Expire
604800	; Negative Cache TTL
)

	IN	A	127.0.0.1
@	IN	NS	ns
@	IN	A	127.0.0.1
ns	IN	A	127.0.0.1
teste	IN	A	127.0.0.1
mail	IN	A	127.0.0.1
@	IN	MX	10	mail.local.scramble.io.
