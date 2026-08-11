#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

workbuddy_home="${WORKBUDDY_HOME:-${HOME}/.workbuddy}"
package_version="${XIQUE_WORKBUDDY_MCP_VERSION:-0.9.0}"
skip_login='0'

while [ "$#" -gt 0 ]; do
    case "$1" in
        --workbuddy-home)
            workbuddy_home="$2"
            shift 2
            ;;
        --package-version)
            package_version="$2"
            shift 2
            ;;
        --skip-login)
            skip_login='1'
            shift
            ;;
        *)
            echo "未知安装参数：$1" >&2
            exit 1
            ;;
    esac
done

case "$package_version" in
    ''|*[!0-9A-Za-z.+-]*)
        echo "MCP npm 包版本格式无效：$package_version" >&2
        exit 1
        ;;
esac

version_compare() {
    awk -v left="${1#v}" -v right="${2#v}" 'BEGIN {
        split(left, a, "."); split(right, b, ".");
        for (i = 1; i <= 3; i++) {
            av = a[i] + 0; bv = b[i] + 0;
            if (av > bv) exit 0;
            if (av < bv) exit 1;
        }
        exit 0;
    }'
}

best_version=''
node_path=''
npx_path=''
node_source=''
versions_root="$workbuddy_home/binaries/node/versions"
if [ -d "$versions_root" ]; then
    for version_dir in "$versions_root"/*; do
        [ -d "$version_dir" ] || continue
        candidate_node=''
        candidate_npx=''
        if [ -x "$version_dir/bin/node" ] && [ -x "$version_dir/bin/npx" ]; then
            candidate_node="$version_dir/bin/node"
            candidate_npx="$version_dir/bin/npx"
        elif [ -x "$version_dir/node" ] && [ -x "$version_dir/npx" ]; then
            candidate_node="$version_dir/node"
            candidate_npx="$version_dir/npx"
        fi
        [ -n "$candidate_node" ] || continue
        actual_version="$($candidate_node --version 2>/dev/null || true)"
        version_compare "$actual_version" '20.19.0' || continue
        if [ -z "$best_version" ] || version_compare "$actual_version" "$best_version"; then
            best_version="$actual_version"
            node_path="$candidate_node"
            npx_path="$candidate_npx"
            node_source='WorkBuddy 内置 Node'
        fi
    done
fi

if [ -z "$node_path" ]; then
    candidate_node="$(command -v node || true)"
    candidate_npx="$(command -v npx || true)"
    if [ -n "$candidate_node" ] && [ -n "$candidate_npx" ]; then
        actual_version="$($candidate_node --version 2>/dev/null || true)"
        if version_compare "$actual_version" '20.19.0'; then
            best_version="$actual_version"
            node_path="$candidate_node"
            npx_path="$candidate_npx"
            node_source='系统 Node'
        fi
    fi
fi

if [ -z "$node_path" ]; then
    echo '没有找到 Node.js 20.19.0 或更高版本。请先升级 WorkBuddy，再重新执行安装。' >&2
    exit 1
fi

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
configure_script="$script_dir/configure-workbuddy.mjs"
if [ ! -f "$configure_script" ]; then
    echo "安装文件不完整，缺少：$configure_script" >&2
    exit 1
fi

package_spec="@xqyz/workbuddy-plugin-xique@$package_version"
result="$($node_path "$configure_script" \
    --workbuddy-home "$workbuddy_home" \
    --command "$npx_path" \
    --package "$package_spec")"

changed="$($node_path -e 'const r=JSON.parse(process.argv[1]);process.stdout.write(String(r.changed))' "$result")"
config_file="$($node_path -e 'const r=JSON.parse(process.argv[1]);process.stdout.write(r.configFile)' "$result")"
backup_file="$($node_path -e 'const r=JSON.parse(process.argv[1]);process.stdout.write(r.backupFile || "")' "$result")"
if [ "$changed" = 'true' ]; then
    echo "喜鹊标书 MCP 已写入：$config_file"
    if [ -n "$backup_file" ]; then
        echo "原配置已备份：$backup_file"
    fi
else
    echo "喜鹊标书 MCP 已是最新配置：$config_file"
fi
echo "运行环境：$node_source ${best_version#v}"
echo "MCP 版本：$package_spec（首次启动时由 npx 自动下载）"

if [ "$skip_login" != '1' ]; then
    login_status="$($node_path -e 'const fs=require("fs"),os=require("os"),path=require("path");try{const c=JSON.parse(fs.readFileSync(path.join(os.homedir(),".xq-opencli","config.json"),"utf8"));process.stdout.write(c&&c.token?"logged-in":"missing")}catch{process.stdout.write("missing")}' )"
    if [ "$login_status" = 'logged-in' ]; then
        echo '已检测到喜鹊登录状态，不重复打开授权页。'
    else
        echo '正在打开喜鹊浏览器授权，请在浏览器完成登录后返回。'
        "$npx_path" -y '@xqyz/xq-cli@0.2.1' login --browser --timeout-sec 600
        echo '喜鹊登录完成。'
    fi
fi

echo '请完全退出并重新打开 WorkBuddy，然后输入“检查喜鹊标书环境”。'
