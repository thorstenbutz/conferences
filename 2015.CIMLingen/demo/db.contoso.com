$TTL	86400
contoso.com.	IN	SOA	sea-dns1.contoso.com. root.contoso.com. (
			      1		
			 604800	
			  86400
			2419200
			  86400);  

		IN	NS	sea-dns1.contoso.com.

sea-dns1	IN	A 	192.168.0.94

sea-test1	IN	A 	192.168.0.1
sea-test2	IN	A 	192.168.0.1
sea-test3 	IN	CNAME   sea-test1.contoso.com.

