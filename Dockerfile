FROM golang:1.16 AS builder
WORKDIR /src

# avoid downloading the dependencies on succesive builds
RUN apt-get update -qq && apt-get install -qqy \
  build-essential \
  libsystemd-dev

COPY go.mod go.sum ./

RUN go mod download
RUN go mod verify

COPY . .

# Force the go compiler to use modules
ENV GO111MODULE=on
ENV GOOS=linux
ENV GOARCH=amd64
RUN go test
RUN CGO_ENABLED=0 go build -a -tags nosystemd -o /bin/postfix_exporter .

FROM gcr.io/distroless/static:nonroot
EXPOSE 9154
WORKDIR /
COPY --from=builder /bin/postfix_exporter /bin/
USER nonroot:nonroot
ENTRYPOINT ["/bin/postfix_exporter"]
