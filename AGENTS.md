# AGENTS

本工作区专职负责 **大学课程表** 板块。

## 强制规则

1. 先阅读本目录下的 `CODEX_CONTEXT.md`，严格按照其中列出的代码主路径开发。
2. 只修改本板块代码，禁止修改其他板块代码。
3. 如确需跨板块依赖（例如仪表盘入口、App Group 权限、pbxproj 注册），先在 `CODEX_CONTEXT.md` 中记录，不要随意改动其他板块文件。
4. 修改文件后必须重新生成工程文件：`python3 work/make_pbxproj.py`，否则新文件不会进入编译。

## 自动提交（必须执行）

开发完成并**验证编译通过**后，最后一步必须自动提交：

```bash
./commit-board.sh "feat(timetable): <功能说明>"
```
