# Web3 Security Research

使用 Hugo 与 PaperMod 构建的 Web3 安全研究博客，记录 Solidity 漏洞分析、DeFi 安全与 Ethernaut 学习笔记。

## 内容结构

栏目目录使用 `_index.md`，文章使用 Page Bundle：

```text
content/posts/
├── ethernaut/
│   ├── _index.md
│   └── recovery/
│       ├── index.md
│       └── img/
│           └── recovery-address.webp
└── solidity-vulnerability/
    ├── _index.md
    └── reentrancy/
        ├── index.md
        └── img/
```

## 在文章中插入图片

将图片上传到文章自己的 `img/` 目录，然后在 `index.md` 中使用相对路径：

```markdown
![重入攻击流程](img/reentrancy-attack-flow.webp)
```

建议图片使用英文小写文件名，优先采用 WebP，并尽量控制在 500 KB 以内。

## 新增文章

创建文章目录：

```text
content/posts/<栏目>/<文章-slug>/
├── index.md
└── img/
```

Front Matter 和文章章节可参考 `archetypes/default.md`。

## 本地预览

```bash
hugo server -D
```

推送到 `main` 后，GitHub Actions 会自动构建并部署 GitHub Pages。
