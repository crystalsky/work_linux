#!/usr/bin/env python3
"""按 benchmark.json schema 生成汇总（当前结构无 run-N 子目录）。"""
import json
import math
from pathlib import Path
from datetime import datetime, timezone

WS = Path("/mnt/sdd-data/workspace/work_linux/.opencode/skill/linux-troubleshoot-workspace/iteration-1")

def stats(vals):
    if not vals:
        return {"mean": 0.0, "stddev": 0.0, "min": 0.0, "max": 0.0}
    n = len(vals); m = sum(vals) / n
    sd = math.sqrt(sum((x - m) ** 2 for x in vals) / (n - 1)) if n > 1 else 0.0
    return {"mean": round(m, 4), "stddev": round(sd, 4), "min": round(min(vals), 4), "max": round(max(vals), 4)}

runs = []
for evd in sorted(WS.glob("eval-*")):
    meta = json.loads((evd / "eval_metadata.json").read_text())
    eid = meta["eval_id"]; ename = meta["eval_name"]
    for cfg in ["with_skill", "without_skill"]:
        g = json.loads((evd / cfg / "grading.json").read_text())
        s = g["summary"]
        runs.append({
            "eval_id": eid,
            "eval_name": ename,
            "configuration": cfg,
            "run_number": 1,
            "result": {
                "pass_rate": s["pass_rate"], "passed": s["passed"], "failed": s["failed"],
                "total": s["total"], "time_seconds": 0.0, "tokens": 0, "tool_calls": 0, "errors": 0,
            },
            "expectations": g["expectations"],
            "notes": [],
        })

run_summary = {}
for cfg in ["with_skill", "without_skill"]:
    pr = [r["result"]["pass_rate"] for r in runs if r["configuration"] == cfg]
    run_summary[cfg] = {"pass_rate": stats(pr), "time_seconds": stats([0.0]), "tokens": stats([0])}
run_summary["delta"] = {
    "pass_rate": f"{(run_summary['with_skill']['pass_rate']['mean'] - run_summary['without_skill']['pass_rate']['mean']):+.2f}",
    "time_seconds": "+0.0", "tokens": "+0",
}

benchmark = {
    "metadata": {
        "skill_name": "linux-troubleshoot",
        "skill_path": "/mnt/sdd-data/workspace/work_linux/.opencode/skill/linux-troubleshoot",
        "executor_model": "huangza-openai-deepseek-flash",
        "analyzer_model": "huangza-openai-deepseek-flash",
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "evals_run": [m["eval_id"] for m in [json.loads((WS/e/"eval_metadata.json").read_text()) for e in sorted([p.name for p in WS.glob("eval-*")])]],
        "runs_per_configuration": 1,
    },
    "runs": runs,
    "run_summary": run_summary,
    "notes": [
        "eval-1 的断言在两种配置下均全部通过，区分度低：baseline 也能完成常规磁盘排查，需补充 skill 特有行为的断言（如是否按作用域沉淀手册、是否分离原始输出）。",
        "with_skill 的显著优势在于：自动沉淀符合规范的手册文件、原始输出按检查项分文件归档。",
        "eval-2 baseline 未识别 Swap 耗尽的多维度体检，with_skill 覆盖更全。",
    ],
}
out = WS / "benchmark.json"
out.write_text(json.dumps(benchmark, ensure_ascii=False, indent=2))
print(f"written {out}")
print(json.dumps(run_summary, ensure_ascii=False, indent=2))