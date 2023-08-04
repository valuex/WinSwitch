# WinSwitch
Switch window by incremental search
# Usage
-----

Action                         | Shortcut        | Remarks
------------------------------ | --------------- | ----------
Activate WinSwitch            | `F1`   | This shortcut can be customized in WinSwitch.ahk
Switch among current process windows            | `F3`     | This shortcut can be customized in WinSwitch.ahk
_When WinSwitch is open_      |                 |
Preview the selected window      | `UP` or `DOWN`         | use UP or DOWN to select the item, and the window will be bring to 2nd top-most accordingly.
Switch to selected window      | `Enter`         |
Close selected window          | `Ctrl + W`      | todo
Dismiss WinSwitch             | `Esc`           |
Define short name of process             |           | This can be set in the `Config.ini`


# Features
1. Incremental search
2. Search title by Chinese PinYin first letter is supported.
3. Add some prefined abbreviation for widely used software. This can be set in the `Config.ini`:
```
e  xx is to search Excel with the title of xx
w  xx is to search Word with the title of xx
p  xx is to search Powerpnt with the title of xx
f  xx is to search Explorer with the title of xx
```
the above mentioned abbreviation is predefined in the program  
4. Switch among current process windows. 
 - When the process has only one window, nothing will happen when press the HotKey .
 - When the process has only two windows, directly switch to the other one when press the HotKey .
5. Close the main window automatically when lose focus
6. Can preview the window when selecting item using UP or DOWN  in the listview.
# Todo
1. Auto switch IME to English mode when the the window pops-up [done, but not work perfectly, help needed]
2. Close selected window  
