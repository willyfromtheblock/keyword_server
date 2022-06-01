docker-compose down
git pull
docker build . -t keyword_server
docker-compose up -d