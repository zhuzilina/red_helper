import os
import threading
from queue import Queue
from volcenginesdkarkruntime import Ark

# 从环境变量中读取API Key
API_KEY = os.environ.get("ARK_API_KEY")
if not API_KEY:
    raise ValueError("请设置环境变量ARK_API_KEY")

# 模型ID，请根据实际情况替换
MODEL_ID = "doubao-1-5-pro-32k-250115"

def model_worker(client, question_queue, result_queue):
    """工作线程函数，处理问题并将结果放入结果队列"""
    while True:
        # 从队列获取问题，block=True表示阻塞等待
        question_id, question = question_queue.get()
        
        try:
            # 调用大模型
            completion = client.chat.completions.create(
                model=MODEL_ID,
                messages=[{"role": "user", "content": question}]
            )
            
            # 获取回答内容
            answer = completion.choices[0].message.content
            
            # 将结果放入结果队列，包含问题ID以便追踪
            result_queue.put((question_id, question, answer, None))
            
        except Exception as e:
            # 处理其他异常
            result_queue.put((question_id, question, None, f"错误: {str(e)}"))
        finally:
            # 标记任务完成
            question_queue.task_done()

def print_results(result_queue, total_questions):
    """打印结果的线程函数，按结果返回顺序打印"""
    received = 0
    while received < total_questions:
        # 等待结果
        question_id, question, answer, error = result_queue.get()
        received += 1
        
        # 打印结果
        print(f"\n问题 #{question_id}: {question}")
        if error:
            print(f"回答错误: {error}")
        else:
            print(f"回答: {answer}")
        
        result_queue.task_done()

def main():
    # 一组小问题
    questions = [
        "什么是人工智能？",
        "Python的主要应用领域有哪些？",
        "机器学习和深度学习的区别是什么？",
        "什么是云计算？",
        "大数据的特征是什么？",
        "区块链技术的核心特点是什么？",
        "什么是自然语言处理？",
        "计算机视觉主要研究什么？"
    ]
    
    # 问题数量
    num_questions = len(questions)
    
    # 如果没有问题，直接返回
    if num_questions == 0:
        print("没有问题需要处理")
        return
    
    # 创建问题队列和结果队列
    question_queue = Queue()
    result_queue = Queue()
    
    # 初始化客户端
    client = Ark(api_key=API_KEY)
    
    # 设置线程数量，可以根据API并发限制调整
    num_threads = min(4, num_questions)  # 这里限制最多4个并发线程
    
    # 创建并启动工作线程
    for _ in range(num_threads):
        worker = threading.Thread(
            target=model_worker,
            args=(client, question_queue, result_queue),
            daemon=True  # 守护线程，主程序退出时自动结束
        )
        worker.start()
    
    # 创建并启动打印结果的线程
    print_thread = threading.Thread(
        target=print_results,
        args=(result_queue, num_questions),
        daemon=True
    )
    print_thread.start()
    
    # 将问题放入队列
    for i, question in enumerate(questions, 1):
        question_queue.put((i, question))
    
    print(f"已提交{num_questions}个问题，正在等待结果...")
    
    # 等待所有问题处理完成
    question_queue.join()
    result_queue.join()
    
    print("\n所有问题处理完毕")

if __name__ == "__main__":
    main()
