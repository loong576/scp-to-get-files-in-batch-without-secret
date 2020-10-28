**前言：**

​    在生产运维变更时，有时需要通过免密方式下载远程主机的文件或目录，这时可以使用expect和内部命令 spawn实现该需求。本文模拟通过scp免密获取远程主机指定路径下相关文件和目录至本地服务器。

**环境说明：**

|   主机名    |  操作系统版本   |      ip      | expect version |            备注            |
| :---------: | :-------------: | :----------: | :------------: | :------------------------: |
| ansible-awx | Centos 7.6.1810 | 172.27.34.51 |      5.45      | 本地服务器，获取文件至本地 |
|   client    | Centos 7.6.1810 | 172.27.34.85 |       /        |          远程主机          |

## 一、expect安装

```bash
[root@ansible-awx ~]# which expect         
/usr/bin/which: no expect in (/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin)
[root@ansible-awx ~]# yum -y install expect
```

![image-20201028160144771](https://i.loli.net/2020/10/28/GvfSmMTC4d5kej6.png)

若没有expect命令，则需安装

## 二、构造测试文件和目录

```bash
[root@client product]# pwd
/root/product
[root@client product]# ll
总用量 4
-rwxr--r-- 1 root root 218 10月 28 14:23 file.sh
[root@client product]# more file.sh 
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
[root@client product]# ./file.sh 
记录了10+0 的读入
记录了10+0 的写出
10485760字节(10 MB)已复制，0.0125638 秒，835 MB/秒
记录了10+0 的读入
记录了10+0 的写出
10485760字节(10 MB)已复制，0.0149011 秒，704 MB/秒
记录了10+0 的读入
记录了10+0 的写出
10485760字节(10 MB)已复制，0.0159792 秒，656 MB/秒
记录了10+0 的读入
记录了10+0 的写出
10485760字节(10 MB)已复制，0.0190673 秒，550 MB/秒
记录了10+0 的读入
记录了10+0 的写出
10485760字节(10 MB)已复制，0.0260948 秒，402 MB/秒
[root@client product]# ll
总用量 20484
drwxr-xr-x 2 root root       66 10月 28 15:25 dir
-rwxr--r-- 1 root root      218 10月 28 14:23 file.sh
-rw-r--r-- 1 root root 10485760 10月 28 15:25 myfile_4.txt
-rw-r--r-- 1 root root 10485760 10月 28 15:25 myfile_5.txt
[root@client product]# tree
.
├── dir
│   ├── myfile_1.txt
│   ├── myfile_2.txt
│   └── myfile_3.txt
├── file.sh
├── myfile_4.txt
└── myfile_5.txt

1 directory, 6 files
```

![image-20201028152638685](https://i.loli.net/2020/10/28/BWVFmEhPMsQ1uXr.png)

在远程主机client的/root/product路径下，使用dd命令构造测试文件myfile_{1..5}.txt和目录dir，每个文件10M，其中1、2、3号文件在dir目录中。

## 三、免密脚本

### 1.scp.sh

```bash
[root@ansible-awx files]# cd
[root@ansible-awx ~]# cd scp
[root@ansible-awx scp]# ll
总用量 8
-rwxr--r-- 1 root root 236 10月 28 15:21 scp_file_dir.sh
-rwxr--r-- 1 root root 501 10月 28 15:18 scp.sh
[root@ansible-awx scp]# more scp.sh 
#!/usr/bin/expect
set timeout 10
set host [lindex $argv 0]
set username [lindex $argv 1]
set password [lindex $argv 2]
set file1 [lindex $argv 3]
set file2 [lindex $argv 4]
set dir [lindex $argv 5]
set local_path [lindex $argv 6]
set dest_path [lindex $argv 7]

spawn scp -r $username@$host:$dest_path/\{$file1,$file2,$dir\} $local_path
 expect {
 "(yes/no)?"
  {
    send "yes\n"
    expect "*assword:" { send "$password\n"}
  }
 "*assword:"
  {
    send "$password\n"
  }
}
expect "100%"
expect eof
```

一共8个参数

> **$argv 0:**远程主机ip
>
> **$argv 1:**连接远程主机的用户
>
> **$argv 2:**连接远程主机的密码
>
> **$argv 3:**要获取的文件名1
>
> **$argv 4:**要获取的文件名2
>
> **$argv 5:**要获取的目录名
>
> **$argv 6:**获取文件保存的本地路径
>
> **$argv 7:**远程主机文件所在路径

scp.sh为基础脚本，供后面的scp_file_dir.sh调用

### 2.scp_file_dir.sh

```bash
[root@ansible-awx scp]# more scp_file_dir.sh 
#!/bin/bash

IP=172.27.34.85
USER=root
PASSWD=monitor123!
DEST1=myfile_4.txt
DEST2=myfile_5.txt
DEST3=dir
LOCAL_PATH=/tmp/files
DEST_PATH=/root/product

$HOME/scp/scp.sh   $IP $USER $PASSWD  $DEST1 $DEST2 $DEST3 $LOCAL_PATH  $DEST_PATH
```

根据实际情况填写对应的8个参数

## 四、运行测试

```bash
[root@ansible-awx scp]# pwd
/root/scp
[root@ansible-awx scp]# ll
总用量 8
-rwxr--r-- 1 root root 236 10月 28 15:21 scp_file_dir.sh
-rwxr--r-- 1 root root 501 10月 28 15:18 scp.sh
[root@ansible-awx scp]# ./scp_file_dir.sh 
spawn scp -r root@172.27.34.85:/root/product/{myfile_4.txt,myfile_5.txt,dir} /tmp/files
root@172.27.34.85's password: 
myfile_4.txt                                                                                                                                            100%   10MB  60.2MB/s   00:00    
myfile_5.txt                                                                                                                                            100%   10MB  58.9MB/s   00:00    
myfile_1.txt                                                                                                                                            100%   10MB  67.6MB/s   00:00    
myfile_2.txt                                                                                                                                            100%   10MB  62.8MB/s   00:00    
myfile_3.txt                                                                                                                                            100%   10MB  64.1MB/s   00:00    
[root@ansible-awx scp]# cd /tmp
[root@ansible-awx tmp]# cd files/
[root@ansible-awx files]# tree 
.
├── dir
│   ├── myfile_1.txt
│   ├── myfile_2.txt
│   └── myfile_3.txt
├── myfile_4.txt
└── myfile_5.txt

1 directory, 5 files
[root@ansible-awx files]# du -sm *
30      dir
10      myfile_4.txt
10      myfile_5.txt
```

![image-20201028154156820](https://i.loli.net/2020/10/28/WOXBDzmciy8uw1Y.png)

运行scp_file_dir.sh，免密获取相关文件和目录，下载至本地/tmp/files目录。

测试符合预期。



&nbsp;

&nbsp;

**本文所有脚本和配置文件已上传github：**[ansible-production-practice-5](https://github.com/loong576/ansible-production-practice-5/archive/main.zip)
