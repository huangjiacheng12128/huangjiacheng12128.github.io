# 个人博客

一个**免 ICP 备案**的个人博客：Hexo 生成静态站点，Butterfly 主题，部署在 Cloudflare Pages（境外节点）。写文章只需要 Markdown，`git push` 即发布。

## 技术栈

| 部分 | 选择 |
| --- | --- |
| 生成器 | [Hexo](https://hexo.io/zh-cn/) |
| 主题 | [Butterfly](https://butterfly.js.org/) |
| 托管 | Cloudflare Pages（免费，境外节点） |
| 域名 | 自选，见下文推荐 |

## 已内置

- 首页渐变横幅 + 副标题、侧栏作者卡片和公告；
- 右上角本地搜索（`hexo-generator-searchdb`，无需第三方服务）；
- 文章目录、代码块复制、文章版权声明、分享按钮；
- 明暗主题切换（右下角月亮/太阳按钮）；
- 归档、标签、关于页；
- 构建时自动生成 `search.xml`、`sitemap.xml`、`feed.xml`。

## 目录结构

```
.
├─ _config.yml            Hexo 主配置（站点名、作者、域名、主题）
├─ _config.butterfly.yml  Butterfly 主题配置（菜单、头像、横幅、侧栏、搜索）
├─ package.json           依赖与 npm 脚本
├─ scaffolds/             新建文章 / 页面的模板
├─ source/
│  ├─ _posts/             文章（Markdown）
│  ├─ about/              关于页
│  ├─ tags/               标签页
│  └─ img/                图片、头像
└─ public/                构建产物（已 gitignore，不提交）
```

## 本地开发

要求 Node.js 18+（推荐 22，已写在 `.node-version` 里）。

```bash
npm install        # 首次安装依赖
npm run dev        # 本地预览 http://localhost:4000
npm run build      # 构建到 public/
npm run clean      # 清空缓存和 public/
```

## 写文章

```bash
npm run new -- "文章标题"
```

会生成 `source/_posts/文章标题.md`，编辑它即可。头部（front-matter）示例：

```yaml
---
title: 文章标题
date: 2026-10-21 18:00:00
tags:
  - 技术
categories:
  - 笔记
---
```

- 首页摘要优先取 front-matter 里的 `description`；没写就用 `<!-- more -->` 之前的文字；
- 图片放到 `source/img/`，用 `/img/图片名.png` 引用；
- 写完 `npm run build` 确认没问题，再提交。

## 部署到 Cloudflare Pages

### 1. 推到 GitHub

先在 GitHub 建一个空仓库（不要勾选初始化 README），然后：

```bash
git init
git add .
git commit -m "init blog"
git branch -M main
git remote add origin git@github.com:你的用户名/仓库名.git
git push -u origin main
```

### 2. 在 Cloudflare 创建 Pages 项目

1. 打开 Cloudflare Dashboard → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**；
2. 选择刚才的仓库和 `main` 分支；
3. 构建设置：
   - Framework preset：`Hexo`（没有就选 `None`）
   - Build command：`npm run build`
   - Build output directory：`public`
4. 环境变量加一条 `NODE_VERSION = 22`；
5. 点 **Save and Deploy**，一两分钟后拿到 `xxx.pages.dev` 地址。

之后每次 `git push`，Cloudflare 会自动重新构建发布，不用手动上传。

### 3. 绑定自己的域名

- 域名已托管在 Cloudflare：Pages 项目 → **Custom domains** → **Set up a custom domain**，输入域名，DNS 记录会自动添加；
- 域名在别家 DNS：手动加一条 `CNAME` 指向 `xxx.pages.dev`；根域名（不带 www）需要支持 CNAME Flattening 的 DNS，建议直接把域名 DNS 迁到 Cloudflare 免费套餐。

绑定后把 `_config.yml` 里的 `url` 改成正式域名，再提交一次，让 RSS 和 sitemap 里的链接正确。

## 域名注册商推荐

价格随汇率和促销浮动，以官网为准。单位：美元/年。

| 注册商 | .com 参考价 | 支付方式 | 说明 |
| --- | --- | --- | --- |
| Cloudflare Registrar | ≈ $10.4 | 信用卡、PayPal | 按成本价卖，无溢价，含隐私保护；必须用 Cloudflare DNS |
| Porkbun | ≈ $11 首年 | 信用卡、PayPal | 送 WHOIS 隐私，界面友好，续费透明 |
| Spaceship | ≈ $9 首年 | 信用卡、PayPal | Namecheap 姊妹品牌，促销多 |
| Namecheap | ≈ $11 首年，续费 $16+ | 信用卡、PayPal | 老牌注册商，常有优惠码 |
| 阿里云 / 腾讯云 | ¥55–80 首年 | 支付宝、微信 | 需实名认证；解析到境外服务器同样**不需要备案** |

购买建议：

- **.com 最稳**；.me 适合个人；.dev / .app 强制 HTTPS，本站全站 HTTPS 正好可用；
- **避开 .cn**（需实名、受国内政策约束）和超低价小众后缀（续费刺客）；
- 需要一张双币信用卡（Visa / Mastercard）或 PayPal，银联单币卡经常失败；
- 只有支付宝的话，就在阿里云/腾讯云买域名并实名，解析到 Cloudflare Pages，一样免备案；
- **不要买"已备案域名"或"备案授权码"**：违规，随时会被注销；
- 域名注册后 60 天内不能转移注册商，别买错再换。

## 上线前检查清单

- [ ] `_config.yml` 里的 `title`、`author`、`description`、`url` 改成自己的；
- [ ] 替换 `source/img/avatar.svg` 头像，按需替换 `source/img/banner.svg` 横幅；
- [ ] 在 `_config.butterfly.yml` 里取消注释 `social`，填自己的 GitHub / 邮箱；
- [ ] 修改 `source/about/index.md` 里的自我介绍和联系方式；
- [ ] 删除示例文章 `hello-world.md`；
- [ ] 确认 HTTPS 已开启（Cloudflare 自动签发证书）；
- [ ] 把 `sitemap.xml` 提交到 Google Search Console / Bing 站长工具；
- [ ] 代码在 Git 仓库里，文章本身就是备份。

## 常用命令

| 命令 | 作用 |
| --- | --- |
| `npm run dev` | 本地预览，改文件自动刷新 |
| `npm run build` | 生成静态文件到 `public/` |
| `npm run clean` | 清理缓存和 `public/` |
| `npm run new -- "标题"` | 新建文章 |

## 常见问题

**Cloudflare 构建失败，报 Node 版本错误？**
在 Pages 项目的环境变量里设置 `NODE_VERSION = 22`，重新部署。

**国内访问慢？**
Cloudflare 免费套餐的节点常绕道美西，这是免备案方案的主要代价。可以换香港/日本 VPS 做反向代理，或者接受现状。**不要用国内 CDN 加速**——国内 CDN 绑定自定义域名必须备案。

**想加评论？**
推荐 Giscus：基于 GitHub Discussions，免服务器、免备案。

**想加访问统计？**
Cloudflare Web Analytics（免费、无需改代码）或 Umami（可自建）。

**免备案的边界在哪？**
服务器在境外不需要 ICP 备案；但域名在国内注册仍需实名；国内 CDN、对象存储自定义域名、微信登录/支付/小程序仍然需要备案；内容合规要求和境内网站一样。

**主题怎么改？**
所有可覆盖项见 `node_modules/hexo-theme-butterfly/_config.yml`，把想改的键写进根目录的 `_config.butterfly.yml` 即可。

## 备选部署：GitHub Pages

如果不想用 Cloudflare，也可以部署到 GitHub Pages：

```bash
npm install hexo-deployer-git --save
```

在 `_config.yml` 里配置：

```yaml
deploy:
  type: git
  repo: git@github.com:你的用户名/仓库名.git
  branch: gh-pages
```

然后 `npm run clean && npm run build && npx hexo deploy`。缺点是国内访问不稳定。

---

文章版权归作者所有。
