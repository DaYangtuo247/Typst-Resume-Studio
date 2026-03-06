import os
import subprocess
import argparse
import re
import tempfile

def list_themes():
    """扫描 themes 目录，返回包含 template.typ 的主题列表"""
    themes = []
    themes_dir = "themes"
    if not os.path.exists(themes_dir):
        return themes
    
    for item in os.listdir(themes_dir):
        item_path = os.path.join(themes_dir, item)
        if os.path.isdir(item_path):
            template_path = os.path.join(item_path, "template.typ")
            example_path = os.path.join(item_path, "example.typ")
            if os.path.exists(template_path):
                themes.append({
                    "name": item,
                    "path": item_path,
                    "template": template_path,
                    "example": example_path if os.path.exists(example_path) else None
                })
    return sorted(themes, key=lambda x: x["name"])

def compile_preview(theme, format="pdf"):
    """编译主题自带的 example.typ 预览"""
    if not theme["example"]:
        print(f"  跳过 [{theme['name']}]: 找不到 example.typ")
        return False

    theme_name = theme["name"]
    theme_path = theme["path"]
    output_file = os.path.join(theme_path, f"{theme_name}.{format}")
    
    print(f"正在编译 [{theme_name}] 示例 -> {format.upper()}...")
    
    cmd = [
        "typst", "compile",
        theme["example"],
        output_file,
        "--pages", "1",
        "--root", "."
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"  成功: {output_file}")
            return True
        else:
            print(f"  失败: {result.stderr.splitlines()[0] if result.stderr else '未知错误'}")
            return False
    except Exception as e:
        print(f"  错误: {str(e)}")
        return False

def compile_resume_for_theme(theme, resume_content, output_dir, data_file, format="pdf"):
    """使用指定主题和数据文件编译用户的 resume.typ 内容"""
    theme_name = theme["name"]
    output_file = os.path.join(output_dir, f"{theme_name}.{format}")
    
    # 1. 替换主题导入路径
    # 匹配 #import "themes/.../template.typ": blueprint
    import_pattern = r'#import\s+["\']/?themes/.*?/template\.typ["\']\s*:\s*blueprint'
    new_content = re.sub(import_pattern, f'#import "themes/{theme_name}/template.typ": blueprint', resume_content)
    
    # 2. 替换数据文件路径
    # 匹配 yaml("...")
    data_pattern = r'yaml\(["\'].*?\.yml["\']\)'
    new_content = re.sub(data_pattern, f'yaml("{data_file}")', new_content)

    # 创建临时文件
    with tempfile.NamedTemporaryFile(mode='w', suffix='.typ', dir='.', delete=False) as tmp:
        tmp.write(new_content)
        tmp_path = tmp.name
    
    print(f"正在生成 [{theme_name}] 预览 (数据: {data_file})...")
    
    cmd = [
        "typst", "compile",
        tmp_path,
        output_file,
        "--root", "."
    ]
    
    if format == "png":
        cmd.extend(["--pages", "1"])
        
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"  完成: {output_file}")
            return True
        else:
            print(f"  失败 [{theme_name}]: {result.stderr.strip() if result.stderr else '未知错误'}")
            return False
    except Exception as e:
        print(f"  运行错误 [{theme_name}]: {str(e)}")
        return False
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

def update_readme(themes):
    """更新 README.md 中的主题展示表格"""
    print("正在更新 README.md 主题表格...")
    readme_path = "README.md"
    if not os.path.exists(readme_path):
        print(f"  错误: 找不到 {readme_path}")
        return

    rows = []
    for i in range(0, len(themes), 3):
        chunk = themes[i:i+3]
        names = [t["name"].replace("-", " ").title() for t in chunk]
        while len(names) < 3:
            names.append("")
        rows.append("| " + " | ".join(names) + " |")
        if i == 0:
            rows.append("| :---: | :---: | :---: |")
        imgs = [f"![](themes/{t['name']}/{t['name']}.png)" for t in chunk]
        while len(imgs) < 3:
            imgs.append("")
        rows.append("| " + " | ".join(imgs) + " |")

    table_content = "\n".join(rows)
    with open(readme_path, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = r"(## 🎨 主题\n\n).*?(\n\n## )"
    replacement = r"\1" + "本项目内置精美主题，可通过修改 `resume.typ` 中的 import 语句快速切换。\n\n" + table_content + r"\2"
    new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    if new_content == content:
        pattern = r"(## 🎨 主题\n\n).*"
        replacement = r"\1" + "本项目内置精美主题，可通过修改 `resume.typ` 中的 import 语句快速切换。\n\n" + table_content + "\n"
        new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(new_content)
    print("  README.md 已更新。")

def main():
    parser = argparse.ArgumentParser(description="Typst 简历预览生成工具")
    parser.add_argument("--pdf", action="store_true", help="生成各主题自带的 PDF 示例")
    parser.add_argument("--png", action="store_true", help="生成各主题自带的 PNG 预览图")
    parser.add_argument("--readme", action="store_true", help="更新 README.md 主题表格")
    parser.add_argument("--preview", action="store_true", help="使用指定的 data.yml 为所有主题生成简历预览")
    parser.add_argument("-f", "--file", default="data.yml", help="指定数据文件 (默认: data.yml)")
    parser.add_argument("--format", choices=["pdf", "png"], default="pdf", help="--preview 的输出格式 (默认: pdf)")
    parser.add_argument("--all", action="store_true", help="执行所有任务")
    
    args = parser.parse_args()
    
    if not (args.pdf or args.png or args.readme or args.preview or args.all):
        parser.print_help()
        return

    themes = list_themes()
    if not themes:
        print("未发现任何主题。")
        return

    if args.preview or args.all:
        print("\n=== 开始为所有主题生成简历预览 ===")
        resume_path = "resume.typ"
        if not os.path.exists(resume_path):
            print(f"错误: 找不到 {resume_path}")
        elif not os.path.exists(args.file):
            print(f"错误: 找不到数据文件 {args.file}")
        else:
            with open(resume_path, "r", encoding="utf-8") as f:
                resume_content = f.read()
            output_dir = "previews"
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
            for theme in themes:
                compile_resume_for_theme(theme, resume_content, output_dir, args.file, args.format)
            print(f"\n预览已生成在 {output_dir}/ 目录下。")

    if args.pdf or args.all:
        print("\n=== 开始生成主题自带 PDF 示例 ===")
        for theme in themes:
            compile_preview(theme, "pdf")

    if args.png or args.all:
        print("\n=== 开始生成主题自带 PNG 预览图 ===")
        for theme in themes:
            compile_preview(theme, "png")

    if args.readme or args.all:
        print("\n=== 更新 README ===")
        update_readme(themes)

if __name__ == "__main__":
    main()
