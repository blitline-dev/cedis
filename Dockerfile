FROM crystallang/crystal:1.11.2

RUN apt-get update
RUN apt-get install -y nano git

ENV CL_VERSION="1.00.09"


RUN git clone https://github.com/blitline-dev/cedis.git cedis

RUN cd cedis/src && crystal build main.cr -o server --release
RUN cd cedis/src && echo '#!/bin/bash' >> start.sh && echo './server >> /var/log/cedis/cedis.log' >> start.sh
RUN cd cedis/src && chmod 777 start.sh

EXPOSE 9765/tcp
