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
