#!/usr/bin/env bash
# 验证脚本：{{FEATURE}}
# 约定：全部通过 exit 0；任一失败 exit 1，并把失败线索打印到 stdout。
# 用法：bash scripts/verify/{{FEATURE}}.sh
set -uo pipefail

PASS=0
FAIL=0

check() {
  # check "描述" <命令...>
  local desc="$1"; shift
  if "$@" >/tmp/verify_out.$$ 2>&1; then
    echo "✅ $desc"
    PASS=$((PASS+1))
  else
    echo "❌ $desc"
    sed 's/^/     /' /tmp/verify_out.$$ | head -30
    FAIL=$((FAIL+1))
  fi
}

# ---- 在这里按"停止条件"逐条写检查，示例： ----
# check "服务在 8080 端口响应 200" bash -c 'curl -sf -o /dev/null http://localhost:8080/health'
# check "单元测试通过" npm test
# check "输出文件存在且非空" bash -c 'test -s out/result.json'

echo
rm -f /tmp/verify_out.$$
if [ $((PASS + FAIL)) -eq 0 ]; then
  echo "❌ 没有定义任何检查：请按 docs/loops/{{FEATURE}}.md 的停止条件补充 check 行"
  exit 1
fi
echo "通过 $PASS 项，失败 $FAIL 项"
[ "$FAIL" -eq 0 ]
