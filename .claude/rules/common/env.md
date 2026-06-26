# Environment Variables (.env) 规范

## 文件命名与用途

| 文件 | 用途 | 提交 Git |
|------|------|----------|
| `.env` | 默认环境变量 | ❌ |
| `.env.local` | 本地覆盖（个人） | ❌ |
| `.env.development` | 开发环境 | ✅ |
| `.env.production` | 生产环境 | ✅ |
| `.env.example` | 变量文档/模板 | ✅ |
| `.env.*.local` | 环境特定本地覆盖 | ❌ |

## 安全规则

1. **永远不提交** `.env`、`.env.local`、`.env.*.local`
2. **禁止**在代码中硬编码密钥、Token、密码
3. **禁止**在日志中打印环境变量值
4. `.env.example` 中用占位符代替真实值（如 `sk-xxxxx`）

## 变量命名

```bash
# 格式：大写下划线，前缀表示作用域
APP_NAME=study-system
APP_PORT=3000

# API 密钥加前缀
API_KEY=sk-xxxxx
MINIMAX_API_KEY=xxxxx

# 数据库
DATABASE_URL=postgresql://localhost:5432/mydb

# 布尔值用小写
DEBUG=true
FEATURE_X_ENABLED=false
```

## .env.example 模板

```bash
# === Application ===
APP_NAME=study-system
APP_PORT=3000
NODE_ENV=development

# === API Keys ===
# Get from: https://platform.minimax.io
MINIMAX_API_KEY=your-key-here

# === Database ===
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# === Debug ===
DEBUG=false
```

## 代码中使用

```javascript
// Node.js
const apiKey = process.env.API_KEY;

// 必需变量启动时校验
const required = ['API_KEY', 'DATABASE_URL'];
for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required env: ${key}`);
  }
}
```

## .gitignore 确保覆盖

```gitignore
# 已配置
.env
.env.local
.env.*.local
```

## 检查清单

- [ ] `.env` 在 `.gitignore` 中
- [ ] `.env.example` 提交到仓库（无真实密钥）
- [ ] 敏感变量命名带 `_KEY`、`_SECRET`、`_TOKEN` 后缀
- [ ] 启动时校验必需变量
- [ ] 不在 `console.log` 中打印环境变量
