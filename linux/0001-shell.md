
统计行数:
 if [[ $(echo $result | grep -i "Inactive Completed" | wc -1) -eq "1" ]]
 wc -1命令用于对输出结果进行单词计数，其中-1表示只计算行数

错误重定向：
result=$(kubect1 axyom get smftracesession $1 | tail -n +2 2>&1) 
| tail -n +2 :表示在输出结果中去掉第一行，因为第一行通常是标题，而不是实际输出的内容。
2>&1: 表示将错误信息重定向（redirect）到标准输出，并将其存储在变量result中，以便稍后进行进一步处理。


循环执行某个命令，并统计执行结果：
 count=0 ; for i in {1..10}; do ret=$( ./dcomp exec smf-tester ./smf-tester -d=vzw_product_phase_2_golden_cfg  -tc=test_sess_est_pcf_sgw_race_condition2.json -u=$i |grep "SUCC" | wc -l); ((count+=$ret)); done; echo $count
