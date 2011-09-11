include eebax.e

without warning

-- This is the second example created in the usage tutorial in readme.html


-- To have EEBAX create XML for you first create an instance of the parser as
-- you would when for parsing a document, then create a handler to handle the
-- outputed XML:

    atom eebax
    eebax = eebax_NewInstance()

    -- All this example handler does is print the XML to the console,
    -- hovever it could be written to do something else with it
    procedure onXML(integer hInst, sequence XML)
        puts(1,XML)
    end procedure

    eebax_SetXMLEvent(eebax,routine_id("onXML"))

-- Note that the XML event will be called multiple times for a single document.

-- Call the eebax_StartDocument to start a new XML document then call XML creation
-- routines until your document is finished.</p>
        eebax_StartDocument(eebax)
        -- Start a non-empty (must have closing tag) element
        eebax_StartElement(eebax,"toplevel",{{"attribute1","value1"},{"attribute2","value2"}},0)
        eebax_StartElement(eebax,"empty",{},1)
        eebax_StartElement(eebax,"secondlevel",{},0)
        eebax_Characters(eebax,"Character content")
        eebax_EndElement(eebax,"secondlevel")
        eebax_EndElement(eebax,"toplevel")
        eebax_EndDocument(eebax)
        
eebax_DestroyInstance(eebax)