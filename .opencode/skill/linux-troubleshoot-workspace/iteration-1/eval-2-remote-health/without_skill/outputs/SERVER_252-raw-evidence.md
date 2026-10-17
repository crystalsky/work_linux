# SERVER_252 巡检原始证据（只读采集）

采集时间：2026-10-08 17:51 CST
连接方式：ssh -o BatchMode=yes -o ConnectTimeout=5 SERVER_252

## 1. 系统标识
```
192.168.16.252
luli
Linux 5.14.0-687.10.1.el9_8.0.1.x86_64 #1 SMP PREEMPT_DYNAMIC Sun May 24 12:01:19 UTC 2026 x86_64
NAME="Rocky Linux"  VERSION="9.8 (Blue Onyx)"  ID="rocky"
```

## 2. 负载 / CPU / 内存
```
 17:50:40 up 85 days,  1:24,  3 users,  load average: 6.91, 6.18, 6.27
CPU(s): 112  Model name: Intel(R) Xeon(R) Platinum 8280 CPU @ 2.70GHz
Mem:  total 257022  used 202190  free 4381  buff/cache 54357  available 54831
Swap: total 4095   used 4095   free 0
/dev/dm-1 partition 4G 4G -2
```
/proc/stat cpu 累计：user=2781694947 system=615938154 idle=78493637821 iowait=23016888 softirq=160855932 steal=0  ==> idle≈95.4%

## 3. 内存明细
```
MemTotal: 263190980 kB
MemFree: 4158200 kB
MemAvailable: 55768352 kB
SwapTotal: 4194300 kB
SwapFree: 100 kB            <== 耗尽
Committed_AS: 219914468 kB  <== 210G
CommitLimit: 135789788 kB   <== 129G
vm.overcommit_memory = 0
vm.swappiness = 60
```

## 4. 磁盘
```
/dev/mapper/rlm-root xfs  500G  138G  363G  28% /
/dev/sdb1            xfs  960M  398M  563M  42% /boot
/dev/mapper/rlm-home xfs  300G  2.6G  298G   1% /home
/dev/sda1            xfs   26T  6.3T   20T  25% /data
inode 使用率均 <=1%
```

## 5. 服务与失败单元
```
systemctl --failed -> 0 loaded units listed.
running: auditd chronyd crond dbus-broker docker firewalld gssproxy irqbalance
         jenkins-agent libvirtd NetworkManager polkit rsyslog sshd journald
         logind machined udevd user@0 user@1001 virtlogd
```

## 6. libvirtd 错误（本次启动周期 596 条）
```
Sep 24 21:09:16 ... libvirtd[27463]: nl_recv returned with error: No buffer space available
... (持续至)
Oct 08 17:37:07 ... libvirtd[27463]: nl_recv returned with error: No buffer space available
```

## 7. 网络
```
br0   RX drop=1456155  eno1 RX drop=377005 missed=117
br0   192.168.16.252/24   default via 192.168.16.1
DNS nameserver 192.168.16.253
ip -br addr: eno2/3/4 down, ens2f0/f1 down, virbr0 down(192.168.122.1)
net.core.rmem_max = 212992
nf_conntrack_count/max = 494 / 262144
ss -s: Total 419, TCP estab 12
```

## 8. 安全 / 时间
```
SELinux: Enforcing (targeted)
firewalld: active
chronyd: active; System clock synchronized: yes; offset ~0.0001s
Time zone: Asia/Shanghai (+0800)
```

## 9. Docker
```
docker ps (6):
  luli-dev_gcc7-1             Up 9 days
  gcc7_only_x86_64-dev_gcc7-1 Up 2 weeks
  mattermost                  Up 6 weeks (healthy)
  mattermost-postgres         Up 6 weeks
  node-exporter               Up 2 months
  cadvisor                    Up 2 months (unhealthy)   <== unhealthy
docker ps -a: 19 个（多个 Exited 1/2/127、Created）
cadvisor health: wget: can't connect to remote host: Connection refused
```

## 10. KVM 虚拟机
```
 19 llm-gateway-142           running
 21 rocky9-vm-141             running
 30 jenkins-agent-144         running
 32 k8s-worker3-196           running
 34 kylinSP1-desktop-test-122 running
 37 vrnet-demo-140            running
 39 harbor-backup-133         running
qemu-kvm RSS: 33392276 / 33356040 / 33329992 / 32679088 / 31947308 / 8236216 / 8196432 kB
```

## 11. 核心转储 / 内核
```
coredumpctl: 11 条
  2026-08-13 types_test dumped core
  2026-08-15 opencode dumped core (trap invalid opcode)
  2026-08-25 postgres dumped core x2
dmesg: 无 soft/hard lockup、无 hung task、无 xfs/I-O error
journalctl -b -p err 非 buffer 类：
  2026-08-26/09-15/09-16 Failed to start dnf makecache (近期已恢复)
  2026-09-20 sshd kex_exchange_identification: Connection reset by peer
  2026-09-24 NetworkManager platform-linux: error reading .../veth...dev_id
D-state: kworker/u448:1+ixgbe (瞬时); 巡检时另见 xfsaild/sda1
```