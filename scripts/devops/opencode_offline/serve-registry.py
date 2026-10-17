#!/usr/bin/env python3
"""极简离线 npm registry：为内网无外网环境提供 opencode 插件依赖的安装源。

opencode 启动时会用内置 npm（Arborist）在各配置目录执行
`@opencode-ai/plugin@<opencode版本>` 的依赖安装。本脚本把事先下载好的
tarball 以 npm registry 协议暴露在本地，使该安装可以完全离线完成。

只用 Python 标准库，无第三方依赖。

用法示例：
    python3 serve-registry.py --tarball /path/opencode-ai-plugin-1.14.39.tgz
    python3 serve-registry.py --tarball /tmp/x.tgz --port 4873 --host 127.0.0.1
"""

import argparse
import base64
import hashlib
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


def build_packument(name, version, base_url, tarball_name, tarball_bytes):
    shasum = hashlib.sha1(tarball_bytes).hexdigest()
    integrity = "sha512-" + base64.b64encode(hashlib.sha512(tarball_bytes).digest()).decode()
    return {
        "name": name,
        "dist-tags": {"latest": version},
        "versions": {
            version: {
                "name": name,
                "version": version,
                "dist": {
                    "tarball": f"{base_url}/{tarball_name}",
                    "shasum": shasum,
                    "integrity": integrity,
                },
            }
        },
    }


def main():
    parser = argparse.ArgumentParser(description="极简离线 npm registry")
    parser.add_argument("--tarball", required=True, help="离线包 tgz 路径（npm pack 产物）")
    parser.add_argument("--package", default="@opencode-ai/plugin", help="包名")
    parser.add_argument("--version", default="1.14.39", help="包版本")
    parser.add_argument("--host", default="127.0.0.1", help="监听地址")
    parser.add_argument("--port", type=int, default=4873, help="监听端口")
    args = parser.parse_args()

    with open(args.tarball, "rb") as f:
        tarball_bytes = f.read()

    import os

    tarball_name = os.path.basename(args.tarball)
    base_url = f"http://{args.host}:{args.port}"
    packument = build_packument(
        args.package, args.version, base_url, tarball_name, tarball_bytes
    )
    packument_bytes = json.dumps(packument).encode()

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *fmt_args):
            sys.stderr.write("REQ %s\n" % (fmt % fmt_args))
            sys.stderr.flush()

        def _send(self, code, body, ctype="application/json"):
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self):
            length = int(self.headers.get("Content-Length", 0) or 0)
            self.rfile.read(length)
            self._send(200, b"{}")

        def do_GET(self):
            path = self.path.split("?")[0]
            if path.endswith(".tgz"):
                self._send(200, tarball_bytes, "application/octet-stream")
            elif any(k in path for k in ("advisories", "audit", "deprecation")):
                self._send(200, b"{}")
            else:
                self._send(200, packument_bytes)

    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"serving {args.package}@{args.version} at {base_url}/ (Ctrl-C to stop)", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()