#!/usr/bin/env python3.11
"""按平台 + Python 版本并行下载 wheel 及全部依赖（仅二进制包，不编译源码）

目标平台：
  Windows amd64      -> win_amd64
  Linux x86_64       -> manylinux_2_17/manylinux2014/manylinux_2_27_x86_64  （glibc 2.17 ~ 2.27）
  Linux arm64        -> manylinux_2_17/manylinux2014/manylinux_2_27_aarch64

目标 Python 版本（CPython）：
  3.11 / 3.12 / 3.13 / 3.14 / 3.15   -> ABI cp311 / cp312 / cp313 / cp314 / cp315

策略：先整批尝试；若整批失败（个别包无可用 wheel / 依赖树过大无法解析），
      自动降级为逐包下载，并用 --parallel 指定线程数并行执行——能下载的都
      下载，失败项汇总到脚本末尾报告中（含对应 pip 日志路径），不中断其余包。

用法：
  python download_wheels.py requirements.txt                       # 三个平台 × 全部 Python 版本
  python download_wheels.py requirements.txt --python-versions 3.11 3.12 3.13
  python download_wheels.py requirements.txt --parallel 8 \\
      --index https://pypi.tuna.tsinghua.edu.cn/simple
  python download_wheels.py requirements.txt --tmp-dir /var/tmp/pipdl   # /tmp 为带配额 tmpfs 时
"""

import argparse
import os
import re
import subprocess
import sys
import threading
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

DEFAULT_PYTHON_VERSIONS = ["3.11", "3.12", "3.13", "3.14", "3.15"]

TARGETS = [
    {"name": "windows_amd64",          "platforms": ["win_amd64"]},
    {"name": "linux_x86_64_glibc227",  "platforms": ["manylinux_2_17_x86_64", "manylinux2014_x86_64", "manylinux_2_27_x86_64"]},
    {"name": "linux_aarch64_glibc227", "platforms": ["manylinux_2_17_aarch64", "manylinux2014_aarch64", "manylinux_2_27_aarch64"]},
]

_PKG_SPLIT_RE = re.compile(r"[-_.]+")
_VERSION_RE = re.compile(r"^\d+\.\d+$")


def abi_for(python_version: str) -> str:
    """3.12 -> cp312，cp + 去掉点的版本号。"""
    return "cp" + python_version.replace(".", "")


def normalize_name(name: str) -> str:
    """按 PEP 503 归一化包名，用于去重（Babel/babel、ruamel.yaml/ruamel_yaml 视为同一个包）。"""
    return _PKG_SPLIT_RE.sub("-", name).strip().lower()


def build_cmd(requirements: Path | None, out_dir: Path, platforms: list[str],
              index: str | None, retries: int, python_version: str, abi: str) -> list[str]:
    cmd = [
        sys.executable, "-m", "pip", "download",
        "--dest", str(out_dir),
        "--only-binary=:all:",
        "--implementation", "cp",
        "--python-version", python_version,
        "--abi", abi,
        "--no-cache-dir",
        "--timeout", "60",
        "--retries", str(retries),
    ]
    for p in platforms:
        cmd += ["--platform", p]
    if index:
        cmd += ["--index-url", index]
    if requirements:
        cmd += ["-r", str(requirements)]
    return cmd


def run(cmd: list[str], env: dict | None = None) -> bool:
    return subprocess.run(cmd, env=env).returncode == 0


def parse_requirements(requirements: Path) -> list[str]:
    """解析依赖清单：忽略空行、整行注释、pip 选项行（-r/-e/--index-url 等）与行内注释，并按包名去重。"""
    items: list[str] = []
    seen: set[str] = set()
    for line in requirements.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("#") or s.startswith("-"):
            continue
        s = re.split(r"\s+#", s, maxsplit=1)[0].strip()  # 去掉行内注释
        if not s:
            continue
        name = re.split(r"[<>=!~;\[\s]", s, maxsplit=1)[0]
        key = normalize_name(name)
        if not key or key in seen:
            continue
        seen.add(key)
        items.append(s)
    return items


def target_dir(out_root: Path, platform_name: str, python_version: str) -> Path:
    """输出目录带 Python 版本后缀，避免不同版本互相覆盖：<out>/<平台>_py<版本>。"""
    return out_root / f"{platform_name}_py{python_version.replace('.', '')}"


def download_batch(requirements: Path, out_dir: Path, platforms: list[str], index: str | None,
                   retries: int, python_version: str, abi: str, env: dict | None = None) -> bool:
    print(f"\n=== [批量] {', '.join(platforms)} (py{python_version}) -> {out_dir.name} ===")
    return run(build_cmd(requirements, out_dir, platforms, index, retries, python_version, abi), env)


def download_each(requirements: Path, out_dir: Path, platforms: list[str], index: str | None,
                  retries: int, jobs: int, python_version: str, abi: str,
                  env: dict | None = None) -> tuple[list[str], dict]:
    """逐包下载，返回 (失败项列表[含日志路径], 结果表 {item: (ok, log_path)})"""
    items = parse_requirements(requirements)
    if not items:
        return [], {}
    total = len(items)
    done = 0
    lock = threading.Lock()
    results: dict[str, tuple[bool, str]] = {}

    def _log_file(item: str) -> Path:
        safe = "".join("_" if c in '/\\:@=<>|*?[]' else c for c in item)
        log_dir = out_dir / "pip_logs"
        log_dir.mkdir(parents=True, exist_ok=True)
        return log_dir / f"{safe}.log"

    def _worker(item: str):
        nonlocal done
        log = _log_file(item)
        with log.open("w", encoding="utf-8") as fh:
            cmd = build_cmd(None, out_dir, platforms, index, retries, python_version, abi) + [item]
            ok = subprocess.run(cmd, stdout=fh, stderr=fh, env=env).returncode == 0
        with lock:
            done += 1
            results[item] = (ok, str(log))
            print(f"[{done}/{total}] {item} -> {'OK' if ok else 'FAIL'}")

    if jobs <= 1:
        for item in items:
            _worker(item)
    else:
        with ThreadPoolExecutor(max_workers=jobs) as ex:
            list(ex.map(_worker, items))

    failed = [it for it, (ok, _) in results.items() if not ok]
    return failed, results


def main():
    ap = argparse.ArgumentParser(description="按平台 + Python 版本下载 wheel 及其依赖（整批失败时自动逐包并行兜底）")
    ap.add_argument("requirements", nargs="?", default="requirements.txt",
                    help="依赖清单文件，默认 requirements.txt")
    ap.add_argument("--out", default="wheelhouse", help="输出根目录，默认 wheelhouse")
    ap.add_argument("--index", default=None, help="PIP 镜像源，如 https://pypi.tuna.tsinghua.edu.cn/simple")
    ap.add_argument("--platforms", nargs="+", default=[t["name"] for t in TARGETS],
                    help="仅下载指定平台: windows_amd64, linux_x86_64_glibc227, linux_aarch64_glibc227")
    ap.add_argument("--python-versions", nargs="+", default=DEFAULT_PYTHON_VERSIONS,
                    help="仅下载指定 Python 版本，如 3.11 3.12 3.13 3.14 3.15（默认全部）")
    ap.add_argument("--retries", type=int, default=5, help="下载重试次数")
    ap.add_argument("--tmp-dir", default=None,
                    help="pip 子进程临时目录（TMPDIR）。当 /tmp 为 tmpfs 且启用用户配额时，"
                         "大 wheel 下载会因 EDQUOT(Errno 122) 失败，可指向无配额目录（如 /var/tmp）")
    ap.add_argument("--parallel", type=int, default=4, help="逐包兜底时并行线程数，1 为串行，默认 4")
    ap.add_argument("--no-batch", action="store_true",
                    help="跳过整批下载，直接逐包并行下载（依赖树过大导致整批解析超时时使用）")
    ap.add_argument("--strict", action="store_true", help="存在失败包时以非零码退出")
    args = ap.parse_args()

    req = Path(args.requirements)
    if not req.is_file():
        sys.exit(f"依赖文件不存在: {req}")

    if args.parallel < 1:
        sys.exit("--parallel 必须 >= 1")

    env = os.environ.copy()
    if args.tmp_dir:
        tmp = Path(args.tmp_dir).expanduser()
        tmp.mkdir(parents=True, exist_ok=True)
        env["TMPDIR"] = str(tmp)
        print(f"临时目录 TMPDIR = {tmp}（规避 /tmp 配额限制）")

    python_versions = []
    for v in args.python_versions:
        v = v.strip().lstrip("py")
        if not _VERSION_RE.match(v):
            sys.exit(f"Python 版本格式错误: {v}（应为 3.12 之类）")
        if v not in python_versions:
            python_versions.append(v)

    all_failed: dict[str, list[str]] = {}
    for t in TARGETS:
        if t["name"] not in args.platforms:
            continue
        for pyver in python_versions:
            abi = abi_for(pyver)
            out = target_dir(Path(args.out), t["name"], pyver)
            out.mkdir(parents=True, exist_ok=True)
            if not args.no_batch and download_batch(req, out, t["platforms"], args.index,
                                                    args.retries, pyver, abi, env):
                continue
            if args.no_batch:
                print(f"\n[ {out.name} ] --no-batch：直接逐包并行下载（线程数={args.parallel}）")
            else:
                print(f"\n[ {out.name} ] 整批下载未全部成功，转为逐包并行下载"
                      f"（线程数={args.parallel}，失败仅报告不中断）")
            failed, _ = download_each(req, out, t["platforms"], args.index, args.retries,
                                      args.parallel, pyver, abi, env)
            if failed:
                all_failed[out.name] = failed

    print("\n" + "=" * 60)
    print("下载完成，产物目录:")
    for t in TARGETS:
        if t["name"] in args.platforms:
            for pyver in python_versions:
                print(f"  - {target_dir(Path(args.out), t['name'], pyver)}")

    if all_failed:
        print("\n[失败报告] 以下包在当前平台/Python 版本无可用 wheel（未强制下载，日志见对应文件）:")
        for name, failed in all_failed.items():
            print(f"  [{name}]")
            for item in failed:
                print(f"    - {item}")
    else:
        print("\n[失败报告] 无，全部成功")

    if args.strict and all_failed:
        sys.exit(1)


if __name__ == "__main__":
    main()