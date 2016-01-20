docker run -d -p 2019:2019 --name my-script -v "$PWD":/usr/src/myapp -w /usr/src/myapp perls:poe perl fauxdelio.pl
