// ─────────────────────────────────────────────────────────
//  导入模块化协议
// ─────────────────────────────────────────────────────────

#import "../module-core.typ": markup, render-contacts, render-dict-item, resume-info-extras, standard-modules

#let get-url-label(url, custom-label: "") = {
  if custom-label != "" { return custom-label + ": " }
  let label = "链接: "
  if url.contains("github.com") { label = "GitHub: " }
  else if url.contains("linkedin.com") { label = "LinkedIn: " }
  else if url.contains("zhihu.com") { label = "知乎: " }
  label
}

// ─────────────────────────────────────────────────────────
//  辅助函数
// ─────────────────────────────────────────────────────────

#let delimiter = " | "

#let resume-date(start, end: "") = {
  if start == "" and end == "" {
    ""
  } else if end == "" {
    start
  } else {
    start + " - " + end
  }
}

// ─────────────────────────────────────────────────────────
//  简历块级元素
// ─────────────────────────────────────────────────────────

#let resume-item-header(date: "", title: "", subtitle: "", url: "", url-label: "") = {
  let title-content = markup(title)
  let left-text = if subtitle != "" {
    [#title-content - #markup(subtitle)]
  } else {
    title-content
  }

  grid(
    columns: (1fr, auto),
    align: (left, right),
    strong(left-text), strong(markup(date)),
  )
}

#let resume-education(university: "", degree: "", major: "", start: "", end: "", url: "", url-label: "", body) = {
  let date = resume-date(start, end: end)
  let subtitle = if major != "" { major + " - " + degree } else { degree }

  resume-item-header(date: date, title: university, subtitle: subtitle, url: url, url-label: url-label)
  v(0.3em)
  body
}

#let resume-work(company: "", duty: "", start: "", end: "", url: "", url-label: "", body) = {
  let date = resume-date(start, end: end)

  resume-item-header(date: date, title: company, subtitle: duty, url: url, url-label: url-label)
  v(0.3em)
  body
}

#let resume-project(title: "", duty: "", start: "", end: "", url: "", url-label: "", body) = {
  let date = resume-date(start, end: end)

  resume-item-header(date: date, title: title, subtitle: duty, url: url, url-label: url-label)
  v(0.3em)
  body
}

#let resume-section(title) = {
  v(0.8em)
  text(size: 11pt, weight: "bold", fill: black, title)
  v(-0.6em)
  line(length: 100%, stroke: 0.8pt + black)
  v(0.2em)
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
  let avatar = resume-info.at("avatar", default: "")
  let contacts = resume-info.at("contacts", default: ())

  let fonts-theme = ("Noto Serif SC", "Times New Roman", "Heiti SC", "PingFang SC")
  let fonts-effective = if fonts-global.len() > 0 { (..fonts-global, ..fonts-theme) } else { fonts-theme }

  set document(author: name, title: name + " 的简历")
  set page(margin: (x: 1.5cm, y: 1.5cm))
  set text(font: fonts-effective, lang: "zh", size: 9.5pt, fill: rgb("#3a3a3a"))
  set par(justify: true)

  set list(indent: 0.5em, body-indent: 0.5em)
  show list: set block(spacing: 0.5em)
  show strong: set text(fill: black)

  // ─────────────────────────────────────────────────────────
  //  简历头部
  // ─────────────────────────────────────────────────────────

  block(width: 100%, height: auto)[
    #if avatar != "" [
      #place(top + right, dx: 0cm, dy: -0.5cm)[
        #image(avatar, width: 2.2cm, height: 3cm, fit: "cover")
      ]
    ]
    #align(center)[
      #v(0.5em)
      #text(weight: 700, size: 16pt, fill: black, name)
      #v(0.8em)

      #if contacts.len() > 0 {
        text(size: 9pt, fill: black)[#render-contacts(contacts, delimiter: [ #delimiter ], show-label: true)]
      }
    ]
    #v(1.2em)
  ]

  // ─────────────────────────────────────────────────────────
  //  简历信息扩展字段
  // ─────────────────────────────────────────────────────────

  let extras = resume-info-extras(resume-info)

  if extras.summary != "" {
    resume-section("个人简介")
    block(width: 100%, below: 0.5em)[#markup(extras.summary)]
    v(0.5em)
  }

  if extras.self-evaluation != "" {
    resume-section("自我评价")
    block(width: 100%, below: 0.5em)[#markup(extras.self-evaluation)]
    v(0.5em)
  }

  if extras.interests.len() > 0 {
    resume-section("兴趣爱好")
    block(width: 100%, below: 0.5em)[#extras.interests.join("、")]
    v(0.5em)
  }

  // ─────────────────────────────────────────────────────────
  //  简历内容（模块化渲染）
  // ─────────────────────────────────────────────────────────

  for module in modules {
    if module.id == "resume-info" {
      continue
    } else if module.id == "education" {
      resume-section(module.title)
      for edu in module.payload {
        let url = edu.at("url", default: "")
        resume-education(
          university: edu.school,
          degree: edu.degree,
          major: edu.major,
          start: edu.start,
          end: edu.end,
          url: url,
          url-label: edu.at("url-label", default: ""),
        )[
          #if url != "" {
            let label = get-url-label(url, custom-label: edu.at("url-label", default: ""))
            block(width: 100%, below: 0.5em)[#text(size: 8.5pt, fill: rgb("#555555"), [#label #link(url)])]
          }
          #let details = edu.at("details", default: ())
          #if details.len() > 0 {
            for d in details {
              block(width: 100%, below: 0.5em)[#markup(d)]
            }
          }
        ]
        v(0.5em)
      }
    } else if module.id == "experience" {
      resume-section(module.title)
      for exp in module.payload {
        let url = exp.at("url", default: "")
        resume-work(
          company: exp.company,
          duty: exp.position,
          start: exp.start,
          end: exp.end,
          url: url,
          url-label: exp.at("url-label", default: ""),
        )[
          #let details = exp.at("details", default: ())
          #let all-items = details.map(d => markup(d))
          #if url != "" {
            let label = get-url-label(url, custom-label: exp.at("url-label", default: ""))
            all-items.insert(0, text(size: 8.5pt, fill: rgb("#555555"), [#label #link(url)]))
          }
          #if all-items.len() > 0 {
            list(..all-items)
          }
        ]
        v(0.5em)
      }
    } else if module.id == "projects" or module.id == "internship" {
      resume-section(module.title)
      for item in module.payload {
        let url = item.at("url", default: "")
        resume-project(
          title: item.at("name", default: item.at("company", default: "")),
          duty: item.at("role", default: item.at("position", default: "")),
          start: item.start,
          end: item.end,
          url: url,
          url-label: item.at("url-label", default: ""),
        )[
          #let details = item.at("details", default: ())
          #let all-items = details.map(d => markup(d))
          #if url != "" {
            let label = get-url-label(url, custom-label: item.at("url-label", default: ""))
            all-items.insert(0, text(size: 8.5pt, fill: rgb("#555555"), [#label #link(url)]))
          }
          #if all-items.len() > 0 {
            list(..all-items)
          }
        ]
        v(0.5em)
      }
    } else if module.id == "skills" {
      resume-section(module.title)
      for skill in module.payload {
        block(width: 100%, below: 0.5em)[#markup(skill)]
      }
      v(0.5em)
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
        block(width: 100%, below: 0.5em)[#markup(module.payload)]
      } else {
        module.payload
      }
      v(0.5em)
    }
  }

  body
}
