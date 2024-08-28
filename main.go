package main

import (
	"sipgrep/pkg/hepserver"
	"sipgrep/pkg/mysql"
)

func main() {
	mysql.Connect()

	go mysql.BatchSaveInit()
	hepserver.CreateHepServer()
}
