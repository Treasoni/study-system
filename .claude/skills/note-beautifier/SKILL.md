---
name: note-beautifier
description: 将学习笔记导出为多种格式：PDF、Word、PPT。支持排版美化、图表生成、多格式输出。触发词：导出、美化、PDF、Word、PPT、排版、格式转换、beautify、export。
---

# Note Beautifier - 学习笔记美化输出器

将 Markdown 学习笔记导出为多种格式，支持排版美化和图表生成。

## 触发条件

当用户提出以下类型的请求时，调用此技能:

- "帮我导出为 PDF"
- "生成 Word 文档"
- "做成 PPT"
- "美化一下排版"
- "格式转换"
- "导出成其他格式"
- 任何涉及笔记格式转换或美化的请求

## 核心功能

### 功能 1: PDF 导出

将 Markdown 转换为精美的 PDF 文档。

**实现方式**:
```bash
# 使用 pandoc 转换
pandoc input.md -o output.pdf --pdf-engine=xelatex -V mainfont="Noto Sans CJK SC"

# 或使用 md-to-pdf (如果安装了)
md-to-pdf input.md
```

**美化选项**:
- 自定义字体和字号
- 添加页眉页脚
- 目录生成
- 代码高亮
- 图表支持

### 功能 2: Word 导出

将 Markdown 转换为 Word 文档 (.docx)。

**实现方式**:
```bash
# 使用 pandoc 转换
pandoc input.md -o output.docx --reference-doc=template.docx

# 基础转换
pandoc input.md -o output.docx
```

**美化选项**:
- 自定义样式模板
- 目录生成
- 图片和表格支持
- 批注和修订

### 功能 3: PPT 导出

将 Markdown 转换为 PowerPoint 演示文稿。

**实现方式**:
```bash
# 使用 pandoc 转换
pandoc input.md -o output.pptx --slide-level=2

# 使用 mdppt (专门工具)
mdppt input.md -o output.pptx
```

**美化选项**:
- 自定义主题和配色
- 幻灯片布局
- 动画效果
- 图表和图片

### 功能 4: Markdown 美化

在导出前美化 Markdown 格式。

**美化内容**:
1. **标题层级统一**: 确保标题层级正确
2. **代码块格式**: 添加语言标识，统一缩进
3. **表格格式**: 对齐表格列，美化表格样式
4. **列表格式**: 统一列表符号，嵌套缩进
5. **引用格式**: 美化引用块样式
6. **图片处理**: 调整图片大小，添加图注

## 工作流程

### Step 1: 读取源文件

1. 读取 `/workspace/learning_notes/output/final_note.md`
2. 如果不存在，读取 `/workspace/learning_notes/chapters/` 下的所有章节文件
3. 检查文件内容和格式

### Step 2: 选择输出格式

询问用户需要的输出格式:

**请选择输出格式:**
| 选项 | 说明 |
|------|------|
| 📄 PDF | 适合打印、分享、存档 |
| 📝 Word | 适合编辑、协作、提交 |
| 📊 PPT | 适合演示、汇报、教学 |
| 🎨 Markdown美化 | 仅美化格式，不转换 |

### Step 3: 美化处理

根据选择的格式，执行相应的美化:

#### PDF 美化:
1. 添加封面页
2. 生成目录
3. 设置页眉页脚
4. 调整字体和间距
5. 代码高亮
6. 图表支持

#### Word 美化:
1. 应用样式模板
2. 生成目录
3. 设置页眉页脚
4. 图片和表格格式化
5. 添加批注模板

#### PPT 美化:
1. 选择主题模板
2. 分割幻灯片
3. 添加过渡动画
4. 优化图表展示
5. 添加演讲者备注

### Step 4: 执行转换

使用适当的工具进行格式转换:

```bash
# PDF 转换
pandoc input.md -o output.pdf [options]

# Word 转换
pandoc input.md -o output.docx [options]

# PPT 转换
pandoc input.md -o output.pptx [options]
```

### Step 5: 保存输出

将生成的文件保存到:
```
/workspace/learning_notes/output/final_note.{format}
```

### Step 6: 生成导出报告

向用户展示导出结果:

```markdown
## 📤 笔记导出完成

### 输出信息
- 格式：{PDF/Word/PPT}
- 文件大小：{size}
- 页数/幻灯片数：{n}

### 文件路径
- 完整笔记：`/workspace/learning_notes/output/final_note.{format}`

### 美化内容
- ✅ 目录生成
- ✅ 代码高亮
- ✅ 图表支持
- ✅ 格式统一

### 后续操作
- 如需进一步修改，请指定具体部分
- 如需导出其他格式，请告知
```

## 输出格式规范

### PDF 输出规范
```yaml
页面设置:
  纸张: A4
  边距: 2.5cm
  方向: 纵向

字体设置:
  正文: "Noto Sans CJK SC" 12pt
  标题: "Noto Sans CJK SC" 16pt
  代码: "Fira Code" 10pt

页眉页脚:
  页眉: 章节标题
  页脚: 页码
```

### Word 输出规范
```yaml
样式模板:
  标题1: Heading 1
  标题2: Heading 2
  正文: Normal
  代码块: Code Block

目录设置:
  层级: 3
  带页码: true
  超链接: true
```

### PPT 输出规范
```yaml
幻灯片设置:
  比例: 16:9
  主题: 默认
  配色: 蓝色系

内容分布:
  标题幻灯片: 1
  内容幻灯片: {n}
  总结幻灯片: 1
```

## 工具依赖

### 必需工具
```bash
# pandoc (核心转换工具)
brew install pandoc

# xelatex (PDF 生成)
brew install --cask mactex-no-gui

# 图表生成 (可选)
brew install graphviz
```

### 可选工具
```bash
# md-to-pdf (Node.js 工具)
npm install -g md-to-pdf

# mdppt (PPT 专用)
npm install -g mdppt

# pandoc-filter (过滤器)
pip install pandocfilters
```

## 高级用法

### 1. 自定义模板

```bash
# 使用自定义 PDF 模板
pandoc input.md -o output.pdf \
  --template=mytemplate.tex \
  --variable=mainfont:"Noto Sans CJK SC"

# 使用自定义 Word 模板
pandoc input.md -o output.docx \
  --reference-doc=mytemplate.docx
```

### 2. 批量导出

```bash
# 导出所有格式
for format in pdf docx pptx; do
  pandoc input.md -o output.$format
done
```

### 3. 增量更新

```bash
# 仅更新修改的章节
pandoc chapters/*.md -o output.pdf
```

## 常见问题

### Q1: PDF 中文显示乱码
```bash
# 使用 XeLaTeX 引擎
pandoc input.md -o output.pdf --pdf-engine=xelatex

# 指定中文字体
pandoc input.md -o output.pdf \
  --pdf-engine=xelatex \
  -V mainfont="Noto Sans CJK SC"
```

### Q2: 代码块格式丢失
```bash
# 添加代码高亮
pandoc input.md -o output.pdf \
  --highlight-style=tango

# 使用自定义样式
pandoc input.md -o output.pdf \
  --highlight-style=mytheme
```

### Q3: 图片不显示
```bash
# 确保图片路径正确
# 使用相对路径或绝对路径
pandoc input.md -o output.pdf \
  --resource-path=.
```

## 注意事项

1. **工具依赖**: 确保 pandoc 和相关工具已安装
2. **字体支持**: PDF 导出需要中文字体支持
3. **图片路径**: 确保图片路径正确，建议使用相对路径
4. **文件大小**: 大量图片可能导致文件过大，建议压缩图片
5. **格式兼容**: Word 格式可能在不同版本中有差异
6. **性能考虑**: 大文件转换可能需要较长时间

## 与其他技能的关系

```
note-assembler (组装)
    ↓ 生成 final_note.md
note-beautifier (本技能)
    ↓ 格式转换 + 美化
    ↓
最终输出 (PDF/Word/PPT)
```
