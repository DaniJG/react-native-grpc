FROM golang:1.9

RUN apt-get update && apt-get install -y unzip

# Install protobuf
RUN mkdir -p /usr/bin/protoc \
  # now fetch a zip from https://github.com/google/protobuf/releases and unpack it into proto/
  && GOPROTO=protoc-3.5.1-linux-x86_64.zip \
  && wget https://github.com/google/protobuf/releases/download/v3.5.1/$GOPROTO \
  && unzip ./$GOPROTO -d /usr/bin/protoc \
  && rm $GOPROTO

# Install go packages (Should this use go-wrapper according to docker hub instructions?)
RUN go get -u google.golang.org/grpc \
  && go get -u github.com/golang/protobuf/proto \
  && go get -u github.com/golang/protobuf/protoc-gen-go

# Copy the code
WORKDIR /go/src/github.com/danijg/react-native-grpc/server/helloworld
COPY ./proto ./proto
COPY ./server ./server

# Generate grpc server impl from protobuf
RUN /usr/bin/protoc/bin/protoc --proto_path=proto --go_out=plugins=grpc:server/helloworld helloworld.proto

# Run the server (Again, should it use go-wrapper run?)
ENV PORT=50050
EXPOSE $PORT
CMD ["go", "run", "./server/main.go"]