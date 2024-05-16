package test

import (
	"fmt"
	"testing"
)
func TestMy(t *testing.T) {
//  	b :=[]int{1,2,3,4,5}
  	b :=[]int{}
//  	b :=[]int{}
	i := 0
        fmt.Printf("p:%p\n",b)
	for _, n := range b {
            if n == 2 {
	      continue
	    }
	    b[i] = n
	    i ++
		//if k==2 || k==4 {
		//	b[i] = n
		//	i++
		//}
	}
	b = b[:i]
	fmt.Printf("b:%v p:%p\n",b,b)
}
//test result:
//=== RUN   TestMy
//b:[3 5]
