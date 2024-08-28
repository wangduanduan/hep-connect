package main

import (
	"sipgrep/pkg/hepserver"
	"sipgrep/pkg/pg"
)

func main() {
	pg.Connect()

	go pg.BatchSaveInit()
	hepserver.CreateHepServer()
}
