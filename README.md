# hep-connect

hep-connect接受HEP格式的UDP消息, 然后写入PostgreSQL数据

## 架构图

```
FreeSWITCH ----------> hep-connect -> PostgreSQL
OpenSIPS   ----------| 
heplify    ----------|
Kamailio   ----------|
```

## 数据库
- 只支持 PostgreSQL 16

## 部署方式

只支持docker部署

```sh
docker run -d 
-p 9060:9060/udp \
-e DBAddr="127.0.0.1" \
-e DBName="postgres" \
-e DBUser="root" \
-e DBPort="5432" \
-e DBPasswd="pass" \
-e MaxBatchItems="100" \
--name hep-connect \
eddiemurphy5/hep-connect:latest
```

**环境变量说明**

- DBAddr 数据库IP地址
- DBName 数据库名
- DBPort 数据库端口号
- DBPasswd 数据库密码
- MaxBatchItems 单个批次一次性插入的SIP消息数
- LogLevel 日志级别, 默认info
- UDPListenPort UDP监听端口，默认9060

# 集成方案

集成方案假设hep-connect的服务地址是1.2.3.4:9060

## OpenSIPS 2X

test witch OpenSIPS 2.4

```bash
# add hep listen
listen=hep_udp:your_ip:9061

loadmodule "proto_hep.so"
modparam("proto_hep", "hep_id","[hep_dst] 1.2.3.4:9060;transport=udp;version=3") 
loadmodule "siptrace.so"
modparam("siptrace", "trace_id","[tid]uri=hep:hep_dst")

# add ite in request route();
if(!is_method("REGISTER") && !has_totag()){
  sip_trace("tid", "d", "sip");
}
```

## OpenSIPS 3.x 

```
socket=hep_udp:127.0.0.1:9060
loadmodule "proto_hep.so"
modparam("proto_hep", "hep_id","[hid] 1.2.3.4:9060;transport=udp;version=3")
loadmodule "tracer.so"
modparam("tracer", "trace_id","[tid]uri=hep:hid")


route {
    ...
    if (has_totag()) {
        route(r_seq_request);
    } else {
		trace("tid", "d", "sip");
    }
    ...
}
```

## FreeSWITCH

fs version 1.6.8+ 

编辑： sofia.conf.xml


```
<param name="capture-server" value="udp:1.2.3.4:9060;hep=3;capture_id=100"/>
```

```shell
freeswitch@fsnode04> sofia global capture on
 
+OK Global capture on
freeswitch@fsnode04> sofia global capture off
 
+OK Global capture off
```

然后将下面两个文件的sip-capture设置为yes
- sofia_internal.conf.xml
- sofia_external.conf.xml


```
<param name="sip-capture" value="yes"/>
```

最后，建议重启一下fs.

## heplify集成

参考 https://github.com/sipcapture/heplify

heplify是一个go语言开发的，基于网卡抓包的方式，捕获sip消息的客户端程序，整个程序就是一个二进制文件，可以不依赖其他组件运行。

- -i 指定网卡。需要更具机器真实网卡进行修改
- -m SIP 指定抓SIP消息
- -hs 指定sipgrep-go的地址。需要根据sipgrep-go的真实地址进行修改
- -p 指定生成日志文件的位置
- -dim 排除某些类型的SIP包，例如排除OPTIONS和REGISTER注册的包
- -pr 指定抓包的端口范围。

```
nohup ./heplify -i eno1 \
  -m SIP \
  -hs 1.2.3.4:9060 \
  -p "/var/log/" \
  -dim OPTIONS,REGISTER \
  -pr "5060-5061" &
```

# 集群与负载均衡

hep-connect是可以集群部署的的，例如一次性部署两台hep-connect

- hc1 192.168.1.100:9060
- hc2 192.168.1.101:9060

假如有多台SIP server需要写入hep-connect时，除了写死hep-connect的地址外，还有一种UDP的负载均衡方案。

> 注意 k8s的service或者haproxy对UDP的负载均衡都处理的不好。

唯一我使用过的有效方案是使用nginx的UDP proxy代理。

nginx版本需要高于1.9.13, 下面是配置文件

```conf
stream {
    upstream dns_upstreams {
        server 192.168.1.100:9060;
        server 192.168.1.101:9060;
    }

    server {
        listen 53 udp;
        proxy_pass dns_upstreams;
        proxy_timeout 1s;
        proxy_responses 0;
        error_log logs/dns.log;
    }
}
```