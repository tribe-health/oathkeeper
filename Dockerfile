# To compile this image manually run:
#
# $ make docker
FROM golang:1.16-alpine AS builder

RUN apk add -U --no-cache ca-certificates
RUN apk -U --no-cache add build-base git gcc bash

WORKDIR /go/src/github.com/ory/oathkeeper

ADD go.mod go.mod
ADD go.sum go.sum

ENV GO111MODULE on
ENV CGO_ENABLED 1

RUN go mod download

ADD . .

RUN go build -o /usr/bin/oathkeeper main.go

FROM alpine:3.14.2

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/bin/oathkeeper /usr/bin/oathkeeper
COPY --from=builder /go/src/github.com/ory/oathkeeper/cordico/config.yaml /etc/config/config.yaml
COPY --from=builder /go/src/github.com/ory/oathkeeper/cordico/jwks.json /etc/config/jwks.json
COPY --from=builder /go/src/github.com/ory/oathkeeper/cordico/access-rules.yml /etc/config/access-rules.yml

EXPOSE 4455 4456

USER 1000

ENTRYPOINT ["oathkeeper"]
CMD ["serve", "-c", "/etc/config/config.yaml"]
