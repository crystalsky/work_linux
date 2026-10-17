packagedirs=("vrdes-6.0.1" "vrnet_framework-1.0.0" "vrnet_library-1.0.0")

md5_file="${vrnet_cloud}/so_md5sum.txt"
: > "${md5_file}"
log_info "输出所有 .so 文件的 MD5 到 ${md5_file}"
scan_dirs=("${vrnet_cloud}" "${deps_libs}")
for pkgdir in "${packagedirs[@]}"; do
    scan_dirs+=("${basedir_install}/${pkgdir}")
done
for dir in "${scan_dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r -d '' sofile; do
        md5=$(md5sum "$sofile" | awk '{print $1}')
        relpath="${sofile#${dir}/}"
        echo "${md5}  ${relpath}" >> "${md5_file}"
        log_info "MD5: ${md5}  ${relpath}"
    done < <(find "$dir" -name "*.so*" -type f -print0 2>/dev/null | sort -z)
done

log_step 9 "开始压缩打包组件"
for dir in "${packagedirs[@]}"; do
    if [[ -d "$dir" ]]; then
        tar -zcf "${dir}.tar.gz" "$dir" && mv "${dir}.tar.gz" "${stodir}/" && rm -rf "$dir"
        log_info "✅ 打包成功: ${dir}.tar.gz"
    else
        log_warn "⚠️ 目录不存在，跳过打包: ${dir}"
    fi
done
log_info "✅ 安装完成"