# PyStand by hiroi-sora

[skywind3000/PyStand](https://github.com/skywind3000/PyStand) 是一个非常好用的Python独立部署环境，使用一个小巧的exe作为启动器拉起Python运行。可让Python代码在一台没有安装任何环境的机器上跑起来，极大方便了Python程序的打包和发布。

本项目基于原项目做了一些改动，在README中记录了一些我的经验和遇到的坑，并附带了一套使用 VS Code 开发内嵌式Python的解决方法（拥有完整的语法提示和调试功能）。

**使用案例： [Umi-OCR](https://github.com/hiroi-sora/Umi-OCR)**

---

本文可以指导小白通过PyStand部署项目，自定义项目名称和路径，享受愉快的Python开发体验。完事了可以轻松打包带走。不会C++或者Cmake也木有关系，这里提供了一键编译脚本。

不妨先看看 [原项目](https://github.com/skywind3000/PyStand) 的Readme。

下面将详细介绍本项目的特点和使用方法。

## 将环境初始化转移到外部脚本

在原版PyStand中，运行环境初始化是由内嵌在cpp中的一段Python代码字符串负责，这个字符串会作为`-c`启动参数传给Python解释器。所以如果想自己设置运行环境会比较麻烦，要重新编译exe。

为了便于自定义和修改环境配置（比如指定包的路径），我将环境初始化这部分工作转移到外部的启动脚本.py中进行。同时，这样可以兼顾使用 VS Code 在完全相同的环境中进行开发和调试。

## 自定义启动脚本及解释器路径

在原版PyStand中，启动脚本是与exe同级的 `PyStand.int` 或同名int文件。Python解释器路径则默认是`runtime`目录。

而在我的版本中，需要在 `PyStand.cpp` 开头指定启动脚本和Python解释器路径：

- `PYSTAND_STATIC_PATH` ：启动脚本路径
- `PYSTAND_RUNTIME_PATH` ：运行环境目录（即Python解释器的目录）

例：
```
#define PYSTAND_STATIC_PATH L"\\AppData\\main.py"
#define PYSTAND_RUNTIME_PATH "\\AppData\\.runtime"
```

上面这个例子中，我把解释器和脚本统统都放在 `AppData` 这个内容目录中，这样可以做到程序根目录下只有两个文件(夹)，更加简洁优雅。

建议将内容目录改成你项目的名字便于用户区分。比如项目叫 MyApp ，那么文件夹可以叫 `MyApp-data` 。

示例，可以是这样的结构（假设不封包）：
```
MyApp
├─ MyApp-data
│    ├─ .runtime
│    │    └─ Python解释器扔在这~
│    ├─ .site-packages
│    │    ├─ PyQt放在这~
│    │    └─ 其他Python模块也丢在这~
│    ├─ app
│    │    └─ 程序逻辑
│    ├─ assets
│    │    └─ 资源文件
│    ├─ ui
│    │    └─ 界面文件
│    ├─ utils
│    │    └─ 通用工具
│    └─ main.py
└─ MyApp.exe
```

当然，如果考虑封包和加密的话则可能不适用这种目录结构，可以参考原作者的 [文章](https://www.zhihu.com/question/48776632/answer/2336654649) 。

## 编译 PyStand.exe

配置好自己的启动脚本及解释器路径后就可以编译生成exe了，编译时可以指定生成32位还是64位程序。32位程序只能使用32位的Python解释器及模块（PyQt），64位同理。

提示：QT6（PySide6）只支持64位Win10以上系统，不支持32位系统或者64位Win7。
- 如果要用QT6，那么也必须编译64位PyStand。
- 如果要兼容Win7，那么必须使用QT5。可配合32位或64位PyStand。

#### 前期准备：

1. 安装Cmake、VS 2019。
2. 替换 `appicon.ico` 为你的程序图标。

#### 一键编译脚本：

运行 `build.bat` 即可，会自动编译为32位程序。

这个脚本将在`build/Release`目录下生成 `PyStand.exe` ，然后将exe拷贝到本目录下，重命名为与bat同名（`build.exe`）。

如果你想修改生成exe的名称，则改动bat的文件名即可，如改为 `我的程序.bat` 。

#### 手动编译：

```
在项目目录中打开cmd
```

构建工程，可自己调整参数或指定编译器

```cmd
# 创建 build 子目录，用于存储构建过程中生成的临时文件
mkdir build

# 指定构建目录为build，生成器为VS2019，生成32位exe，当前目录为根目录
cmake -B build -G "Visual Studio 16 2019" -A Win32 .
```

编译

```
# 生成到 build/Release 目录下
cmake --build build --config Release
```

## 配置Python运行和开发环境

完成以上步骤后，就可以抛开跟c++有关的东西，专注于我们的Python了。

> 后续的步骤也可以转移到一台空白的机器上进行，不需要安装VS或Python。
> 
> 比如可以在模拟生产环境/用户日常使用的环境中进行，以便及时发现兼容性问题，补充必要的运行库，及手动裁切Python模块。

### 下载Python嵌入式包

以32位为例：

1. 打开官网 https://www.python.org/downloads/windows/
2. Ctrl+F，搜索 `Python 3.8.10`
3. `Download Windows embeddable package (32-bit)` 下载32位嵌入式包
4. 最终得到一个 `python-3.8.10-embed-win32.zip` 。

### 搭建基础Python环境

1. 在合适的位置创建你Python项目的文件夹。（小技巧：为了保证日后的兼容性，可以特意在中文及含空格目录中开发，以便及时发现和处理路径兼容性问题。如 `E:/工程/My App/` 。）
2. 将之前编译得到的 `PyStand.exe` 复制过去。直接运行，应该会弹窗报错 `无法找到Python解释器……` ，就正常。
3. 创建目录： `AppData/.runtime` ，将刚下载好的Python嵌入式包解压进入。再创建一个 `.site-packages` 预留给未来放置第三方库。形成这样的结构：
    ```
    My Project
    ├─ AppData
    │    ├─ .site-packages
    │    └─ .runtime
    │           ├─ python38.dll
    │           ├─ python38.zip
    │           ├─ pythonw.exe
    │           ├─ ……一堆东西
    └─ PyStand.exe
    ```
    再运行PyStand，会弹窗报错 `无法找到启动脚本……` ，就正常。 
4. 在 `AppData` 目录下写一个简单的 `main.py` ：
    ```Python
    import os
    import sys

    # 重定向输出流到控制台窗口
    try:
        fd = os.open('CONOUT$', os.O_RDWR | os.O_BINARY)
        fp = os.fdopen(fd, 'w')
        sys.stdout = fp
        sys.stderr = fp
    except Exception as e:
        fp = open(os.devnull, 'w')
        sys.stdout = fp
        sys.stderr = fp

    # 向控制台输出
    print("Cmd: Hello PyStand!")


    # 定义一个消息弹窗函数
    def MessageBox(msg, info='Message'):
        import ctypes
        ctypes.windll.user32.MessageBoxW(None, str(msg), str(info), 0)
        return 0


    # 展示弹窗
    MessageBox("Msg: Hello PyStand!")
    ```
    直接运行，会展示弹窗 `Msg: Hello PyStand!` 。如果在控制台中运行，还会在控制台打印 `Cmd: Hello PyStand!` 。

### 搭建 VS Code 开发环境

由于我个人喜欢 VS Code ，就以它为例。如果你习惯用PyCharm或别的编辑器，应该也是可以的。

#### 下载 VS Code 

##### Win10/11 用户：

1. 打开官网： https://code.visualstudio.com/Download
2. 下载 System Installer x64
3. 安装过程中注意：建议勾选 `将“通过Code打开”操作添加到Windows资源管理器文件(目录)上下文菜单`

##### Win7 用户：

- `1.70.3`版是最后一个支持win7的版本，请在下述地址下载。（选Windows System）
- https://code.visualstudio.com/updates/v1_70

#### 安装插件

1. 打开 VS Code ，按 `Ctrl+Shift+X` 打开插件商店，搜索并安装 `Python` 。这是辅助语法高亮的插件。
2. 如果有需要，搜索并安装 `Chinese (Simplified)` 语言插件。
3. 关闭 VS Code 。

#### 配置环境

1. 在上文创建好的项目目录（假设是`My Project`）中，将本项目的 `VSCode Environment` 中的 `.vscode` 目录复制过去。形成这样的结构：
    ```
    My Project
    ├─ .vscode
    │    ├─ launch.json
    │    └─ settings.json
    ├─ AppData
    │    └─ ......
    └─ PyStand.exe
    ```
2. 文件管理器在 `My Project` 中，右键 → 通过Code打开。
3. VS Code中，点左上角`文件`→`将工作区另存为`，保存到 `.vscode` 目录中或者任意你喜欢的目录。以后你再次打开VS Code时，就可以直接在欢迎页面打开这个工作区了。
4. 修改一下 `.vscode` 目录中两个json配置文件，将启动脚本、解释器和第三方库的路径改为你自己的。需要修改的地方，已经用`//【改】……`的注释标出来了。其他条目就不要乱动。
5. 点F5调试程序。如果有弹窗 `Msg: Hello PyStand!` ，且VS Code内部的控制台打印了 `Cmd: Hello PyStand!` ，就说明VS Code开发环境已经配置好了。

### 安装pip

> 若你的机器上已经安装过常规版本Python可以跳过这一部分，用常规Python即可。

嵌入式Python默认是不带pip的。PyStand也不鼓励通过pip来安装模块，我们推荐手动配置和维护第三方模块。

不过，我们仍需要通过pip来方便下载第三方模块，为此，需要在嵌入式Python环境中安装pip。请参考以下步骤。

（记得挂好科学上网。）

1. 为了不影响原始环境，我们可以复制一份环境（`.runtime`文件夹）放在另外的目录下，命名为`runpip`。这份环境专门用来下载模块，与你的项目本体并不关联。
2. 安装pip，在控制台中执行下列操作：（建议在VS Code内置控制台进行）
    ```
    # 下载pip安装脚本到当前目录下
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py

    # 用runpip环境中的Python解释器运行该脚本
    runpip/python.exe get-pip.py
    ```
    如果最后输出类似 `Successfully installed pip-xxx` 说明安装成功了。
3. 添加路径：打开 `runpip/python38._pth` ，把`#import site`前面的#删掉，变成 `import site` 。保存。

### 下载模块

以 PySide2 为例，讲解如何下载、安装和使用模块。

1. 通过pip下载PySide2包（而不安装）。注意平台是win32。需要下载别的模块的话，将指令最后的PySide2改为你需要的包名。
    ```
    runpip/python.exe -m pip download --only-binary=:all: --platform win32 PySide2
    ```
2. 在runpip的同级目录就可以看到下载好了两个包。用压缩软件（如7z，winrar）可以直接打开它们，或者后缀改为.zip也能打开。
   ```
    ├─ PySide2-5.15.2.1-5.15.2-cp35.cp36.cp37.cp38.cp39.cp310-none-win32.whl
    └─ shiboken2-5.15.2.1-5.15.2-cp35.cp36.cp37.cp38.cp39.cp310-none-win32.whl
   ```
3. 在你的项目的AppData下（即`.runtime`同级目录）新建一个文件夹`.site-packages`，将以上两个包的本体解压进去。
   （比如`PySide2`是本体，必须导入；`PySide2-5.15.2.1.dist-info`则不需要。`shiboken2`也是同理。）

### 在代码中导入模块

将 main.py 的内容全删了，粘贴以下内容：

<details>
<summary>点击展开</summary>

```Python
def initRuntimeEnvironment(startup_script):
    """初始化运行环境。startup_script: 启动脚本路径"""
    import os
    import sys
    import site

    # 重定向输出流到控制台窗口
    try:
        fd = os.open('CONOUT$', os.O_RDWR | os.O_BINARY)
        fp = os.fdopen(fd, 'w')
        sys.stdout = fp
        sys.stderr = fp
    except Exception as e:
        fp = open(os.devnull, 'w')
        sys.stdout = fp
        sys.stderr = fp

    # 定义一个最简单的消息弹窗
    def MessageBox(msg, info='Message'):
        import ctypes
        ctypes.windll.user32.MessageBoxW(None, str(msg), str(info), 0)
        return 0
    os.MessageBox = MessageBox

    # 初始化工作目录和Python搜索路径
    script = os.path.abspath(startup_script)  # 启动脚本.py的路径
    home = os.path.dirname(script)  # 工作目录
    os.chdir(home)  # 重新设定工作目录（不在最顶层，而在UmiOCR-data文件夹下）
    for n in ['.', '.site-packages']:  # 将模块目录添加到 Python 搜索路径中
        path = os.path.abspath(os.path.join(home, n))
        if os.path.exists(path):
            site.addsitedir(path)

    # 初始化Qt搜索路径，采用相对路径，避免中文路径编码问题
    try:
        from PySide2.QtCore import QCoreApplication
        QCoreApplication.addLibraryPath('./.site-packages/PySide2/plugins')
    except Exception as e:
        print(e)
        os.MessageBox(f'addLibraryPath fail!\n\n{e}')
        os._exit(0)
    print('Init runtime environment complete!')


if __name__ == '__main__':
    initRuntimeEnvironment(__file__)  # 初始化运行环境

```

</details></br>

在VS Code编辑器中，如果 `from PySide2.QtCore import QCoreApplication` 这一句有语法高亮，没有波浪线，说明VS Code已经识别了第三方库。

按F5运行一下，如果输出`Init runtime environment complete!`，说明第三方库PySide2已经成功导入。

上述代码连带解决了PySide（PyQt同理）在中文路径下无法使用的问题。如果你不需要导入Qt，则将代码中“`初始化Qt搜索路径`”那段 try……except…… 删掉即可。

一个非常重要的事项：上述代码将程序的工作目录修改为了当前所在的路径（即`main.py`同级目录），而不是PyStand.exe所在的目录。如果你需要在代码中使用相对路径，要特别注意这一点。

### PyQt Hello World

在 `AppData` 下编写你项目的正式代码。举个例子，假设直接创建一个 `app.py` ：

```python
from PySide2.QtWidgets import QApplication, QLabel

app = QApplication([])
label = QLabel('Hello World!')
label.setFixedSize(800, 500)
label.show()

app.exec_()
```

然后，在初始化脚本 `main.py` 的最后来引用它：

```python
if __name__ == '__main__':
    initRuntimeEnvironment(__file__)  # 初始化运行环境

    # 进入程序正式入口
    import app
```

按F5运行一下试试，窗口显示出来了。

### QML Hello World

如果在中文路径运行qml，除了需要在main.py中初始化Qt搜索路径，还需要在创建qml引擎时初始化qml库路径。如下：

app.py
```python
import os
import sys
from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine

app = QGuiApplication(sys.argv)
engine = QQmlApplicationEngine()
engine.addImportPath("./.site-packages/PySide2/qml")  # 相对路径重新导入包
current_dir = os.path.dirname(os.path.abspath(__file__))  # 同级目录
engine.load(f"{current_dir}/app.qml")  # 启动同级目录下的app.qml
if not engine.rootObjects():
    sys.exit(-1)
sys.exit(app.exec_())
```

app.qml
```qml
import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    visible: true
    width: 800
    height: 500
    title: "Hello World!"

    Text {
        text: "Hello World!"
        anchors.centerIn: parent
    }
}
```

为了给qml提供语法补全，可以在VS Code插件商店中搜索并安装 `QML`、`QML Snippets` 等插件。

### 调试与发布

调试直接在VS Code中F5运行，支持断点等功能。发布则直接将代码连同exe压缩成一个文件即可，当然你也可以进一步封包和加密。

使用本方案的好处是调试与发布是完全相同的环境，VS Code调用了同一个Python解释器和第三方库文件，可以在开发阶段就检查出兼容性问题。

### 手动裁切模块

待填坑…………
