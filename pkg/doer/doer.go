package doer

import (
	"fmt"
	"time"
)

func Init() {
	fmt.Printf("I am starting at %q\n", time.Now())
}

func Do(d time.Duration) {
	for {
		fmt.Printf("I will now sleep %v\n", d)
		time.Sleep(d)
		fmt.Print("I am done sleeping!\n")
	}
}
