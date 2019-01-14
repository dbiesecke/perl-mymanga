FROM metabrik/metabrik
MAINTAINER dbiesecke


RUN apt-get update && apt-get upgrade -y -f 
RUN  apt-get install libdist.+-perl librest.+-perl liblwp.+-perl libdancer.+-perl libanyevent.+-perl libmoose.+-perl -f -y

ADD . /project
COPY ./bin/intcpan /bin/intcpan
RUN chmod +x /bin/intcpan
WORKDIR /project


RUN cpanm -n Dist::Zilla App::cpanminus AnyData AnyEvent AnyEvent::HTTP AnyEvent::HTTPD App::Daemon Archive::Zip autodie base Cache::Memcached::Fast Carp constant Dancer Dancer::Plugin::WebSocket Dancer::Request Data::Dumper Data::Table DateTime DBD::SQLite DBI Elastic::Doc Elastic::Model Exporter ExtUtils::MakeMaker File::Copy File::Fetch File::HomeDir File::Slurp File::Spec File::Temp Finance::Bank::Kraken FindBin HTML::Form HTML::HeadParser HTML::TokeParser HTML::TreeBuilder HTTP::Cookies HTTP::Request HTTP::Request::Common Inline IO::Handle IO::Socket Plugin::Tiny App::Daemon || echo true

RUN dzil authordeps --missing |  cpanm -n --installdeps  -S 
RUN dzil authordeps --missing |  cpanm -n  -f
RUN cpanm -n . || echo true

RUN dzil install 


#EXPOSE 9999

#CMD ["exec", "", "--listen",":9999",""]

ENTRYPOINT ["mymanga"]
