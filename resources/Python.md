# Python
> 更新时间: 2026年02月27日



# 小技巧



# 导入表格

# txt

- 使用readlines函数，读取文本所有内容，并返回一个列表，每个元素是一行的内容。然后使用split函数，按照空格或逗号分割每行的内容，并取出第一列元素。例如：

```python
with open("data.txt", "r") as f: # 打开文件
    data = f.readlines() # 读取所有行
    first_column = [] # 创建一个空列表，用于存放第一列元素
    for line in data: # 遍历每一行
        line = line.strip() # 去掉换行符
        elements = line.split() # 按照空格分割每一行的内容
        first_column.append(elements[0]) # 取出第一列元素，并添加到列表中
    print(first_column) # 打印第一列元素
```

- 使用pandas库，导入txt文本数据为一个DataFrame对象，然后使用iloc方法，提取第一列元素。例如：

```python
import pandas as pd # 导入pandas库
df = pd.read_csv("data.txt", sep=" ", header=None) # 读取txt文本数据，假设每列之间用空格分隔，没有表头
first_column = df.iloc[:, 0] # 提取第一列元素
print(first_column) # 打印第一列元素
```


(1) python读取、写入txt文本内容 - CSDN博客. https://blog.csdn.net/qq_37828488/article/details/100024924.
(2) Python读取txt文本三种方式 - 知乎 - 知乎专栏. https://zhuanlan.zhihu.com/p/399263571.
(3) 【python】读取和输出到txt - CSDN博客. https://blog.csdn.net/zxfhahaha/article/details/81288660.



# csv

- 使用csv.reader函数，读取csv文本所有内容，并返回一个迭代器，每个元素是一行的内容。然后使用列表推导式，提取第一列元素。例如：

```python
import csv
with open("data.csv", "r") as f: # 打开文件
    reader = csv.reader(f) # 读取所有行
    first_column = [row[0] for row in reader] # 提取第一列元素
    print(first_column) # 打印第一列元素
```

- 使用csv.DictReader函数，读取csv文本所有内容，并返回一个迭代器，每个元素是一个字典，键是列名，值是对应的数据。然后使用列表推导式，提取第一列元素。例如：

```python
import csv
with open("data.csv", "r") as f: # 打开文件
    reader = csv.DictReader(f) # 读取所有行
    first_column = [row["col1"] for row in reader] # 提取第一列元素，假设列名为col1
    print(first_column) # 打印第一列元素
```

- 使用pandas.read_csv函数，导入csv文本数据为一个DataFrame对象，然后使用iloc方法，提取第一列元素。例如：

```python
import pandas as pd # 导入pandas库
df = pd.read_csv("data.csv") # 读取csv文本数据
first_column = df.iloc[:, 0] # 提取第一列元素
print(first_column) # 打印第一列元素
```


(1) 用python玩转csv文件：csv模块 - 知乎 - 知乎专栏. https://zhuanlan.zhihu.com/p/38537335.
(2) python中csv文件的创建、读取、修改等操作总结 - CSDN博客. https://blog.csdn.net/m0_46483236/article/details/109583685.
(3) Reading and Writing CSV Files in Python – Real Python. https://realpython.com/python-csv/.



# xls

- 使用xlrd库，读取xls文本所有内容，并返回一个Book对象，然后使用sheet_by_index或sheet_by_name方法，获取指定的Sheet对象，再使用col_values方法，提取第一列元素。例如：

```python
import xlrd
book = xlrd.open_workbook("data.xls") # 打开文件
sheet = book.sheet_by_index(0) # 获取第一个Sheet对象
first_column = sheet.col_values(0) # 提取第一列元素
print(first_column) # 打印第一列元素
```

- 使用pandas库，导入xls文本数据为一个DataFrame对象，然后使用iloc方法，提取第一列元素。例如：

```python
import pandas as pd # 导入pandas库
df = pd.read_excel("data.xls") # 读取xls文本数据
first_column = df.iloc[:, 0] # 提取第一列元素
print(first_column) # 打印第一列元素
```


(1) Reading/parsing Excel (xls) files with Python - Stack Overflow. https://stackoverflow.com/questions/2942889/reading-parsing-excel-xls-files-with-python.
(2) Python--pandas读取excel - 知乎. https://zhuanlan.zhihu.com/p/362709226.
(3) python载入xls数据_Python-处理XLS数据 - CSDN博客. https://blog.csdn.net/cunzai1985/article/details/108752557.
