docker run -d \
  --link redis:redis \
  --name lua-api-debug \
  -v "$(pwd)/app/conf":/opt/openresty/nginx/conf \
  -v "$(pwd)/app/lualib":/opt/openresty/nginx/lualib \
  -v "$(pwd)/app/logs":/opt/openresty/nginx/logs \
  -p 8080:8080 \
  lua-api