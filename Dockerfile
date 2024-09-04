FROM golang:1.22.5 AS builder

# ENV GO111MODULE=on GOPROXY=https://goproxy.cn,direct

WORKDIR /app

COPY . .

RUN go build -o run .

FROM alpine:3.14.2

WORKDIR /app
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
RUN apk update && apk add tzdata curl net-tools && cp -r -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo "curl http://localhost:3000/metrics/prometheus" > /app/README.md

COPY --from=builder /app/run .
#COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
ENV TZ=Asia/Shanghai

EXPOSE 9060/udp

ENTRYPOINT ["/app/run"]

