

![image](dnsmasq.jpg?raw=true)



Perl + Dancer + Bootstrap
/etc/dnsmasq.conf 수정 필요
```c
log-facility = /var/log/dnsmasq.log
addn-hosts=/etc/dynamic_host
```
