1.只是安装工具，不需要init mod, 可以这样：GO111MODULE=off go get xxx
2.go get xxx  安装工具时候, 源代码包不会被移除在编译完成后, 源码包放在/usr/local/gopath/src 下面, 可以手动移除。
3.go get xxx  安装工具,编译的可执行文件放在 /usr/local/gopath/bin 
