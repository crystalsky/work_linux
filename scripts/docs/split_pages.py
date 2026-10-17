#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""split_pages.py —— 把 crawler-to-md 的合并 Markdown 拆成逐页文件。

crawler-to-md 的合并产物以页面分隔线 `---` 加 `<!-- URL: ... title: ... -->`
注释块标记每一页；本脚本据此拆分，输出文件名为页面路径转成的 kebab-case slug。

    ./split_pages.py -i <合并 md> -o <输出目录>
"""

from __future__ import annotations

import argparse
import os
import re
import sys

PAGE_RE = re.compile(
    r"^---\s*\n<!--\s*\nURL:\s*(\S+)\s*\ntitle:\s*(.*?)\s*\n-->\s*\n",
    re.MULTILINE,
)


def slugify(url: str) -> str:
    path = re.sub(r"^https?://", "", url)
    path = re.sub(r"[/:.]", "-", path)
    path = re.sub(r"-+", "-", path).strip("-")
    return path or "index"


def main() -> int:
    ap = argparse.ArgumentParser(description="拆分 crawler-to-md 合并 Markdown 为逐页文件")
    ap.add_argument("-i", "--input", required=True, help="合并后的 .md")
    ap.add_argument("-o", "--output", required=True, help="输出目录")
    args = ap.parse_args()

    with open(args.input, encoding="utf-8") as fh:
        text = fh.read()

    matches = list(PAGE_RE.finditer(text))
    if not matches:
        sys.exit("未找到页面分隔标记（<!-- URL: ... -->）")

    os.makedirs(args.output, exist_ok=True)
    head = text[: matches[0].start()].rstrip()
    n = 0
    for idx, m in enumerate(matches):
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        body = text[m.end() : end].rstrip()
        url, title = m.group(1), m.group(2)
        slug = slugify(url)
        out = os.path.join(args.output, f"{slug}.md")
        with open(out, "w", encoding="utf-8") as fh:
            fh.write(f"<!-- source: {url} -->\n<!-- title: {title} -->\n\n{body}\n")
        n += 1
    if head:
        with open(os.path.join(args.output, "000-index.md"), "w", encoding="utf-8") as fh:
            fh.write(head + "\n")
    print(f"已拆分 {n} 页 → {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())