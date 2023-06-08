#!/bin/bash


function save_containerd_image() {
  echo "  从containerd配置文件中获取相关镜像"
  cat /etc/containerd/config.toml |grep sandbox_image |awk -F '"' '{print $2}' >> ./images.txt

}


function main() {
  cd images
  # 判断当前文件夹下的./images.txt 是否存在，如果存在则删除
  [ -f ./images.txt ] && rm -f ./images.txt
  echo "开始执行save_containerd_image"
  save_containerd_image
  cd ..
}


main
