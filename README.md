# 个人博客

一个**免 ICP 备案**的个人博客：Hexo 生成静态站点，Butterfly 主题，部署在 **GitHub Pages**。写文章只需要 Markdown，提交后 GitHub Actions 自动构建上线。

- 线上地址：<https://huangjiacheng12128.github.io>
- 仓库：<https://github.com/huangjiacheng12128/huangjiacheng12128.github.io>
- 操作手册：[使用手册.md](使用手册.md)（改博主名、公告、标签、菜单都看这份）

## 技术栈

| 部分 | 选择 |
| --- | --- |
| 生成器 | [Hexo](https://hexo.io/zh-cn/) 8 |
| 主题 | [Butterfly](https://butterfly.js.org/) 5.7 |
| 托管 | GitHub Pages（免费，境外节点，无需备案） |
| 部署 | GitHub Actions（`.github/workflows/pages.yml`） |

## 已内置

- **紫罗兰极光横幅**：渐变标题、徽章、打字机副标题；
- **文章卡片**：封面图、悬停浮起、渐变顶边；侧栏卡片统一圆角与阴影；
- **自定义样式**：`source/css/custom.css` 控制横幅、卡片、正文标题、页脚、导航下划线；
- 右上角本地搜索（`hexo-generator-searchdb`，无需第三方服务）；
- 文章目录、代码块复制、文章版权声明、分享按钮；
- 明暗主题切换（右下角月亮/太阳按钮）；
- 归档、分类、标签、相册、关于页；
- **相册照片墙**：网格缩略图、点开左右翻看大图，桌面「上传照片」一键发布；
- 构建时生成 `search.xml`、`sitemap.xml`、`atom.xml`。

## 目录结构

```
.
├─ _config.yml            Hexo 主配置（站点名、作者、域名、主题）
├─ _config.butterfly.yml  Butterfly 配置（菜单、头像、横幅、侧栏、搜索）
├─ package.json           依赖与 npm 脚本
├─ scaffolds/             新建文章 / 页面的模板
├─ 发布文章.cmd          双击运行（桌面上的「写博客」快捷方式指向它）
├─ 发布文章.ps1          新建/编辑 → 构建 → 提交 → 推送
├─ 添加图片.cmd          双击运行（桌面上的「添加图片」快捷方式指向它）
├─ 添加图片.ps1          选图/截图 → 存入 source/img → 复制 Markdown
├─ 上传照片.cmd          双击运行（桌面上的「上传照片」快捷方式指向它）
├─ 上传照片.ps1          多选照片 → 相册 → 自动构建/提交/推送
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
| 首页横幅 | `source/img/banner.svg` |
| 文章封面 | 文章头部的 `cover:`；示例封面 `source/img/cover-hello-2.svg` |
| 头像 / 站点图标 | `source/img/avatar.svg` / `source/img/favicon.svg` |
| 卡片圆角、页脚、横幅动效 | `source/css/custom.css`（由 `inject.head` 引入） |

想换一个主色：把 `theme_color.main` 和 `custom.css` 顶部的 `--accent` 一起改掉即可。改完双击「写博客」推送，或 `npm run build` 本地预览。

## 写文章

### 方式一：双击桌面上的「写博客」（最省事）

1. 双击桌面的 **写博客**（仓库里是 `发布文章.cmd`）；
2. 按提示选「新建文章」或输入已有文章序号；
3. 在打开的 Typora 里写完、保存；
4. 回到黑色窗口按 **Enter**。

脚本会自动构建、提交、推送。第一次推送可能会弹出 **GitHub 登录窗口**，登录一次以后就不用再登了；如果没有弹窗或推送失败，它会自动打开 GitHub Desktop，在右上角点一次 **Push origin** 即可，1～2 分钟后网站更新。

### 方式二：在 GitHub 网页上写（不用电脑装任何东西）

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

一张图后面跟一段自己的观察，就是最自然的“图片 + 点评”排版：图片居中、图注显示在图片下方、点一下可以放大。

1. 双击桌面上的 **添加图片**（或运行 `.\添加图片.cmd`）；
2. 选图片——截图的话直接在窗口里按 `Ctrl+V` 粘贴也行；然后输入图注，例如 `图 1：雨后的巷子`；
3. 它会把图片存进 `source/img/`，并把 Markdown 复制到剪贴板；
4. 回到 Typora，定位到图片下方，按 `Ctrl+V`，接着写点评；
5. 保存，回到「写博客」窗口按 Enter，正常发布。

正文里写出来是这样：

```markdown
![图 1：雨后的小巷](/img/lane.jpg)

这张照片最打动我的是墙上的光。作者没有拍整条街，只截了一段……

![图 2：门牌特写](/img/door.jpg)

第二张把视线收得更近，局部反而更有故事。
```

- 方括号里的文字就是图注（图片的 alt），会自动显示在图片下方；不写也能显示，但写了更像图文笔记；
- 图片按正文宽度自适应，长截图或竖图都不会撑破版面；
- 想新建一篇带图片结构的文章：`npm run new -- photo "标题"`（模板见 `scaffolds/photo.md`）。

## 相册（照片墙）

顶部菜单的「相册」是一个独立照片墙：缩略图排成网格，点开可左右翻看大图。

### 上传照片（推荐）

1. 双击桌面上的 **上传照片**（或运行 `.\上传照片.cmd`）；
2. 多选照片，确定；
3. 输入一句说明（可留空），脚本会自动：
   - 把图片复制到 `source/img/photos/`；
   - 把记录追加到 `source/_data/photos.yml`；
   - 构建、提交并推送；
4. 等 1–3 分钟，打开 <https://huangjiacheng12128.github.io/photos/>，`Ctrl+F5` 刷新。

### 手动加（在 GitHub 网页也能做）

1. 把图片上传到仓库的 `source/img/photos/`；
2. 编辑 `source/_data/photos.yml`，追加：

   ```yaml
   - src: /img/photos/照片.jpg
     caption: 一句话说明
     date: '2026-10-23'
   ```

3. 提交后 Actions 会自动发布。

说明：

- 手机照片建议先压到 2000px 以内，仓库更轻、打开更快；
- 想删照片：删掉 `source/img/photos/` 里的图和 `photos.yml` 里对应的三行；
- 相册页模板在 `source/photos/index.md`，样式在 `source/css/custom.css` 的 `.photo-*` 部分。

## 自动部署（已配置好）

`.github/workflows/pages.yml` 会在每次推送到 `main` 时：

1. `npm ci` 安装依赖；
2. `npm run build` 生成静态文件；
3. 把 `public/` 发布到 GitHub Pages。

仓库设置里只需要保持：

- **Settings → Pages → Build and deployment → Source = GitHub Actions**；
- 仓库是 **Public**（免费账号的 Pages 要求公开）。

部署进度：<https://github.com/huangjiacheng12128/huangjiacheng12128.github.io/actions>

## 换自己的域名（可选）

1. 买一个域名（`.top` 约 ¥15 首年 / ¥35 续费，`.com` 约 ¥70/年）；
2. GitHub 仓库 → **Settings → Pages → Custom domain** 填域名，保存；
3. 到域名商加一条 `CNAME` 记录：主机记录 `@`（或 `www`），值 `huangjiacheng12128.github.io`；
4. 等 DNS 生效后勾选 **Enforce HTTPS**；
5. 把 `_config.yml` 的 `url` 改成新域名，提交一次。

不买域名也完全可用，先用 `huangjiacheng12128.github.io` 就行；以后换域名，文章内容不用动。

## 上线前检查清单

- [ ] `_config.yml` 里的 `title`、`author`、`description`、`url` 改成自己的；
- [ ] 替换 `source/img/avatar.svg` 头像和 `source/img/banner.svg` 横幅；
- [ ] 在 `_config.butterfly.yml` 里取消注释 `social`，填 GitHub / 邮箱；
- [ ] 修改 `source/about/index.md` 里的自我介绍；
- [ ] 删除示例文章 `hello-world.md`；
- [ ] 仓库保持 Public，Pages 源保持 GitHub Actions。

## 常用命令

| 命令 | 作用 |
| --- | --- |
| `npm run dev` | 本地预览，改文件自动刷新 |
| `npm run build` | 生成静态文件到 `public/` |
| `npm run clean` | 清理缓存和 `public/` |
| `npm run new -- "标题"` | 新建文章 |
| `.\发布文章.ps1 -Title "标题"` | 一键发布（也可双击快捷方式） |
| `.\添加图片.ps1` | 选图/截图并复制 Markdown（也可双击快捷方式） |
| `npm run new -- photo "标题"` | 新建带图片结构的文章 |

## 常见问题

**推送时提示要登录 / 脚本打不开 GitHub Desktop？**
第一次推送会让 GitHub 登录一次（浏览器或弹窗），登录后以后全自动。如果一直失败，就在 GitHub Desktop 里手动点 **Push origin**，本地提交都在。

**网页上一提交就 404 / 页面是旧的？**
Actions 里等构建完成（约 1 分钟），再强制刷新（Ctrl+F5）。构建失败看 Actions 的红色日志。

**图片放哪、多大合适？**
统一放 `source/img/`，用 `/img/文件名` 引用。上传前把照片压到 1 MB 以内（可用 [Squoosh](https://squoosh.app/) 或 TinyPNG）；图片会随文章永久留在仓库里，太大以后自己 clone 也会慢。

**浏览量一直转圈 / 显示不出来？**
本站已经去掉了浏览量统计，侧边栏「网站信息」只显示文章数目。如果你以后重新开启不蒜子，遇到一直转圈，通常是它服务端 502，可以在 `_config.butterfly.yml` 里把 `busuanzi` 三项改回 `false`；如果「网站信息」里「最后更新时间」在转圈，把 `aside.card_webinfo.last_push_date` 改成 `false`。

**国内访问慢？**
GitHub Pages 在国内时快时慢，这是免备案方案的主要代价。可以换 Cloudflare Pages（见下），或接受现状。**不要用国内 CDN**——绑定自定义域名必须备案。

**想加评论？**
推荐 Giscus：基于 GitHub Discussions，免服务器、免备案。

**想加访问统计？**
Cloudflare Web Analytics（免费、无需改代码）或 Umami。

**免备案的边界在哪？**
服务器在境外不需要 ICP 备案；但域名在国内注册仍需实名；国内 CDN、对象存储自定义域名、微信登录/支付/小程序仍然需要备案；内容合规要求与境内网站一样。

**主题怎么改？**
所有可覆盖项见 `node_modules/hexo-theme-butterfly/_config.yml`，把想改的键写进根目录 `_config.butterfly.yml` 即可。

## 备选：Cloudflare Pages

如果以后觉得 GitHub Pages 慢，可以把仓库接到 Cloudflare Pages：

- 构建设置：命令 `npm run build`，输出目录 `public`，环境变量 `NODE_VERSION = 22`；
- 之后 `git push` 同样自动构建，地址是 `项目名.pages.dev`；
- 自定义域名同样只需加一条 CNAME。

---

文章版权归作者所有。
