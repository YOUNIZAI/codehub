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

func TestDelSlice_3(t *testing.T) {
	b :=[]int{1,2,3,4,5}
	i := 0
	for k, n := range b {
		if k==2 || k==4 {
			b[i] = n
			i++
		}
	}
	b = b[:i]
	fmt.Printf("b:%v \n",b)
}

//非排序数组
//使用 struct{} 节省空间， 指定 cap=len(arr) 避免 map 扩容。记录非重复元素索引 j，将元素前移，原地去重，只需一次遍历。
//时间复杂度：O(n)
//空间复杂度：O(n)
func TestDelSlice_4(t *testing.T) {
    removeDuplication_map([]string{"1","2","2","3"))
    removeDuplication_sort([]string{"1","2","2","3"))
}
func removeDuplication_map(arr []string) []string {
    set := make(map[string]struct{}, len(arr))
    j := 0
    for _, v := range arr {
        _, ok := set[v]
        if ok {
            continue
        }
        set[v] = struct{}{}
        arr[j] = v
        j++
    }
    return arr[:j]
}

//已排序数组
//时间复杂度：O(n)
//空间复杂度：O(1)
func removeDuplication_sort(arr []string) []string {
    length := len(arr)
    if length == 0 {
        return arr
    }

    j := 0
    for i := 1; i < length; i++ {
        if arr[i] != arr[j] {
            j++
            if j < i {
                swap(arr, i, j)
            }
        }
    }

    return arr[:j+1]
}

func swap(arr []string, a, b int) {
   arr[a], arr[b] = arr[b], arr[a]
}
			  
