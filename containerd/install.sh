#!/bin/bash
set -e
filename="./install_$(date '+%Y-%m-%d').log"
# 查看cpu架构信息
MACHINE=`/usr/bin/uname -m`
if [[ $MACHINE == 'x86_64' ]]; then
    cpu_info='amd64'
elif [[ $MACHINE == 'aarch64' ]]; then
	cpu_info='arm64'
else
	cpu_info='others'
	echo "ERROR: 当前CPU架构非arm或amd，暂不支持安装"
	exit -1
fi

# 全量直接安装
function install_full_containerd() {
  # check dockerd
  if echo "quit" | which dockerd >/dev/null 2>&1
  then
    echo "dockerd is installed, uninstall it first"
    exit -1
  else
    echo "Docker is not installed"
  fi

  # check podman
  if echo "quit" | which podman >/dev/null 2>&1
  then
    echo "podman is installed, uninstall it first"
    exit -1
  else
      echo "podman is not installed"
  fi

  find ./package -name  nerdctl-full-\*-linux-${cpu_info}.tar.gz | xargs -I {} tar Cxzvf /usr/local {} > /dev/null
  systemctl daemon-reload
  systemctl enable --now containerd

}

function containerd_setenv() {
  mkdir -p /etc/containerd
  containerd config default | tee /etc/containerd/config.toml
  echo "  修改containerd使用systemed 的cgroup"
  sed -i '/SystemdCgroup/ s#false#true#g' /etc/containerd/config.toml
  echo "  修改disable_apparmor为true"
  sed -i '/disable_apparmor/ s#false#true#g' /etc/containerd/config.toml
  echo "  替换pause下载地址"
  sed -i '/sandbox_image/ s#registry.k8s.io/pause:3.8#registry.aliyuncs.com/google_containers/pause:3.8#g' /etc/containerd/config.toml
  systemctl restart containerd
}


# 分步骤安装
function install_containerd() {
  # 解压文件/usr/local目录
  find ../package/ -name  containerd-\*-linux-${cpu_info}.tar.gz | xargs -I {} tar Cxzvf /usr/local {} > /dev/null
  # 创建文件并将其复制到/usr/lib/systemd/system/目录
  echo << EOF >> /usr/lib/systemd/system/containerd.service

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target
[Service]
#uncomment to enable the experimental sbservice (sandboxed) version of containerd/cri integration
#Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999
[Install]
WantedBy=multi-user.target
EOF

  # 重启服务并开机自启
  systemctl daemon-reload
  systemctl enable --now containerd
}

function install_runc() {
  find ./package/other -name  runc.${cpu_info} | xargs -I {}  install -m 755 {} /usr/local/sbin/runc > /dev/null
}

function install_nerdctl() {
  find ./package/other -name  nerdctl-\*-linux-${cpu_info}.tar.gz | xargs -I {}  tar Cxzvf /usr/local/bin {} > /dev/null
}


function get_images() {
  # 下载镜像
  bash ./images/get_images_list.sh
  for i in $(cat ./images/images.txt);do nerdctl pull $i >/dev/null ;done
}


function main() {

  echo "开始执行install_full_containerd..."
  install_full_containerd
  echo "开始执行containerd_setenv..."
  containerd_setenv
  echo "开始下载containerd相关镜像"
  get_images
}


main

