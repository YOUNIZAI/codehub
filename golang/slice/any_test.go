package slice_test

import (
	"fmt"
	"testing"
)

func TestDelSlice_1(t *testing.T){
	addApid := []string{"wg","wg","wg","1","2","5","wg"}
	needDle := []string{"wg","3"}
	for _, remove := range needDle {
		for i := 0; i < len(addApid); i++ {
			if addApid[i] == remove {
				end := len(addApid) - 1
				addApid[i] = addApid[end]
				addApid = addApid[:end]
				i--
			}
		}
	}
	fmt.Printf("valie:%v\n",addApid)
}

func TestDelSlice_2(t *testing.T){
	addApid := []string{"wg","wg","wg","1","2","5","wg"}
	needDle := []string{"wg","3"}
	i := 0
	rm := false
	for _, a := range addApid {
		rm = false
		for _,del := range needDle{
			if a == del{
				rm = true
				break
			}
		}
		if !rm {
			addApid[i] = a
			i ++
		}
	}
	addApid = addApid[:i]

	fmt.Printf("valie:%v",addApid)
}
