# AwesomeCompileScript


<div align=center>
<img src="http://moguimg.u.qiniudn.com/p1/161018/idid_ifqtsytbmzqtoztbmizdambqgyyde_1238x1300.jpg" width = "600" height = "660" alt="" />
</div>


## Why

主客或是业务方的Demo编译时间实在无法忍受，每次拉完代码，pod update后再编译简直是个噩梦，那么有没有可能转变下策略，压缩这块等待的时间呢。
## Idea
想着搞了七年通信，是不是可以借鉴下TDM的思想，把碎片时间利用起来或是系统起一个polling进程，在后台默默的帮你编译好，真正run的时候只需要link每个模块就好了。
## How
既然思路有了，就差开始写代码了😈，整理下思路看看需要哪些操作。


### 1.why recompile

首先要搞清楚为什么要重新编译，编译前的条件是什么？答案很明显——需要获取最新的代码。因此我们首先需要有个自动pull的脚本，还要找出每个repo的`当前branch`来拉代码。

为什么要先去拉代码呢？比如我们支付Demo中的Podfile中是这样的写法

```

  pod 'MGJPFFoundation', :path => '../MGJPFFoundation/'
  pod 'MGJPFPay', :path => '../MGJPFPay/'
  pod 'MGJPFWallet', :path => '../MGJPFWallet/'
  pod 'MGJPFSecurityCenter', :path => '../MGJPFSecurityCenter/'
  pod 'MGJPFFinance', :path => '../MGJPFFinance/'
  pod 'MGJPFBaifumei', :path => '../MGJPFBaifumei/'


```

如果不先将每个组件的最新代码拉一边的话，那么编译其实是没有什么意义的，因为后面可能还得需要挨个拉一边代码，然后在pod update,再编译。

### 2.pod update?
是否需要在`编译前`进行`pod update`呢？这个需要视情况而定。比如你当前正在业务组件的Demo中撸代码，忽然后台进程给你悄悄地pod update了，那只能默默哭了😢，因此这里需要判断一下要进行`pod update`操作的xx.xcworkspace是否已经打开，如果打开了，那么就跳过 `pod update`。[**这里判断某个xcworkspace是否是打开的状态，花了好长时间**(´°̥̥̥̥̥̥̥̥ω°̥̥̥）**，各种的ps -e ps aux lsof 都不成功，因为执行I/O操作后读写进程就结束了**］
### 3.how to complile without Xcode
很明显既然是通过脚本，肯定是通过`xcodebuild命令行`来做［**xctool需要安装，并且目前针对Xcode8GM进行更新**］。

思路也非常简单，首先将需要的组件放到同一个目录下，比如我们的支付组件的目录结构类似下面这样

```
BobdeMacBook-Pro:MGJPF bob$ pwd
/Users/bob/Mogujie/MGJPF
BobdeMacBook-Pro:MGJPF bob$ ls
MGJPFBaifumei		MGJPFShell		mgjpffoundationfwk_ios
MGJPFDemo		MGJPFVendors_iOS	mgjpffoundationsdk_ios
MGJPFFinance		MGJPFWallet		mgjpfpayfwk_ios
MGJPFFoundation		MGJReactiveCocoa	mgjpfpaysdk_ios
MGJPFPay		mgjpffinancefwk_ios	testmgjpf
MGJPFSecurityCenter	mgjpffinancesdk_ios

```

然后遍历每个repo，找到每个repo下的`podfile`文件所在路径，然后找出`*.xcworkspace`，判断该repo下的`*.xcworkspace`是否已经打开，进而决定是否需要`pod update`，然后通过xcodebuild编译**［这里有个小坑：通过xcodebuild进行编译时需要获取 `scheme` 因此这里需要通过一些指令解析xcworkspace文件找出scheme］**
### 4.polling process

如何体现TDM的思想，利用空闲时刻轮询执行脚本呢？**`crontab`**,只需要通过crontab指令就可以实现轮询执行。

## Example

还是以我们的支付组件为例，结构目录如下

```
BobdeMacBook-Pro:MGJPF bob$ pwd
/Users/bob/Mogujie/MGJPF
BobdeMacBook-Pro:MGJPF bob$ ls
MGJPFBaifumei		MGJPFShell		mgjpffoundationfwk_ios
MGJPFDemo		MGJPFVendors_iOS	mgjpffoundationsdk_ios
MGJPFFinance		MGJPFWallet		mgjpfpayfwk_ios
MGJPFFoundation		MGJReactiveCocoa	mgjpfpaysdk_ios
MGJPFPay		mgjpffinancefwk_ios	testmgjpf
MGJPFSecurityCenter	mgjpffinancesdk_ios

```
所有的组件存在 **`/Users/bob/Mogujie/MGJPF`**目录下

脚本文件随意放置，比如脚本位置为 **[/Users/bob/pollBuild.sh](http://gitlab.mogujie.org/senmiao/AwesomeCompileScript/raw/master/pollBuild.sh)**

### 显式执行

如果你只是想测试一下效果，显式执行这个脚本的话，只需打开终端，输入

	sh /Users/bob/pollBuild.sh /Users/bob/Mogujie/MGJPF
	
即可看到终端输出。

### 隐式轮询执行

如果你想在后台起一个进程，设定的轮询周期为周一到周五9:00——21:00每隔半小时执行一次脚本。可以通过下面指令执行

输入 

	crontab -e
	
会进入vi编辑状态

然后输入[**`注意有空格`**]

	*/30 9-21 * * 1-5 sh /Users/bob/pollBuild.sh /Users/bob/Mogujie/MGJPF
	

这样就可以在后台默默执行。每次执行前会有类似下面这样的提示


<img src="http://moguimg.u.qiniudn.com/p1/161018/idid_ifrtmobrgyzgiztbmizdambqhayde_1444x424.jpg" width = "400" height = "120" alt="" />

关于crontab的时间格式可以参考[这个](http://www.atool.org/crontab.php)
### Final


使用这个脚本的目的在于加速编译，节省大家开发等待的时间，但是个人认为最优的解决方案还是推动所有组件能支持静态库打包。而对于业务方各自的开发Demo，使用这个脚本同样
