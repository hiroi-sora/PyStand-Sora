@REM 若build目录不存在
if not exist build (

    @REM 创建构建目录
    mkdir build

    @REM 指定构建目录为build，生成器为VS2019，生成32位exe，当前目录为根目录
    cmake -B build -G "Visual Studio 16 2019" -A Win32 .

)

@REM 构建生成到 build/Release 目录下
cmake --build build --config Release

@REM 将生成的exe复制到本目录，改名为与这个bat同名
copy build\Release\PyStand.exe "%~n0".exe