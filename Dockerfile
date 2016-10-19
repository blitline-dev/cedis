FROM crystallang/crystal

RUN apt-get update
RUn apt-get install -y nano

ENV CL_VERSION="1.00.07"

COPY src/ /src
RUN cd /src && crystal compile main.cr -o server --release
RUN cd /src && echo '#!/bin/bash' >> start.sh && echo './server >> /var/log/cedis/cedis.log' >> start.sh
RUN cd /src && chmod 777 start.sh

EXPOSE 9765/tcp
