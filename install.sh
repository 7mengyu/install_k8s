#!/bin/bash


bash ./init_env.sh


cd containerd && bash install.sh && cd ..

cd k8s && bash install.sh && cd ..

