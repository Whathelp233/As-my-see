#!/usr/bin/env python3
"""
Git自动维护系统
自动提交、推送、备份Git仓库
"""

import os
import sys
import subprocess
import json
import shutil
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

class GitAutoMaintainer:
    def __init__(self, repo_dir: str):
        self.repo_dir = Path(repo_dir)
        self.log_dir = self.repo_dir / "logs" / "git"
        self.backup_dir = self.repo_dir / "backups" / "git"
        self.config_file = self.repo_dir / "git_maintainer_config.json"
        
        # 创建目录
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        
        # 加载配置
        self.config = self.load_config()
        
        # 日志文件
        self.log_file = self.log_dir / f"git_maintainer_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        
    def load_config(self) -> Dict:
        """加载配置"""
        default_config = {
            "git_user": "OpenClaw Bot",
            "git_email": "bot@openclaw.ai",
            "max_backups": 30,
            "auto_push": True,
            "create_backup": True,
            "run_gc": True,
            "remote_name": "origin",
            "branch": "master"
        }
        
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    user_config = json.load(f)
                    default_config.update(user_config)
            except Exception as e:
                print(f"加载配置文件失败: {e}")
        
        return default_config
    
    def save_config(self):
        """保存配置"""
        try:
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"保存配置文件失败: {e}")
    
    def log(self, message: str, level: str = "INFO"):
        """记录日志"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log_entry = f"[{timestamp}] [{level}] {message}"
        
        # 写入日志文件
        with open(self.log_file, 'a', encoding='utf-8') as f:
            f.write(log_entry + '\n')
        
        # 输出到控制台
        print(log_entry)
    
    def run_git_command(self, command: List[str], check: bool = False) -> subprocess.CompletedProcess:
        """运行Git命令"""
        try:
            result = subprocess.run(
                ['git'] + command,
                cwd=self.repo_dir,
                capture_output=True,
                text=True,
                encoding='utf-8'
            )
            
            if result.stdout:
                self.log(f"Git命令输出: {' '.join(command)}\n{result.stdout}")
            if result.stderr:
                self.log(f"Git命令错误: {' '.join(command)}\n{result.stderr}", "WARNING")
            
            if check and result.returncode != 0:
                raise subprocess.CalledProcessError(result.returncode, command)
            
            return result
            
        except Exception as e:
            self.log(f"运行Git命令失败: {' '.join(command)} - {e}", "ERROR")
            raise
    
    def check_git_status(self) -> bool:
        """检查Git状态"""
        self.log("检查Git状态...")
        
        # 检查是否是Git仓库
        if not (self.repo_dir / ".git").exists():
            self.log("不是Git仓库", "ERROR")
            return False
        
        # 检查是否有未提交的更改
        status_result = self.run_git_command(["status", "--porcelain"])
        
        if status_result.stdout.strip():
            self.log(f"发现未提交的更改:\n{status_result.stdout}")
            return True
        else:
            self.log("没有未提交的更改")
            return False
    
    def configure_git_user(self):
        """配置Git用户"""
        self.log("配置Git用户...")
        
        self.run_git_command(["config", "user.name", self.config["git_user"]])
        self.run_git_command(["config", "user.email", self.config["git_email"]])
        
        self.log(f"Git用户配置: {self.config['git_user']} <{self.config['git_email']}>")
    
    def auto_commit_changes(self) -> Optional[str]:
        """自动提交更改"""
        self.log("自动提交更改...")
        
        # 添加所有更改
        add_result = self.run_git_command(["add", "."])
        
        if add_result.returncode != 0:
            self.log("添加文件失败", "ERROR")
            return None
        
        # 生成提交信息
        commit_message = f"""自动提交: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

更新内容:
- 文档维护与优化
- 自动生成的更改
- 系统维护更新"""
        
        # 提交
        commit_result = self.run_git_command(["commit", "-m", commit_message])
        
        if commit_result.returncode == 0:
            # 获取提交哈希
            hash_result = self.run_git_command(["rev-parse", "--short", "HEAD"])
            commit_hash = hash_result.stdout.strip()
            self.log(f"提交成功: {commit_hash}")
            return commit_hash
        else:
            self.log("没有需要提交的更改", "WARNING")
            return None
    
    def auto_push_to_remote(self) -> bool:
        """自动推送到远程仓库"""
        if not self.config["auto_push"]:
            self.log("自动推送已禁用，跳过")
            return True
        
        self.log("推送到远程仓库...")
        
        # 检查远程仓库
        remote_result = self.run_git_command(["remote"])
        if self.config["remote_name"] not in remote_result.stdout:
            self.log(f"远程仓库 '{self.config['remote_name']}' 不存在", "ERROR")
            return False
        
        # 推送
        push_result = self.run_git_command(
            ["push", self.config["remote_name"], self.config["branch"]]
        )
        
        if push_result.returncode == 0:
            self.log(f"推送成功: {self.config['branch']} -> {self.config['remote_name']}")
            return True
        else:
            self.log("推送失败", "ERROR")
            return False
    
    def create_git_backup(self) -> Optional[Path]:
        """创建Git备份"""
        if not self.config["create_backup"]:
            self.log("备份创建已禁用，跳过")
            return None
        
        self.log("创建Git备份...")
        
        backup_name = f"git_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.tar.gz"
        backup_path = self.backup_dir / backup_name
        
        try:
            # 备份.git目录
            shutil.make_archive(
                str(backup_path.with_suffix('')),  # 去掉.tar.gz
                'gztar',
                self.repo_dir,
                '.git'
            )
            
            # 获取文件大小
            file_size = backup_path.stat().st_size / (1024 * 1024)  # MB
            
            self.log(f"Git备份完成: {backup_name} ({file_size:.2f} MB)")
            return backup_path
            
        except Exception as e:
            self.log(f"创建备份失败: {e}", "ERROR")
            return None
    
    def cleanup_old_backups(self):
        """清理旧备份"""
        self.log("清理旧备份...")
        
        try:
            # 获取所有备份文件，按修改时间排序
            backups = list(self.backup_dir.glob("*.tar.gz"))
            backups.sort(key=lambda x: x.stat().st_mtime, reverse=True)
            
            max_backups = self.config["max_backups"]
            
            if len(backups) <= max_backups:
                self.log(f"备份文件数量正常 ({len(backups)}/{max_backups})")
                return
            
            # 删除多余的备份
            to_delete = backups[max_backups:]
            for backup in to_delete:
                try:
                    backup.unlink()
                    self.log(f"删除旧备份: {backup.name}")
                except Exception as e:
                    self.log(f"删除备份失败 {backup.name}: {e}", "WARNING")
            
            self.log(f"备份清理完成，删除了 {len(to_delete)} 个旧备份")
            
        except Exception as e:
            self.log(f"清理备份失败: {e}", "ERROR")
    
    def run_git_garbage_collection(self):
        """运行Git垃圾回收"""
        if not self.config["run_gc"]:
            self.log("垃圾回收已禁用，跳过")
            return
        
        self.log("运行Git垃圾回收...")
        
        try:
            # 检查松散对象数量
            count_result = self.run_git_command(["count-objects", "-v"])
            lines = count_result.stdout.strip().split('\n')
            
            loose_objects = 0
            for line in lines:
                if line.startswith('count:'):
                    loose_objects = int(line.split(':')[1].strip())
                    break
            
            if loose_objects > 100:
                self.log(f"执行垃圾回收 (松散对象: {loose_objects})")
                
                # 运行垃圾回收
                gc_result = self.run_git_command(["gc", "--auto", "--prune=now"])
                
                if gc_result.returncode == 0:
                    # 检查回收效果
                    new_count_result = self.run_git_command(["count-objects", "-v"])
                    new_lines = new_count_result.stdout.strip().split('\n')
                    
                    new_loose_objects = 0
                    for line in new_lines:
                        if line.startswith('count:'):
                            new_loose_objects = int(line.split(':')[1].strip())
                            break
                    
                    reduced = loose_objects - new_loose_objects
                    self.log(f"垃圾回收完成，减少 {reduced} 个松散对象")
                else:
                    self.log("垃圾回收失败", "WARNING")
            else:
                self.log(f"不需要垃圾回收 (松散对象: {loose_objects})")
                
        except Exception as e:
            self.log(f"垃圾回收失败: {e}", "ERROR")
    
    def check_git_health(self):
        """检查Git仓库健康状态"""
        self.log("检查Git仓库健康状态...")
        
        health_report = self.log_dir / f"git_health_{datetime.now().strftime('%Y%m%d')}.md"
        
        report_content = [
            "# Git仓库健康检查报告",
            f"检查时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"仓库位置: {self.repo_dir}",
            ""
        ]
        
        try:
            # 分支状态
            branch_result = self.run_git_command(["branch", "-avv"])
            report_content.append("## 分支状态")
            report_content.append("```bash")
            report_content.append(branch_result.stdout.strip())
            report_content.append("```")
            report_content.append("")
            
            # 远程状态
            remote_result = self.run_git_command(["remote", "-v"])
            report_content.append("## 远程仓库状态")
            report_content.append("```bash")
            report_content.append(remote_result.stdout.strip())
            report_content.append("```")
            report_content.append("")
            
            # 最近提交
            log_result = self.run_git_command(["log", "--oneline", "-10"])
            report_content.append("## 最近提交")
            report_content.append("```bash")
            report_content.append(log_result.stdout.strip())
            report_content.append("```")
            report_content.append("")
            
            # 存储库统计
            report_content.append("## 存储库统计")
            report_content.append("```bash")
            
            # 文件总数
            file_count = sum(1 for _ in self.repo_dir.rglob("*") if _.is_file())
            report_content.append(f"文件总数: {file_count}")
            
            # Git对象数
            count_result = self.run_git_command(["count-objects", "-v"])
            for line in count_result.stdout.strip().split('\n'):
                report_content.append(line)
            
            # 存储库大小
            repo_size = sum(f.stat().st_size for f in (self.repo_dir / ".git").rglob("*") if f.is_file())
            repo_size_mb = repo_size / (1024 * 1024)
            report_content.append(f"存储库大小: {repo_size_mb:.2f} MB")
            
            report_content.append("```")
            report_content.append("")
            
            # 问题检查
            report_content.append("## 问题检查")
            
            issues_found = 0
            
            # 检查悬空对象
            fsck_result = self.run_git_command(["fsck", "--full"])
            if "dangling" in fsck_result.stdout:
                report_content.append("⚠️ 发现悬空对象")
                issues_found += 1
            
            # 检查包文件大小
            for line in count_result.stdout.strip().split('\n'):
                if line.startswith("size-pack:"):
                    size_kb = int(line.split(":")[1].strip())
                    if size_kb > 100000:  # 大于100MB
                        size_mb = size_kb / 1024
                        report_content.append(f"⚠️ Git包文件较大 ({size_mb:.1f}MB)，建议运行 git gc")
                        issues_found += 1
                    break
            
            if issues_found == 0:
                report_content.append("✅ Git仓库健康状态良好")
            
            # 写入报告
            with open(health_report, 'w', encoding='utf-8') as f:
                f.write('\n'.join(report_content))
            
            self.log(f"健康检查报告生成: {health_report}")
            
        except Exception as e:
            self.log(f"健康检查失败: {e}", "ERROR")
    
    def generate_maintenance_report(self, commit_hash: Optional[str], backup_file: Optional[Path]):
        """生成维护报告"""
        report_file = self.log_dir / f"maintenance_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
        
        report_content = [
            "# Git自动维护报告",
            f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"仓库位置: {self.repo_dir}",
            ""
        ]
        
        # 基本状态
        report_content.append("## 基本状态")
        report_content.append("")
        
        try:
            branch_result = self.run_git_command(["branch", "--show-current"])
            current_branch = branch_result.stdout.strip()
            report_content.append(f"- 当前分支: {current_branch}")
        except:
            report_content.append("- 当前分支: 未知")
        
        if commit_hash:
            report_content.append(f"- 最新提交: {commit_hash}")
        else:
            report_content.append("- 最新提交: 无新提交")
        
        if backup_file and backup_file.exists():
            file_size = backup_file.stat().st_size / (1024 * 1024)  # MB
            report_content.append(f"- 备份文件: {backup_file.name} ({file_size:.2f} MB)")
        else:
            report_content.append("- 备份文件: 无")
        
        report_content.append("")
        
        # 维护操作记录
        report_content.append("## 维护操作记录")
        report_content.append("")
        report_content.append("```")
        
        # 读取日志文件最后50行
        try:
            with open(self.log_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                report_content.extend(lines[-50:] if len(lines) > 50 else lines)
        except:
            report_content.append("无日志记录")
        
        report_content.append("```")
        report_content.append("")
        
        # 建议
        report_content.append("## 维护建议")
        report_content.append("")
        report_content.append("1. **定期运行本维护脚本**")
        report_content.append("2. **监控Git仓库大小**")
        report_content.append("3. **及时解决合并冲突**")
        report_content.append("4. **定期清理旧分支**")
        report_content.append("")
        
        # 写入报告
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(report_content))
        
        self.log(f"维护报告生成: {report_file}")
    
    def run_maintenance(self) -> Dict:
        """运行完整维护流程"""
        self.log("=== 开始Git自动维护 ===")
        
        results = {
            "status": "success",
            "commit": None,
            "backup": None,
            "timestamp": datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        
        try:
            # 1. 检查Git状态
            if not self.check_git_status():
                self.log("没有需要维护的内容，跳过提交")
            else:
                # 2. 配置Git用户
                self.configure_git_user()
                
                # 3. 自动提交更改
                commit_hash = self.auto_commit_changes()
                results["commit"] = commit_hash
                
                # 4. 如果有新提交，推送到远程
                if commit_hash and self.config["auto_push"]:
                    self.auto_push_to_remote()
            
            # 5. 创建备份
            backup_file = self.create_git_backup()
            if backup_file:
                results["backup"] = backup_file.name
            
            # 6. 运行垃圾回收
            self.run_git_garbage_collection()
            
            # 7. 检查健康状态
            self.check_git_health()
            
            # 8. 清理旧备份
            self.cleanup_old_backups()
            
            # 9. 生成维护报告
            self.generate_maintenance_report(results["commit"], backup_file)
            
            self.log("=== Git自动维护完成 ===")
            
        except Exception as e:
            self.log(f"维护过程中出现错误: {e}", "ERROR")
            results["status"] = "error"
            results["error"] = str(e)
        
        return results

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Git自动维护系统")
    parser.add_argument("--repo-dir", default="/root/.openclaw/workspace/As-my-see",
                       help="Git仓库目录")
    parser.add_argument("--config", action="store_true",
                       help="显示当前配置")
    parser.add_argument("--set-config", type=str,
                       help="设置配置，格式: key=value")
    parser.add_argument("--health-check", action="store_true",
                       help="只运行健康检查")
    parser.add_argument("--create-backup", action="store_true",
                       help="只创建备份")
    
    args = parser.parse_args()
    
    # 创建维护器
    maintainer = GitAutoMaintainer(args.repo_dir)
    
    if args.config:
        # 显示配置
        print("当前配置:")
        for key, value in maintainer.config.items():
            print(f"  {key}: {value}")
        return
    
    if args.set_config:
        # 设置配置
        try:
            key, value = args.set_config.split('=', 1)
            if key in maintainer.config:
                # 尝试转换类型
                if value.lower() in ['true', 'false']:
                    maintainer.config[key] = value.lower() == 'true'
                elif value.isdigit():
                    maintainer.config[key] = int(value)
                else:
                    maintainer.config[key] = value
                
                maintainer.save_config()
                print(f"配置已更新: {key} = {maintainer.config[key]}")
            else:
                print(f"未知配置项: {key}")
        except ValueError:
            print("配置格式错误，应为 key=value")
        return
    
    if args.health_check:
        # 只运行健康检查
        maintainer.check_git_health()
        return
    
    if args.create_backup:
        # 只创建备份
        backup_file = maintainer.create_git_backup()
        if backup_file:
            print(f"备份创建成功: {backup_file}")
        return
    
    # 运行完整维护
    results = maintainer.run_maintenance()
    
    # 输出结果
    print("\n=== 维护结果 ===")
    print(f"状态: {results['status']}")
    print(f"时间: {results['timestamp']}")
    
    if results.get('commit'):
        print(f"提交: {results['commit']}")
    else:
        print("提交: 无新提交")
    
    if results.get('backup'):
        print(f"备份: {results['backup']}")
    else:
        print("备份: 无")
    
    if results.get('error'):
        print(f"错误: {results['error']}")

if __name__ == "__main__":
    main()