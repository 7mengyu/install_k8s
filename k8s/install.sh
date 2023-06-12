#!/bin/bash

set -e


function k8s_command() {
  echo "  设置执行kubectl命令权限"
  mkdir -p $HOME/.kube
  [ -f $HOME/.kube/config ] && rm -f $HOME/.kube/config
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  # 如果是root用户可以直接执行如下：
  # export KUBECONFIG=/etc/kubernetes/admin.conf

  echo "  设置kubectl命令补齐"
  kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
  sudo chmod a+r /etc/bash_completion.d/kubectl
}


function init_cluster() {
  kubeadm init --config ./admin_systemd.yaml
}


function install_kubexx() {
  # 检查是否已安装
  if echo "quit" | which kubeadm >/dev/null 2>&1
  then
    echo "kubeadm is installed, uninstall it first"
    exit -1
  else
    echo "kubeadm is not installed"
  fi

  if echo "quit" | which kubectl >/dev/null 2>&1
  then
    echo "kubectl is installed, uninstall it first"
    exit -1
  else
    echo "kubectl is not installed"
  fi

  if echo "quit" | which kubelet >/dev/null 2>&1
  then
    echo "kubelet is installed, uninstall it first"
    exit -1
  else
    echo "kubelet is not installed"
  fi

  rpm -ivh  ./package/*.rpm
  # 设置kubelet开机自启动
  systemctl disable kubelet
  systemctl enable --now kubelet
}

function get_images() {
  # 下载镜像
  bash ./images/get_images_list.sh
  for i in $(cat ./images/images.txt);do nerdctl pull $i >/dev/null ;done
}

function set_crictl() {
  crictl config runtime-endpoint unix:///run/containerd/containerd.sock
}

function main() {

  echo "开始执行install_kubexx..."
  install_kubexx
  get_images
  echo "开始初始化集群"
  init_cluster
  echo "开始执行k8s相关操作"
  k8s_command
  echo "pod可以调度到当前控制平面的节点"
  kubectl taint nodes master-01 node-role.kubernetes.io/master-
  echo "开始安装网络插件"
  kubectl create -f flannel/kube-flannel.yml
  kubectl cluster-info
  echo "配置crictl使用containerd"
  set_crictl
}


main
