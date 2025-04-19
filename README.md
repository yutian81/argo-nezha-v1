# Argo Nezha Dashboard V1

本项目修改自 [ssfun/argo-nezha](https://github.com/ssfun/argo-nezha)，原版采用 cf-r2 作为备份方案，我改成了采用 `github 私有仓库`作为备份方案

----

## 项目特点：

- **自动备份**: 支持自动备份到 github 私有仓库（北京时间每天凌晨2点）
- **安全访问**: 通过 caddy 和 Cloudflare Tunnel 提供安全的访问
- **一键部署**: 运行 `nezhav1.sh` 输入必要变量后，实现一键部署

----

## 前置准备
1. **CloudFlare开启GRPC流量代理**

2. **设置 Tunnel Public hostname**

  - Type: `HTTPS`
  - URL: `localhost:443`
  - Additional application settings
    - TLS
      - No TLS Verify: `on`
      - HTTP2 connection: `on`
  - **记录 argo 域名和 token 备用**

3. **设置 GitHub Apps**

  - 入口地址：https://github.com/settings/developers
  - 点击右上角 `new OAuth app` 开始新建
  - 填写以下参数：
    - Application name：`nezha_v1`
    - Homepage URL: `https://用于哪吒面板的argo域名`
    - Authorization callback URL: `https://用于哪吒面板的argo域名/api/v1/oauth2/callback`
  - **记录 `Client ID` 和 `Client secrets` 备用**

----

## 快速开始

### VPS 平台
1. **执行一键脚本**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/yutian81/argo-nezha-v1/github/nezhav1.sh)
```

2. **按提示输入以下变量**

- **GITHUB_TOKEN**=github的访问令牌
- **GITHUB_REPO_OWNER**=github用户名
- **GITHUB_REPO_NAME**=用于备份的github仓库名
- **BACKUP_BRANCH**=用于备份的github仓库分支
- **ARGO_AUTH**='Cloudflare Argo Tunnel 令牌'，json格式的秘钥必须用英文单引号包裹
- **ARGO_DOMAIN**=在argo中设置的哪吒面板域名

3. **访问面板**

```
https://你在argo隧道中设置的面板域名
```

> **初始用户名/密码为：admin/admin**

4. **手动部署**

依次执行以下命令: 注意--需要在 env.txt 文件中填入变量值

```bash
git clone -b github https://ghproxy.net/https://github.com/yutian81/argo-nezha-v1.git
cd argo-nezha-v1
docker compose pull
docker compose up -d
```

### PaaS 平台
1. **拉取dockhub镜像**

```bash
docker pull yutian81/argo-nezha-v1:latest
```

2. **设置变量**

变量名与vps搭建相同

3. **暴露443端口**

----

## 其他操作

### 更新镜像

**手动更新**：登录 vps，依次运行以下命令：

```bash
cd argo-nezha-v1
docker compose pull
docker compose up -d
```

**自动更新**：加入系统 corn 任务
```bash
(crontab -l 2>/dev/null | grep -v "argo-nezha-v1"; echo "0 3 * * * cd /root/argo-nezha-v1 && /usr/bin/docker compose pull && /usr/bin/docker compose up -d >> /var/log/nezha_update.log 2>&1") | crontab -
```

## 备份和恢复

**项目支持自动备份到 Github 私有仓库**

备份脚本 `/backup.sh` 会在每天凌晨 2 点执行。

**ssh 进入 `argo-nezha-v1` 目录，修改 `backup.sh` 文件开头的变量，可以执行手动备份和恢复**

### 手动备份
```bash
# 在vps终端执行
cd argo-nezha-v1 && chmod +x backup.sh && ./backup.sh backup
# 在docker内执行
docker exec -it argo-nezha-v1 /backup.sh backup
```

### 手动恢复
```bash
# 在vps终端执行
cd argo-nezha-v1 && chmod +x backup.sh && ./backup.sh restore
# 在docker内执行
docker exec -it argo-nezha-v1 /backup.sh restore
```

----

## 基础设置

### agent 设置

1. **Agent对接地址【域名/IP:端口】**：`面板域名:443`

2. **Agent 使用 TLS 连接**：打 √

3. **前端真实IP请求头**：nz-realip （也可以不设置）

### 绑定 github 登录

1. **访问 vps 目录：`/root/argo-nezha-v1/dashboard`**

2. **修改 `config.yaml` 文件，在最后面加上以下代码：**

```yaml
oauth2:
  GitHub:
    client_id: 改为你在前置工作中获得的 github Client ID
    client_secret: 改为你在前置工作中获得的 github Client secret
    # 以下代码不要动
    endpoint:
      auth_url: https://github.com/login/oauth/authorize
      token_url: https://github.com/login/oauth/access_token
    user_id_path: id
    user_info_url: https://api.github.com/user
```

3. **登录哪吒管理后台，打开个人设置**

在头像右侧找到 `Oauth2 bindings`，点击绑定，即可以 github 账户登录

同时建议点击`更新个人资料`，勾选`禁止密码登录`

### 设置前端界面背景图

打开`系统设置`，找到`自定义代码（样式和脚本）`，输入以下代码：

```html
<script>
    window.CustomBackgroundImage = "改为你喜欢的背景图直链，以 http(s) 开头";
    window.CustomDesc = "VPS探针";
</script>
```

### 设置TG通知

只说TG通知，其他通知方式请看官方文档

- 打开`系统设置` —— `通知`，点 + 号创建
- 名称：TG 通知
- URL：`https://api.telegram.org/bot<tg token>/sendMessage?chat_id=<tg id>&text=#NEZHA#`,替换 <> 及其中的内容
- 跳转到 `警报规则`，点 + 号创建
- 离线警报
  - 名称：⚡ 离线
  - 规则：`[{"type":"offline","duration":180,"cover":0}]`
- 其他警报规则请看官方文档

----

## 许可证

本项目采用 [MIT 许可证](LICENSE)。
