docker run -d \
  --link redis:redis \
  --name lua-api-release \
  -p 8080:8080 \
  lua-api