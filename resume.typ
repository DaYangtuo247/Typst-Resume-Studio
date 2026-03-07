// 1. 主题选择
#import "themes/prism/template.typ": blueprint

// 2. 数据加载
#let data = yaml("data.yml")

// 3. 全局字体（可选）：优先于主题字体，主题字体作为兜底
#let global-font-config = data.at("global-font", default: (:))
#let global-fonts = global-font-config.at("fonts", default: ())

#let global-font-list = if type(global-fonts) == array {
  global-fonts
} else if type(global-fonts) == str and global-fonts != "" {
  (global-fonts,)
} else {
  ()
}

#show: blueprint.with(
  data: data,
  fonts-global: global-font-list,
)
