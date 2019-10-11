```
<VirtualHost *:80>
  RewriteEngine On
  # Redirect all non-static requests to unicorn
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteRule ^/(.*)$ balancer://unicornservers%{REQUEST_URI} [P,QSA,L]

  <Proxy balancer://unicornservers>
    Allow from any
    BalancerMember http://127.0.0.1:8080
  </Proxy>
</VirtualHost>
```
