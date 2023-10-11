package main

import (
	"github.com/dbraley/mcdet/pkg/doer"
	"time"
)

const sleepTime = 5 * time.Second

func main() {
	doer.Init()
	doer.Do(sleepTime)
}
