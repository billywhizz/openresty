wrk -t 2 -c 10 -d 10 -s bench.lua http://127.0.0.1:8080/
wrk -t 2 -c 100 -d 10 -s bench.lua http://127.0.0.1:8080/
wrk -t 2 -c 500 -d 10 -s bench.lua http://127.0.0.1:8080/