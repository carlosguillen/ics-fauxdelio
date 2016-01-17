FROM perl:5.22
COPY . /usr/src/myapp
WORKDIR /usr/src/myapp
RUN apt-get update && apt-get install -y vim
RUN cpan App::cpanminus
RUN cpanm --notest Inline::Files Data::Faker POE
