# 主题开发指南 (Theme Development Guide)

非常欢迎社区开发者贡献更多精美的主题！为了保证生态的统一和高可用性，请在开发主题时严格遵守以下规范。

---

## 字体覆盖与校验（重要）

本项目已支持全局字体优先：`resume.typ` 会把 `data.yml` 中的 `global-font.fonts` 传入主题的 `fonts-global` 参数。

主题侧推荐模式：

```typst
#let fonts-theme = ("Heiti SC", "PingFang SC")
#let fonts-effective = if fonts-global.len() > 0 { (..fonts-global, ..fonts-theme) } else { fonts-theme }
#set text(font: fonts-effective)
```

请注意：

1. 字体族名称必须与 Typst 识别名称一致（可用 `typst fonts` 查询）。
2. 建议优先使用系统已安装字体，避免不同环境下字体发现行为不一致。
3. 开发/发布前建议执行严格字体检查，避免“本机有字体、他人环境缺失”问题：

```bash
python compile_previews.py --preview --strict-fonts
```

4. 避免在局部 `text(...)` 中硬编码其他字体（如 `font: "Arial"`），否则会绕过全局字体覆盖。

---

## 1. 目录结构规范

每一个新主题必须放置在 `themes/<主题名>/` 目录下，并且至少包含以下两个核心文件：

```text
themes/my-theme/
├── template.typ    # 1. 核心渲染代码，导出 blueprint() 函数
└── example.typ     # 2. 专属预览入口（无需修改项目根目录即可独立编译预览）
```

---

## 2. 模块化渲染协议（推荐）

为了让主题开发更简单、更统一，本项目提供了 **模块化渲染协议**（`themes/module-core.typ`）。

### 核心理念

将简历分为以下几类模块，主题作者只需为每类模块设计样式：

1. **information** - 个人信息（姓名、头像、联系方式等；主题侧对应 `module.id == "resume-info"`）
2. **education** - 教育经历
3. **experience** - 工作经历
4. **projects** - 项目经历
5. **internship** - 实习经历
6. **skills** - 个人技能
7. **awards** - 荣誉奖项
8. **certificates** - 资质证书
9. **自定义模块** - 用户可以在 `content` 数组中添加任意 `type`

### 使用方法

在你的 `template.typ` 中引入模块协议：

```typst
#import "../module-core.typ": standard-modules

#let blueprint(data: (:), body) = {
  // 获取所有模块
  let modules = standard-modules(data)

  // 遍历渲染每个模块
  for module in modules {
    if module.id == "resume-info" {
      // 渲染头部个人信息
      render-header(module.payload)
    } else if module.id == "education" {
      // 渲染教育经历
      render-section(module.title)
      for item in module.payload {
        render-education-item(item)
      }
    } else if module.id == "experience" {
      // 渲染工作经历
      render-section(module.title)
      for item in module.payload {
        render-experience-item(item)
      }
    } else if module.id == "projects" {
      // 渲染项目经历
      render-section(module.title)
      for item in module.payload {
        render-project-item(item)
      }
    } else if module.id == "internship" {
      // 渲染实习经历
      render-section(module.title)
      for item in module.payload {
        render-internship-item(item)
      }
    } else if module.id == "skills" {
      // 渲染技能列表
      render-section(module.title)
      render-skills(module.payload)
    } else {
      // 渲染自定义模块（通用处理）
      render-section(module.title)
      render-custom-content(module.payload)
    }
  }

  body
}
```

### 模块数据结构

每个模块是一个字典，包含以下字段：

- `id` (string): 模块的唯一标识符
- `title` (string): 模块的显示标题（新格式来自 `content[].title`）
- `payload` (any): 模块的数据内容

### 用户如何自定义

用户可以在 `data.yml` 中通过 `content` 数组天然控制模块顺序：

```yaml
information:
    name: "你的名字"
    contacts: []

content:
    - type: education
      title: "教育背景"
      items:
          - school: "..."
    - type: awards
      title: "获奖情况"
      items:
          - title: "国家奖学金"
            date: "2023"
```

---

## 3. 接口标准规范（传统方式）

如果不使用模块化协议，`template.typ` 必须导出一个名为 `blueprint` 的入口函数，并接收 `data` 字典作为参数。推荐同时支持可选参数 `fonts-global`，用于接收来自 `resume.typ` 的全局字体列表，实现“全局字体优先、主题字体兜底”。

```typst
#let blueprint(
  data: (:),
  fonts-global: (),
  body,
) = {
  // 主题字体配置（由主题作者决定）
  let fonts-theme = ("Heiti SC", "Heiti SC")
  let fonts-effective = if fonts-global.len() > 0 { (..fonts-global, ..fonts-theme) } else { fonts-theme }

  // 应用字体
  set text(font: fonts-effective)

  // 渲染逻辑...
}
```

---

## 4. 预览入口规范 (example.typ)

在你的主题目录中，必须提供 `example.typ` 用于独立预览：

```typst
#import "template.typ": blueprint

#let data = yaml("../../data.yml")  // 引用项目根目录的数据

#show: blueprint.with(data: data)
```

**预览命令：**

```bash
typst compile themes/my-theme/example.typ --root .
```

---

## 5. 数据健壮性规范（非常重要）

在从 `data` 字典中提取数据时，**必须提供默认值 (default)**，避免用户未填写某字段时导致编译崩溃。

```typst
// ✅ 正确做法：
let resume-info = data.at("information", default: data.at("resume-info", default: (:)))
let avatar = resume-info.at("avatar", default: "")
let content = data.at("content", default: data.at("sections", default: ()))

// ❌ 错误做法（会导致崩溃）：
// let avatar = data.resume-info.avatar
```

---

## 6. 代码规范

### 命名规范

- 使用 kebab-case（连字符）命名**所有**函数和变量：
    - ✅ 正确：`resume-item`, `chi-line`, `fa-home`, `contact-icon`
    - ❌ 错误：`resume_item`, `chiline`, `fa_home`

### 代码组织

- 用分隔注释块组织代码，提高可读性：

    ```typst
    // ─────────────────────────────────────────────────────────
    //  图标定义
    // ─────────────────────────────────────────────────────────

    #let icon(symbol) = { ... }

    // ─────────────────────────────────────────────────────────
    //  辅助函数
    // ─────────────────────────────────────────────────────────

    #let format-date(date) = { ... }
    ```

### 函数写法

- 对于有多个参数的函数，使用命名参数：
    ```typst
    #let resume-item(title: "", position: "", detail: "", time: "") = {
      // ...
    }
    ```

---

## 7. 统一 YAML 数据规范

所有主题必须优先支持以下统一格式：`information + content`。

### 顶层结构

```yaml
global-font:
    fonts: []

information:
    title: "个人信息"
    name: ""
    avatar: ""
    contacts: []
    summary: ""
    self-evaluation: ""
    interests: []

content:
    - type: education
      title: "教育经历"
      items: []
    - type: experience
      title: "工作经历"
      items: []
    - type: projects
      title: "项目经历"
      items: []
```

### content 条目约定

- `type`: 模块类型（如 `education`/`experience`/`projects`/`skills`/`awards`/`certificates`）
- `title`: 段落标题
- `items`: 条目数组
- `enabled`（可选）: `false` 时跳过渲染

### 字段示例

```yaml
content:
    - type: education
      title: "教育经历"
      items:
          - school: "学校名称"
            degree: "学位"
            major: "专业"
            start: "2020.09"
            end: "2024.06"
            details:
                - "..."

    - type: internship
      title: "实习经历"
      items:
          - name: "项目或实习名称"
            role: "职责"
            start: "2024.01"
            end: "2024.03"
            details:
                - '项目地址：#link("https://example.com/project")[https://example.com/project]'
                - "技术栈：Go / PostgreSQL / Redis"
                - "..."

    - type: skills
      title: "技能"
      items:
          - name: "Python"
            level: "精通"
            description: "5年经验"
          - "熟悉 Docker/K8s 等容器化技术"
          - category: "前端"
            items: ["React", "Vue"]
```

> 兼容说明：`module-core.typ` 仍兼容旧格式（`resume-info` / `sections` / `module-config`），但新主题与新数据建议统一采用 `information` / `content`。

补充约定：

- 项目、实习等带外链的条目统一使用 `url` 字段。
- 如果链接恰好是 GitHub，写成普通 `url` 即可；是否显示为 GitHub 由主题样式自行决定。
- 技术栈描述优先写入 `details` 中的一行文本，例如 `技术栈：Go / Redis / PostgreSQL`，不单独约定 `tags` 字段。

### module-core.typ 辅助函数

主题可从 `module-core.typ` 导入以下常用工具：

| 函数                                        | 说明                                                                  |
| ------------------------------------------- | --------------------------------------------------------------------- |
| `standard-modules(data)`                    | 将 YAML 数据解析为标准化模块数组，每个模块含 `id`, `title`, `payload` |
| `extract-items(section-data)`               | 从段落数据中提取 items 数组（兼容裸数组和 `{title, items}` 字典）     |
| `extract-title(section-data, fallback: "")` | 从段落数据中提取标题                                                  |
| `contact-value(c)`                          | 获取联系方式的显示值（兼容 `value` 和 `label` 字段）                  |
| `render-contact(c)`                         | 渲染单个联系方式（自动处理 URL 链接）                                 |
| `render-contacts(contacts, ...)`            | 批量渲染联系方式（支持 delimiter/show-label/icon-fn 参数）            |
| `normalize-skills(skills)`                  | 将混合格式的技能数组归一化为字符串列表                                |
| `resume-info-extras(resume-info)`           | 提取 resume-info 中的扩展字段（summary, interests 等）                |
| `render-dict-item(item)`                    | 通用字典条目渲染                                                      |
| `markup(text)`                              | 将 YAML 字符串按内嵌 Typst 语法解析                                   |

---

## 8. 自定义扩展

用户可以在 `data.yml` 的 `content` 数组中增加自定义 `type`（例如 `publications`、`open-source` 等）。主题开发者若希望支持这些扩展字段：

1. 在 `blueprint()` 中用 `.at()` 方法检查和提取
2. 提供默认值以保证健壮性
3. 在 README 或文件头注释中说明支持的扩展字段

**示例：**

```typst
let content = data.at("content", default: data.at("sections", default: ()))
for section in content {
  if section.at("type", default: "") == "publications" {
    let items = section.at("items", default: ())
    // 渲染 publications...
  }
}
```

---

## 9. 提交新主题

完成开发后，欢迎向本项目提交 Pull Request：

1. 确保目录结构符合规范
2. 运行 `typst compile themes/my-theme/example.typ --root .` 测试编译
3. 在 PR 中说明主题的特色和适用场景
4. 更新根目录 [README.md](../README.md) 的主题预览部分（可选）

---

## 10. 常见问题与解决方案

### Q: 如何在主题中使用字体？

A: 在 `blueprint()` 的最开始定义 `fonts-theme` 变量，使用 `set text(font: fonts-theme)` 全局应用。不要从用户数据或参数中读取字体，字体应该是主题设计的一部分。

### Q: 如何处理可选的数据字段？

A: **始终**使用 `.at("field", default: value)` 的写法。对于合成类字段（对象或数组），应提供合理的默认值（通常是 `(:)` 或 `()`）。

### Q: 如何渲染嵌套的列表数据？

A: 使用 `.map(d => [...])` 和 `.join()` 的组合：

```typst
details.map(d => [#d]).join("\n")
```

### Q: 编译时出现"unknown font"警告，怎么办？

A: 确保使用的字体在目标系统上可用。对于中文主题，常用的安全字体有：

- macOS: Songti SC, Heiti SC, Kaiti SC
- Windows: SimSun, SimHei
- Linux/跨平台: Noto Sans CJK SC

---

## 11. 参考实现

本项目的 `modern` 和 `classic` 两个主题都是完整的参考实现。建议在开发新主题时参考它们的结构和编码风格。
