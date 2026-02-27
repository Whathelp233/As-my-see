#!/usr/bin/env python3
"""
自动化系统管理器
统一管理文档质量监控和Git自动维护
"""

import os
import sys
import json
import schedule
import time
import threading
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

class AutomationSystem:
    def __init__(self, workspace_dir: str):
        self.workspace_dir = Path(workspace_dir)
        self.as_my_see_dir = self.workspace_dir / "As-my-see"
        self.config_file = self.as_my_see_dir / "automation_config.json"
        self.log_dir = self.as_my_see_dir / "logs" / "automation"
        
        # 创建目录
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        # 加载配置
        self.config = self.load_config()
        
        # 日志文件
        self.log_file = self.log_dir / f"automation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        
    def load_config(self) -> Dict:
        """加载配置"""
        default_config = {
            "document_monitor": {
                "enabled": True,
                "schedule": "0 3 * * *",  # 每天凌晨3点
                "threshold_lines": 50,
                "generate_report": True,
                "backup_before_analysis": True
            },
            "git_maintainer": {
                "enabled": True,
                "schedule": "0 4 * * *",  # 每天凌晨4点
                "auto_push": True,
                "create_backup": True,
                "run_gc": True
            },
            "system": {
                "full_maintenance_schedule": "0 5 * * 0",  # 每周日凌晨5点
                "notification_enabled": False,
                "max_log_files": 100,
                "cleanup_old_logs": True
            }
        }
        
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    user_config = json.load(f)
                    # 深度合并配置
                    self.deep_merge(default_config, user_config)
            except Exception as e:
                self.log(f"加载配置文件失败: {e}", "ERROR")
        
        return default_config
    
    def deep_merge(self, base: Dict, update: Dict):
        """深度合并字典"""
        for key, value in update.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self.deep_merge(base[key], value)
            else:
                base[key] = value
    
    def save_config(self):
        """保存配置"""
        try:
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, indent=2, ensure_ascii=False)
            self.log("配置已保存")
        except Exception as e:
            self.log(f"保存配置文件失败: {e}", "ERROR")
    
    def log(self, message: str, level: str = "INFO"):
        """记录日志"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log_entry = f"[{timestamp}] [{level}] {message}"
        
        # 写入日志文件
        with open(self.log_file, 'a', encoding='utf-8') as f:
            f.write(log_entry + '\n')
        
        # 输出到控制台
        print(log_entry)
    
    def run_document_monitor(self):
        """运行文档质量监控"""
        if not self.config["document_monitor"]["enabled"]:
            self.log("文档质量监控已禁用，跳过")
            return
        
        self.log("=== 开始文档质量监控 ===")
        
        try:
            # 运行文档分析
            import subprocess
            
            cmd = ["python3", str(self.as_my_see_dir / "analyze_docs.py")]
            result = subprocess.run(
                cmd,
                cwd=self.as_my_see_dir,
                capture_output=True,
                text=True,
                encoding='utf-8'
            )
            
            if result.returncode == 0:
                self.log("文档质量监控完成")
                
                # 解析输出，获取统计信息
                for line in result.stdout.split('\n'):
                    if "总文档数:" in line:
                        self.log(line.strip())
                    elif "需要优化:" in line:
                        self.log(line.strip())
            else:
                self.log(f"文档质量监控失败: {result.stderr}", "ERROR")
                
        except Exception as e:
            self.log(f"运行文档质量监控失败: {e}", "ERROR")
    
    def run_git_maintainer(self):
        """运行Git自动维护"""
        if not self.config["git_maintainer"]["enabled"]:
            self.log("Git自动维护已禁用，跳过")
            return
        
        self.log("=== 开始Git自动维护 ===")
        
        try:
            import subprocess
            
            cmd = ["python3", str(self.as_my_see_dir / "git_auto_maintain.py")]
            result = subprocess.run(
                cmd,
                cwd=self.as_my_see_dir,
                capture_output=True,
                text=True,
                encoding='utf-8'
            )
            
            if result.returncode == 0:
                self.log("Git自动维护完成")
                
                # 解析输出，获取结果
                for line in result.stdout.split('\n'):
                    if "状态:" in line or "提交:" in line or "备份:" in line:
                        self.log(line.strip())
            else:
                self.log(f"Git自动维护失败: {result.stderr}", "ERROR")
                
        except Exception as e:
            self.log(f"运行Git自动维护失败: {e}", "ERROR")
    
    def run_full_maintenance(self):
        """运行完整维护流程"""
        self.log("=== 开始完整自动化维护 ===")
        
        start_time = time.time()
        
        # 1. 文档质量监控
        self.run_document_monitor()
        
        # 2. Git自动维护
        self.run_git_maintainer()
        
        # 3. 系统清理
        self.cleanup_system()
        
        end_time = time.time()
        duration = end_time - start_time
        
        self.log(f"=== 完整自动化维护完成，耗时: {duration:.2f}秒 ===")
        
        # 生成总结报告
        self.generate_summary_report(duration)
    
    def cleanup_system(self):
        """系统清理"""
        if not self.config["system"]["cleanup_old_logs"]:
            return
        
        self.log("清理旧日志文件...")
        
        try:
            # 清理自动化日志
            automation_logs = list(self.log_dir.glob("*.log"))
            automation_logs.sort(key=lambda x: x.stat().st_mtime, reverse=True)
            
            max_logs = self.config["system"]["max_log_files"]
            if len(automation_logs) > max_logs:
                to_delete = automation_logs[max_logs:]
                for log_file in to_delete:
                    try:
                        log_file.unlink()
                        self.log(f"删除旧日志: {log_file.name}")
                    except Exception as e:
                        self.log(f"删除日志失败 {log_file.name}: {e}", "WARNING")
            
            # 清理其他日志目录
            for log_type in ["git", "document"]:
                type_log_dir = self.as_my_see_dir / "logs" / log_type
                if type_log_dir.exists():
                    type_logs = list(type_log_dir.glob("*.log"))
                    type_logs.sort(key=lambda x: x.stat().st_mtime, reverse=True)
                    
                    if len(type_logs) > max_logs:
                        to_delete = type_logs[max_logs:]
                        for log_file in to_delete:
                            try:
                                log_file.unlink()
                            except:
                                pass
            
            self.log("系统清理完成")
            
        except Exception as e:
            self.log(f"系统清理失败: {e}", "ERROR")
    
    def generate_summary_report(self, duration: float):
        """生成总结报告"""
        report_file = self.log_dir / f"summary_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
        
        report_content = [
            "# 自动化系统维护总结报告",
            f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"执行耗时: {duration:.2f}秒",
            ""
        ]
        
        # 系统状态
        report_content.append("## 系统状态")
        report_content.append("")
        report_content.append(f"- 文档质量监控: {'✅ 启用' if self.config['document_monitor']['enabled'] else '❌ 禁用'}")
        report_content.append(f"- Git自动维护: {'✅ 启用' if self.config['git_maintainer']['enabled'] else '❌ 禁用'}")
        report_content.append("")
        
        # 目录统计
        report_content.append("## 目录统计")
        report_content.append("")
        
        try:
            # 文档统计
            docs_dir = self.as_my_see_dir / "docs"
            if docs_dir.exists():
                md_files = list(docs_dir.rglob("*.md"))
                report_content.append(f"- 文档总数: {len(md_files)}")
            
            # 日志统计
            logs_dir = self.as_my_see_dir / "logs"
            if logs_dir.exists():
                log_files = list(logs_dir.rglob("*.log"))
                report_content.append(f"- 日志文件: {len(log_files)}")
            
            # 备份统计
            backups_dir = self.as_my_see_dir / "backups"
            if backups_dir.exists():
                backup_files = list(backups_dir.rglob("*.tar.gz"))
                report_content.append(f"- 备份文件: {len(backup_files)}")
            
        except Exception as e:
            report_content.append(f"- 统计错误: {e}")
        
        report_content.append("")
        
        # 最近日志
        report_content.append("## 最近日志")
        report_content.append("")
        report_content.append("```")
        
        try:
            with open(self.log_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                report_content.extend(lines[-20:] if len(lines) > 20 else lines)
        except:
            report_content.append("无日志记录")
        
        report_content.append("```")
        report_content.append("")
        
        # 建议
        report_content.append("## 维护建议")
        report_content.append("")
        report_content.append("1. **定期审查报告**：每周检查自动化报告")
        report_content.append("2. **优化配置**：根据需求调整自动化配置")
        report_content.append("3. **监控系统**：关注系统运行状态和资源使用")
        report_content.append("4. **备份重要数据**：定期备份配置和重要文档")
        report_content.append("")
        
        # 写入报告
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(report_content))
        
        self.log(f"总结报告生成: {report_file}")
    
    def setup_scheduled_tasks(self):
        """设置定时任务"""
        self.log("设置定时任务...")
        
        # 文档质量监控
        if self.config["document_monitor"]["enabled"]:
            schedule_str = self.config["document_monitor"]["schedule"]
            schedule.every().day.at(schedule_str.split()[1] + ":" + schedule_str.split()[0]).do(
                self.run_document_monitor
            )
            self.log(f"文档质量监控计划: {schedule_str}")
        
        # Git自动维护
        if self.config["git_maintainer"]["enabled"]:
            schedule_str = self.config["git_maintainer"]["schedule"]
            schedule.every().day.at(schedule_str.split()[1] + ":" + schedule_str.split()[0]).do(
                self.run_git_maintainer
            )
            self.log(f"Git自动维护计划: {schedule_str}")
        
        # 完整维护
        full_schedule = self.config["system"]["full_maintenance_schedule"]
        day_of_week = int(full_schedule.split()[4]) if full_schedule.split()[4] != '*' else None
        hour = full_schedule.split()[1]
        minute = full_schedule.split()[0]
        
        if day_of_week is not None:
            # 每周特定天
            schedule.every(day_of_week).day.at(f"{hour}:{minute}").do(
                self.run_full_maintenance
            )
        else:
            # 每天
            schedule.every().day.at(f"{hour}:{minute}").do(
                self.run_full_maintenance
            )
        
        self.log(f"完整维护计划: {full_schedule}")
        
        self.log("定时任务设置完成")
    
    def run_scheduler(self):
        """运行调度器"""
        self.log("启动自动化系统调度器...")
        self.setup_scheduled_tasks()
        
        try:
            while True:
                schedule.run_pending()
                time.sleep(60)  # 每分钟检查一次
        except KeyboardInterrupt:
            self.log("调度器已停止")
        except Exception as e:
            self.log(f"调度器运行错误: {e}", "ERROR")
    
    def show_status(self):
        """显示系统状态"""
        print("=== 自动化系统状态 ===")
        print(f"工作目录: {self.workspace_dir}")
        print(f"配置文件: {self.config_file}")
        print(f"日志目录: {self.log_dir}")
        print("")
        
        print("📊 文档质量监控:")
        doc_config = self.config["document_monitor"]
        print(f"  状态: {'✅ 启用' if doc_config['enabled'] else '❌ 禁用'}")
        print(f"  计划: {doc_config['schedule']}")
        print(f"  阈值: {doc_config['threshold_lines']} 行")
        print("")
        
        print("🔧 Git自动维护:")
        git_config = self.config["git_maintainer"]
        print(f"  状态: {'✅ 启用' if git_config['enabled'] else '❌ 禁用'}")
        print(f"  计划: {git_config['schedule']}")
        print(f"  自动推送: {'✅ 是' if git_config['auto_push'] else '❌ 否'}")
        print(f"  创建备份: {'✅ 是' if git_config['create_backup'] else '❌ 否'}")
        print("")
        
        print("⚙️ 系统配置:")
        sys_config = self.config["system"]
        print(f"  完整维护计划: {sys_config['full_maintenance_schedule']}")
        print(f"  最大日志文件: {sys_config['max_log_files']}")
        print(f"  清理旧日志: {'✅ 是' if sys_config['cleanup_old_logs'] else '❌ 否'}")
        print("")
        
        # 显示目录统计
        print("📁 目录统计:")
        try:
            docs_count = len(list((self.as_my_see_dir / "docs").rglob("*.md")))
            print(f"  文档数量: {docs_count}")
        except:
            print("  文档数量: 未知")
        
        try:
            logs_count = len(list((self.as_my_see_dir / "logs").rglob("*.log")))
            print(f"  日志数量: {logs_count}")
        except:
            print("  日志数量: 未知")
        
        try:
            backups_count = len(list((self.as_my_see_dir / "backups").rglob("*.tar.gz")))
            print(f"  备份数量: {backups_count}")
        except:
            print("  备份数量: 未知")

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="自动化系统管理器")
    parser.add_argument("--workspace-dir", default="/root/.openclaw/workspace",
                       help="工作目录")
    parser.add_argument("--run-document-monitor", action="store_true",
                       help="运行文档质量监控")
    parser.add_argument("--run-git-maintainer", action="store_true",
                       help="运行Git自动维护")
    parser.add_argument("--run-full", action="store_true",
                       help="运行完整维护流程")
    parser.add_argument("--status", action="store_true",
                       help="显示系统状态")
    parser.add_argument("--start-scheduler", action="store_true",
                       help="启动调度器")
    parser.add_argument("--set-config", type=str,
                       help="设置配置，格式: section.key=value")
    
    args = parser.parse_args()
    
    # 创建自动化系统
    system = AutomationSystem(args.workspace_dir)
    
    if args.status:
        # 显示状态
        system.show_status()
        return
    
    if args.set_config:
        # 设置配置
        try:
            path, value = args.set_config.split('=', 1)
            parts = path.split('.')
            
            if len(parts) == 2:
                section, key = parts
                if section in system.config and key in system.config[section]:
                    # 尝试转换类型
                    if value.lower() in ['true', 'false']:
                        system.config[section][key] = value.lower() == 'true'
                    elif value.isdigit():
                        system.config[section][key] = int(value)
                    else:
                        system.config[section][key] = value
                    
                    system.save_config()
                    print(f"配置已更新: {section}.{key} = {system.config[section][key]}")
                else:
                    print(f"未知配置项: {path}")
            else:
                print("配置路径格式错误，应为 section.key=value")
        except ValueError:
            print("配置格式错误，应为 section.key=value")
        return
    
    if args.run_document_monitor:
        # 运行文档质量监控
        system.run_document_monitor()
        return
    
    if args.run_git_maintainer:
        # 运行Git自动维护
        system.run_git_maintainer()
        return
    
    if args.run_full:
        # 运行完整维护流程
        system.run_full_maintenance()
        return
    
    if args.start_scheduler:
        # 启动调度器
        system.run_scheduler()
        return
    
    # 默认显示帮助
    print("自动化系统管理器")
    print("")
    print("用法:")
    print("  --run-document-monitor   运行文档质量监控")
    print("  --run-git-maintainer     运行Git自动维护")
    print("  --run-full               运行完整维护流程")
    print("  --status                 显示系统状态")
    print("  --start-scheduler        启动调度器")
    print("  --set-config section.key=value  设置配置")
    print("")
    print("示例:")
    print("  python3 automation_system.py --status")
    print("  python3 automation_system.py --run-full")
    print("  python3 automation_system.py --set-config document_monitor.threshold_lines=100")

if __name__ == "__main__":
    main()
