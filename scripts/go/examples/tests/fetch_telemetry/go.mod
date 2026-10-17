module fetch_telemetry

go 1.25

// 仅用于在外网单独拉取 golang.org/x/telemetry 的这个精确版本（供上传内网 Gitea 源）。
// 该版本被 golang.org/x/tools v0.49.0 依赖；内网 Gitea 缺此精确版本。
require golang.org/x/telemetry v0.0.0-20260811182544-a038080d80e5