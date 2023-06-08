#!/bin/bash
set -e

function init_env() {
  echo "  禁用swap"

  swapoff -a
  [ ! -f /etc/fstab.scy.bak ] && cp -a /etc/fstab /etc/fstab.scy.bak
  sed -i '/^[^#].*[\t\ ]swap[\t\ ]/ s/^/#/' /etc/fstab
  mount -a

  echo "  禁止firewalld"
  systemctl stop firewalld
  systemctl disable firewalld
  echo "  关闭selinux"
  setenforce 0
  # 判断文件是否存在，不存在为真，执行后面的命令
  [ ! -f /etc/selinux/config.scy.bak ] && cp -a /etc/selinux/config /etc/selinux/config.scy.bak
  sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
  echo "  转发 IPv4 并让 iptables 看到桥接流量"
  cat <<EOF | tee /etc/modules-load.d/python调用k8s接口.conf
overlay
br_netfilter
EOF

  modprobe overlay
  modprobe br_netfilter

  echo "  设置所需的 sysctl 参数，参数在重新启动后保持不变"
  cat <<EOF | tee /etc/sysctl.d/python调用k8s接口.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

  echo "  应用 sysctl 参数而不重新启动"
  sysctl --system

}

function main() {
  # 初始化环境
  echo "开始执行init_env..."
  init_env
}


main