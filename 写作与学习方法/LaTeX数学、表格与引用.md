# LaTeX 数学、表格与引用

## 数学模式

数学表达式必须放在数学模式中。行内模式适合短符号，独立显示模式适合较长的表达式。常见写法如下：

```latex
行内：$x_i^2 + y^2$

不编号的独立公式：
\[
  \frac{a+b}{c+d} = \sqrt{x}
\]

带编号的公式：
\begin{equation}
  \sum_{i=1}^{n} x_i
\end{equation}
```

上下标用 `_` 和 `^`；较长的表达式必须用 `{...}` 括起来，例如 `x_{i+1}`。分数用 `\frac{分子}{分母}`，根式用 `\sqrt{...}`。希腊字母可用 `\alpha`、`\Gamma` 等命令。数学符号要表达的意义应在正文解释，排版语法本身不会给出概念定义。

多行公式可使用 `amsmath` 提供的 `align` 或 `aligned` 环境，在对齐位置前写 `&`，用 `\\` 换行。矩阵环境也由 `amsmath` 提供。用 `\text{...}` 在公式中放短文本：

```latex
\begin{align}
  p &= q + r, \\
  s &= \frac{p}{2}
\end{align}

\[
\begin{bmatrix}
  a & b \\
  c & d
\end{bmatrix}
\qquad
f(t)=
\begin{cases}
  t^2, & t \ge 0, \\
  -t, & t < 0
\end{cases}
\]

\[
  x \underbrace{+\,y}_{\text{一个分组}}
\]
```

要使用这些环境，请在导言区加载 `amsmath`。方括号矩阵用 `bmatrix`，圆括号矩阵用 `pmatrix`，花括号矩阵用 `Bmatrix`。左右括号尺寸不合适时，可以成对使用 `\left` 与 `\right`；如果一边不显示定界符，可使用 `\left.` 或 `\right.`。例如，竖线右下方可以标注取值条件：

```latex
\left.(2x^3-x+z)\right|_{x=3}
```

点号表示不显示左侧定界符；该写法只演示排版记号。公式语法的可用范围由宏包和编译环境决定。

## 常用算子与微分记号

三角函数、对数和极限是数学运算符，写成 `\sin`、`\log`、`\lim` 可获得直立字体与合适间距。模运算可写成 `a \pmod{n}`。导数常用 `\frac{dy}{dx}` 表示，偏导数可写成 `\frac{\partial f}{\partial x}`。下面是语法演示：

```latex
\[
  \sin x + \log y,\qquad
  \lim_{t\to 0}\frac{f(t)-f(0)}{t},\qquad
  a \pmod{n}
\]

\[
  \left.\frac{df}{dx}\right|_{x=a}
\]
```

这些符号的数学意义和适用条件要在正文定义；排版命令只控制写法。

## 表格

`tabular` 负责表格主体；列格式中的 `l`、`c`、`r` 分别表示左对齐、居中和右对齐，`p{宽度}` 可指定一列的段落宽度。`&` 分隔单元格，`\\` 结束一行。`table` 使表格成为浮动体，可添加标题和交叉引用。

```latex
\begin{table}[tbp]
  \centering
  \caption{测量记录}
  \label{tab:measurements}
  \begin{tabular}{lcr}
    \hline
    项目 & 读数 & 单位 \\
    \hline
    长度 & 12.4 & mm \\
    时间 & 3.0 & s \\
    \hline
  \end{tabular}
\end{table}
```

这是排版语法示例，表中的数值仅为展示单元格格式。列太宽时，先精简标题、换行或调整列宽；把整张表缩得很小会同时缩小文字。`[tbp]` 是浮动位置提示，不保证表格紧贴源代码所在位置。

## 交叉引用和参考文献

给章节、图片、公式或表格设置唯一的 `\label{...}`，再用 `\ref{...}` 引用。浮动体中的标签应放在 `\caption` 之后，使标签记录该图表的编号。

```latex
\section{符号说明}\label{sec:symbols}

参见第~\ref{sec:symbols} 节。

\begin{thebibliography}{9}
  \bibitem{example} 示例作者. 示例标题. 示例出版信息.
\end{thebibliography}

正文引用：\cite{example}
```

参考文献标题、编号样式和引用格式常由文档类或参考文献工具控制。投稿或交付文档时，以指定模板为准。`thebibliography` 可用于直接列出简短参考文献；较大的文献库通常使用 BibTeX 或 `biblatex` 等工具。

## LaTeX 与符号表达式转换

数学公式的排版输出与符号解析是两类不同任务。SymPy 的 `latex(expr)` 把符号表达式输出为 LaTeX 数学源码；这不是完整的 TEX 文档，也不意味着可以从输出无损还原原表达式。下面是 API 片段：

```python
from sympy import latex, symbols

x = symbols("x")
tex_source = latex(x**2)
print(tex_source)  # x^{2}
```

反向解析可使用 `sympy.parsing.latex.parse_latex`。SymPy 文档将 LaTeX 解析标为实验功能：TeX 首先是排版语言，记法可能有歧义；解析器只接受其语法覆盖的数学表达式，不能解析任意宏包、整份文档或自定义命令。ANTLR 后端还需要相应的 Python 运行时依赖，具体后端和依赖按所用 SymPy 版本的文档检查。下面同样是依赖 SymPy 和所选解析后端的 API 片段：

```python
from sympy.parsing.latex import parse_latex

expr = parse_latex(r"\frac{1}{x}")
print(expr)
```

另一个方向是将有限范围的 Python 计算步骤排成公式。`handcalcs` 面向 Jupyter 单元格中的算术计算，可用 `%%tex` 输出 LaTeX；它不是把任意 Python 程序转换成 LaTeX 的编译器。下面展示两个 Jupyter 单元格：先运行导入单元格，再在另一个单元格首行写魔法命令。这是 API 片段，不是普通 Python 脚本：

```python
import handcalcs.render
from math import sqrt
```

另一个 Jupyter 单元格：

```python
%%tex
a = 2 / 3 * sqrt(9)
```

符号打印器、LaTeX 解析器和计算步骤排版器输出用途不同；需要验证公式含义时，应将表达式送入独立的符号或数值检查，不能只比较排版结果。

## 展示代码

代码可以用 `verbatim` 原样显示。需要语法高亮或行内选项时，可使用 `listings` 宏包；宏包必须在导言区加载：

```latex
\usepackage{listings}

\begin{lstlisting}[language=Python]
def add(left, right):
    return left + right
\end{lstlisting}
```

围栏语言名、行号、边框、颜色等属于展示设置，不会替代码做语法检查或执行。长代码要考虑分页和行宽；正式文档常把完整程序放在独立文件或附录中。

## 参考资料

- [CTAN：amsmath 宏包](https://ctan.org/pkg/amsmath)
- [CTAN：listings 宏包](https://ctan.org/pkg/listings)
- [Overleaf：Tables](https://www.overleaf.com/learn/latex/Tables)
- [Overleaf：Bibliography management in LaTeX](https://www.overleaf.com/learn/latex/Bibliography_management_in_LaTeX)
- [SymPy：Printing](https://docs.sympy.org/latest/modules/printing.html)
- [SymPy：Parsing](https://docs.sympy.org/latest/modules/parsing.html)
- [handcalcs：README](https://github.com/connorferster/handcalcs)
