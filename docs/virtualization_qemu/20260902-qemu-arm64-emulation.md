---
title: "【安装配置】QEMU 模拟 ARM64 系统与 multiarch user-static 使用指南"
type: note
status: active
scope: virtualization_qemu
created: 2026-09-02 00:00:00
updated: 2026-09-02 00:00:00
summary: "在 x86_64 宿主上用 QEMU TCG 模拟 aarch64 系统并运行 Ubuntu cloud image，以及用 multiarch/qemu-user-static 在 Docker 中运行 arm64 容器。"
keywords: [linux, qemu, arm64, aarch64, tcg, uefi, multiarch, docker]
verification: "qemu-system-aarch64 --version"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# QEMU 模拟 ARM64 系统

## 1. 安装 QEMU 全套（含 aarch64 系统模拟）

```bash
sudo apt update
sudo apt install -y qemu-system-arm qemu-efi-aarch64 cloud-image-utils
```

## 2. 下载 arm64 镜像

以 Ubuntu cloud image 为例：

```bash
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-arm64.img
```

## 3. 启动虚拟机

明确使用 TCG（软件模拟，不写 `-enable-kvm`）：

```bash
qemu-system-aarch64 \
  -M virt -cpu cortex-a72 -smp 4 -m 4G \
  -accel tcg,thread=multi \
  -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
  -drive if=none,format=qcow2,file=focal-server-cloudimg-arm64.img,id=hd0 \
  -device virtio-blk-device,drive=hd0 \
  -nographic \
  -netdev user,id=n0,hostfwd=tcp::3222-:22 \
  -device virtio-net-pci,netdev=n0
```

## 4. 使用容器镜像模拟 arm64

通过 `multiarch/qemu-user-static` 注册 binfmt 后，可在 x86_64 宿主上直接运行 arm64 容器镜像：

```sh
docker run --privileged --rm multiarch/qemu-user-static:latest --reset -p yes
docker run -d -u root -p 3222:22 \
  -v $PWD:/workspace -w /workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --rm --entrypoint "" \
  jenkins/inbound-agent_jdk25_npm_py311:1.1_arm64 bash -c "tail -f /dev/null"
```