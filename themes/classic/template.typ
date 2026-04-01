// ─────────────────────────────────────────────────────────
//  导入模块化协议
// ─────────────────────────────────────────────────────────

#import "../module-core.typ": (
  contact-value, get-url-label, markup, render-contacts, render-dict-item, resume-info-extras, standard-modules,
)

// ─────────────────────────────────────────────────────────
//  辅助函数
// ─────────────────────────────────────────────────────────

#let delimiter = " | "

#let array-to-str(a, delimiter: delimiter) = {
  a.join(delimiter)
}

#let resume-date(start, end: "") = {
  if start == "" and end == "" {
    ""
  } else {
    start + " " + "–" + " " + end
  }
}


// ─────────────────────────────────────────────────────────
//  简历块级元素
// ─────────────────────────────────────────────────────────

#let resume-item(left: "", right: "", url: "", url-label: "", body) = {
  text(size: 12pt, place(end, right))
  text(size: 12pt, left)
  linebreak()
  body
}

#let resume-education(university: "", degree: "", school: "", start: "", end: "", url: "", url-label: "", body) = {
  let uni-content = strong(markup(university))
  let left = (
    uni-content,
    if school != "" { markup(school) } else { [] },
    if degree != "" { markup(degree) } else { [] },
  )
  let right = resume-date(start, end: end)

  resume-item(
    left: array-to-str(left),
    right: right,
    url: url,
    url-label: url-label,
    body,
  )
}

#let resume-work(company: "", duty: "", start: "", end: "", url: "", url-label: "", body) = {
  let company-content = strong(markup(company))
  let left = (company-content, if duty != "" { markup(duty) } else { [] })
  let right = resume-date(start, end: end)

  resume-item(
    left: array-to-str(left),
    right: right,
    url: url,
    url-label: url-label,
    body,
  )
}

#let resume-project(title: "", duty: "", start: "", end: "", url: "", url-label: "", body) = {
  let title-content = strong(markup(title))
  let left = (title-content, if duty != "" { markup(duty) } else { [] })
  let right = resume-date(start, end: end)

  resume-item(
    left: array-to-str(left),
    right: right,
    url: url,
    url-label: url-label,
    body,
  )
}

#let resume-section(title) = {
  v(-8pt)
  heading(level: 1, title)
  line(length: 100%)
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
  let contacts = resume-info.at("contacts", default: ())

  // 主题字体配置
  let fonts-theme = ("Heiti SC", "Heiti SC")
  let fonts-effective = if fonts-global.len() > 0 { (..fonts-global, ..fonts-theme) } else { fonts-theme }

  // 页面和文字样式设置
  set document(author: name, title: name + " 的简历")
  set page(margin: (x: 1cm, y: 1cm))
  set text(font: fonts-effective, lang: "zh")

  // ─────────────────────────────────────────────────────────
  //  简历头部
  // ─────────────────────────────────────────────────────────

  // 姓名
  align(center)[
    #block(text(weight: 700, 1.7em, name))
  ]

  // 联系方式
  if contacts.len() > 0 {
    set align(center)
    render-contacts(contacts, delimiter: [  |  ])
    v(0.3em)
  }

  // ─────────────────────────────────────────────────────────
  //  简历信息扩展字段
  // ─────────────────────────────────────────────────────────

  let extras = resume-info-extras(resume-info)

  set par(justify: true)

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
        let url-label = edu.at("url-label", default: "")
        resume-education(
          university: edu.school,
          degree: edu.degree,
          school: edu.major,
          start: edu.start,
          end: edu.end,
          url: url,
          url-label: url-label,
        )[
          #let details = edu.at("details", default: ())
          #if url != "" {
            let label = get-url-label(url, custom-label: url-label)
            details.insert(0, text(size: 9pt, fill: gray, [#label #link(url)]))
          }
          #if details.len() > 0 {
            list(..details.map(d => if type(d) == content { d } else { markup(d) }))
          }
        ]
      }
    } else if module.id == "experience" {
      // 工作经历
      resume-section(module.title)
      for exp in module.payload {
        let url = exp.at("url", default: "")
        let url-label = exp.at("url-label", default: "")
        resume-work(
          company: exp.company,
          duty: exp.position,
          start: exp.start,
          end: exp.end,
          url: url,
          url-label: url-label,
        )[
          #let details = exp.at("details", default: ())
          #if url != "" {
            let label = get-url-label(url, custom-label: url-label)
            details.insert(0, text(size: 9pt, fill: gray, [#label #link(url)]))
          }
          #if details.len() > 0 {
            list(..details.map(d => if type(d) == content { d } else { markup(d) }))
          }
        ]
      }
    } else if module.id == "internship" {
      // 实习经历
      resume-section(module.title)
      for intern in module.payload {
        let url = intern.at("url", default: "")
        let url-label = intern.at("url-label", default: "")
        resume-work(
          company: intern.at("company", default: intern.at("name", default: "")),
          duty: intern.at("position", default: intern.at("role", default: "")),
          start: intern.start,
          end: intern.end,
          url: url,
          url-label: url-label,
        )[
          #let details = intern.at("details", default: ())
          #if url != "" {
            let label = get-url-label(url, custom-label: url-label)
            details.insert(0, text(size: 9pt, fill: gray, [#label #link(url)]))
          }
          #if details.len() > 0 {
            list(..details.map(d => if type(d) == content { d } else { markup(d) }))
          }
        ]
      }
    } else if module.id == "projects" {
      // 项目经历
      resume-section(module.title)
      for proj in module.payload {
        let url = proj.at("url", default: "")
        let url-label = proj.at("url-label", default: "")
        resume-project(
          title: proj.name,
          duty: proj.role,
          start: proj.start,
          end: proj.end,
          url: url,
          url-label: url-label,
        )[
          #let details = proj.at("details", default: ())
          #if url != "" {
            let label = get-url-label(url, custom-label: url-label)
            details.insert(0, text(size: 9pt, fill: gray, [#label #link(url)]))
          }
          #if details.len() > 0 {
            list(..details.map(d => if type(d) == content { d } else { markup(d) }))
          }
        ]
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

  // ─────────────────────────────────────────────────────────
  //  resume-info 扩展字段（放在简历尾部）
  // ─────────────────────────────────────────────────────────

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
