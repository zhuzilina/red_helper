import re
import chardet
import json
import os

def detect_encoding(byte_data):
    """自动检测字节数据的编码格式"""
    result = chardet.detect(byte_data)
    encoding = result['encoding']
    confidence = result['confidence']
    
    if not encoding or confidence < 0.5:
        probable_encodings = ['gbk', 'gb2312', 'utf-8', 'iso-8859-1']
        for enc in probable_encodings:
            try:
                byte_data.decode(enc)
                return enc
            except UnicodeDecodeError:
                continue
        return 'utf-8'
    return encoding

def decode_content(byte_content):
    """将字节内容解码为Unicode字符串"""
    if not byte_content:
        return ""
    
    try:
        encoding = detect_encoding(byte_content)
        return byte_content.decode(encoding)
    except (UnicodeDecodeError, LookupError):
        try:
            return byte_content.decode('gbk', errors='replace')
        except UnicodeDecodeError:
            return byte_content.decode('utf-8', errors='replace')

def process_content(content_data):
    """处理content内容，仅在段落间添加分割线"""
    # 确保内容是字符串
    if isinstance(content_data, bytes):
        content = decode_content(content_data)
    else:
        content = str(content_data) if not isinstance(content_data, str) else content_data
    
    if not content:
        return ""
    
    # 按一个或多个换行符分割段落
    paragraphs = re.split(r'\n+', content)
    # 过滤空段落并去除首尾空白
    paragraphs = [para.strip() for para in paragraphs if para.strip()]
    
    # 在段落之间添加分割线
    if len(paragraphs) > 0:
        # 使用"---"作为分割线，前后各加一个换行
        processed_paragraphs = "\n---\n".join(paragraphs)
    else:
        processed_paragraphs = ""
    
    return processed_paragraphs

def process_json_file(input_file_path, output_file_path=None):
    """处理JSON文件并保存结果"""
    if not os.path.exists(input_file_path):
        raise FileNotFoundError(f"输入文件不存在: {input_file_path}")
    
    if not output_file_path:
        file_dir, file_name = os.path.split(input_file_path)
        file_base, file_ext = os.path.splitext(file_name)
        output_file_path = os.path.join(file_dir, f"{file_base}_processed{file_ext}")
    
    # 读取并解析JSON文件
    with open(input_file_path, 'rb') as f:
        byte_data = f.read()
    
    encoding = detect_encoding(byte_data)
    try:
        json_content = byte_data.decode(encoding)
    except UnicodeDecodeError:
        json_content = byte_data.decode('utf-8', errors='replace')
    
    try:
        data = json.loads(json_content)
    except json.JSONDecodeError as e:
        raise ValueError(f"JSON解析错误: {str(e)}")
    
    # 处理content字段
    if isinstance(data, list):
        for item in data:
            if isinstance(item, dict) and 'small_chapters' in item:
                for small_chapter in item['small_chapters']:
                    if 'content' in small_chapter:
                        small_chapter['content'] = process_content(small_chapter['content'])
    elif isinstance(data, dict) and 'small_chapters' in data:
        for small_chapter in data['small_chapters']:
            if 'content' in small_chapter:
                small_chapter['content'] = process_content(small_chapter['content'])
    else:
        raise ValueError("JSON格式不符合预期")
    
    # 保存处理后的文件
    with open(output_file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"处理完成，文件保存至: {output_file_path}")
    return output_file_path

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        input_path = sys.argv[1]
        output_path = sys.argv[2] if len(sys.argv) > 2 else None
        process_json_file(input_path, output_path)
    else:
        print("使用方法: python json_processor.py 输入文件路径 [输出文件路径]")
