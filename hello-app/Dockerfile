FROM golang:1.15 as build-env
WORKDIR /go/src/app
ADD main.go /go/src/app
ADD go.mod /go/src/app
RUN go mod tidy
RUN go build -o /go/bin/app

FROM gcr.io/distroless/base
LABEL org.opencontainers.image.authors="Enrique Tejeda"
COPY --from=build-env /go/bin/app /
EXPOSE 8080
CMD ["/app"]
	
