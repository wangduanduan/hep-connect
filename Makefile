version=$(shell cat VERSION)
image_name=eddiemurphy5/hep-connect:latest

DBAddr=
DBName=
DBUserPasswd=

dev:
	watchexec -r -e go -- go run main.go
go:
	go build -o run .
image-build:
	docker build . -t $(image_name)
image-push:
	docker push $(image_name)
test:
	go test -v ./...
run:
	docker run -d \
	-p 3000:3000 \
	-p 9060:9060/udp \
	-e DBAddr="$(DBAddr)" \
	-e DBName="$(DBName)" \
	-e DBUserPasswd="$(DBUserPasswd)" \
	--name hep-connect \
	eddiemurphy5/hep-connect:latest
capture-hep:
	sngrep -c -N -H udp:127.0.0.1:9060
start-uas:
	sipp -sn uas
start-uac:
	sipp -sn uac 127.0.0.1