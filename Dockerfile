FROM crystallang/crystal

RUN apt-get update
RUn apt-get install -y nano

ENV CL_VERSION="1.00.02"

COPY src/ /src
RUN cd /src && crystal compile main.cr -o server --release

EXPOSE 9765/tcp
