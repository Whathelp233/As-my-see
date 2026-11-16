# Markdown 公式与折叠

Markdown 是带有标记符号的纯文本格式。标题、列表、链接和代码围栏由渲染器解析；公式、表格和 HTML 的支持则可能是额外扩展。因此，同一个 Markdown 文件在不同网站或预览器中未必完全相同。下文注明 GitHub 特有的行为时，仅指 GitHub 的 Markdown 渲染。

## 数学公式

GitHub 使用 MathJax 渲染 LaTeX 风格的数学表达式。行内公式通常用一对美元符号包围；块级公式用独立行上的两个美元符号包围。GitHub 也支持用带 `math` 信息字符串的代码围栏显示块级公式。

````markdown
行内：$a_i^2 + b_j^2 = c^2$

块级：
$$
\sum_{k=1}^{n} \frac{1}{k^2}
$$

另一种块级写法：
```math
\sqrt{x^2 + y^2}
```
````

实际显示时，块级公式如下：

$$
\sum_{k=1}^{n} \frac{1}{k^2}
$$

常用写法包括：

| 目标 | 语法 |
| --- | --- |
| 希腊字母 | `\alpha`, `\Gamma` |
| 上下标 | `x_i`, `x^2`, `x_{i+1}` |
| 分数、根式 | `\frac{a+b}{c}`, `\sqrt{x}` |
| 求和、累乘、积分 | `\sum_{i=1}^{n} x_i`, `\prod_{i=1}^{n} x_i`, `\int_a^b f(x)\,dx` |
| 省略号 | `\ldots` 与基线对齐，`\cdots` 与数学中线对齐 |
| 矩阵 | `\begin{bmatrix}a&b\\c&d\end{bmatrix}` |
| 分段式 | `\begin{cases}x,&x\ge0\\-x,&x<0\end{cases}` |
| 公式内文字 | `\text{where}` |

复杂的上下标要用花括号标明完整范围，例如 `x_{i+1}`；如果省略花括号，通常只有紧邻的一个字符属于上下标。矩阵或分段式中的 `&` 用于对齐列，`\\` 用于换行。

GitHub 的数学语法不是完整的 LaTeX 文档编译器。它适合排版表达式，但不能据此假定任意宏包、导言区设置、自定义命令或文档环境都可用。换到其他 Markdown 平台时，先查看该平台的公式扩展和定界符规则。

### 定界符和围栏边界

公式符号与 Markdown 语法有时会冲突。GitHub 支持一种行内形式：用美元符号、反引号、表达式、反引号和美元符号依次包围公式，以减少与 Markdown 标记的歧义：

```markdown
表达式：$`\sqrt{3x-1}+(1+x)^2`$
```

如果文档中包含货币符号等字面美元符号，要按目标平台的规则转义或隔开，不能把它和公式定界符混用。把含公式语法的原文放进代码围栏展示时，围栏中的内容只作为示例文本，不会再被当作公式渲染。

代码围栏至少由三个相同的反引号或波浪号组成，闭合围栏要与开启围栏类型相同、长度不短于开启围栏。若示例内部本身含有三反引号，就用四个反引号包住外层示例，避免内层围栏提前结束外层代码块。

````markdown
这里演示一个包含代码块的 Markdown 片段：
```python
print("Markdown 里的示例代码")
```
外层用四个反引号，所以内层的三个反引号不会结束它。
````

给围栏增加 `python`、`latex`、`math` 等信息字符串可以提示语法高亮或公式渲染，但通常不会执行示例代码。具体效果由网站决定。

## 可折叠内容

GitHub 支持用 HTML 的 `<details>` 创建默认收起的区域，并用 `<summary>` 写摘要。该容器内可以放 Markdown 段落、标题、图片和代码块。

````markdown
<details>
<summary>展开查看示例</summary>

这里可以有普通 Markdown 内容。

```python
print("hello")
```

</details>
````

`<summary>` 后留一个空行，容器内的 Markdown 更容易按预期解析。需要默认展开时，可在 `<details>` 标签上使用 `open` 属性。HTML 标签及其表现依赖目标平台的过滤与渲染策略，不要把 GitHub 的显示结果直接推广到所有 Markdown 编辑器。

## 检查清单

- 在最终发布的平台预览标题、公式、表格、代码和折叠区域。
- 数学内容只放进数学定界符；需要展示公式源码时放进围栏代码块。
- 每个代码围栏都有配对的闭合围栏，嵌套示例用更长的外层围栏。
- 不能从语法高亮推断代码已经运行，也不能从公式正常显示推断完整 LaTeX 文档能够编译。

## 参考资料

- [GitHub：Writing mathematical expressions](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/writing-mathematical-expressions)
- [GitHub：Organizing information with collapsed sections](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections)
- [GitHub Flavored Markdown 规范：Fenced code blocks](https://github.github.com/gfm/#fenced-code-blocks)
