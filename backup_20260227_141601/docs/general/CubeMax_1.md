# 项目
> 更新时间: 2026年02月27日

# 串口舵机控制

> 使用ROS通过串口向STM32发送命令，从而利用STM32控制舵机

- 舵机通过pwm波形控制

- 一个定时器可以产生一种周期的pwm波，而定时器的每个通道可以设置不同的占空比







# CubeMX

> 跟着教程学习
>
> [【STM32】HAL库 STM32CubeMX教程](https://blog.csdn.net/as480133937/article/details/98983268?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522168967143716800226523675%2522%252C%2522scm%2522%253A%252220140713.130102334.pc%255Fblog.%2522%257D&request_id=168967143716800226523675&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~blog~first_rank_ecpm_v1~times_rank-13-98983268-null-null.268^v1^koosearch&utm_term=STM32CubeMX%E6%95%99%E7%A8%8B&spm=1018.2226.3001.4450)

# 环境

安装包在百度网盘的软件cubemx里面



- 没有生成项目文件

原因是编辑了没有封装库的芯片，在help中添加相应的封装库就行了





# 问题

- 设置一些GPIO后NVIC里没有相应中断线

可能是bug，先跳到下面界面，再在右侧选择GPIO相应的中断模式，下面的EXIT line[XX:XX] interrrupts就弹出来了

![image-20230718173415920](Images/项目.assert/image-20230718173415920.png)

好吧搞错了，是中断边沿触发条件GPIO-MODE选错了

![image-20230718174614172](Images/项目.assert/image-20230718174614172.png)





- 调试时停在  `LDR R0, =SystemInit`

造成的影响就是重定向fgetc()后，单片机跑不起来，发不了串口(因为停在了这一句)

解决方法，如图所示：

当使用Keil调试时，程序停留在此处，且不能单步运行到初始化中去，可以打开魔术棒，如下操作：

[更多了解](https://blog.csdn.net/u014717398/article/details/55251859)





# GPIO

```c
/**
  * @brief  Toggles the specified GPIO pins.
  * @param  GPIOx Where x can be (A..K) to select the GPIO peripheral for STM32F429X device or
  *                      x can be (A..I) to select the GPIO peripheral for STM32F40XX and STM32F427X devices.
  * @param  GPIO_Pin Specifies the pins to be toggled.
  * @retval None
  */
GPIO_PinState HAL_GPIO_ReadPin(GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin)

/**
  * @brief  Sets or clears the selected data port bit.
  *
  * @note   This function uses GPIOx_BSRR register to allow atomic read/modify
  *         accesses. In this way, there is no risk of an IRQ occurring between
  *         the read and the modify access.
  *
  * @param  GPIOx: where x can be (A..G depending on device used) to select the GPIO peripheral
  * @param  GPIO_Pin: specifies the port bit to be written.
  *          This parameter can be one of GPIO_PIN_x where x can be (0..15).
  * @param  PinState: specifies the value to be written to the selected bit.
  *          This parameter can be one of the GPIO_PinState enum values:
  *            @arg GPIO_PIN_RESET: to clear the port pin
  *            @arg GPIO_PIN_SET: to set the port pin
  * @retval None
  */
void HAL_GPIO_WritePin(GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin, GPIO_PinState PinState)
=====关于gpio pin state:====
typedef enum
{
  GPIO_PIN_RESET = 0,
  GPIO_PIN_SET
}GPIO_PinState;
===========================

/**
  * @brief  Toggles the specified GPIO pin
  * @param  GPIOx: where x can be (A..G depending on device used) to select the GPIO peripheral
  * @param  GPIO_Pin: Specifies the pins to be toggled.
  * @retval None
  */
void HAL_GPIO_TogglePin(GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin)
    
/**
  * @brief  Locks GPIO Pins configuration registers.
  * @note   The locked registers are GPIOx_MODER, GPIOx_OTYPER, GPIOx_OSPEEDR,
  *         GPIOx_PUPDR, GPIOx_AFRL and GPIOx_AFRH.
  * @note   The configuration of the locked GPIO pins can no longer be modified
  *         until the next reset.
  * @param  GPIOx where x can be (A..F) to select the GPIO peripheral for STM32F4 family
  * @param  GPIO_Pin specifies the port bit to be locked.
  *         This parameter can be any combination of GPIO_PIN_x where x can be (0..15).
  * @retval None
  */
HAL_StatusTypeDef HAL_GPIO_LockPin(GPIO_TypeDef* GPIOx, uint16_t GPIO_Pin)
```



# 串口

![image-20230725025244950](Images/项目.assert/image-20230725025244950.png)

# 回调机制

cubemx的串口很有意思，它为了提高效率使用了回调的机制，官方生成的默认代码里会调用HAL_UART_IRQHandler(&huart1)函数，当IRQHandler触发后会判断是接收还是发送并形成中断调用各自的回调函数·所以我们可以直接改写相关回调函数

> https://blog.csdn.net/weixin_44322104/article/details/125210812

```c
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)//自定义回调函数 在UART_Receive_IT()中调用
{
	//判断是哪个串口触发的中断  huart1.Instance = USART1;定义在MX_USART1_UART_Init中
	if(huart==&huart1)//huart ->Instance == USART1两种判断条件等价
	{
		if((UART1_RX_STA & 0x8000)==0)//接收未完成&位运算符 &&短路与判断
		{
			if(UART1_RX_STA & 0x4000)//接收到 \r
			{
				if(Res==0x0a)//下一个必须是接收 \n
					UART1_RX_STA|=0x8000;
				else
					UART1_RX_STA=0;
			}
			else //未接收到\r
			{
				if(Res==0x0d)//Receive \r
				{
					UART1_RX_STA|=0x4000;
				}
				else
				{
					UART1_RX_Buffer[UART1_RX_STA&0X3FFF]=Res;
					UART1_RX_STA++;
					if(UART1_RX_STA>UART1_REC_LEN-1) UART1_RX_STA=0;//如果接收数据大于200Byte 重新开始接收
				}
			}
		}
		HAL_UART_Receive_IT(&huart1, &Res, 1);//完成一次接受，再此开启中断
	}
}
```

其他回调

```c
HAL_UART_IRQHandler(UART_HandleTypeDef *huart);        //串口中断处理函数
HAL_UART_TxCpltCallback(UART_HandleTypeDef *huart);    //串口发送中断回调函数
HAL_UART_TxHalfCpltCallback(UART_HandleTypeDef *huart);  //串口发送一半中断回调函数（用的较少）
HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart);    //串口接收中断回调函数
HAL_UART_RxHalfCpltCallback(UART_HandleTypeDef *huart);//串口接收一半回调函数（用的较少）
HAL_UART_ErrorCallback();                              //串口接收错误函数
```



# 重写fgetc()

```c
/**
  * 函数功能: 重定向c库函数printf到DEBUG_USARTx
  * 输入参数: 无
  * 返 回 值: 无
  * 说    明：无
  */
int fputc(int ch, FILE *f)
{
  HAL_UART_Transmit(&huart1, (uint8_t *)&ch, 1, 0xffff);
  return ch;
}
 
/**
  * 函数功能: 重定向c库函数getchar,scanf到DEBUG_USARTx
  * 输入参数: 无
  * 返 回 值: 无
  * 说    明：无
  */
int fgetc(FILE *f)
{
  uint8_t ch = 0;
  HAL_UART_Receive(&huart1, &ch, 1, 0xffff);
  return ch;
}
```



# 死锁问题

频繁触发中断消耗CPU，会造成丢失数据现象

用 [fifo](https://blog.csdn.net/little_grapes/article/details/121092291?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522169031364216800184130113%2522%252C%2522scm%2522%253A%252220140713.130102334.pc%255Fblog.%2522%257D&request_id=169031364216800184130113&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~blog~first_rank_ecpm_v1~times_rank-14-121092291-null-null.268^v1^koosearch&utm_term=STM32%2B&spm=1018.2226.3001.4450)

 [DMA](https://blog.csdn.net/little_grapes/article/details/121112475?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522169031364216800184130113%2522%252C%2522scm%2522%253A%252220140713.130102334.pc%255Fblog.%2522%257D&request_id=169031364216800184130113&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~blog~first_rank_ecpm_v1~times_rank-18-121112475-null-null.268^v1^koosearch&utm_term=STM32%2B&spm=1018.2226.3001.4450)

# PWM

同样的设置相应定时器

![image-20230724185130231](Images/项目.assert/image-20230724185130231.png)

![image-20230724185150325](Images/项目.assert/image-20230724185150325.png)

相关函数：

```c
HAL_TIM_PWM_Start(&htim3,TIM_CHANNEL_1);  //开启tim3的通道1
__HAL_TIM_SetCompare(&htim3, TIM_CHANNEL_1, pwmVal);    //修改比较值，修改占空比
```



测试用命令码

```c
250：
     55 AA A1 0C FA 00 FA 00 00 00 00 00 00 00 00 00 E0 0D 0A 
50：
     55 AA A1 0C 32 00 32 00 00 00 00 00 00 00 00 00 43 0D 0A
-90：
    55 AA A1 0C A6 FF A6 FF 00 00 00 00 00 00 00 00 64 0D 0A
-290：
    55 AA A1 0C DE FE DE FE 00 00 00 00 00 00 00 00 B5 0D 0A 
```





# 编码器

![image-20230719125252118](Images/项目.assert/image-20230719125252118.png)



![image-20230719125510894](Images/项目.assert/image-20230719125320386.png)

![image-20230719125510894](Images/项目.assert/image-20230719125510894.png)



```C
HAL_TIM_Encoder_Start(&htim2,TIM_CHANNEL_ALL);  //开启定时器 
HAL_TIM_Base_Start_IT(&htim2);                 //开启定时器中断

__HAL_TIM_GET_COUNTER(&htim2);             //获取计数值
__HAL_TIM_SET_COUNTER(&htim2,0);           //清零计数值
```





# I2C

![image-20230725014325319](Images/项目.assert/image-20230725014325319.png)

```c
HAL_I2C_Master_Receive(I2C_HandleTypeDef *hi2c, uint16_t DevAddress, uint8_t *pData, uint16_t Size, uint32_t Timeout);    //i2c读
```

> 功能：IIC读一个字节
> 参数：
>
> *hi2c： 设置使用的是那个IIC 例：&hi2c2
>
> DevAddress： 写入的地址 设置写入数据的地址 例 0xA0
>
> *pDat：a 存储读取到的数据
>
> Size： 发送的字节数
>
> Timeout： 最大读取时间，超过时间将自动退出读取函数
>
> 例子：
>
> ```c
> HAL_I2C_Master_Transmit(&hi2c1,0xA1,(uint8_t*)TxData,2,1000) ；;
> ```



```c
//i2c写
HAL_I2C_Mem_Write(I2C_HandleTypeDef *hi2c, uint16_t DevAddress, uint16_t MemAddress, uint16_t MemAddSize, uint8_t *pData, uint16_t Size, uint32_t Timeout);
/* 第1个参数为I2C操作句柄
   第2个参数为从机设备地址
   第3个参数为从机寄存器地址
   第4个参数为从机寄存器地址长度
   第5个参数为发送的数据的起始地址
   第6个参数为传输数据的大小
   第7个参数为操作超时时间 　　*/

```



# 定时器中断

![image-20230725014401242](Images/项目.assert/image-20230725014401242.png)

![image-20230725014104737](Images/项目.assert/image-20230725014104737.png)

![image-20230725014133187](Images/项目.assert/image-20230725014133187.png)

![image-20230725014148179](Images/项目.assert/image-20230725014148179.png)



```c
HAL_TIM_Base_Start_IT(&htim2);  //开启定时器

如果程序卡在这一句，那么在此之前加上
    
__HAL_TIM_CLEAR_FLAG(&htim2,TIM_FLAG_UPDATE);
```

```c
//重写回调函数
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
    static unsigned char ledState = 0;
    if (htim == (&htim2))
    {
        if (ledState == 0)
            HAL_GPIO_WritePin(GPIOE,GPIO_PIN_15,GPIO_PIN_RESET);
        else
            HAL_GPIO_WritePin(GPIOE,GPIO_PIN_15,GPIO_PIN_SET);
        ledState = !ledState;
    }
}
```



# 问题

# 进error hadle

```c
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
```

可能是我时钟没设置对，STM32F407原来使用HSE和PC13冲突了，改为使用HSI时钟就可以了



# 编码器计数一直在0，1徘徊

需要RCC选择HSE时钟，同时PWM选择内部时钟才有作用

![image-20230731034152655](Images/项目.assert/image-20230731034152655.png)



# 单片机reset后卡在ldr指令

> stm32 调试时卡在 LDR R0, =SystemInit不能进入main

*option中勾选Use MicroLIB就解决*

触发条件我测试到是cubemx开启串口后出现
