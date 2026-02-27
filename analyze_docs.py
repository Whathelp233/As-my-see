#!/usr/bin/env python3
"""
文档质量分析工具
分析As-my-see知识库中的文档质量
"""

import os
import sys
from pathlib import Path
from datetime import datetime
from collections import defaultdict

class DocumentAnalyzer:
    def __init__(self, docs_dir):
        self.docs_dir = Path(docs_dir)
        self.report_file = self.docs_dir.parent / f"document_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
        
        # 统计
        self.stats = {
            'total': 0,
            'good': 0,
            'shallow': 0,
            'duplicate': 0
        }
        
        self.shallow_docs = []
        self.duplicate_docs = []
        self.category_stats = defaultdict(lambda: {'total': 0, 'shallow': 0})
    
    def analyze_document(self, filepath):
        """分析单个文档"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
                
            # 基本统计
            line_count = len(lines)
            
            # 检查内容
            has_titles = any(line.strip().startswith('#') for line in lines)
            has_code = '```' in content
            has_lists = any(line.strip().startswith('-') or line.strip().startswith('*') for line in lines)
            
            # 判断质量
            if line_count < 30:
                quality = '🔴 过浅'
                needs_improvement = True
            elif line_count < 100:
                quality = '🟡 一般'
                needs_improvement = True
            elif not has_titles:
                quality = '🟡 无结构'
                needs_improvement = True
            else:
                quality = '🟢 良好'
                needs_improvement = False
            
            return {
                'path': str(filepath.relative_to(self.docs_dir)),
                'lines': line_count,
                'quality': quality,
                'needs_improvement': needs_improvement,
                'has_titles': has_titles,
                'has_code': has_code,
                'has_lists': has_lists
            }
            
        except Exception as e:
            print(f"分析文档失败: {filepath}, 错误: {e}")
            return None
    
    def find_duplicates(self, files):
        """查找重复文档"""
        duplicates = []
        seen = {}
        
        for filepath in files:
            filename = filepath.name
            # 检查是否带数字后缀
            if '_' in filename and filename.endswith('.md'):
                base_name = filename[:-3]  # 去掉.md
                parts = base_name.split('_')
                if parts[-1].isdigit():
                    # 可能是重复文档
                    original_name = '_'.join(parts[:-1]) + '.md'
                    if original_name in seen:
                        duplicates.append({
                            'path': str(filepath.relative_to(self.docs_dir)),
                            'original': seen[original_name]
                        })
                else:
                    seen[filename] = str(filepath.relative_to(self.docs_dir))
            else:
                seen[filename] = str(filepath.relative_to(self.docs_dir))
        
        return duplicates
    
    def run_analysis(self):
        """运行分析"""
        print("开始分析文档...")
        
        # 收集所有文档
        all_files = list(self.docs_dir.rglob('*.md'))
        self.stats['total'] = len(all_files)
        
        # 查找重复文档
        self.duplicate_docs = self.find_duplicates(all_files)
        self.stats['duplicate'] = len(self.duplicate_docs)
        
        # 按目录分析
        report_content = []
        report_content.append("# 📊 文档质量分析报告")
        report_content.append(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report_content.append(f"分析目录: {self.docs_dir}")
        report_content.append(f"文档总数: {self.stats['total']}")
        report_content.append("")
        
        # 按目录分析
        for category_dir in sorted(self.docs_dir.iterdir()):
            if category_dir.is_dir():
                category_name = category_dir.name
                category_files = list(category_dir.rglob('*.md'))
                
                if not category_files:
                    continue
                
                report_content.append(f"## 📁 {category_name}")
                report_content.append("")
                report_content.append("| 文档 | 行数 | 质量 | 建议 |")
                report_content.append("|------|------|------|------|")
                
                category_shallow = 0
                
                for filepath in sorted(category_files):
                    result = self.analyze_document(filepath)
                    if not result:
                        continue
                    
                    self.stats['total'] += 1
                    self.category_stats[category_name]['total'] += 1
                    
                    if result['needs_improvement']:
                        self.stats['shallow'] += 1
                        category_shallow += 1
                        self.category_stats[category_name]['shallow'] += 1
                        self.shallow_docs.append({
                            'path': result['path'],
                            'lines': result['lines'],
                            'quality': result['quality']
                        })
                    else:
                        self.stats['good'] += 1
                    
                    # 生成建议
                    suggestion = "保持"
                    if result['lines'] < 30:
                        suggestion = "需要大幅扩充"
                    elif result['lines'] < 100:
                        suggestion = "建议补充内容"
                    elif not result['has_titles']:
                        suggestion = "添加标题结构"
                    elif not result['has_code'] and '代码' in result['path']:
                        suggestion = "添加代码示例"
                    
                    report_content.append(f"| {result['path']} | {result['lines']} | {result['quality']} | {suggestion} |")
                
                report_content.append("")
                report_content.append(f"**统计**: {len(category_files)} 个文档，其中 {category_shallow} 个需要优化")
                report_content.append("")
        
        # 总体统计
        report_content.append("# 📈 总体统计")
        report_content.append("")
        report_content.append(f"- **总文档数**: {self.stats['total']}")
        report_content.append(f"- **质量良好**: {self.stats['good']} ({self.stats['good']/self.stats['total']*100:.1f}%)")
        report_content.append(f"- **需要优化**: {self.stats['shallow']} ({self.stats['shallow']/self.stats['total']*100:.1f}%)")
        report_content.append(f"- **重复文档**: {self.stats['duplicate']} ({self.stats['duplicate']/self.stats['total']*100:.1f}%)")
        report_content.append("")
        
        # 需要优化的文档
        if self.shallow_docs:
            report_content.append("# 🔧 需要优化的文档")
            report_content.append("")
            report_content.append(f"以下 {len(self.shallow_docs)} 个文档需要优化:")
            report_content.append("")
            
            # 按行数排序，最少的优先
            sorted_shallow = sorted(self.shallow_docs, key=lambda x: x['lines'])
            for doc in sorted_shallow[:20]:  # 只显示前20个
                report_content.append(f"- {doc['path']} ({doc['lines']} 行) - {doc['quality']}")
            
            if len(self.shallow_docs) > 20:
                report_content.append(f"- ... 还有 {len(self.shallow_docs) - 20} 个")
            report_content.append("")
        
        # 重复文档
        if self.duplicate_docs:
            report_content.append("# 🔄 重复文档")
            report_content.append("")
            report_content.append(f"以下 {len(self.duplicate_docs)} 个文档可能是重复的:")
            report_content.append("")
            
            for dup in self.duplicate_docs[:10]:  # 只显示前10个
                report_content.append(f"- {dup['path']} (可能是 {dup['original']} 的重复)")
            
            if len(self.duplicate_docs) > 10:
                report_content.append(f"- ... 还有 {len(self.duplicate_docs) - 10} 个")
            report_content.append("")
        
        # 建议
        report_content.append("# 🎯 优化建议")
        report_content.append("")
        report_content.append("## 立即行动")
        report_content.append("")
        report_content.append("1. **优先优化核心文档**: 选择3-5个最重要的技术文档进行深度优化")
        report_content.append("2. **清理重复文档**: 删除或合并带 `_1`, `_2` 等后缀的重复文档")
        report_content.append("3. **建立文档标准**: 参考质量良好的文档，制定文档编写规范")
        report_content.append("")
        
        report_content.append("## 自动化建议")
        report_content.append("")
        report_content.append("1. **设置定时分析**: 每周自动运行文档质量分析")
        report_content.append("2. **自动备份**: 优化前自动备份原文档")
        report_content.append("3. **质量监控**: 设置文档质量阈值，自动提醒")
        report_content.append("")
        
        # 写入报告
        with open(self.report_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(report_content))
        
        # 输出到控制台
        print(f"\n=== 文档质量分析完成 ===")
        print(f"报告文件: {self.report_file}")
        print(f"\n📊 总体统计:")
        print(f"  总文档数: {self.stats['total']}")
        print(f"  质量良好: {self.stats['good']} ({self.stats['good']/self.stats['total']*100:.1f}%)")
        print(f"  需要优化: {self.stats['shallow']} ({self.stats['shallow']/self.stats['total']*100:.1f}%)")
        print(f"  重复文档: {self.stats['duplicate']} ({self.stats['duplicate']/self.stats['total']*100:.1f}%)")
        
        if self.shallow_docs:
            print(f"\n🔧 需要优化的文档（前10个，按行数排序）:")
            sorted_shallow = sorted(self.shallow_docs, key=lambda x: x['lines'])
            for doc in sorted_shallow[:10]:
                print(f"  - {doc['path']} ({doc['lines']} 行)")

def main():
    docs_dir = "/root/.openclaw/workspace/As-my-see/docs"
    
    if not os.path.exists(docs_dir):
        print(f"错误: 文档目录不存在: {docs_dir}")
        sys.exit(1)
    
    analyzer = DocumentAnalyzer(docs_dir)
    analyzer.run_analysis()

if __name__ == "__main__":
    main()