Windows 2000 Alpha Blending Example
Thomas Parslow (PatRat)
patrat@rat-software.com
2nd December 2001

INTRODUCTION
------------

This include file can be used to make a window semi-transparent. It uses the GDI's Alpha Blending which is only available in Windows 2000 (and XP of course), in previous windows versions it will just do nothing.

The routines in the include do not require win32lib although the example does.


USE
---

global function alphablend_Supported()
   Returns true if alpha blending is supported on this platform. NOTE: If you call any of the other routines on an unsuported platform nothing will happen.

global procedure alphablend_SetWinAlpha(atom hWnd, integer alpha)
   Sets the windows Alpha value to alpha. alpha can be from 0 (transparent) to 255 (opaque). -1 will turn of alpha transparency.

global procedure alphablend_SetWinTransColor(atom hWnd, atom color)
   Sets the windows transparent color to color. Use win32lib's rgb(red,green,blue) to get a color value. Pass -1 as the color value to turn of color transparency.