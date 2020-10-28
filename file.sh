#!/bin/bash
#by loong576


#批量生成测试文件
for num in {1..5}
do
  dd if=/dev/zero of=myfile_$num.txt bs=1M count=10
done

#生成目录dir并将前3个文件移到该目录
mkdir dir
mv myfile_{1..3}.txt dir
