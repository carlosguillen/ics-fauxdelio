docker run -d -p 2019:2019 --name fauxdelio -v "$PWD":/usr/src/myapp -w /usr/src/myapp docker-hub-int.mtnsat.io/fauxdelio:v3 perl fauxdelio -d 2 -c 30
