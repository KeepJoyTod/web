#!/usr/bin/env python3
"""
Bug报告格式转换脚本 - 通用格式转换

支持在不同Bug报告格式间转换：标准Markdown ↔ 飞书 ↔ Jira ↔ 禅道

用法：
    python convert_format.py --input bug_report.md --format feishu --output feishu_bug.md
    python convert_format.py --input bug_report.md --format jira --output jira_bug.md
    python convert_format.py --input bug_report.md --format zentao --output zentao_bug.md
"""

import argparse
import sys
import os

# 复用已有模块
from export_to_feishu_md import parse_bug_report, to_feishu_format
from export_to_jira_md import to_jira_format
from export_to_zentao_md import generate_zentao_report


def detect_input_format(content: str) -> str:
    """自动检测输入文件的格式"""
    if content.strip().startswith('# ') and '- ' in content and '||' not in content:
        return 'feishu'
    if '*Summary*' in content or 'h3.' in content or '{code}' in content:
        return 'jira'
    return 'markdown'


def convert_file(input_path: str, target_format: str, output_path: str = None) -> str:
    """转换Bug报告到目标格式"""
    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    source_format = detect_input_format(content)

    # 解析为内部数据结构
    if source_format == 'feishu' or source_format == 'jira':
        # 先转为标准Markdown再解析（简化处理）
        bug = parse_bug_report(content)
    else:
        bug = parse_bug_report(content)

    # 转换为目标格式
    format_map = {
        'feishu': to_feishu_format,
        'jira': to_jira_format,
        'zentao': lambda bug: generate_zentao_report(bug),
        'markdown': None,  # TODO: 实现to_markdown_format
    }

    if target_format not in format_map:
        print(f"❌ 不支持的目标格式：{target_format}")
        print(f"📋 支持的格式：{', '.join(format_map.keys())}")
        sys.exit(1)

    converter = format_map[target_format]
    if converter is None:
        print(f"❌ 目标格式 {target_format} 尚未实现")
        sys.exit(1)

    result = converter(bug)

    if output_path is None:
        base, _ = os.path.splitext(input_path)
        suffix = f"-{target_format}版" if target_format != 'markdown' else ""
        output_path = f"{base}{suffix}.md"

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(result)

    return output_path


def main():
    parser = argparse.ArgumentParser(description='Bug报告格式转换')
    parser.add_argument('--input', '-i', required=True, help='输入Bug报告文件')
    parser.add_argument('--format', '-f', required=True,
                       choices=['feishu', 'jira', 'zentao'],
                       help='目标格式：feishu/jira/zentao')
    parser.add_argument('--output', '-o', help='输出文件路径')

    args = parser.parse_args()

    if not os.path.exists(args.input):
        print(f"❌ 文件不存在：{args.input}")
        sys.exit(1)

    output = convert_file(args.input, args.format, args.output)

    format_names = {
        'feishu': '飞书',
        'jira': 'Jira',
        'zentao': '禅道',
    }
    print(f"✅ {format_names.get(args.format, args.format)}格式Bug报告已生成：{output}")


if __name__ == '__main__':
    main()
