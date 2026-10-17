#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""bilingual_translate.py —— 把 Markdown 文档做「英上中下」逐句对照翻译。

用途
----
配合 `ghcr.io/obeone/crawler-to-md` 抓取到的文档（如 pi.dev/docs），
把英文原文**逐句**翻译为简体中文，保持 Markdown 结构不变：

    English sentence.
    中文译文。

规则
----
* 代码块（``` / ~~~ 围栏）、行内代码、链接、URL、命令、参数名一律**原样保留**；
* 标题：英文标题行下方追加一行中文（不重复标题层级，避免污染目录）；
* 列表项 / 引用块：保持原有标记，译文按同缩进续行，仍属同一列表项 / 引用块；
* 表格：判定为句子则整行拆分逐格翻译，并用 `<br>` 把中文并入同一单元格，保持表格合法；
* 纯符号 / 纯数字 / 无 ASCII 字母的片段不翻译；
* 译文结果带缓存（按句子内容哈希），支持中断续跑。

依赖
----
仅 Python 标准库（urllib），无需第三方包。

示例
----
    # 先看规模（不调用模型）
    ./bilingual_translate.py -i ~/.work_linux_working/outputs/pi-dev-docs -o out --dry-run

    # 正式翻译（默认从 ~/.pi/agent/models.json 读取 LiteLLM 网关配置）
    ./bilingual_translate.py -i ~/.work_linux_working/outputs/pi-dev-docs -o out -j 4
"""

from __future__ import annotations

import argparse
import concurrent.futures as futures
import hashlib
import json
import os
import re
import sys
import threading
import time
import urllib.error
import urllib.request

WORK_DIR = os.environ.get("WORK_DIR", os.path.expanduser("~/.work_linux_working"))
DEFAULT_MODELS_JSON = os.path.expanduser("~/.pi/agent/models.json")
DEFAULT_BASE_URL = "http://192.168.16.142:4000/v1"
DEFAULT_MODEL = "huangza-openai-deepseek-flash"

SYSTEM_PROMPT = (
    "You are a professional technical translator working on software documentation. "
    "You will receive a JSON array of English sentences. "
    "Translate every sentence into Simplified Chinese. "
    "Hard rules: "
    "(1) Output ONLY a JSON array of strings, same length and same order as the input; "
    "(2) Never merge, split, reorder, add or drop sentences; "
    "(3) Keep inline code spans, backticked tokens, URLs, file paths, command names, flags, "
    "environment variable names, product names and version numbers exactly as they appear; "
    "(4) Keep the sentence's trailing punctuation style; "
    "(5) Output no explanation, no markdown fence, no extra text."
)

# 常见缩写：不视为句末
ABBR = {
    "e.g.", "i.e.", "etc.", "vs.", "mr.", "mrs.", "ms.", "dr.", "no.", "fig.", "cf.",
    "al.", "approx.", "inc.", "ltd.", "co.", "st.", "jr.", "sr.", "dept.", "est.",
    "min.", "max.", "sec.", "ver.", "vol.", "ch.", "p.", "pp.",
}

FENCE_RE = re.compile(r"^\s*(```|~~~)")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
BULLET_RE = re.compile(r"^(\s*)([-*+])\s+(.*)$")
ORDERED_RE = re.compile(r"^(\s*)(\d+[.)])\s+(.*)$")
QUOTE_RE = re.compile(r"^(\s*>+\s?)(.*)$")
PROTECT_RE = re.compile(r"`[^`\n]*`|\[[^\]]*\]\([^)\s]*\)|https?://[^\s)>]+")
SPLIT_RE = re.compile(r"([.!?]+)(\s+)(?=[\"'(\[A-Z0-9])")
HAS_LATIN_RE = re.compile(r"[A-Za-z]{2,}")


# --------------------------------------------------------------------------- #
# HTTP 调用
# --------------------------------------------------------------------------- #
class Gateway:
    """OpenAI 兼容端点的极简客户端（无第三方依赖、强制直连不走代理）。"""

    def __init__(self, base_url: str, model: str, api_key: str, timeout: int = 180):
        self.url = base_url.rstrip("/") + "/chat/completions"
        self.model = model
        self.api_key = api_key
        self.timeout = timeout
        self._opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def translate_batch(self, sentences: list[str], retries: int = 3) -> list[str]:
        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": json.dumps(sentences, ensure_ascii=False)},
            ],
            "temperature": 0.1,
            "max_tokens": 8192,
        }
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        last_err: Exception | None = None
        for attempt in range(1, retries + 1):
            req = urllib.request.Request(
                self.url,
                data=data,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": "Bearer " + self.api_key,
                },
                method="POST",
            )
            try:
                with self._opener.open(req, timeout=self.timeout) as resp:
                    body = json.loads(resp.read().decode("utf-8"))
                content = body["choices"][0]["message"]["content"]
                return _parse_json_array(content, len(sentences))
            except Exception as exc:  # noqa: BLE001 - 统一重试
                last_err = exc
                if attempt < retries:
                    time.sleep(2 * attempt)
        raise RuntimeError(f"batch failed after {retries} tries: {last_err}")


def _parse_json_array(content: str, expected: int) -> list[str]:
    text = content.strip()
    if text.startswith("```"):
        text = re.sub(r"^```[a-zA-Z]*\n?", "", text)
        text = re.sub(r"\n?```$", "", text).strip()
    start, end = text.find("["), text.rfind("]")
    if start == -1 or end == -1:
        raise ValueError("no JSON array in response")
    arr = json.loads(text[start : end + 1])
    if not isinstance(arr, list) or len(arr) != expected:
        raise ValueError(f"length mismatch: got {len(arr) if isinstance(arr, list) else '?'} want {expected}")
    return [str(x).strip() for x in arr]


# --------------------------------------------------------------------------- #
# Markdown 解析
# --------------------------------------------------------------------------- #
def split_sentences(text: str) -> list[str]:
    """按句末标点切句，保护行内代码 / 链接 / URL。"""
    holders: list[str] = []

    def _stash(m: re.Match) -> str:
        holders.append(m.group(0))
        return f"\x00{len(holders) - 1}\x00"

    protected = PROTECT_RE.sub(_stash, text)

    out: list[str] = []
    last = 0
    for m in SPLIT_RE.finditer(protected):
        head = protected[last : m.end(1)]
        last_word = head.split()[-1].lower() if head.split() else ""
        if last_word in ABBR:
            continue
        out.append(head.strip())
        last = m.end()
    tail = protected[last:].strip()
    if tail:
        out.append(tail)

    def _restore(s: str) -> str:
        return re.sub(r"\x00(\d+)\x00", lambda m: holders[int(m.group(1))], s)

    return [_restore(s) for s in out if s.strip()]


def translatable(sentence: str) -> bool:
    plain = re.sub(r"`[^`]*`", "", sentence)
    plain = re.sub(r"https?://\S+", "", plain)
    return bool(HAS_LATIN_RE.search(plain))


class Unit:
    """一个待输出的片段：原样输出 / 「英文 + 译文」/ 表格行。"""

    __slots__ = ("raw", "sentence", "prefix", "cont", "key", "cells")

    def __init__(self, raw=None, sentence=None, prefix="", cont="", cells=None):
        self.raw = raw
        self.sentence = sentence
        self.prefix = prefix
        self.cont = cont
        self.key = None
        self.cells = cells


def parse_markdown(text: str, style: str = "plain") -> list[Unit]:
    units: list[Unit] = []
    lines = text.split("\n")
    i = 0
    n = len(lines)

    # front matter
    if n and lines[0].strip() == "---":
        j = 1
        while j < n and lines[j].strip() not in ("---", "..."):
            j += 1
        if j < n:
            units.append(Unit(raw="\n".join(lines[: j + 1])))
            i = j + 1

    while i < n:
        line = lines[i]

        # HTML 注释（爬虫元数据）：不翻译、不移动
        if line.lstrip().startswith("<!--"):
            block = [line]
            i += 1
            while i < n and "-->" not in block[-1]:
                block.append(lines[i])
                i += 1
            units.append(Unit(raw="\n".join(block)))
            continue

        if FENCE_RE.match(line):
            fence = FENCE_RE.match(line).group(1)
            block = [line]
            i += 1
            while i < n and not lines[i].strip().startswith(fence):
                block.append(lines[i])
                i += 1
            if i < n:
                block.append(lines[i])
                i += 1
            units.append(Unit(raw="\n".join(block)))
            continue

        if not line.strip():
            units.append(Unit(raw=line))
            i += 1
            continue

        # 表格行
        if line.lstrip().startswith("|") and line.rstrip().endswith("|"):
            cells = line.strip().strip("|").split("|")
            if all(re.fullmatch(r"\s*:?-{2,}:?\s*", c) for c in cells if c.strip()):
                units.append(Unit(raw=line))
                i += 1
                continue
            units.append(Unit(cells=[c.strip() for c in cells]))
            i += 1
            continue

        m = HEADING_RE.match(line)
        if m:
            cont = "\n> 【译】" if style == "skill" else ""
            units.append(Unit(sentence=m.group(2).strip(), prefix=f"{m.group(1)} ", cont=cont))
            i += 1
            continue

        m = QUOTE_RE.match(line)
        if m:
            quote_prefix, rest = m.group(1), m.group(2)
            cont = "> 【译】" if style == "skill" else quote_prefix
            for s in split_sentences(rest) or [rest]:
                units.append(Unit(sentence=s, prefix=quote_prefix, cont=cont))
            i += 1
            continue

        m = BULLET_RE.match(line) or ORDERED_RE.match(line)
        if m:
            indent, marker, rest = m.group(1), m.group(2), m.group(3)
            pad = " " * (len(indent) + len(marker) + 1)
            cont = pad + "> 【译】" if style == "skill" else pad
            sentences = split_sentences(rest) or [rest]
            for k, s in enumerate(sentences):
                pfx = (indent + marker + " ") if k == 0 else pad
                units.append(Unit(sentence=s, prefix=pfx, cont=cont))
            i += 1
            continue

        cont = "\n> 【译】" if style == "skill" else ""
        for s in split_sentences(line) or [line]:
            units.append(Unit(sentence=s, prefix="", cont=cont))
        i += 1

    return units


def _iter_texts(units: list[Unit]):
    """产出所有需要翻译的文本（正文句子 + 表格单元格）。"""
    for u in units:
        if u.raw is not None:
            continue
        if u.cells is not None:
            for txt in u.cells:
                if not txt:
                    continue
                for s in split_sentences(txt) or [txt]:
                    if translatable(s):
                        yield s
            continue
        if u.sentence and translatable(u.sentence):
            yield u.sentence


def _strip_links_for_translation(text: str) -> str:
    """译文行不携带链接/图片：只保留链接文字，避免链接计数翻倍且更易读。

    注意链接文字本身可能含方括号（如 ``[`object[]`](#models)``），故用非贪婪匹配。
    """
    text = re.sub(r"!\[(.+?)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"\[(.+?)\]\([^)]*\)", r"\1", text)
    return re.sub(r"<(\S+://[^>]+)>", r"\1", text)


def rebuild(units: list[Unit], cache: dict[str, str], style: str = "plain") -> str:
    out: list[str] = []
    for u in units:
        if u.raw is not None:
            out.append(u.raw)
            continue
        if u.cells is not None:
            rendered = []
            for txt in u.cells:
                if not txt:
                    rendered.append(txt)
                    continue
                zhs = []
                for s in split_sentences(txt) or [txt]:
                    if not translatable(s):
                        continue
                    zh = cache.get(hashlib.sha256(s.encode()).hexdigest())
                    if zh:
                        zhs.append(_strip_links_for_translation(zh) if style == "skill" else zh)
                mark = "【译】" if style == "skill" else ""
                rendered.append(f"{txt}<br>{mark}{' '.join(zhs)}" if zhs else txt)
            out.append("| " + " | ".join(rendered) + " |")
            continue

        out.append(u.prefix + u.sentence)
        if translatable(u.sentence):
            key = hashlib.sha256(u.sentence.encode()).hexdigest()
            u.key = key
            zh = cache.get(key)
            if zh:
                if style == "skill":
                    zh = _strip_links_for_translation(zh)
                out.append(u.cont + zh)
    return "\n".join(out)


# --------------------------------------------------------------------------- #
# 主流程
# --------------------------------------------------------------------------- #
def load_api_key(explicit: str | None, models_json: str, provider: str) -> str:
    if explicit:
        return explicit
    for env in ("LITELLM_API_KEY", "OPENAI_API_KEY"):
        if os.environ.get(env):
            return os.environ[env]
    try:
        with open(models_json, encoding="utf-8") as fh:
            data = json.load(fh)
        return data["providers"][provider]["apiKey"]
    except Exception as exc:  # noqa: BLE001
        sys.exit(f"无法获取 API Key（--api-key / $LITELLM_API_KEY / {models_json}）：{exc}")


def collect_files(paths: list[str]) -> list[str]:
    files: list[str] = []
    for p in paths:
        if os.path.isdir(p):
            for root, _dirs, names in os.walk(p):
                for nm in sorted(names):
                    if nm.endswith(".md") and not nm.endswith(".bilingual.md"):
                        files.append(os.path.join(root, nm))
        elif os.path.isfile(p):
            files.append(p)
    return files


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Markdown 逐句英中对照翻译（英上中下）",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("-i", "--input", nargs="+", default=[], help="输入 .md 文件或目录（可多个）")
    ap.add_argument("-o", "--output", help="输出目录（默认：与输入同目录，文件名加 .bilingual 后缀）")
    ap.add_argument("-j", "--jobs", type=int, default=int(os.environ.get("BT_JOBS", "4")), help="并发数（默认 4）")
    ap.add_argument("-b", "--batch-size", type=int, default=int(os.environ.get("BT_BATCH", "30")), help="每批句子数（默认 30）")
    ap.add_argument("--model", default=os.environ.get("BT_MODEL", DEFAULT_MODEL))
    ap.add_argument("--base-url", default=os.environ.get("BT_BASE_URL", DEFAULT_BASE_URL))
    ap.add_argument("--api-key", help="显式指定 API Key（默认读 $LITELLM_API_KEY 或 ~/.pi/agent/models.json）")
    ap.add_argument("--models-json", default=os.environ.get("BT_MODELS_JSON", DEFAULT_MODELS_JSON))
    ap.add_argument("--provider", default=os.environ.get("BT_PROVIDER", "litellm"))
    ap.add_argument("--cache", default=os.environ.get("BT_CACHE", os.path.join(WORK_DIR, "outputs", "bilingual-cache.json")),
                    help="译文缓存文件（默认 $WORK_DIR/outputs/bilingual-cache.json）")
    ap.add_argument("--dry-run", action="store_true", help="只统计待翻译句子数，不调用模型")
    ap.add_argument("--style", choices=["plain", "skill"], default=os.environ.get("BT_STYLE", "skill"),
                    help="译文渲染风格：plain=英文下方直接跟中文；skill=英文下方加 `> 【译】` 标记（默认，契合 web-doc-crawl-translate 约定）")
    ap.add_argument("--in-place", action="store_true", help="就地写回原文件（先自行备份原文）")
    ap.add_argument("--overwrite", action="store_true", help="覆盖已存在的输出文件")
    args = ap.parse_args()

    if not args.input:
        ap.print_help()
        return 2

    files = collect_files(args.input)
    if not files:
        sys.exit("未找到任何 .md 文件")

    cache: dict[str, str] = {}
    if os.path.exists(args.cache):
        try:
            with open(args.cache, encoding="utf-8") as fh:
                cache = json.load(fh)
        except Exception:  # noqa: BLE001
            cache = {}

    # 1) 解析全部文件，汇总待翻译句子
    parsed: dict[str, list[Unit]] = {}
    pending: dict[str, str] = {}  # key -> sentence
    for path in files:
        with open(path, encoding="utf-8") as fh:
            units = parse_markdown(fh.read(), args.style)
        parsed[path] = units
        for u in _iter_texts(units):
            key = hashlib.sha256(u.encode()).hexdigest()
            if key not in cache:
                pending[key] = u

    print(f"文件数: {len(files)}  句子总数(待译): {len(pending)}  缓存命中: {len(cache)}")
    if args.dry_run:
        for path in files:
            cnt = sum(1 for _ in _iter_texts(parsed[path]))
            print(f"  {os.path.basename(path)}: {cnt}")
        return 0

    if pending:
        api_key = load_api_key(args.api_key, args.models_json, args.provider)
        gw = Gateway(args.base_url, args.model, api_key)
        keys = list(pending)
        batches = [keys[i : i + args.batch_size] for i in range(0, len(keys), args.batch_size)]
        print(f"批次数: {len(batches)}  并发: {args.jobs}  模型: {args.model}")
        lock = threading.Lock()
        done = {"n": 0}

        def work(batch: list[str]) -> None:
            sentences = [pending[k] for k in batch]
            try:
                result = gw.translate_batch(sentences)
            except Exception:  # 失败则拆半逐条重试
                result = []
                for k in batch:
                    try:
                        result.append(gw.translate_batch([pending[k]], retries=4)[0])
                    except Exception as exc:  # noqa: BLE001
                        print(f"  [warn] 单句翻译失败，保留英文: {exc}", file=sys.stderr)
                        result.append("")
            with lock:
                for k, zh in zip(batch, result):
                    if zh:
                        cache[k] = zh
                done["n"] += 1
                if done["n"] % 10 == 0 or done["n"] == len(batches):
                    print(f"  进度 {done['n']}/{len(batches)}")
                    tmp = args.cache + ".tmp"
                    with open(tmp, "w", encoding="utf-8") as fh:
                        json.dump(cache, fh, ensure_ascii=False)
                    os.replace(tmp, args.cache)

        with futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
            list(pool.map(work, batches))

        with open(args.cache, "w", encoding="utf-8") as fh:
            json.dump(cache, fh, ensure_ascii=False)

    # 2) 重建输出
    written = 0
    for path in files:
        if args.in_place:
            out_path = path
        elif args.output:
            os.makedirs(args.output, exist_ok=True)
            out_path = os.path.join(args.output, os.path.basename(path).replace(".md", ".bilingual.md"))
        else:
            out_path = path.replace(".md", ".bilingual.md")
        if os.path.exists(out_path) and not args.overwrite and not args.in_place:
            print(f"  skip (已存在): {out_path}")
            continue
        with open(out_path, "w", encoding="utf-8") as fh:
            fh.write(rebuild(parsed[path], cache, args.style))
        written += 1
    print(f"输出文件: {written} 个")
    return 0


if __name__ == "__main__":
    sys.exit(main())