docker run -it -p 2019:2019 --rm --name my-script -v "$PWD":/usr/src/myapp -w /usr/src/myapp perls:poe bash
