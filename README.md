# 个人博客

基于 [Hexo](https://hexo.io/zh-cn/) 与 [Butterfly](https://butterfly.js.org/) 主题的静态博客。推送到 `main` 后，GitHub Actions 会自动构建并发布到 GitHub Pages。

- 线上地址：<https://huangjiacheng12128.github.io>
- 仓库：<https://github.com/huangjiacheng12128/huangjiacheng12128.github.io>
- 详细操作说明：[使用手册.md](使用手册.md)

## 技术栈

| 部分 | 选择 |
| --- | --- |
| 生成器 | [Hexo](https://hexo.io/zh-cn/) 8 |
| 主题 | [Butterfly](https://butterfly.js.org/) 5.7 |
| 托管 | GitHub Pages |
| 部署 | GitHub Actions（`.github/workflows/pages.yml`） |

## 已内置

- **紫罗兰极光横幅**：渐变标题、徽章、打字机副标题；
- **文章卡片**：圆角、悬停浮起、渐变顶边；侧栏卡片统一圆角与阴影；
- **自定义样式**：`source/css/custom.css` 控制横幅、卡片、正文标题、页脚、导航下划线；
- 右上角本地搜索（`hexo-generator-searchdb`，无需第三方服务）；
- 文章目录、代码块复制、文章版权声明、分享按钮；
- 明暗主题切换（右下角月亮/太阳按钮）；
- 归档、分类、标签、相册、关于页；
- **相册照片墙**：网格缩略图、点开左右翻看大图，配套上传脚本；
- 构建时生成 `search.xml`、`sitemap.xml`、`atom.xml`。

## 目录结构

```
.
├─ _config.yml            Hexo 主配置（站点名、作者、域名、主题）
├─ _config.butterfly.yml  Butterfly 配置（菜单、头像、横幅、侧栏、搜索）
├─ package.json           依赖与 npm 脚本
├─ scaffolds/             新建文章 / 页面的模板
├─ 发布文章.cmd           双击运行（桌面快捷方式「写博客」指向它）
├─ 发布文章.ps1           新建/编辑 → 构建 → 提交 → 推送
├─ 添加图片.cmd           双击运行（桌面快捷方式「添加图片」指向它）
├─ 添加图片.ps1           选图/截图 → 存入 source/img → 复制 Markdown
├─ 上传照片.cmd           双击运行（桌面快捷方式「上传照片」指向它）
├─ 上传照片.ps1           多选照片 → 相册 → 自动构建/提交/推送
├─ .github/workflows/
│  └─ pages.yml           推送到 main 后自动构建并部署
├─ scripts/
│  └─ photo-gallery.js    相册标签（{% photo_gallery %}）
├─ source/
│  ├─ _posts/             文章（Markdown）
│  ├─ _data/photos.yml    相册照片清单（由「上传照片」自动维护）
│  ├─ about/              关于页
│  ├─ categories/         分类页
│  ├─ tags/               标签页
│  ├─ photos/             相册页
│  ├─ css/custom.css      视觉微调（横幅极光、卡片、相册、页脚）
│  ├─ img/                图片、头像、横幅、文章封面
│  │  └─ photos/          相册原图
└─ public/                构建产物（已 gitignore，不提交）
```

## 视觉与配色

| 想改什么 | 改哪里 |
| --- | --- |
| 主色、链接色、按钮色 | `_config.butterfly.yml` 的 `theme_color` |
| 全站字号 | `_config.butterfly.yml` 的 `font.global_font_size`（当前 15px，想更大改 16px） |
| 首页横幅 | `source/img/banner.svg` |
| 文章封面 | 默认不启用；想给某篇文章加封面，在文章开头加 `cover: /img/xxx.jpg` |
| 头像 / 站点图标 | `source/img/avatar.svg` / `source/img/favicon.svg` |
| 卡片圆角、页脚、横幅动效 | `source/css/custom.css`（由 `inject.head` 引入） |

想换主色：把 `theme_color.main` 和 `custom.css` 顶部的 `--accent` 一起改掉，提交后生效；也可以 `npm run build` 本地预览。

## 写文章

### 方式一：发布脚本

1. 运行 `.\发布文章.cmd`（或双击桌面快捷方式「写博客」）；
2. 按提示选「新建文章」或输入已有文章序号；
3. 在打开的编辑器里写完、保存；
4. 回到黑色窗口按 **Enter**。

脚本会自动构建、提交、推送。首次推送需要登录 GitHub；如果推送失败，脚本会打开 GitHub Desktop，点一次 **Push origin** 即可。

### 方式二：在 GitHub 网页上写

1. 打开仓库 → `source/_posts` → **Add file** → **Create new file**；
2. 文件名填 `source/_posts/我的新文章.md`；
3. 粘贴下面的模板，写完点 **Commit changes**；
4. 等 Actions 跑完（约 1～2 分钟）自动上线。

### 方式三：命令行

```bash
npm run new -- "文章标题"   # 生成 source/_posts/文章标题.md
npm run dev                 # 本地预览 http://localhost:4000
npm run build               # 构建到 public/
git add -A && git commit -m "post: 文章标题" && git push
```

文章头部的 front-matter：

```yaml
---
title: 文章标题
date: 2026-10-21 18:00:00
description: 显示在首页摘要里的一句话（可选）
tags:
  - 技术
categories:
  - 笔记
---
```

- 首页摘要优先用 `description`，没写就用 `<!-- more -->` 之前的文字；
- 图片放到 `source/img/`，用 `/img/图片名.png` 引用；
- 删除示例文章：删掉 `source/_posts/hello-world.md` 再提交即可。

## 图片 + 点评（读图笔记）

一张图后面跟一段观察，就是最自然的“图片 + 点评”排版：图片居中、图注显示在图片下方、点一下可以放大。

1. 运行 `.\添加图片.cmd`（或双击桌面快捷方式「添加图片」）；
2. 选图片——截图的话直接在窗口里按 `Ctrl+V` 粘贴也行；然后输入图注，例如 `图 1：雨后的巷子`；
3. 它会把图片存进 `source/img/`，并把 Markdown 复制到剪贴板；
4. 回到编辑器，定位到图片下方，按 `Ctrl+V`，接着写点评；
5. 保存，回到发布窗口按 Enter，正常发布。

正文里写出来是这样：

```markdown
![图 1：雨后的小巷](/img/lane.jpg)

这张照片最打动我的是墙上的光。作者没有拍整条街，只截了一段……

![图 2：门牌特写](/img/door.jpg)

第二张把视线收得更近，局部反而更有故事。
```

- 方括号里的文字就是图注（图片的 alt），会自动显示在图片下方；不写也能显示；
- 图片按正文宽度自适应，长截图或竖图都不会撑破版面；
- 新建带图片结构的文章：`npm run new -- photo "标题"`（模板见 `scaffolds/photo.md`）。

## 相册（照片墙）

顶部菜单的「相册」是一个独立照片墙：缩略图排成网格，点开可左右翻看大图。

### 上传照片

1. 运行 `.\上传照片.cmd`（或双击桌面快捷方式「上传照片」）；
2. 多选照片，确定；
3. 输入一句说明（可留空），脚本会自动：
   - 把图片复制到 `source/img/photos/`；
   - 把记录追加到 `source/_data/photos.yml`；
   - 构建、提交并推送；
4. 等 Actions 完成，打开 <https://huangjiacheng12128.github.io/photos/>，刷新页面。

### 手动添加（在 GitHub 网页也能做）

1. 把图片上传到仓库的 `source/img/photos/`；
2. 编辑 `source/_data/photos.yml`，追加：

   ```yaml
   - src: /img/photos/照片.jpg
     caption: 一句话说明
     date: '2026-10-23'
   ```

3. 提交后 Actions 会自动发布。

说明：

- 原图会原样进入仓库，体积越大，clone 和页面加载越慢；
- 删除照片：删掉 `source/img/photos/` 里的图和 `photos.yml` 里对应的三行；
- 相册页模板在 `source/photos/index.md`，样式在 `source/css/custom.css` 的 `.photo-*` 部分。

## 自动部署

`.github/workflows/pages.yml` 会在每次推送到 `main` 时：

1. `npm ci` 安装依赖；
2. `npm run build` 生成静态文件；
3. 把 `public/` 发布到 GitHub Pages。

仓库设置需要保持：

- **Settings → Pages → Build and deployment → Source = GitHub Actions**；
- 仓库为 **Public**。

部署进度：<https://github.com/huangjiacheng12128/huangjiacheng12128.github.io/actions>

## 常用命令

| 命令 | 作用 |
| --- | --- |
| `npm run dev` | 本地预览，改文件自动刷新 |
| `npm run build` | 生成静态文件到 `public/` |
| `npm run clean` | 清理缓存和 `public/` |
| `npm run new -- "标题"` | 新建文章 |
| `.\发布文章.ps1 -Title "标题"` | 一键发布（也可双击快捷方式） |
| `.\添加图片.ps1` | 选图/截图并复制 Markdown（也可双击快捷方式） |
| `.\上传照片.ps1` | 多选照片加入相册并发布 |
| `npm run new -- photo "标题"` | 新建带图片结构的文章 |

## 常见问题

**推送时提示要登录 / 脚本打不开 GitHub Desktop？**
首次推送需要登录 GitHub 一次，之后会自动完成。如果一直失败，在 GitHub Desktop 里手动点 **Push origin**，本地提交都在。

**网页上一提交就 404 / 页面是旧的？**
在 Actions 里等构建完成（约 1 分钟），再强制刷新（Ctrl+F5）。构建失败看 Actions 的红色日志。

**图片放哪、多大合适？**
统一放 `source/img/`，用 `/img/文件名` 引用。图片会随文章永久留在仓库里，体积越大，clone 和加载越慢。

**浏览量或「网站信息」显示异常？**
主题使用不蒜子统计。如果服务不可用，在 `_config.butterfly.yml` 里把 `busuanzi` 三项设为 `false`；如果「最后更新时间」一直加载，把 `aside.card_webinfo.last_push_date` 设为 `false`。

**主题怎么改？**
所有可覆盖项见 `node_modules/hexo-theme-butterfly/_config.yml`，把想改的键写进根目录 `_config.butterfly.yml` 即可。

---

文章版权归作者所有。
