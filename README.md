# Fuhaha 的智能合约安全笔记

一个使用 [Hugo](https://gohugo.io/) 与 [PaperMod](https://github.com/adityatelange/hugo-PaperMod) 构建的个人技术站点，记录 Solidity 和智能合约安全学习笔记。

## 内容结构

- `content/posts/`：可发布的文章。
- `examples/`：文章配套的独立代码示例与复现脚本。
- `themes/PaperMod/`：站点主题。
- `.github/workflows/hugo.yml`：GitHub Pages 构建与部署工作流。

## 本地预览

安装 Hugo Extended 后，在仓库根目录运行：

```bash
hugo server -D
```

访问命令输出的本地地址即可预览。发布内容时，推送到 `main` 分支会触发 GitHub Pages 部署。

## 新增文章

```bash
hugo new content/posts/文章-slug.md
```

文章请保留 Front Matter；Foundry 脚本或其他可执行示例请放入 `examples/`，不要直接放在 `content/posts/`。
