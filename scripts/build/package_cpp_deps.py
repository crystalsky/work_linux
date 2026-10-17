#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""
package_cpp_deps.py —— 通用 C++ 工程「依赖库按需打包 + 打包后自校验」工具

用途:
    对任意 C++ 工程的安装目录(install dir), 自动完成两件事:
      1) 打包: 以工程自身产物为种子, 通过动态依赖分析求出依赖闭包,
         只把"确实被依赖"的三方库从给定搜索根目录(可多个)拷贝到目标目录;
         未被依赖的三方库既不拷贝, 对安装目录中残留的无关三方库也会清理。
      2) 自校验: 打包后再次分析安装目录内所有业务二进制/库的依赖,
         确认除系统库外的所有依赖都已存在于本地安装目录,
         使产物能够"直接运行"或在无三方库的容器镜像中直接运行。

设计目标:
    - 通用: 不依赖具体工程/CMake, 通过命令行参数描述搜索根、安装目录、目标子目录;
    - 跨平台:
        * Linux  : ldd 解析 .so 依赖;
        * macOS  : otool -L 解析 .dylib 依赖;
        * Windows: 纯标准库解析 PE 导入表与延迟导入表, 打包 .dll 依赖;
                   (Windows 系统 DLL(如 kernel32/api-ms-win-*/ucrtbase 等)按白名单跳过;
                    文件名匹配大小写不敏感; 追加搜索根以支持多套三方库布局)
    - 幂等: 重复执行结果一致;
    - 零第三方依赖: 仅使用 Python 标准库 + 平台自带工具。

典型用法:
    python3 package_cpp_deps.py \
        --install-dir /path/to/install \
        --search-root /path/to/third_party/root \
        --search-root /path/to/another/root \
        --dest bin \
        --qt-plugins --osg-plugins \
        --verify

    # Windows(DLL 打包): 指定平台与多个搜索根; 目标目录通常为 bin
    python package_cpp_deps.py ^
        --platform windows ^
        --install-dir D:\build\install ^
        --search-root D:\third_party\vcpkg\installed\x64-windows \
        --search-root D:\third_party\qt\bin ^
        --dest bin --qt-plugins --verify

退出码:
    0  打包(及校验)成功
    1  参数/环境错误
    2  打包成功但自校验失败(存在缺失或未本地化的非系统依赖)
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import struct
import subprocess
import sys
from collections import deque
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set, Tuple

# --------------------------------------------------------------------------- #
# 常量与正则
# --------------------------------------------------------------------------- #

ELF_MAGIC = b"\x7fELF"
PE_MAGIC = b"MZ"
MACHO_MAGICS = {
    0xFEEDFACE, 0xFEEDFACF,          # 32/64 位, 大端
    0xCEFAEDFE, 0xCFFAEDFE,          # 32/64 位, 小端
    0xCAFEBABE, 0xCAFEBABF,          # FAT/universal
}

# 动态库文件名(用于识别三方库索引与目标目录内的库文件)
LIB_SUFFIX_RE = re.compile(r"\.(so(\.[0-9.]*)?|dylib|dll)$", re.IGNORECASE)

# 系统/内核/编译器运行时库白名单(这些由运行环境提供, 不打包)
SYSTEM_LIB_RE = re.compile(
    r"^(linux-vdso|ld-linux|ld64|libdl\.so|libpthread\.so|libc\.so|libm\.so"
    r"|librt\.so|libresolv\.so|libnsl\.so|libnss.*\.so|libutil\.so|libcrypt\.so"
    r"|libgcc_s\.so|libstdc\+\+\.so|libgomp\.so|libatomic\.so|libquadmath\.so"
    r"|libmvec\.so|libitm\.so|libtsan\.so|libasan\.so|libubsan\.so|liblsan\.so"
    r"|libBrokenLocale\.so|libanl\.so)"
)

# 视为"系统库所在目录"的路径前缀(命中即认为是运行环境提供的系统库)
SYSTEM_PATH_PREFIXES = (
    "/lib/", "/lib64/", "/usr/lib/", "/usr/lib64/", "/usr/local/lib/",
    "/usr/libexec/", "/System/Library/", "/usr/lib64/",
)

# Windows: OS 自带的系统 DLL 白名单(不打包), 名称大小写不敏感
WINDOWS_SYSTEM_DLL_RE = re.compile(
    r"^(kernel32|kernelbase|user32|gdi32|gdiplus|advapi32|shell32|shlwapi|ole32|oleaut32"
    r"|comdlg32|comctl32|ws2_32|wsock32|winmm|version|setupapi|dbghelp|psapi|iphlpapi"
    r"|ntdll|msvcrt|ucrtbase|vcruntime[0-9_]*|msvcp[0-9_]*|concrt[0-9_]*|vccorlib[0-9_]*"
    r"|api-ms-win-[a-z0-9\-]*|ext-ms-win-[a-z0-9\-]*|bcrypt|bcryptprimitives|ncrypt|crypt32"
    r"|secur32|wintrust|rpcrt4|imm32|uxtheme|dwmapi|winspool|userenv|powrprof|cfgmgr32"
    r"|wtsapi32|avrt|opengl32|glu32|d3d[0-9]*|dxgi|dxva2|d2d1|dwrite|dcomp|mfplat"
    r"|mfreadwrite|mfuuid|mf|oleacc|propsys|authz|netapi32|mpr|winhttp|urlmon|wininet"
    r"|wsdapi|dnsapi|dhcpcsvc|normaliz|fltlib|pdh|wevtapi|twinapi|combase|coremessaging"
    r"|msimg32|win32u|winsta|shcore|windows\.storage|winrt|onecore|ucrtbased)\.dll$",
    re.IGNORECASE,
)

# Windows: 系统目录标记(小写, 含反斜杠), 命中即视为系统库路径
WINDOWS_SYSTEM_DIR_MARKERS = (
    "\\windows\\system32\\", "\\windows\\syswow64\\",
    "\\windows\\winsxs\\", "\\windows\\assembly\\", "\\windows\\",
)


def is_windows_platform(platform: str) -> bool:
    return platform == "windows"

# ld.so 无法解析时的输出关键字
_LDD_NOT_FOUND_RE = re.compile(r"^\s*(\S+)\s+=>\s+not found\s*$")
_LDD_RESOLVED_RE = re.compile(r"^\s*(\S+)\s+=>\s+(\S+)\s+\(0x[0-9a-fA-F]+\)\s*$")


_SYSTEM_SONAMES_CACHE: Optional[Set[str]] = None


def system_sonames() -> Set[str]:
    """返回运行环境(OS/基础镜像)已提供的库 soname 集合(基于 ldconfig; 非 Linux 返回空集)。"""
    global _SYSTEM_SONAMES_CACHE
    if _SYSTEM_SONAMES_CACHE is not None:
        return _SYSTEM_SONAMES_CACHE
    names: Set[str] = set()
    if sys.platform.startswith("linux"):
        try:
            proc = subprocess.run(["ldconfig", "-p"], capture_output=True, text=True, timeout=30)
            for line in (proc.stdout or "").splitlines():
                line = line.strip()
                if " => " in line:
                    names.add(line.split(" ")[0].strip())
        except (OSError, subprocess.TimeoutExpired):
            pass
    _SYSTEM_SONAMES_CACHE = names
    return names


def log(msg: str, *, quiet: bool = False) -> None:
    if not quiet:
        print(f"[package-deps] {msg}", flush=True)


def warn(msg: str) -> None:
    print(f"[package-deps][WARN] {msg}", file=sys.stderr, flush=True)


def err(msg: str) -> None:
    print(f"[package-deps][ERROR] {msg}", file=sys.stderr, flush=True)


# --------------------------------------------------------------------------- #
# 文件类型识别
# --------------------------------------------------------------------------- #

def detect_kind(path: Path) -> Optional[str]:
    """通过文件魔数判断二进制类型: elf / pe / macho / None。"""
    try:
        with path.open("rb") as fh:
            head = fh.read(4)
    except OSError:
        return None
    if len(head) < 4 or path.is_symlink() and not path.exists():
        return None
    if head == ELF_MAGIC:
        return "elf"
    if head[:2] == PE_MAGIC:
        return "pe"
    m = struct.unpack(">I", head)[0]
    if m in MACHO_MAGICS:
        return "macho"
    return None


def is_lib_file(path: Path) -> bool:
    return bool(LIB_SUFFIX_RE.search(path.name))


# --------------------------------------------------------------------------- #
# 依赖解析器(按平台)
# --------------------------------------------------------------------------- #

class DependencyResolver:
    """解析某个二进制文件的直接依赖, 返回 [(soname, resolved_path_or_None), ...]。"""

    def __init__(self, extra_lib_dirs: Iterable[Path] = ()) -> None:
        self.extra_lib_dirs = [str(p) for p in extra_lib_dirs]

    def _lld_env(self) -> Dict[str, str]:
        env = dict(os.environ)
        if self.extra_lib_dirs:
            merged = os.pathsep.join(self.extra_lib_dirs)
            old = env.get("LD_LIBRARY_PATH", "")
            env["LD_LIBRARY_PATH"] = merged + (os.pathsep + old if old else "")
        return env

    def dependencies(self, path: Path) -> List[Tuple[str, Optional[str]]]:
        raise NotImplementedError


class LinuxLddResolver(DependencyResolver):
    """Linux: 使用 ldd 获取依赖及其解析路径(含 'not found')。"""

    def dependencies(self, path: Path) -> List[Tuple[str, Optional[str]]]:
        try:
            proc = subprocess.run(
                ["ldd", str(path)],
                capture_output=True, text=True, env=self._lld_env(), timeout=120,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            warn(f"ldd 执行失败: {path} ({exc})")
            return []
        out = proc.stdout or ""
        if "not a dynamic executable" in out or "statically linked" in out:
            return []
        deps: List[Tuple[str, Optional[str]]] = []
        for line in out.splitlines():
            m = _LDD_NOT_FOUND_RE.match(line)
            if m:
                deps.append((m.group(1), None))
                continue
            m = _LDD_RESOLVED_RE.match(line)
            if m:
                deps.append((m.group(1), m.group(2)))
        return deps


class MacOtoolResolver(DependencyResolver):
    """macOS: 使用 otool -L 获取依赖(解析路径即记录路径)。"""

    def dependencies(self, path: Path) -> List[Tuple[str, Optional[str]]]:
        try:
            proc = subprocess.run(
                ["otool", "-L", str(path)],
                capture_output=True, text=True, timeout=120,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            warn(f"otool 执行失败: {path} ({exc})")
            return []
        lines = (proc.stdout or "").splitlines()
        deps: List[Tuple[str, Optional[str]]] = []
        for line in lines[1:]:                      # 第一行是文件自身
            line = line.strip()
            if not line or "(" not in line:
                continue
            ref = line.split(" (")[0].strip()
            name = os.path.basename(ref)
            resolved = ref if ref.startswith("/") else None
            if name.startswith("@rpath/") or name.startswith("@loader_path/"):
                name = os.path.basename(ref)
            deps.append((name, resolved))
        return deps


class WindowsPeResolver(DependencyResolver):
    """Windows: 解析 PE 导入表(含延迟导入, 纯标准库), 给出依赖 DLL 名及其本地解析路径。

    解析顺序参照 Windows 加载器: 二进制所在目录 -> --lib-dir/目标目录 -> PATH。
    """

    def dependencies(self, path: Path) -> List[Tuple[str, Optional[str]]]:
        names = _pe_dll_names(path)
        search_dirs: List[Path] = [path.parent]
        search_dirs += [Path(d) for d in self.extra_lib_dirs]
        resolved: List[Tuple[str, Optional[str]]] = []
        for n in names:
            resolved.append((n, self._locate(n, search_dirs)))
        return resolved

    def _locate(self, dll: str, search_dirs: List[Path]) -> Optional[str]:
        low = dll.lower()
        for d in search_dirs:
            cand = d / dll
            if cand.exists():
                return str(cand)
            try:                               # 大小写不敏感兜底
                for child in d.iterdir():
                    if child.name.lower() == low:
                        return str(child)
            except OSError:
                pass
        return shutil.which(dll)


def _pe_dll_names(path: Path) -> List[str]:
    """解析 PE 的导入表与延迟导入表, 返回依赖的 DLL 名称列表(去重, 保序)。

    使用 mmap 只读映射(回退 read_bytes), 避免超大 DLL(如 QtWebEngineCore)占用内存。
    """
    data = None
    fh = None
    mm = None
    path = Path(path)
    try:
        fh = path.open("rb")
        try:
            import mmap
            mm = mmap.mmap(fh.fileno(), 0, access=mmap.ACCESS_READ)
            data = mm
        except (ValueError, OSError):
            data = fh.read()
    except OSError:
        return []
    try:
        return _parse_pe_dlls(data)
    finally:
        if mm is not None:
            try:
                mm.close()
            except OSError:
                pass
        if fh is not None:
            try:
                fh.close()
            except OSError:
                pass


def _parse_pe_dlls(data) -> List[str]:
    """从 PE 映像数据解析导入表(索引1)与延迟导入表(索引13)中的 DLL 名。"""
    if data[:2] != PE_MAGIC:
        return []
    try:
        e_lfanew = struct.unpack_from("<I", data, 0x3C)[0]
        if data[e_lfanew:e_lfanew + 4] != b"PE\x00\x00":
            return []
        coff = e_lfanew + 4
        num_sections = struct.unpack_from("<H", data, coff + 2)[0]
        opt_size = struct.unpack_from("<H", data, coff + 16)[0]
        opt = coff + 20
        magic = struct.unpack_from("<H", data, opt)[0]
        is_pe32p = magic == 0x20B
        dd_off = opt + (0x70 if is_pe32p else 0x60)          # 数据目录起始
        num_dd = struct.unpack_from("<I", data, opt + (108 if is_pe32p else 92))[0]
        sec_off = opt + opt_size
        sections = []
        for i in range(num_sections):
            base = sec_off + i * 40
            va = struct.unpack_from("<I", data, base + 12)[0]
            raw_size = struct.unpack_from("<I", data, base + 16)[0]
            raw_ptr = struct.unpack_from("<I", data, base + 20)[0]
            sections.append((va, raw_size, raw_ptr))

        def rva_to_off(rva: int) -> Optional[int]:
            for va, raw_size, raw_ptr in sections:
                if va <= rva < va + raw_size:
                    return raw_ptr + (rva - va)
            return None

        def read_cstr(off: Optional[int]) -> Optional[str]:
            if off is None or off >= len(data):
                return None
            end = data.find(b"\x00", off)
            if end < 0:
                return None
            return data[off:end].decode("ascii", "replace")

        names: List[str] = []

        def add(name: Optional[str]) -> None:
            if name and name.lower() not in {n.lower() for n in names}:
                names.append(name)

        # 1) 标准导入表(数据目录索引 1), 描述符 20 字节, Name RVA 在 +12
        if num_dd > 1:
            import_rva = struct.unpack_from("<I", data, dd_off + 8)[0]
            off = rva_to_off(import_rva) if import_rva else None
            while off is not None and off + 20 <= len(data):
                orig = struct.unpack_from("<I", data, off)[0]
                name_rva = struct.unpack_from("<I", data, off + 12)[0]
                if orig == 0 and name_rva == 0:
                    break
                add(read_cstr(rva_to_off(name_rva)))
                off += 20

        # 2) 延迟导入表(数据目录索引 13), 描述符 32 字节, DllNameRVA 在 +4
        if num_dd > 13:
            delay_rva = struct.unpack_from("<I", data, dd_off + 13 * 8)[0]
            off = rva_to_off(delay_rva) if delay_rva else None
            while off is not None and off + 32 <= len(data):
                attrs = struct.unpack_from("<I", data, off)[0]
                name_rva = struct.unpack_from("<I", data, off + 4)[0]
                if attrs == 0 and name_rva == 0:
                    break
                add(read_cstr(rva_to_off(name_rva)))
                off += 32

        return names
    except (struct.error, IndexError, ValueError):
        return []


def make_resolver(platform: str, extra_lib_dirs: Iterable[Path]) -> DependencyResolver:
    if platform == "linux":
        return LinuxLddResolver(extra_lib_dirs)
    if platform == "macos":
        return MacOtoolResolver(extra_lib_dirs)
    if platform == "windows":
        return WindowsPeResolver(extra_lib_dirs)
    raise ValueError(f"不支持的平台: {platform}")


def current_platform() -> str:
    if sys.platform.startswith("linux"):
        return "linux"
    if sys.platform == "darwin":
        return "macos"
    if sys.platform.startswith("win"):
        return "windows"
    return sys.platform


# --------------------------------------------------------------------------- #
# 三方库搜索根索引
# --------------------------------------------------------------------------- #

class SearchRootIndex:
    """对多个搜索根目录建立 basename -> [路径] 索引, 支持按库名前缀匹配。

    case_insensitive=True(Windows) 时按文件名小写建索引, 匹配时大小写不敏感。
    """

    def __init__(self, roots: List[Path], extra_suffixes: Iterable[str] = (),
                 case_insensitive: bool = False) -> None:
        self.roots = [r for r in roots if r.exists()]
        self.case_insensitive = case_insensitive
        self.by_name: Dict[str, List[Path]] = {}
        self._build(extra_suffixes)

    def _key(self, name: str) -> str:
        return name.lower() if self.case_insensitive else name

    def _build(self, extra_suffixes: Iterable[str]) -> None:
        for root in self.roots:
            for dirpath, _dirnames, filenames in os.walk(root):
                for fn in filenames:
                    if is_lib_file(Path(fn)) or any(fn.endswith(s) for s in extra_suffixes):
                        self.by_name.setdefault(self._key(fn), []).append(Path(dirpath) / fn)
        # 为便于前缀匹配, 额外建立排序后的名字列表
        self._names = sorted(self.by_name.keys())

    @property
    def names(self) -> Set[str]:
        return set(self.by_name.keys())

    def has(self, name: str) -> bool:
        return self._key(name) in self.by_name

    def find(self, soname: str) -> List[Path]:
        """精确匹配优先, 否则按 版本化前缀 匹配(如 libfoo.so.1 命中 libfoo.so.1.2.3)。"""
        key = self._key(soname)
        if key in self.by_name:
            return list(self.by_name[key])
        prefix = key + "."
        hits: List[Path] = []
        for name in self._names:
            if name.startswith(prefix):
                hits.extend(self.by_name[name])
        return hits


# --------------------------------------------------------------------------- #
# 文件拷贝(保留符号链接链)
# --------------------------------------------------------------------------- #

def _copy_file(src: Path, dst: Path, dry: bool) -> None:
    if dry:
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists() or dst.is_symlink():
        try:
            if dst.resolve() == src.resolve():
                return
        except OSError:
            pass
    shutil.copy2(src, dst, follow_symlinks=True)
    try:
        os.chmod(dst, os.stat(src).st_mode)
    except OSError:
        pass


def copy_library(src: Path, dest_dir: Path, dry: bool) -> List[str]:
    """
    拷贝库文件到目标目录, 保留符号链接语义:
      - 若 src 是符号链接: 拷贝真实目标文件(用其自身名), 并在目标目录重建同名符号链接;
      - 否则直接拷贝文件。
    返回本次涉及的所有 basename(真实名 + 链接名), 用于"保留集合"。
    """
    names: List[str] = []
    if src.is_symlink():
        real = src.resolve()
        _copy_file(real, dest_dir / real.name, dry)
        names.append(real.name)
        link = dest_dir / src.name
        if not dry:
            link.parent.mkdir(parents=True, exist_ok=True)
            if link.is_symlink() or link.exists():
                link.unlink()
            link.symlink_to(real.name)
        names.append(src.name)
    else:
        _copy_file(src, dest_dir / src.name, dry)
        names.append(src.name)
    return names


# --------------------------------------------------------------------------- #
# 路径判定
# --------------------------------------------------------------------------- #

def _norm(p: str) -> str:
    return os.path.normpath(os.path.abspath(p))


def is_inside(path: str, root: Path) -> bool:
    try:
        p = _norm(path)
        r = _norm(str(root))
        return os.path.commonpath([p, r]) == r
    except (ValueError, OSError):
        return False


def is_system_path(path: str) -> bool:
    # Windows 风格路径(盘符或反斜杠): 仅当位于系统目录时视为系统库
    if re.match(r"^[A-Za-z]:[\\/]", path) or "\\" in path:
        low = path.replace("/", "\\").lower()
        return any(m in low for m in WINDOWS_SYSTEM_DIR_MARKERS)
    p = _norm(path)
    return any(p.startswith(pref.rstrip("/") + "/") or p == pref.rstrip("/")
               for pref in SYSTEM_PATH_PREFIXES) or "/usr/lib" in p or "/lib64" in p


def is_system_lib(soname: str) -> bool:
    """是否系统库: 编译器/内核运行时白名单、Windows 系统 DLL 白名单, 或运行环境 ldconfig 已提供。"""
    if SYSTEM_LIB_RE.match(soname) or WINDOWS_SYSTEM_DLL_RE.match(soname):
        return True
    return soname in system_sonames()


def _local_names(install_dir: Path, case_insensitive: bool = False) -> Set[str]:
    """安装目录内所有文件名集合(含子目录), 用于判断依赖是否已在包内可用。"""
    names: Set[str] = set()
    for _dp, _dn, fns in os.walk(install_dir):
        for fn in fns:
            names.add(fn.lower() if case_insensitive else fn)
    return names


def _runtime_lib_dirs(install_dir: Path, dest_dir: Path, args: argparse.Namespace) -> List[Path]:
    """
    运行时库搜索目录: 用于 ldd 解析与自校验时模拟"容器/直接运行"的加载环境。
    默认包含: 用户 --lib-dir 指定的目录 + 目标目录 + 安装目录下的 lib/lib64。
    """
    dirs: List[Path] = []
    for d in list(args.lib_dir) + [str(dest_dir), str(install_dir / "lib"), str(install_dir / "lib64")]:
        p = Path(d)
        if p.exists() and p not in dirs:
            dirs.append(p)
    return dirs


# --------------------------------------------------------------------------- #
# 主流程
# --------------------------------------------------------------------------- #

def gather_binaries(scan_dirs: List[Path]) -> List[Path]:
    """收集待分析/校验的所有二进制文件(按魔数识别)。"""
    result: List[Path] = []
    for d in scan_dirs:
        if not d.exists():
            continue
        for dirpath, _dirnames, filenames in os.walk(d):
            for fn in filenames:
                p = Path(dirpath) / fn
                if p.is_symlink() and not p.exists():
                    continue
                if detect_kind(p):
                    result.append(p)
    return result


def clean_stale(dest_dir: Path, index: "SearchRootIndex", dry: bool) -> List[Path]:
    """清理目标目录顶层的"来自三方库搜索根、但非本轮依赖"的残留库。"""
    removed: List[Path] = []
    if not dest_dir.exists():
        return removed
    for p in dest_dir.iterdir():
        if p.is_dir() or not is_lib_file(p):
            continue
        if index.has(p.name):
            removed.append(p)
            if not dry:
                p.unlink()
    return removed


def package_roots(args: argparse.Namespace, dest_dir: Path) -> None:
    """处理 Qt / osg 插件目录的整目录拷贝(运行时 dlopen, 依赖闭包分析不到)。"""
    if not (args.qt_plugins or args.osg_plugins):
        return
    for root in args.search_root:
        root = Path(root)
        if not root.exists():
            continue
        for pkg in sorted(root.iterdir()):
            if not pkg.is_dir():
                continue
            if args.osg_plugins:
                for libdir in ("lib", "lib64", "bin"):
                    base = pkg / libdir
                    if base.is_dir():
                        for plug in base.glob("osgPlugins*"):
                            if plug.is_dir():
                                target = dest_dir / plug.name
                                if not args.dry_run:
                                    if target.exists():
                                        shutil.rmtree(target)
                                    shutil.copytree(plug, target, symlinks=True)
                                log(f"拷贝 OSG 插件: {plug.name} -> {dest_dir}")
            if args.qt_plugins:
                for qtdir in (pkg / "plugins", pkg / "lib" / "qt_plugins", pkg / "bin" / "plugins"):
                    if qtdir.is_dir():
                        target = dest_dir / "qt_plugins"
                        if not args.dry_run:
                            target.mkdir(parents=True, exist_ok=True)
                            _copytree_merge(qtdir, target)
                        log(f"拷贝 Qt 插件: {qtdir} -> {target}")


def _copytree_merge(src: Path, dst: Path) -> None:
    for dirpath, _dirnames, filenames in os.walk(src):
        rel = Path(dirpath).relative_to(src)
        (dst / rel).mkdir(parents=True, exist_ok=True)
        for fn in filenames:
            s = Path(dirpath) / fn
            d = dst / rel / fn
            if s.is_symlink():
                if d.exists() or d.is_symlink():
                    d.unlink()
                d.symlink_to(os.readlink(s))
            else:
                shutil.copy2(s, d)


def package(args: argparse.Namespace) -> Tuple[int, Dict[str, object]]:
    platform = args.platform or current_platform()
    install_dir = Path(args.install_dir).resolve()
    dest_dir = (install_dir / args.dest).resolve() if args.dest else install_dir
    if not install_dir.exists():
        err(f"安装目录不存在: {install_dir}")
        return 1, {}

    index = SearchRootIndex([Path(r) for r in args.search_root],
                            case_insensitive=is_windows_platform(platform))
    root_names = index.names
    lib_dirs = _runtime_lib_dirs(install_dir, dest_dir, args)
    log(f"平台={platform} 安装目录={install_dir} 目标目录={dest_dir}")
    log(f"搜索根={[str(Path(r)) for r in args.search_root]}")
    log(f"运行时库目录={[str(p) for p in lib_dirs]}")
    log(f"搜索根库文件 basename 数={len(root_names)}")

    dest_dir.mkdir(parents=True, exist_ok=True)

    # 1) 插件整目录拷贝(可配置)
    package_roots(args, dest_dir)

    # 2) 清理顶层无用三方库残留(后续闭包会按需要重新拷入)
    removed = clean_stale(dest_dir, index, args.dry_run or not args.clean)
    if removed:
        log(f"清理残留三方库: {len(removed)} 个")

    # 3) 收集种子并求依赖闭包
    scan_dirs = [Path(d) for d in (args.scan_dir or [str(install_dir)])]
    seeds = gather_binaries(scan_dirs)
    log(f"种子二进制(工程自身) 数={len(seeds)}")

    resolver = make_resolver(platform, lib_dirs)

    kept: Set[str] = set()
    seen: Set[str] = set()
    copied: List[str] = []
    unresolved: List[str] = []
    queue: deque[Path] = deque(seeds)
    round_guard = 0
    while queue and round_guard < args.max_rounds:
        round_guard += 1
        size = len(queue)
        for _ in range(size):
            binary = queue.popleft()
            for soname, respath in resolver.dependencies(binary):
                if soname in seen:
                    continue
                seen.add(soname)
                if any(re.search(pat, soname) for pat in args.exclude):
                    continue
                cands = index.find(soname)
                if cands:
                    for c in cands:
                        names = copy_library(c, dest_dir, args.dry_run)
                        kept.update(names)
                        copied.append(soname)
                        # 拷贝后继续扫描真实文件以传播传递依赖
                        real = c.resolve() if c.is_symlink() else c
                        queue.append(dest_dir / real.name)
                elif respath and is_inside(respath, install_dir):
                    kept.add(Path(respath).name)
                    queue.append(Path(respath))
                else:
                    unresolved.append(soname)

    # 4) 额外系统库(如 libOpenGL/libGLdispatch), 按需从系统目录拷入
    for pattern in args.extra_system_lib:
        for p in _find_system_libs(pattern, platform):
            for n in copy_library(Path(p), dest_dir, args.dry_run):
                kept.add(n)
            log(f"拷贝额外系统库: {p}")

    stats = {
        "platform": platform,
        "install_dir": str(install_dir),
        "dest_dir": str(dest_dir),
        "root_names": len(root_names),
        "seeds": len(seeds),
        "copied_unique": len(set(copied)),
        "kept_names": len(kept),
        "cleaned_stale": len(removed),
        "unresolved": sorted(set(unresolved)),
    }
    log(f"依赖闭包打包完成: 拷贝 {len(set(copied))} 个依赖名, 保留 {len(kept)} 个文件名")

    # 5) 打包后自校验
    if args.verify:
        errors, warnings = verify(args, install_dir, dest_dir, index, platform, lib_dirs)
        stats["verify_errors"] = errors
        stats["verify_warnings"] = warnings
        for w in warnings[:50]:
            warn(f"缺失(非搜索根/非系统, 可能是可选系统库): {w['binary']}: {w['soname']}")
        if errors:
            err(f"自校验失败: 发现 {len(errors)} 个问题依赖")
            for p in errors[:50]:
                err(f"  {p['binary']}: {p['soname']} ({p['reason']})")
            return 2, stats
        if warnings:
            log(f"自校验通过(有 {len(warnings)} 条告警, 见上)")
        else:
            log("自校验通过: 所有非系统依赖均已本地化")

    return 0, stats


def _find_system_libs(pattern: str, platform: str) -> List[str]:
    """在系统库目录中按 glob/通配 查找库(用于 OpenGL 等运行环境库)。

    Linux: 常见多架构目录; Windows: System32/SysWOW64 与 PATH 中的目录。
    """
    import glob
    if is_windows_platform(platform):
        dirs: List[str] = []
        sysroot = os.environ.get("SystemRoot", r"C:\Windows")
        dirs += [os.path.join(sysroot, "System32"), os.path.join(sysroot, "SysWOW64")]
        dirs += [p for p in os.environ.get("PATH", "").split(os.pathsep) if p]
    else:
        dirs = [
            "/usr/lib/aarch64-linux-gnu", "/usr/lib/x86_64-linux-gnu",
            "/usr/lib/arm-linux-gnueabihf", "/usr/lib/i386-linux-gnu",
            "/lib/aarch64-linux-gnu", "/lib/x86_64-linux-gnu",
            "/usr/lib64", "/usr/lib", "/lib",
        ]
    found: List[str] = []
    for d in dirs:
        if os.path.isdir(d):
            found.extend(glob.glob(os.path.join(d, pattern)))
    return sorted(set(found))


def verify(args: argparse.Namespace, install_dir: Path, dest_dir: Path,
           index: SearchRootIndex, platform: str,
           lib_dirs: List[Path]) -> Tuple[List[Dict[str, str]], List[Dict[str, str]]]:
    """
    自校验: 安装目录内所有二进制的依赖, 除系统库外都必须已在安装目录本地存在。
    在"运行时库目录"(默认 目标目录 + 安装目录 lib/lib64) 下解析依赖, 模拟直接/容器运行。

    判定(返回 (errors, warnings)):
      - 依赖名存在于搜索根索引 -> 必须解析到安装目录内, 否则 error(未打包/未本地化);
      - 系统库(编译器/内核白名单 或 ldconfig 已提供) -> 通过;
      - 解析为 None 且非系统库/非搜索根 -> warning(缺失), --strict-missing 时升级为 error;
      - 解析到安装目录外的非系统路径 -> error(外部泄漏, 容器内不可用)。
    """
    resolver = make_resolver(platform, lib_dirs)
    binaries = gather_binaries([install_dir])
    errors: List[Dict[str, str]] = []
    warnings: List[Dict[str, str]] = []
    ci = is_windows_platform(platform)
    local_names = _local_names(install_dir, case_insensitive=ci)

    def _name_key(name: str) -> str:
        return name.lower() if ci else name

    def localized(soname: str, respath: Optional[str]) -> bool:
        """依赖是否已随包本地提供: 解析到安装目录内, 或包内存在同名文件($ORIGIN 可命中)。"""
        if respath and is_inside(respath, install_dir):
            return True
        if respath and _name_key(os.path.basename(respath)) in local_names:
            return True
        return _name_key(soname) in local_names

    for binary in binaries:
        if any(re.search(pat, str(binary)) for pat in args.verify_skip):
            continue
        for soname, respath in resolver.dependencies(binary):
            if any(re.search(pat, soname) for pat in args.exclude):
                continue
            local = localized(soname, respath)
            if index.has(soname):
                if not local:
                    errors.append({
                        "binary": str(binary), "soname": soname,
                        "reason": "搜索根中存在但未本地化(未打包)",
                    })
                continue
            if is_system_lib(soname):
                continue
            if respath is None:
                item = {"binary": str(binary), "soname": soname,
                        "reason": "缺失(not found, 既非系统库也不在搜索根)"}
                (errors if args.strict_missing else warnings).append(item)
            elif not local and not is_system_path(respath):
                errors.append({
                    "binary": str(binary), "soname": soname,
                    "reason": f"解析到安装目录外的非系统路径: {respath}",
                })
    return errors, warnings


# --------------------------------------------------------------------------- #
# 命令行
# --------------------------------------------------------------------------- #

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="通用 C++ 工程依赖库按需打包 + 打包后自校验工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "示例:\n"
            "  package_cpp_deps.py --install-dir ./install --search-root ./third_party \\\n"
            "      --dest bin --verify\n"
        ),
    )
    parser.add_argument("--install-dir", required=True,
                        help="工程安装根目录(CMAKE_INSTALL_PREFIX)")
    parser.add_argument("--search-root", required=True, action="append", default=[],
                        help="三方库搜索根目录(可多次指定)")
    parser.add_argument("--dest", default=None,
                        help="依赖库拷贝目标子目录, 相对安装根目录, 默认 bin(不存在则安装根)")
    parser.add_argument("--scan-dir", action="append", default=[],
                        help="种子扫描目录(默认安装根目录), 可多次指定")
    parser.add_argument("--exclude", action="append", default=[],
                        help="按正则排除的依赖名(可多次指定)")
    parser.add_argument("--lib-dir", action="append", default=[],
                        help="运行时库搜索目录(用于依赖解析与自校验, 可多次指定; "
                             "默认已含目标目录与安装目录 lib/lib64)")
    parser.add_argument("--verify-skip", action="append", default=[],
                        help="自校验时按正则跳过某些二进制路径(如可选插件目录, 可多次指定)")
    parser.add_argument("--strict-missing", action="store_true",
                        help="将\"缺失(非搜索根/非系统)\"告警升级为错误")
    parser.add_argument("--extra-system-lib", action="append", default=[],
                        help="额外强制拷贝的系统库 glob(可多次), 如 Linux 的 libOpenGL.so*")
    parser.add_argument("--qt-plugins", action="store_true", help="拷贝 Qt 插件(整目录)")
    parser.add_argument("--osg-plugins", action="store_true", help="拷贝 osg/osgEarth 插件(整目录)")
    parser.add_argument("--clean", dest="clean", action="store_true", default=True,
                        help="清理目标目录顶层无用三方库残留(默认开启)")
    parser.add_argument("--no-clean", dest="clean", action="store_false",
                        help="不清理残留")
    parser.add_argument("--verify", dest="verify", action="store_true", default=True,
                        help="打包后自校验(默认开启)")
    parser.add_argument("--no-verify", dest="verify", action="store_false",
                        help="跳过自校验")
    parser.add_argument("--dry-run", action="store_true", help="只分析不实际拷贝/删除")
    parser.add_argument("--platform", choices=["linux", "macos", "windows"], default=None,
                        help="强制指定平台(默认自动识别)")
    parser.add_argument("--max-rounds", type=int, default=20, help="依赖闭包最大迭代轮数")
    parser.add_argument("--json-report", default=None, help="将结果统计写入 JSON 文件")
    parser.add_argument("-v", "--verbose", action="store_true", help="输出更详细日志")
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.dest is None:
        args.dest = "bin"
    code, stats = package(args)
    if args.json_report and stats:
        try:
            with open(args.json_report, "w", encoding="utf-8") as fh:
                json.dump(stats, fh, ensure_ascii=False, indent=2)
            log(f"统计已写入: {args.json_report}")
        except OSError as exc:
            warn(f"写入 JSON 报告失败: {exc}")
    return code


if __name__ == "__main__":
    sys.exit(main())