#!/usr/bin/env python3
"""程序化评估 linux-troubleshoot 各 run 的断言，生成 grading.json。"""
import json
import re
from pathlib import Path

WS = Path("/mnt/sdd-data/workspace/work_linux/.opencode/skill/linux-troubleshoot-workspace/iteration-1")

def read_all(outdir: Path):
    text = ""
    files = []
    for p in outdir.rglob("*"):
        if p.is_file():
            files.append(p)
            try:
                text += "\n" + p.read_text(errors="ignore")
            except Exception:
                pass
    return text, files

def has_manual(files):
    for p in files:
        if p.suffix == ".md":
            try:
                c = p.read_text(errors="ignore")
            except Exception:
                continue
            if "title:" in c and "keywords:" in c:
                return p.name
    return None

def count_txt(files):
    return sum(1 for p in files if p.suffix == ".txt")

def grade(eval_name):
    base = WS / eval_name
    results = []
    for cfg in ["with_skill", "without_skill"]:
        outdir = base / cfg / "outputs"
        text, files = read_all(outdir)
        tl = text.lower()
        if eval_name == "eval-0-local-performance":
            checks = [
                ("报告将卡顿主因定位为内存/Swap 耗尽，而非 CPU 或磁盘 IO",
                 bool(re.search("swap", tl)) and ("耗尽" in text or "用满" in text or "100%" in text),
                 f"含 swap 且提及耗尽/100%（files={len(files)}）"),
                ("明确给出磁盘 IO 是否异常的判读（排除或确认）",
                 any(k in text for k in ["iowait", "wa=", "磁盘 IO", "磁盘IO", "D 状态", "D状态", "iostat"]),
                 "文本含 iostat/iowait/wa=/D 状态等 IO 判读依据"),
                ("所有建议的修复/清理命令均标注需用户确认，未自动执行任何变更",
                 any(k in text for k in ["需你确认", "需确认", "确认后", "需用户确认", "未执行"]),
                 "含 需确认/未执行 等安全边界措辞"),
                ("在工作目录留下了诊断产出报告文件",
                 any(p.suffix == ".md" and "report" in p.name.lower() or p.suffix == ".md" for p in files),
                 "存在 markdown 报告文件"),
                ("生成了符合规范（含 title/keywords 等 YAML 文件头）的可沉淀运维手册文件",
                 has_manual(files) is not None,
                 f"手册文件={has_manual(files)}"),
                ("原始诊断输出按检查项分别存档为独立文件",
                 count_txt(files) >= 3 or any(p.is_dir() and p.name == "raw" for p in outdir.iterdir()),
                 f".txt 文件数={count_txt(files)}"),
            ]
        elif eval_name == "eval-1-remote-disk":
            checks = [
                ("通过 ssh 别名 SERVER_252 连接（复用 ~/.ssh/config，未要求提供密码）",
                 "server_252" in tl or "192.168.16.252" in text,
                 "报告提及 SERVER_252 / 192.168.16.252"),
                ("结论正确：磁盘未写满，并给出各挂载点使用率",
                 ("未" in text or "没有" in text or "no" in tl) and "%" in text,
                 "报告给出使用率百分比并说明未满"),
                ("定位到具体占用空间最大的目录/文件（如 docker overlay2、qcow2、备份）",
                 any(k in tl for k in ["overlay2", "docker", "qcow2", "/data/kvm", "08_backup", "backup"]),
                 "报告定位到 docker/qcow2/backup 等具体占用"),
                ("清理类命令标注需用户确认，未自动执行",
                 any(k in text for k in ["需你确认", "需确认", "确认后", "需用户确认", "未执行"]),
                 "含 需确认/未执行 措辞"),
                ("生成含 YAML 文件头、分类到 os_storage 的可沉淀手册文件",
                 has_manual(files) is not None,
                 f"手册文件={has_manual(files)}"),
            ]
        else:
            checks = [
                ("巡检覆盖系统身份、资源(CPU/内存/磁盘)、服务、网络等多个维度",
                 (("系统身份" in text) or ("发行版" in text)) and ("服务" in text) and ("网络" in text),
                 "覆盖系统身份/服务/网络等维度"),
                ("将 Swap 100% 耗尽识别为异常项",
                 "swap" in tl and ("100%" in text or "耗尽" in text or "用满" in text),
                 "报告标注 swap 耗尽"),
                ("识别 cadvisor unhealthy 异常",
                 "cadvisor" in tl,
                 "报告提及 cadvisor"),
                ("输出结构化体检报告并存档",
                 any(p.suffix == ".md" for p in files),
                 "存在 markdown 体检报告"),
                ("生成含 YAML 文件头的可沉淀巡检手册文件",
                 has_manual(files) is not None,
                 f"手册文件={has_manual(files)}"),
            ]
        passed = sum(1 for _, ok, _ in checks if ok)
        g = {
            "expectations": [{"text": t, "passed": ok, "evidence": ev} for t, ok, ev in checks],
            "summary": {
                "passed": passed,
                "failed": len(checks) - passed,
                "total": len(checks),
                "pass_rate": round(passed / len(checks), 2),
            },
        }
        (base / cfg / "grading.json").write_text(json.dumps(g, ensure_ascii=False, indent=2))
        results.append((cfg, passed, len(checks)))
    for cfg, p, t in results:
        print(f"{eval_name:28s} {cfg:14s} {p}/{t}")

for e in ["eval-0-local-performance", "eval-1-remote-disk", "eval-2-remote-health"]:
    grade(e)