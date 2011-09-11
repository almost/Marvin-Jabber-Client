Window Draging/Resizing Library
 The library allows you to drag or resize a window from any part of the window
 It's usefull for windows without title bars

Thomas Parslow (PatRat)
patrat@rat-software.com
21/March/2001
http://www.rat-software.com/projects.html

21/March/2001 UPDATE: Only just released a couple of hours ago and allready I've found a bug :( It had a slight problem when used with a window with a title bar (as in example1.exw). Fixed now
28/March/2001 UPDATE: Thanks to EUMAN for pointing out that you need to use releaseDC(Screen) to release a screen DC (no reaseDC(sDC))
28/March/2001 UPDATE: Now draws the focus rect the same thickness as border of the window being moved/resized.
29/March/2001 UPDATE: Should look better when used with my irregular.ew library. If you cut half of the window off it won't show the focus over the bit you removed
 
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴<dragwin_BeginMove>컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

 Syntax:      include dragwin.e
              dragwin_BeginMove(win)

 Description: Must be called from a LeftDown mouse event, takes control of the
 	      mouse and allows the user to move the window around the screen

 Example:
              --From example1.exw
              procedure Win_onMouse(atom event,atom x, atom y, atom shift)
	      	if event = LeftDown then
	      	  dragwin_BeginMove(Win)
	      	end if
	      end procedure
              
              
 See Also:    dragwin_BeginResize
 
 
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴�<dragwin_BeginResize>컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

 Syntax:      include dragwin.e
              dragwin_BeginResize(win,area,min,max)

 Description: Must be called from a LeftDown mouse event, takes control of the
 	      mouse and allows the user to resize window.
 	      Area specfies which area the user is draging from, it can be one of
 	      the following:
 	      
		dragwin_TOPLEFT
		dragwin_TOPRIGHT
		dragwin_BOTTOMLEFT
		dragwin_BOTTOMRIGHT
		dragwin_TOP
		dragwin_BOTTOM
		dragwin_LEFT
		dragwin_RIGHT
		
 	      min and max are both two element sequences which control the minimum
 	      and maximum size the window can be draged to.

 Example:

              --From example2.exw
	      dragwin_BeginResize(Win,                 --id of the window being resized
				  dragwin_BOTTOM,      --this indicates where the it's being resized from
				  {220,85},	       --Minimum dimensions
				  {600,600})           --Maximum dimensions
              
              
 See Also:    dragwin_BeginMove