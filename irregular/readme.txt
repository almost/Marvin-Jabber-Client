Irregular Windows (Irregular.ew)
14 Jan 2001

Thomas Parslow (PatRat)
patrat@rat-software.com


This should be fairly easy to use... I hope :)

REQUIRMENTS

Irregular.ew has no requirements (apart from windows) but the demo (Irregular.exw) requires win32lib

INTRODUCTION

For this method of making irregular shaped windows you must first create a region then associate it with the window. Regions can be created using a number of functions, but they can also be made by combining 2 or more regions into one or cutting one from another. NOTE: all coordinates are always relative to the top left hand corner of the WINDOW.

FUNCTIONS/PROCEDURES

ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ<CreatePolygonRgn>ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

Syntax:      include irregular.ew
             a = CreatePolygonRgn(p)

Description: Creates and returns a polygon region from a number of points supplied in
             the p argument using the format {{x1,y1},{x2,y2},{x3,y3}...

Comments:    The region returned from CreatePolygonRgn() can immediately be associated
             with a window or it can be combined with other regions.
             
Example:

             include irregular.ew
             atom Region
             
             Region = CreatePolygonRgn({200,0},{0,400},{400,400}}))
             

ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ<CreateRoundRectRgn>ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

Syntax:      include irregular.ew
             a = CreateRoundRectRgn(x,y,width,height,corners)

Description: Creates and returns a rectangle region with rounded corners. The corners
             argument specifies the size of the rounded corners.

Comments:    The region returned from CreateRoundRectRgn() can immediately be associated
             with a window or it can be combined with other regions. The x and y arguments
             would normally be 0 and width and height arguments would be the same as the window.
             30 is a good value to start with for the corners argument.
             
Example:

             include irregular.ew
             atom Region
             
             Region = CreateRoundRectRgn(0,0,400,400,30)
             
             
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ<CreateEllipticRgn>ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

Syntax:      include irregular.ew
             a = CreateEllipticRgn(x,y,width,height)

Description: Creates and returns a elliptic (circle) region.

Comments:    The region returned from CreateEllipticRgn() can immediately be associcated
             with a window or it can be combined with other regions.
             
Example:

             include irregular.ew
             atom Region
             
             Region = CreateEllipticRgn(0,0,400,400)
             

ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ<CombineRegions>ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

Syntax:      include irregular.ew
             a = CombineRegions(s)

Description: Combines and returns all the regions specified in the s argument using the
             form: {region1,region2,region3....

Comments:    All the regions passed CombineRegions() are deleted once they have been used
             to create the combined region. The returned region can immediately be associated
             with a window or it can be combined with other regions.
             
Example:

             include irregular.ew
             atom Region,Region1,Region2
             
             --Create regions 1 and 2 here
             
             Region = CombineRegions({Region1,Region2})

             --Regions 1 and 2 have now been deleted
             
             
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ<CutRegion>ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

Syntax:      include irregular.ew
             a = CutRegion(base,cutter)

Description: Cuts the regions specified by the cutter argument from the region specified
             in the base argument.

Comments:    Both the regions passed CutRegion() are deleted once they have been used to
             create the combined region. The returned region can immediately be associated
             with a window or it can be combined with other regions.
             
Example:

             include irregular.ew
             atom Region,Region1,Region2
             
             --Create regions 1 and 2 here
             
             Region = CutRegion(Region1,Region2)

             --Regions 1 and 2 have now been deleted
             
             
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ<SetWindowRgn>ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

Syntax:      include irregular.ew
             SetWindowRgn(hwnd,region)

Description: Associates a region with a window (specified in the hwnd argument)

Comments:    You can get the hwnd of a window in win32lib with the getHandle(id) function
             
Example:

             include irregular.ew
             atom Region,Window
             
             --Create region and Window here
             
             SetWindowRgn(getHandle(Window),Region)
         