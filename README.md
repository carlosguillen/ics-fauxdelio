# fauxdelio_testing

Perl Docker image with POE and other modules

### Build it
```bash
host > docker build -t perls:poe .
```

### Run it
```bash
host > bash runner.sh
root@ee89d04b2b23:/usr/src/myapp# perl fauxdelio.pl
```

Why a Docker image to run a script? Mostly because of the module deps and the fact that it can be extended to do other things
