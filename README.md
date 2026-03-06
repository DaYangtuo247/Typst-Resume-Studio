<div align="center">
  <img src="./img/logo.svg" alt="Typst Resume Studio" width="120" height="120" />
  
  # 🎓 Typst Resume Studio

</div>

一个基于 [Typst](https://typst.app) 构建的**数据驱动型**开源简历模板框架。通过完全分离**简历数据 (YAML)** 与**排版样式 (Typst)**，让你可以像填表一样写简历，同时轻松切换不同的精美主题。

## ✨ 特性

- 📝 **完全数据驱动**：所有的个人信息、经历、项目都在 `data.yml` 中维护。对非程序员极度友好！
- 🎨 **多主题支持**：内置六套主题，一键切换。
- 🧩 **超高扩展性**：主题统一接收数据字典，自由扩展如“荣誉奖项”、“技能清单”等自定义区块，无需修改底层核心接口。
- ⚡ **自动化构建**：内置 GitHub Actions 工作流，Fork 本项目并在网页端修改 YAML 即可自动生成并下载 PDF 简历。

## 🚀 快速开始

### 1. 网页端（推荐）

1. **Fork** 本仓库。
2. 修改 `data.yml` 中的个人信息。
3. 提交更改，GitHub Actions 将自动编译并生成 PDF，你可以在 **Actions** 标签页下载。

### 2. 本地编译

确保已安装 [Typst CLI](https://github.com/typst/typst)。

```bash
# 编译主简历 (使用 resume.typ 中指定的主题)
typst compile resume.typ

# 预览特定主题 (以 modern 为例)
typst compile themes/modern/example.typ --root .
```

## 🛠️ 自动化工具 (`compile_previews.py`)

项目内置了一个 Python 脚本，用于批量生成主题预览图和管理文档。

### 环境依赖

- Python 3.x
- Typst CLI

### 常用命令

```bash
# 1. 为所有主题生成简历预览 (默认使用 data.yml，输出到 previews/ 目录)
python compile_previews.py --preview

# 2. 使用指定的数据文件 (如 my_data.yml) 为所有主题生成预览
python compile_previews.py --preview -f my_data.yml
```

## 🎨 主题

本项目内置精美主题，可通过修改 `resume.typ` 中的 import 语句快速切换。

| Ats Friendly | Avatar Pro | Brilliant Cv |
| :---: | :---: | :---: |
| ![](themes/ats-friendly/ats-friendly.png) | ![](themes/avatar-pro/avatar-pro.png) | ![](themes/brilliant-cv/brilliant-cv.png) |
| Classic | Finance Blue | Modern |
| ![](themes/classic/classic.png) | ![](themes/finance-blue/finance-blue.png) | ![](themes/modern/modern.png) |
| Prism | Resume Ng | Tech Pro |
| ![](themes/prism/prism.png) | ![](themes/resume-ng/resume-ng.png) | ![](themes/tech-pro/tech-pro.png) |
