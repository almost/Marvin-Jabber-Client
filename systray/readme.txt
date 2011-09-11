System Tray Icon
Thomas Parslow (PatRat)
patrat@rat-software.com
21st November 2001

INTRODUCTION
------------

This include file is used to display icons in the system tray (the bit next to the clock on the task bar, AKA the taskbar notification area). It uses win32lib.


USE
---

First create the system tray icon using the systray_Create function, you need to pass a win ID (from win32lib) to it and it returns the ID of the icon:

   constant SysTray = systray_Create(Window1)

Then you need to set it's icon using the systray_SetIcon producedure, just pass the ID and the name of the icon file you want to use:

   systray_SetIcon(SysTray,"test.ico")

You can also set it's tooltip text using the systray_SetTip procedure:

   systray_SetTip(SysTray,"Hello world!")

Now you can show the icon in the system tray using the systray_Show procedure:

   systray_Show(SysTray)

Remember to hide it again before you close the app using the systray_Hide procedure:

   systray_Hide(SysTray)

To trap events for the icon set the event handler using systray_SetEvent, passing it the ID of the systray icon and a routine ID:

   systray_SetEvent(SysTray,routine_id("onsystray"))

The event handler should accept 2 parameters, the first is the ID of the systray icon and the second is a windows message:

   procedure onsystray(integer id, atom message)
       if message= WM_LBUTTONDOWN then
            if message_box("System tray icon left-clicked!","Systray.ew example",0) then end if
       elsif message= WM_RBUTTONDOWN then
           if message_box("System tray icon right-clicked!","Systray.ew example",0) then end if
       end if
   end procedure