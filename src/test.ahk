#include <notes>
#include <note>

ns := Notes('D:\francois\Docs\HotStrings\Notes')
for n in ns {
    OutputDebug(n.Title '`n')
}