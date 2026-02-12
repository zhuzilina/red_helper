import re
import json
import os

def split_novel_by_chapters(txt_file_path, output_json_path=None):
    """
    将具有两级篇章结构的TXT小说分割并保存为JSON格式
    
    结构说明:
    - 大篇章: 第一、二、三...篇，下一行是大篇章标题
    - 小篇章: 一、二、三...，下一行是小篇章标题
    
    参数:
        txt_file_path: TXT小说文件路径
        output_json_path: 输出JSON文件路径，默认与原文件同目录
    """
    # 设置默认输出路径
    if output_json_path is None:
        file_dir, file_name = os.path.split(txt_file_path)
        file_base_name = os.path.splitext(file_name)[0]
        output_json_path = os.path.join(file_dir, f"{file_base_name}_structured.json")
    
    # 读取文件内容，尝试多种编码
    encodings = ['utf-8', 'gbk', 'gb2312', 'ansi', 'iso-8859-1', 'cp936']
    content = None
    
    for encoding in encodings:
        try:
            with open(txt_file_path, 'r', encoding=encoding) as f:
                content = f.read()
            print(f"成功使用编码 {encoding} 读取文件")
            break
        except UnicodeDecodeError:
            continue
        except Exception as e:
            print(f"使用编码 {encoding} 读取失败: {e}")
    
    if content is None:
        # 最后的尝试：使用replace错误处理方式
        try:
            with open(txt_file_path, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
            print("使用utf-8编码并替换无法识别的字符")
        except Exception as e:
            print(f"所有编码尝试均失败: {e}")
            return None
    
    # 按行分割内容，便于处理标题行
    lines = [line.strip() for line in content.split('\n') if line.strip()]
    
    # 定义匹配模式
    # 大篇章模式: 第一、二、三篇，如"第一篇"、"第三篇"
    big_chapter_pattern = re.compile(r'^第[一二三四五六七八九十百千万]+篇$')
    # 小篇章模式: 一、二、三，如"一"、"五"
    small_chapter_pattern = re.compile(r'^[一二三四五六七八九十百千万]+$')
    
    # 存储结构化数据
    novel_structure = []
    current_big_chapter = None
    current_small_chapter = None
    
    # 遍历每一行进行处理
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # 检查是否是大篇章
        if big_chapter_pattern.match(line):
            # 如果已有大篇章，先保存
            if current_big_chapter:
                novel_structure.append(current_big_chapter)
            
            # 新建大篇章，下一行是标题
            big_chapter_number = line[:-1]  # 去除"篇"字
            i += 1
            if i < len(lines):
                big_chapter_title = lines[i]
                i += 1
            else:
                big_chapter_title = ""
            
            current_big_chapter = {
                "big_chapter_number": big_chapter_number,
                "big_chapter_title": big_chapter_title,
                "small_chapters": []
            }
        
        # 检查是否是小篇章
        elif small_chapter_pattern.match(line) and current_big_chapter is not None:
            # 如果已有小篇章，先保存
            if current_small_chapter:
                current_big_chapter["small_chapters"].append(current_small_chapter)
            
            # 新建小篇章，下一行是标题
            small_chapter_number = line
            i += 1
            if i < len(lines):
                small_chapter_title = lines[i]
                i += 1
            else:
                small_chapter_title = ""
            
            current_small_chapter = {
                "small_chapter_number": small_chapter_number,
                "small_chapter_title": small_chapter_title,
                "content": []
            }
        
        # 否则为内容行
        elif current_small_chapter is not None:
            current_small_chapter["content"].append(line)
            i += 1
        
        # 无法识别的行，跳过
        else:
            i += 1
    
    # 添加最后一个小篇章和大篇章
    if current_small_chapter and current_big_chapter:
        current_big_chapter["small_chapters"].append(current_small_chapter)
    if current_big_chapter:
        novel_structure.append(current_big_chapter)
    
    # 将内容列表合并为字符串
    for big_chapter in novel_structure:
        for small_chapter in big_chapter["small_chapters"]:
            small_chapter["content"] = '\n'.join(small_chapter["content"])
    
    # 保存为JSON
    try:
        with open(output_json_path, 'w', encoding='utf-8') as f:
            json.dump(novel_structure, f, ensure_ascii=False, indent=2)
        
        big_chapter_count = len(novel_structure)
        small_chapter_count = sum(len(bc["small_chapters"]) for bc in novel_structure)
        print(f"处理完成: {big_chapter_count}个大篇章，{small_chapter_count}个小篇章")
        print(f"结果已保存至: {output_json_path}")
        return novel_structure
    except Exception as e:
        print(f"保存JSON失败: {e}")
        return None

if __name__ == "__main__":
    # 示例用法
    # 请替换为你的小说文件路径
    txt_file = "book01.txt"
    split_novel_by_chapters(txt_file)