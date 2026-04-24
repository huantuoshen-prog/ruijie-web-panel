# 开发者文档

## 项目结构

```text
ruijie-web-panel/
├── src/              # React + TypeScript 源码
├── public/           # 静态资源
├── dist/             # 提交到仓库的部署产物
├── api/              # CGI 脚本
├── init.d/           # OpenWrt 服务脚本
├── mock/             # 本地 mock server
├── tests/            # API 合同测试
├── README.md
└── docs/
```

## 前端

- 入口：`src/App.tsx`
- API client：`src/lib/api.ts`
- 样式：`src/styles.css`
- 构建：

```bash
npm install
npm run lint
npm run test
npm run build
```

## CGI 后端

每个接口一个脚本，统一通过 `/ruijie-cgi/<name>` 路由暴露。

新增接口时：

1. 在 `api/` 新建脚本
2. 在前端 `src/lib/api.ts` 增加调用
3. 在安装脚本中加入新 CGI 文件与路由
4. 更新 `docs/api.md`
5. 补充 `tests/test_api_contract.sh`

## 本地调试

```bash
npm install
npm run build
python3 mock/server.py
```

## 测试

```bash
# CGI / API 合同测试
bash tests/run_tests.sh

# 前端测试
npm run test
```
