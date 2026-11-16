# LaTeX 入门与排版

LaTeX 将内容、结构和排版规则写在纯文本源文件中，再由 TeX 引擎编译成 PDF 等输出。文档类决定整体结构和默认样式；宏包提供额外能力；正文用命令和环境描述内容。使用模板时，应先遵守模板的文档类和编译说明。

## 文档骨架

一个最小的中文示例：

```latex
\documentclass{ctexart}
\usepackage{amsmath}

\title{一份短文档}
\author{}
\date{\today}

\begin{document}
\maketitle
\tableofcontents

\begin{abstract}
摘要简要说明文章讨论的内容。
\end{abstract}

\section{开始}
这是正文。可以用\textbf{加粗}或\textit{斜体}强调文字。\footnote{这是一个脚注。}

空一行开始新段落。

\subsection{公式}
\[
  x^2 + y^2 = z^2
\]

\begin{itemize}
  \item 无序列表项
  \item 另一项
\end{itemize}

\end{document}
```

`\documentclass` 选择文档类。`ctexart` 是中文文章类；其他常见中文类包括 `ctexrep` 和 `ctexbook`。导言区位于 `\documentclass` 与 `\begin{document}` 之间，用于加载宏包、填写元数据和设置全局样式。`\begin{document}` 到 `\end{document}` 之间是正文；结束标记后的内容不会进入文档。

标题信息用 `\title`、`\author`、`\date` 设置，再由 `\maketitle` 生成。日期命令是 `\date`。宏包应在导言区加载，例如 `\usepackage{graphicx}`。

含中文的文档需要匹配合适的引擎、类和字体。常见做法是使用 XeLaTeX 或 LuaLaTeX，并采用 `ctex` 文档类；具体字体是否可用取决于编译环境。不能只切换引擎而忽略模板的编译要求。

## 保留字符、摘要、目录与链接

在普通文字中，部分字符有特殊含义，需要加反斜线才能显示为字面字符：

| 字符 | 写法 |
| --- | --- |
| `#` | `\#` |
| `$` | `\$` |
| `%` | `\%` |
| `&` | `\&` |
| `_` | `\_` |
| `{`、`}` | `\{`、`\}` |

`%` 在源文件中开始注释；`&` 在表格和对齐公式中分隔列；`_` 在数学模式中表示下标。转义方法要结合所在环境使用。

摘要可用 `abstract` 环境，具体标题和位置由文档类控制。`\tableofcontents` 会依据章节标题生成目录；章节或引用更新后，可能需要重新编译以刷新目录和编号。脚注可在正文相应位置使用 `\footnote{脚注内容}`。

加载 `hyperref` 后，可以用 `\href{网址}{显示文字}` 创建可点击链接，也可用 `\url{网址}` 显示网址。以下为导言区与正文片段：

```latex
% 导言区，通常在其他宏包之后加载
\usepackage{hyperref}

% 正文
参见\href{https://www.latex-project.org/}{LaTeX 项目主页}。
```

## 段落、章节与列表

空行表示开始一个新段落。`\\` 是强制换行命令，适用于需要在同一结构内断行的场景；它不等同于新段落。章节层级取决于文档类：文章类通常从 `\section` 开始，书籍类可使用 `\part`、`\chapter`、`\section` 等。只使用文档类提供的层级命令，不要把未定义的命令名当作通用语法。

无序列表用 `itemize`，编号列表用 `enumerate`；每个条目以 `\item` 开始：

```latex
\begin{enumerate}
  \item 准备材料
  \item 写出结构
  \item 检查输出
\end{enumerate}
```

字体大小命令如 `\small`、`\large`、`\Large`、`\Huge` 会改变后续文字的尺寸。用花括号限定作用范围，避免大小设置意外影响后面的段落：

```latex
{\large 这一小段使用较大的字号。}
```

精确字号可通过 `\fontsize{字号}{基线距离}\selectfont` 设置；它只在选择了可用字体的环境中生效。若要调整间距，优先用章节、列表和段落等语义结构；手工插入很多 `\vspace` 或 `\hfill` 往往会让分页变化更难预测。

## 图片与浮动体

图片通常由 `graphicx` 宏包的 `\includegraphics` 插入。`figure` 是浮动环境，位置选项只是排版建议，最终位置可能因分页而改变。

```latex
% 导言区
\usepackage{graphicx}

% 正文
\begin{figure}[tbp]
  \centering
  \includegraphics[width=0.7\linewidth]{figures/example.pdf}
  \caption{示意图}
  \label{fig:example}
\end{figure}
```

图片文件路径相对于编译时的工作目录或项目设置。`width` 可用 `\linewidth` 等当前排版宽度作为参照。引用图片时，用唯一的标签并在正文中写 `图~\ref{fig:example}`；编译器通常需要再次运行，才能更新交叉引用。

## 注释与排错

百分号 `%` 使该行余下内容成为注释；若要在正文显示百分号，写成 `\%`。LaTeX 的错误信息通常包含文件位置和附近的命令。遇到错误时，先检查最近修改处是否有未配对的大括号、环境是否成对结束、宏包是否在导言区加载，再看日志中的首个错误，而不是只处理后续连锁报错。

## 参考资料

- [Overleaf：Learn LaTeX in 30 minutes](https://www.overleaf.com/learn/latex/Learn_LaTeX_in_30_minutes)
- [Overleaf：Table of contents](https://www.overleaf.com/learn/latex/Table_of_contents)
- [Overleaf：Hyperlinks](https://www.overleaf.com/learn/latex/Hyperlinks)
- [Overleaf：Footnotes](https://www.overleaf.com/learn/latex/Footnotes)
- [Overleaf：Chinese](https://www.overleaf.com/learn/latex/Chinese)
- [Overleaf：XeLaTeX](https://www.overleaf.com/learn/latex/XeLaTeX)
