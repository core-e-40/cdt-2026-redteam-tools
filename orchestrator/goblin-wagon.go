package main 

import (
	"fmt"
	"runtime"
	"unicode"
)

type Platform struct {
	OS string
	Arch string
}

func is_only_letters(s string) bool {
	for _, character := range s{
		if !unicode.IsLetter(character){
			return false
		}
	}
	return true
}

func main(){
	
	host_os := runtime.GOOS
	arch := runtime.GOARCH
	
	// used to format to get only the number in 'intelXX' or 'amdXX'
	if !is_only_letters(arch){
		arch = arch[len(arch)-2:]
	} 


	binaries := map[Platform]string {
		{OS: "windows", Arch:"64"} : "WINDOWS - x64",
		{OS: "windows", Arch:"86"} : "WINDOWS - x86",
		{OS: "windows", Arch:"arm"} : "WINDOWS - ARM",
		{OS: "linux", Arch:"64"} : "LINUX - x64",
		{OS: "linux", Arch:"86"} : "LINUX - x86",
		{OS: "linux", Arch:"arm"} : "LINUX - ARM",
	}

	fmt.Println(binaries[Platform{OS: host_os, Arch: arch}])

}