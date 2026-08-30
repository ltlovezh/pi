#!/usr/bin/env bash
# 同步上游 earendil-works/pi，并把 diy 分支重新叠到最新的 main 上。
#   main : upstream/main 的纯镜像 -> 推到 origin/main
#   diy  : main + learning/ -> rebase 后推到 origin/diy
#
# 需要在 diy 分支上运行（learning/ 只存在于 diy）。想在任何分支上跑：
#   git show diy:learning/sync.sh | bash
#
# 全部逻辑包在 run() 里：bash 会先解析完整个函数体再执行，
# 这样中途 `git switch main` 把本文件从工作区移走也不影响运行。
set -euo pipefail

run() {
  cd "$(git rev-parse --show-toplevel)"

  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "工作区有未提交的改动，先 commit 或 stash 再跑。" >&2
    exit 1
  fi

  local start_branch
  start_branch="$(git rev-parse --abbrev-ref HEAD)"

  echo "==> fetch upstream"
  git fetch upstream

  echo "==> main 快进到 upstream/main"
  git switch main
  if ! git merge --ff-only upstream/main; then
    echo "main 无法快进到 upstream/main：说明 main 上有本地提交，已偏离镜像。" >&2
    echo "把那些提交挪到 diy 上，再用 git reset --hard upstream/main 复位 main。" >&2
    git switch "$start_branch"
    exit 1
  fi
  git push origin main

  echo "==> diy rebase 到 main"
  git switch diy
  git rebase main
  git push --force-with-lease origin diy

  git switch "$start_branch"

  echo
  echo "完成。当前状态："
  git --no-pager log --oneline -1 main
  git --no-pager log --oneline -1 diy
}

run "$@"
