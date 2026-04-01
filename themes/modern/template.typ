// ─────────────────────────────────────────────────────────
//  导入模块化协议
// ─────────────────────────────────────────────────────────

#import "../module-core.typ": get-url-label, markup, render-contacts, render-dict-item, resume-info-extras, standard-modules

// ─────────────────────────────────────────────────────────
//  图标定义（Font-based Unicode icons）
// ─────────────────────────────────────────────────────────

#let icon(symbol) = box(
  baseline: 0.125em,
  height: 1.2em,
  width: 1.2em,
  align(center + horizon, text(size: 0.95em, symbol)),
)

#let fa-home = icon("🏠")
#let fa-email = icon("✉")
#let fa-github = icon("🐙")
#let fa-linkedin = icon("💼")
#let fa-phone = icon("☎")
#let fa-weixin = icon("💬")


// ─────────────────────────────────────────────────────────
//  辅助函数
// ─────────────────────────────────────────────────────────

// 根据联系方式类型返回对应图标
#let contact-icon(t) = {
  if t == "email" { fa-email } else if t == "phone" { fa-phone } else if t == "github" { fa-github } else if (
    t == "linkedin"
  ) { fa-linkedin } else if t == "wechat" { fa-weixin } else { fa-home }
}

// 中文分隔线
#let chi-line() = {
  v(-3pt)
  line(length: 100%)
  v(-5pt)
}


// ─────────────────────────────────────────────────────────
//  简历块级元素
// ─────────────────────────────────────────────────────────

// 简历分隔线
#let resume-section(title) = {
  [== #title]
  chi-line()
}

// 简历条目（包含标题、职位、详情、时间）
#let resume-item(title: "", position: "", detail: "", time: "", url: "", url-label: "") = {
  let title-content = markup(title)
  grid(
    columns: (1fr, auto),
    [*#title-content*], [#markup(time)],
  )
  if position != "" {
    grid(
      columns: (1fr, auto),
      [#markup(position)], if detail != "" { [#markup(detail)] } else { [] },
    )
  }
  v(0.3em)
}

// ─────────────────────────────────────────────────────────
//  主题入口函数
// ─────────────────────────────────────────────────────────

#let blueprint(
  data: (:),
  fonts-global: (),
  body,
) = {
  // 获取所有模块（使用模块化协议）
  let modules = standard-modules(data)

  // 提取个人信息用于头部渲染
  let resume-info = data.at("information", default: (:))
  let name = resume-info.at("name", default: "未命名")
  let avatar = resume-info.at("avatar", default: "")
  let contacts = resume-info.at("contacts", default: ())

  // 主题字体配置
  let fonts-theme = ("Heiti SC", "Heiti SC")
  let fonts-effective = if fonts-global.len() > 0 { (..fonts-global, ..fonts-theme) } else { fonts-theme }

  // 页面和文字样式设置
  set page(margin: (x: 0.9cm, y: 1.3cm), paper: "a4")
  set text(size: 11pt, font: fonts-effective, lang: "zh")
  show link: text
  set par(justify: true)
  set document(title: name + " 的简历", author: name)

  // ─────────────────────────────────────────────────────────
  //  简历头部
  // ─────────────────────────────────────────────────────────

  // 姓名
  align(center, text(style: "normal", weight: "extrabold", size: 20pt, name))

  // 头像（可选）
  if avatar != "" and avatar != none {
    place(top + right, dy: -2em, image(avatar, height: 33mm))
  }

  // 联系方式（带图标）
  if contacts.len() > 0 {
    align(
      center,
      render-contacts(contacts, delimiter: h(0.5em) + "·" + h(0.5em), icon-fn: c-type => box(
        height: 1em,
        contact-icon(c-type),
      )),
    )
  }
  v(0.5em)

  // ─────────────────────────────────────────────────────────
  //  简历信息扩展字段
  // ─────────────────────────────────────────────────────────

  let extras = resume-info-extras(resume-info)


  // ─────────────────────────────────────────────────────────
  //  简历内容（模块化渲染）
  // ─────────────────────────────────────────────────────────

  for module in modules {
    if module.id == "resume-info" {
      // resume-info 已经在头部渲染，跳过
      continue
    } else if module.id == "education" {
      // 教育经历
      resume-section(module.title)
      for edu in module.payload {
        let url = edu.at("url", default: "")
        resume-item(
          title: edu.school,
          position: edu.degree,
          detail: edu.major,
          time: edu.start + " ~ " + edu.end,
          url: url,
          url-label: edu.at("url-label", default: ""),
        )
        let details = edu.at("details", default: ())
        let all-items = details.map(d => markup(d))
        if url != "" {
          let label = get-url-label(url, custom-label: edu.at("url-label", default: ""))
          all-items.insert(0, text(size: 9pt, fill: gray, [#label #link(url)]))
        }
        if all-items.len() > 0 {
          list(..all-items)
        }
        v(0.2em)
      }
    } else if module.id == "experience" {
      // 工作经历
      resume-section(module.title)
      for exp in module.payload {
        let url = exp.at("url", default: "")
        resume-item(
          title: exp.company,
          position: exp.position,
          time: exp.start + " ~ " + exp.end,
          url: url,
          url-label: exp.at("url-label", default: ""),
        )
        let details = exp.at("details", default: ())
        let all-items = details.map(d => markup(d))
        if url != "" {
          let label = get-url-label(url, custom-label: exp.at("url-label", default: ""))
          all-items.insert(0, text(size: 9pt, fill: gray, [#label #link(url)]))
        }
        if all-items.len() > 0 {
          list(..all-items)
        }
        v(0.2em)
      }
    } else if module.id == "internship" {
      // 实习经历
      resume-section(module.title)
      for intern in module.payload {
        let url = intern.at("url", default: "")
        resume-item(
          title: intern.at("company", default: intern.at("name", default: "")),
          position: intern.at("position", default: intern.at("role", default: "")),
          time: intern.start + " ~ " + intern.end,
          url: url,
          url-label: intern.at("url-label", default: ""),
        )
        let details = intern.at("details", default: ())
        let all-items = details.map(d => markup(d))
        if url != "" {
          let label = get-url-label(url, custom-label: intern.at("url-label", default: ""))
          all-items.insert(0, text(size: 9pt, fill: gray, [#label #link(url)]))
        }
        if all-items.len() > 0 {
          list(..all-items)
        }
        v(0.2em)
      }
    } else if module.id == "projects" {
      // 项目经历
      resume-section(module.title)
      for proj in module.payload {
        let url = proj.at("url", default: "")
        resume-item(
          title: proj.name,
          position: proj.role,
          time: proj.start + " ~ " + proj.end,
          url: url,
          url-label: proj.at("url-label", default: ""),
        )
        let details = proj.at("details", default: ())
        let all-items = details.map(d => markup(d))
        if url != "" {
          let label = get-url-label(url, custom-label: proj.at("url-label", default: ""))
          all-items.insert(0, text(size: 9pt, fill: gray, [#label #link(url)]))
        }
        if all-items.len() > 0 {
          list(..all-items)
        }
        v(0.2em)
      }
    } else if module.id == "skills" {
      // 个人技能
      resume-section(module.title)
      list(..module.payload.map(skill => markup(skill)))
    } else {
      // 自定义模块（通用处理）
      resume-section(module.title)
      if type(module.payload) == array {
        list(..module.payload.map(item => {
          if type(item) == str {
            [#markup(item)]
          } else if type(item) == dictionary {
            render-dict-item(item)
          } else {
            [#str(item)]
          }
        }))
      } else if type(module.payload) == str {
        [#markup(module.payload)]
      } else {
        module.payload
      }
    }
  }

  // resume-info 扩展字段（放在简历尾部）
  if extras.summary != "" {
    resume-section("个人简介")
    [#markup(extras.summary)]
  }

  if extras.self-evaluation != "" {
    resume-section("自我评价")
    [#markup(extras.self-evaluation)]
  }

  if extras.interests.len() > 0 {
    resume-section("兴趣爱好")
    [#extras.interests.join("、")]
  }

  body
}
