#import "../module-core.typ": (
  contact-value, markup, render-contacts, render-dict-item, resume-info-extras, standard-modules,
)

// ─────────────────────────────────────────────────────────
//  辅助函数
// ─────────────────────────────────────────────────────────

#let resume-date(start, end: "") = {
  if start == "" and end == "" {
    ""
  } else if end == "" {
    start
  } else {
    start + "-" + end
  }
}

// ─────────────────────────────────────────────────────────
//  简历块级元素
// ─────────────────────────────────────────────────────────

#let theme-color = rgb("4F81BD")
#let theme-bg-color = rgb("DCE6F1")

#let resume-section(title) = {
  v(1.2em)
  block(
    width: 100%,
    stroke: (bottom: 1.5pt + theme-color),
    inset: (bottom: 4pt),
    block(
      fill: theme-bg-color,
      inset: (x: 6pt, y: 4pt),
      radius: 0pt,
      text(weight: "bold", size: 12.5pt, fill: rgb("000000"), title),
    ),
  )
  v(0.5em)
}

#let resume-item-3col(left-text: "", center-text: "", right-text: "", body) = {
  let _markup(v) = if type(v) == str { markup(v) } else { v }
  grid(
    columns: (1.2fr, 2fr, 1.2fr),
    align: (left, center, right),
    text(weight: "bold", _markup(left-text)),
    text(weight: "bold", _markup(center-text)),
    text(weight: "bold", _markup(right-text)),
  )
  v(0.3em)
  body
  v(0.6em)
}

#let resume-education(university: "", degree: "", school: "", start: "", end: "", body) = {
  let date = resume-date(start, end: end)
  let right-col = ()
  if school != "" {
    right-col.push(school)
  }
  if degree != "" {
    right-col.push(degree)
  }

  let uni-content = markup(university)

  resume-item-3col(
    left-text: date,
    center-text: uni-content,
    right-text: right-col.join(" "),
    body,
  )
}

#let resume-work(company: "", duty: "", start: "", end: "", body) = {
  let date = resume-date(start, end: end)

  let company-content = markup(company)

  resume-item-3col(
    left-text: date,
    center-text: company-content,
    right-text: duty,
    body,
  )
}

#let resume-project(title: "", duty: "", start: "", end: "", body) = {
  let date = resume-date(start, end: end)

  let title-content = markup(title)

  resume-item-3col(
    left-text: date,
    center-text: title-content,
    right-text: duty,
    body,
  )
}

// ─────────────────────────────────────────────────────────
//  主题入口函数
// ─────────────────────────────────────────────────────────

#let blueprint(
  data: (:),
  fonts-global: (),
  body,
) = {
  let modules = standard-modules(data)
  let resume-info = data.at("information", default: (:))
  let name = resume-info.at("name", default: "未命名")
  let contacts = resume-info.at("contacts", default: ())

  // 字体设置，模拟图片中的字体观感
  let fonts-theme = ("Times New Roman", "Heiti SC")
  let fonts-effective = if fonts-global.len() > 0 { (..fonts-global, ..fonts-theme) } else { fonts-theme }

  set document(author: name, title: name + " 的简历")
  set page(margin: (x: 1.5cm, y: 1.5cm))
  set text(font: fonts-effective, lang: "zh", size: 10.5pt)

  // 列表样式（使用实心圆点，与图片一致）
  set list(marker: [•])

  // 段落样式
  set par(justify: true, leading: 0.6em, spacing: 0.6em)

  // 头部渲染
  align(center)[
    #block(text(weight: 700, 2em, name))
  ]

  if contacts.len() > 0 {
    set align(center)
    render-contacts(contacts, delimiter: [  |  ])
    v(1em)
  }

  // 简历信息扩展字段
  let extras = resume-info-extras(resume-info)

  // 模块化渲染
  for module in modules {
    if module.id == "resume-info" { continue }

    if module.id == "education" {
      resume-section(module.title)
      for edu in module.payload {
        resume-education(
          university: edu.school,
          degree: edu.degree,
          school: edu.major,
          start: edu.start,
          end: edu.end,
        )[
          #let details = edu.at("details", default: ())
          #if details.len() > 0 {
            list(..details.map(d => if type(d) == content { d } else { markup(d) }))
          }
        ]
      }
    } else if module.id == "experience" {
      resume-section(module.title)
      for exp in module.payload {
        resume-work(
          company: exp.company,
          duty: exp.position,
          start: exp.start,
          end: exp.end,
        )[
          #let details = exp.at("details", default: ())
          #if details.len() > 0 {
            list(..details.map(d => if type(d) == content { d } else { markup(d) }))
          }
        ]
      }
    } else if module.id == "internship" {
      resume-section(module.title)
      for intern in module.payload {
        resume-work(
          company: intern.at("company", default: intern.at("name", default: "")),
          duty: intern.at("position", default: intern.at("role", default: "")),
          start: intern.start,
          end: intern.end,
        )[
          #let details = intern.at("details", default: ())
          #if details.len() > 0 {
            list(..details.map(d => if type(d) == content { d } else { markup(d) }))
          }
        ]
      }
    } else if module.id == "projects" {
      resume-section(module.title)
      for proj in module.payload {
        resume-project(
          title: proj.name,
          duty: proj.role,
          start: proj.start,
          end: proj.end,
        )[
          #let details = proj.at("details", default: ())
          #if details.len() > 0 {
            list(..details.map(d => if type(d) == content { d } else { markup(d) }))
          }
        ]
      }
    } else if module.id == "skills" {
      resume-section(module.title)
      list(..module.payload.map(skill => markup(skill)))
    } else {
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
