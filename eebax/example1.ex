include eebax.e

without warning

-- This is the first example created in the usage tutorial in readme.html

-- To use EEBAX you must first create a parser instance, you can do
-- this with the eebax_NewInstance function:

    atom eebax
    eebax = eebax_NewInstance()
    
-- Each instance can only proccess one document at a time but you can
-- create as many instances as you need.

-- Now add some event handlers for the events you wish to proccess (see
-- below for a full list of availble events), these will be called as the
-- document is parsed:

    procedure onStartElement(integer hInst,sequence Uri, sequence LocalName, sequence QName, sequence Atts)
        puts(1,"Start Element: " & QName & "\n")
    end procedure

    procedure onEndElement(integer hInst,sequence Uri, sequence LocalName, sequence QName)
        puts(1,"End Element: " & QName & "\n")
    end procedure

    procedure onCharacters(integer hInst,sequence Chars)
        puts(1,"Character Data: " & Chars & "\n")
    end procedure

-- Next assign the events to the apropriate handlers:

    eebax_SetStartElementEvent(eebax,routine_id("onStartElement"))
    eebax_SetEndElementEvent(eebax,routine_id("onEndElement"))
    eebax_SetCharactersEvent(eebax,routine_id("onCharacters"))

-- When you are ready to start proccessing an XML document call the eebax_StartDocument
-- procedure, this prepares the instance to recieve a document: 

    eebax_StartDocument(eebax)

-- Next call eebax_Parse one or more times until you have passed the whole document to it,
-- as you call eebax_Parse the events you definded above will be called appropriately. eebax_Parse
-- will normaly return 1 but if there is a parser error it will return 0 (in addition to calling
-- the Error event if it is handled).

    atom fn
    sequence in
    
    fn = open("test.xml","rb") 
    if fn = -1 then
        puts(1,"Unable to open test.xml")
        abort(1)
    end if
    while 1 do
        -- We're reading in one kilobyte at a time from the file
        in = get_bytes(fn,1024)
        if not eebax_Parse(eebax,in) then
            puts(1,"XML document invalid")
            abort(1)
        end if
        if length(in) < 1024 then
            exit
        end if
    end while
    -- Close the file
    close(fn)
    
-- When you have passed the whole document to eebax_Parse call eebax_EndDocument, the EEBAX instance
-- will be set back to the state it was when you first created it and can be used to parse further XML
-- documents.

    eebax_EndDocument(eebax)
    
-- Finnaly, when you no longer have any use for the parser instance you should destroy it with 
-- eebax_DestroyInstance:

    eebax_DestroyInstance(eebax)

-- This will free up any resources used.