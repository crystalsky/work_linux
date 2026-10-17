#!/usr/bin/env python3
"""
Harbor 项目创建脚本
- 先判断项目是否存在
- 不存在则创建
- 已存在（409）则安全跳过
"""

import argparse
import sys
import requests


def harbor_project_exists(harbor_url: str, project: str, auth: tuple, verify: bool) -> bool:
    """判断 Harbor 项目是否存在"""
    url = f"{harbor_url}/api/v2.0/projects"
    params = {"name": project}

    resp = requests.get(url, params=params, auth=auth, verify=verify)

    if resp.status_code != 200:
        raise RuntimeError(
            f"Failed to query Harbor projects: {resp.status_code} {resp.text}"
        )

    projects = resp.json()
    return len(projects) > 0


def create_harbor_project(
    harbor_url: str,
    project: str,
    public: bool,
    auth: tuple,
    verify: bool,
) -> None:
    """创建 Harbor 项目"""
    url = f"{harbor_url}/api/v2.0/projects"
    payload = {
        "project_name": project,
        "public": public,
        "storage_limit": -1,
    }

    resp = requests.post(url, json=payload, auth=auth, verify=verify)

    if resp.status_code == 201:
        print(f"✅ Harbor project '{project}' created successfully.")
    elif resp.status_code == 409:
        print(f"⚠️ Harbor project '{project}' already exists (409), skip.")
    else:
        print(
            f"❌ Failed to create project '{project}': "
            f"{resp.status_code} {resp.text}",
            file=sys.stderr,
        )
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Create Harbor project if not exists")
    parser.add_argument("--url", required=True, help="Harbor base URL")
    parser.add_argument("--user", default="admin", help="Harbor username")
    parser.add_argument("--password", default="Harbor12345", help="Harbor password")
    parser.add_argument("--project", required=True, help="Project name")
    parser.add_argument(
        "--public",
        action="store_true",
        help="Make project public",
    )
    parser.add_argument(
        "--insecure",
        action="store_true",
        help="Skip TLS certificate verification",
    )

    args = parser.parse_args()

    auth = (args.user, args.password)

    if harbor_project_exists(args.url, args.project, auth, not args.insecure):
        print(f"✅ Harbor project '{args.project}' already exists, skip creation.")
        return

    create_harbor_project(
        args.url,
        args.project,
        args.public,
        auth,
        not args.insecure,
    )


if __name__ == "__main__":
    main()