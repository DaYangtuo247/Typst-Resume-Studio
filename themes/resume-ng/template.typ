#import "../module-core.typ": extract-items, extract-title, get-url-label, markup, render-contact

#let _resume-info(data) = {
  data.at("information", default: (:))
}

#let _sections-array(data) = {
  data.at("content", default: data.at("sections", default: none))
}

#let _section-by-type(data, section-type) = {
  let sections = _sections-array(data)
  if sections != none and type(sections) == array {
    let items = ()
    let title = ""
    for section in sections {
      if section.at("type", default: "") == section-type and section.at("enabled", default: true) {
        if title == "" {
          title = section.at("title", default: "")
        }
        let section-items = section.at("items", default: ())
        if type(section-items) == array {
          for item in section-items {
            items.push(item)
          }
        }
      }
    }
    return (title: title, items: items)
  }

  let raw = data.at(section-type, default: none)
  if raw == none {
    return (title: "", items: ())
  }

  (
    title: extract-title(raw, fallback: ""),
    items: extract-items(raw),
  )
}

#let delimiter = " | "

#let array-to-str(a, delimiter: delimiter) = {
  a.join(delimiter)
}

#let resume-contacts(contact) = {
  set align(center)
  array-to-str(contact)
}

#let project(title: "", author: (), contacts: (), fonts: (), body) = {
  set document(author: author.name, title: title)
  set page(
    margin: (x: 1cm, y: 1cm),
  )

  set text(font: fonts, lang: "zh")

  align(center)[
    #block(text(weight: 700, 1.7em, author.name))
  ]

  resume-contacts(contacts)

  set par(justify: true)

  body
}

#let format-date(date) = {
  if type(date) == datetime [date.display()] else if type(date) == str and date.len() == 0 [今] else if (
    type(date) == str
  ) {
    date
  } else {
    // todo panic
  }
}

#let resume-date(start, end: "") = {
  if start == "" and end == "" {
    ""
  } else {
    format-date(start) + " " + $dash.en$ + " " + format-date(end)
  }
}

#let resume-item(left: "", right: "", url: "", url-label: "", body) = {
  let right-text = if type(right) == str { markup(right) } else { right }
  let left-text = if type(left) == str { markup(left) } else { left }

  text(size: 12pt, place(end, right-text))
  text(size: 12pt, left-text)
  linebreak()
  body
}
#let resume-education(university: "", degree: "", school: "", start: "", end: "", url: "", url-label: "", body) = {
  let uni-content = strong(university)
  let left = (uni-content, school, degree)
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
  let company-content = strong(company)
  let left = (company-content, duty)
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
  let title-content = strong(title)
  let left = (title-content, duty)
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
  v(-2pt)
}

// ─────────────────────────────────────────────────────────────────────────────

#let blueprint(data: (:), fonts-global: (), body) = {
  let info = _resume-info(data)
  let fonts-theme = ("Times New Roman", "Heiti SC", "PingFang SC", "STHeiti")
  let fonts-effective = if fonts-global.len() > 0 { (..fonts-global, ..fonts-theme) } else { fonts-theme }

  // Header Config
  let author-name = info.at("name", default: "冯开宇")

  // Process contacts
  let contacts = ()
  if "contacts" in info {
    for c in info.contacts {
      if type(c) == str {
        contacts.push(c)
      } else if type(c) == dictionary {
        contacts.push(render-contact(c))
      }
    }
  }

  show: project.with(
    title: data.at("title", default: "Resume"),
    author: (name: author-name),
    contacts: contacts,
    fonts: fonts-effective,
  )

  // Education
  let edu-section = _section-by-type(data, "education")
  if edu-section.items.len() > 0 {
    let edu-title = if edu-section.title != "" { edu-section.title } else { "教育经历" }
    resume-section(edu-title)
    for edu in edu-section.items {
      let url = edu.at("url", default: "")
      let url-label = edu.at("url-label", default: "")
      resume-education(
        university: edu.at("university", default: edu.at("school", default: "")),
        degree: edu.at("degree", default: ""),
        school: edu.at("school", default: edu.at("major", default: "")),
        start: edu.at("start", default: ""),
        end: edu.at("end", default: ""),
        url: url,
        url-label: url-label,
      )[
        #let details = edu.at("details", default: edu.at("description", default: ()))
        #if type(details) == str { details = (details,) }
        #if url != "" {
          let label = get-url-label(url, custom-label: url-label)
          details.insert(0, text(size: 9pt, fill: gray, [#label #link(url)]))
        }
        #for item in details {
          if type(item) == content {
            [- #item]
          } else {
            [- #eval(item, mode: "markup")]
          }
        }
      ]
    }
  }

  // Skills
  let skill-section = _section-by-type(data, "skills")
  if skill-section.items.len() > 0 {
    let skill-title = if skill-section.title != "" { skill-section.title } else { "技术能力" }
    resume-section(skill-title)
    for s in skill-section.items {
      if type(s) == str {
        [- #eval(s, mode: "markup")]
      } else if type(s) == dictionary {
        // 支持 name/level/description 格式
        let name = s.at("name", default: "")
        if name != "" {
          let level = s.at("level", default: "")
          let description = s.at("description", default: "")
          let parts = (name,)
          if level != "" { parts.push(level) }
          if description != "" { parts.push(description) }
          [- #markup(parts.join("："))]
        } else if "title" in s {
          [*#markup(s.title):* ]
          if "items" in s {
            if type(s.items) == array {
              for item in s.items {
                [- #markup(item)]
              }
            } else {
              markup(s.items)
            }
          }
        }
      }
    }
  }

  // Experience
  let exp-section = _section-by-type(data, "experience")
  if exp-section.items.len() > 0 {
    let exp-title = if exp-section.title != "" { exp-section.title } else { "工作经历" }
    resume-section(exp-title)
    for exp in exp-section.items {
      let url = exp.at("url", default: "")
      let url-label = exp.at("url-label", default: "")
      resume-work(
        company: exp.at("company", default: ""),
        duty: exp.at("duty", default: exp.at("position", default: "")),
        start: exp.at("start", default: ""),
        end: exp.at("end", default: ""),
        url: url,
        url-label: url-label,
      )[
        #let details = exp.at("details", default: exp.at("description", default: ()))
        #if type(details) == str { details = (details,) }
        #if url != "" {
          let label = get-url-label(url, custom-label: url-label)
          details.insert(0, text(size: 9pt, fill: gray, [#label #link(url)]))
        }
        #for item in details {
          if type(item) == content {
            [- #item]
          } else {
            [- #eval(item, mode: "markup")]
          }
        }
      ]
    }
  }

  // Projects & Internship
  for section-key in ("projects", "internship") {
    let section-data = _section-by-type(data, section-key)
    let items = section-data.items
    let section-title = if section-data.title != "" {
      section-data.title
    } else if section-key == "projects" {
      "项目经历"
    } else {
      "实习经历"
    }
    if items.len() > 0 {
      resume-section(section-title)
      for item in items {
        let url = item.at("url", default: "")
        let url-label = item.at("url-label", default: "")
        resume-project(
          title: item.at("title", default: item.at("name", default: "")),
          duty: item.at("duty", default: item.at("role", default: "")),
          start: item.at("start", default: ""),
          end: item.at("end", default: ""),
          url: url,
          url-label: url-label,
        )[
          #let details = item.at("details", default: item.at("description", default: ()))
          #if type(details) == str { details = (details,) }
          #if url != "" {
            let label = get-url-label(url, custom-label: url-label)
            details.insert(0, text(size: 9pt, fill: gray, [#label #link(url)]))
          }
          #for detail in details {
            if type(detail) == content {
              [- #detail]
            } else {
              [- #eval(detail, mode: "markup")]
            }
          }
        ]
      }
    }
  }

  // Awards
  let award-section = _section-by-type(data, "awards")
  if award-section.items.len() > 0 {
    let award-title = if award-section.title != "" { award-section.title } else { "荣誉奖项" }
    resume-section(award-title)
    for award in award-section.items {
      if type(award) == str {
        [- #eval(award, mode: "markup")]
      } else if type(award) == dictionary {
        [
          - *#markup(award.at("title", default: ""))* #if award.at("date", default: "") != "" { [(#markup(award.at("date", default: "")))] }
        ]
      }
    }
  }

  // Certificates
  let cert-section = _section-by-type(data, "certificates")
  if cert-section.items.len() > 0 {
    let cert-title = if cert-section.title != "" { cert-section.title } else { "资质证书" }
    resume-section(cert-title)
    for cert in cert-section.items {
      if type(cert) == dictionary {
        [
          - *#markup(cert.at("name", default: ""))* #if cert.at("date", default: "") != "" { [(#markup(cert.at("date", default: "")))] } #if cert.at("org", default: "") != "" { [ — #markup(cert.at("org", default: ""))] }
        ]
      } else {
        [- #markup(str(cert))]
      }
    }
  }

  // resume-info 扩展字段
  if info.len() > 0 {
    let resume-info = info

    let extra-items = ()
    for (key, label) in (("gender", "性别"), ("species", "种类"), ("birthday", "生日"), ("city", "城市")) {
      let val = resume-info.at(key, default: "")
      if val != "" { extra-items.push(label + "：" + str(val)) }
    }
    if extra-items.len() > 0 {
      resume-section("基本信息")
      [#extra-items.join("  |  ")]
    }

    let motto = resume-info.at("motto", default: "")
    if motto != "" {
      [\ _"#motto"_]
    }

    let summary = resume-info.at("summary", default: "")
    if summary != "" {
      resume-section("个人简介")
      [#markup(summary)]
    }

    let self-evaluation = resume-info.at("self-evaluation", default: "")
    if self-evaluation != "" {
      resume-section("自我评价")
      [#markup(self-evaluation)]
    }

    let interests = resume-info.at("interests", default: ())
    if interests.len() > 0 {
      resume-section("兴趣爱好")
      [#interests.join("、")]
    }
  }

  body
}
