// 1. 主题选择
#import "themes/prism/template.typ": blueprint

// 2. 数据加载
#let data = yaml("data.yml")

#show: blueprint.with(
  data: data,
)
