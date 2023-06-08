### 注意事项
### 1、当前脚本目前只适用于安装1.26.0 版本的k8s
### 2、当前脚本只适用于单节点k8s集群的创建默认节点名称为master-01
### 3、初始化集群前注意修改k8s目录下的admin_systemd.yaml的配置文件中的服务器ip
### 4、当前脚本设置的cgroup为systemd
### 5、执行前请赋予sh文件x权限
```shell
find . -type f -name "*.sh" -exec chmod +x {} \;
```

