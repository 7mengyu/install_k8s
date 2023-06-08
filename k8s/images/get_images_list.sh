#!/bin/bash

function save_k8s_iamge() {
  echo "  获取k8s相关镜像信息，并替换下载地址为阿里云镜像源"
  kubeadm config images list --kubernetes-version $1 |awk -F "/" '{print "registry.aliyuncs.com/google_containers/"$NF}' >> ./images.txt
}

function save_flannel_image() {
  echo "  从flannel配置文件中获取相关镜像"
  cat ../flannel/kube-flannel.yml |grep image -i |awk -F ": " '{print $NF}' >> ./images.txt
}


function save_ingress_image() {
  echo "  从containerd配置文件中获取相关镜像"
  cat ../ingress-nginx/deploy.yaml |grep image -i |awk -F ": " '{print $NF}' >> ./images.txt

}

function main() {
  cd images
  # 判断当前文件夹下的./images.txt 是否存在，如果存在则删除
  [ -f ./images.txt ] && rm -f ./images.txt
  echo "开始执行save_k8s_iamge"
  save_k8s_iamge "1.26.5"
  echo "开始执行save_flannel_image"
  save_flannel_image
  cd ..
#  echo "开始执行save_ingress_image"
#  save_ingress_image
}


main
