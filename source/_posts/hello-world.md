---
title: 你好，世界
date: 2026-10-21 18:00:00
description: 本站的第一篇文章：博客是怎么来的，以及以后怎么发新文章。
tags:
  - 随笔
categories:
  - 生活
---

这是博客的第一篇文章，也是一份简单的使用说明。

<!-- more -->

## 这个博客怎么来的

本站用 [Hexo](https://hexo.io/zh-cn/) 生成，主题是 [Butterfly](https://butterfly.js.org/)，静态文件托管在 Cloudflare Pages 上。服务器在境外，所以不需要 ICP 备案。

## 怎么发新文章

在项目目录打开终端，运行：

```bash
npm run new -- "文章标题"
```

然后在 `source/_posts/` 里编辑生成的 Markdown 文件，写完保存。本地预览：

```bash
npm run dev
```

浏览器打开 http://localhost:4000 就能看到效果。

## 写作小提示

- 用 `<!-- more -->` 控制首页摘要的截断位置；
- 图片放在 `source/img/` 下，用 `/img/xxx.png` 引用；
- 分类和标签写在文章头部的 `categories`、`tags` 里。

> 慢下来，写点真正想写的东西。
