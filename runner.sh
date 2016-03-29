docker run -d -p 2019:2019 --name perlpoe -v "$PWD":/opt/fauxdelio -w /opt/fauxdelio perls:poe perl fauxdelio -d 2 -c 30
