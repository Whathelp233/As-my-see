# Lambda表达式

>  lambda表达式（也称为lambda函数）是在调用或作为函数参数传递的位置处定义匿名函数对象的便捷方法。通常，lambda用于封装传递给算法或异步方法的几行代码 。
>
> lambda的工作原理是编译器会把一个Lambda表达式生成一个匿名类的**匿名对象**，并在类中**重载函数调用运算符**，实现了一个`operator()`方法。

```cpp
//一个简单的实例
#include <algorithm>
#include <cmath>

void abssort(float* x, unsigned n) {
    std::sort(x, x + n,
        // Lambda expression begins
        [](float a, float b) {
            return (std::abs(a) < std::abs(b));
        } // end of lambda expression
    );
}
```

在上面的实例中`std::sort`函数第三个参数应该是传递一个排序规则的**函数**，但是这个实例中直接将排序函数的实现写在应该传递函数的位置，省去了定义排序函数的过程，对于这种不需要复用，且短小的函数，直接传递函数体可以增加代码的可读性。



## Lambda表达式语法定义

<img src="/home/yuchen/图片/lamda.png" alt="lamda"  />

1. 捕获列表。`[]`是Lambda引出符。编译器根据该引出符判断接下来的代码**是否是Lambda函数**，捕获列表能够捕捉上下文中的变量以供Lambda函数使用。
2. 参数列表。**与普通函数的参数列表一致**。如果不需要参数传递，则可以连同括号“()”一起省略。
3. 可变规格。`mutable`修饰符， 默认情况下Lambda函数总是一个`const`函数，`mutable`可以取消其常量性。在使用该修饰符时，参数列表不可省略（即使参数为空）。
4. 异常说明。用于Lamdba表达式内部函数**抛出异常**。
5. 返回类型。 追踪返回类型形式声明函数的返回类型。我们可以在不需要返回值的时候也可以连同符号”->”一起省略。此外，在返回类型明确的情况下，也可以省略该部分，让编译器对返回类型进行推导。
6. lambda函数体。内容与普通函数一样，不过除了可以使用参数之外，还可以使用所有捕获的变量。





## Lambda表达式参数详解

### Lambda捕获列表

> Lambda表达式与普通函数最大的区别是，除了可以使用参数以外，Lambda函数还可以通过捕获列表访问一些上下文中的数据。
>
> 具体地，捕捉列表描述了上下文中哪些数据可以被Lambda使用，以及使用方式（以值传递的方式或引用传递的方式）。语法上，在“`[]`”包括起来的是捕获列表，捕获列表由多个捕获项组成，并以逗号分隔。捕获列表有以下几种形式：

- `[]`表示不捕获任何变量

```cpp
auto function = ([]{
		std::cout << "Hello World!" << std::endl;
	}
);

function();
```

- `[var]`表示值传递方式捕获变量`var`

```cpp
int num = 100;
auto function = ([num]{
		std::cout << num << std::endl;
	}
);

function();
```

- `[=]`表示值传递方式捕获所有**父作用域**的变量（包括`this`）

```cpp
int index = 1;
int num = 100;
auto function = ([=]{
			std::cout << "index: "<< index << ", " 
                << "num: "<< num << std::endl;
	}
);

function();
```

- `[&var]`表示**引用传递**捕捉变量`var`

```cpp
int num = 100;
auto function = ([&num]{
		num = 1000;
		std::cout << "num: " << num << std::endl;
	}
);

function();
```

- `[&]`表示引用传递方式捕捉所有父作用域的变量（包括`this`）

```cpp
int index = 1;
int num = 100;
auto function = ([&]{
		num = 1000;
		index = 2;
		std::cout << "index: "<< index << ", " 
            << "num: "<< num << std::endl;
	}
);

function();
```

- `[this]`表示值传递方式捕捉当前的`this`指针

```cpp
#include <iostream>
using namespace std;
 
class Lambda
{
public:
    void sayHello() {
        std::cout << "Hello" << std::endl;
    };

    void lambda() {
        auto function = [this]{ 
            this->sayHello(); 
        };

        function();
    }
};
 
int main()
{
    Lambda demo;
    demo.lambda();
}
```

- `[=, &]`

   拷贝与引用混合   

  - `[=, &a, &b]`表示以引用传递的方式捕捉变量`a`和`b`，以值传递方式捕捉其它所有变量。

```cpp
int index = 1;
int num = 100;
auto function = ([=, &index, &num]{
		num = 1000;
		index = 2;
		std::cout << "index: "<< index << ", " 
            << "num: "<< num << std::endl;
	}
);

function();
1234567891011
```



- `[&, a, this]`表示以值传递的方式捕捉变量`a`和`this`，引用传递方式捕捉其它所有变量。



不过值得注意的是，捕捉列表**不允许变量重复传递**。下面一些例子就是典型的重复，会导致编译时期的错误。例如：

- `[=,a]`这里已经以值传递方式捕捉了所有变量，但是重复捕捉`a`了，会报错的；
- `[&,&this]`这里`&`已经以引用传递方式捕捉了所有变量，再捕捉`this`也是一种重复。

如果Lambda主体`total`通过引用访问外部变量，并`factor`通过值访问外部变量，则以下捕获子句是等效的：

```cpp
[&total, factor]
[factor, &total]
[&, factor]
[factor, &]
[=, &total]
[&total, =]
```



### Lambda参数列表

> 除了捕获列表之外，Lambda还可以接受输入参数。参数列表是可选的，并且在大多数方面类似于函数的参数列表。

```cpp
auto function = [] (int first, int second){
    return first + second;
};
	
function(100, 200);
```



### 可变规格mutable

`mutable`修饰符， 默认情况下Lambda函数总是一个`const`函数，`mutable`可以取消其常量性。在使用该修饰符时，参数列表不可省略（即使参数为空）。

```cpp
#include <iostream>
using namespace std;

int main()
{
   int m = 0;
   int n = 0;
   [&, n] (int a) mutable { m = ++n + a; }(4);
   cout << m << endl << n << endl;
}
12345678910
```



### 异常说明

你可以使用 `throw()` 异常规范来指示 Lambda 表达式不会引发任何异常。与普通函数一样，如果 Lambda 表达式声明 C4297 异常规范且 Lambda 体引发异常，Visual C++ 编译器将生成警告 `throw()` 。

```cpp
int main() // C4297 expected 
{ 
 	[]() throw() { throw 5; }(); 
}
```

在MSDN的异常规范中，明确指出异常规范是在 C++11 中弃用的 C++ 语言功能。因此这里不建议不建议大家使用。



### 返回类型

Lambda表达式的**返回类型会自动推导**。除非你指定了返回类型，否则不必使用关键字。返回型类似于通常的方法或函数的返回型部分。但是，返回类型必须在参数列表之后，并且必须在返回类型->之前包含类型关键字。如果Lambda主体仅包含一个`return`语句或该表达式未返回值，则可以省略Lambda表达式的`return-type`部分。**如果Lambda主体包含一个`return`语句，则编译器将从`return`表达式的类型中推断出`return`类型**。否则，编译器将返回类型推导为`void`。

```cpp
auto x1 = [](int i){ return i; };
```





### Lambda函数体

Lambda表达式的Lambda主体（标准语法中的复合语句）可以包含普通方法或函数的主体可以包含的任何内容。普通函数和Lambda表达式的主体都可以访问以下类型的变量：

- 捕获变量
- 形参变量
- 局部声明的变量
- 类数据成员，当在类内声明`this`并被捕获时
- 具有静态存储持续时间的任何变量，例如全局变量

```cpp
#include <iostream>
using namespace std;

int main()
{
   int m = 0;
   int n = 0;
   [&, n] (int a) mutable { m = ++n + a; }(4);
   cout << m << endl << n << endl;
}
```







# Lambda表达式的优缺点

## Lambda表达式的优点

- 可以直接在需要调用函数的位置定义**短小精悍的函数**，而不需要预先定义好函数

```cpp
std::find_if(v.begin(), v.end(), [](int& item){return item > 2});
1
```

- 使用Lamdba表达式变得更加紧凑，**结构层次更加明显、代码可读性更好**

## Lambda表达式的缺点

- Lamdba表达式语法比较灵活，增加了阅读代码的难度
- 对于函数复用无能为力