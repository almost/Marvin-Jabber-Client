-- XMLTREE - Library for building XML Trees in memory using EEBAX
-- Copyright (c) Thomas Parslow 2002
-- tom@almostobsolete.net

-- I apologize for the lack of documentation for this file, the only documentation available
-- is the comments (though there are quite of few of them) and the example program (xmltree_viewxml.exw).

-- --------------------------------------------------------------------------
--
-- License
--
-- The contents of this file are subject to the Jabber Open Source License
-- Version 1.0 (the "License").  You may not copy or use this file, in either
-- source code or executable form, except in compliance with the License.  You
-- may obtain a copy of the License at http://www.jabber.com/license/ or at
-- http://www.opensource.org/.  
--
-- Software distributed under the License is distributed on an "AS IS" basis,
-- WITHOUT WARRANTY OF ANY KIND, either express or implied.  See the License
-- for the specific language governing rights and limitations under the
-- License.
--
-- Copyrights
-- 
-- Copyright (c) Thomas Parslow 2002 unless otherwise stated
-- 
-- --------------------------------------------------------------------------

-- If you need to do something with this library that is prohibited by the License then contact me, I'm sure we can work it out :)

-- The include path below is the only differnece between the version of this file used by Marvin and this version
include eebax.e
--include eebax.e
without warning

sequence CurrentNode
constant CN_HINST    = 1,
         CN_NODE     = 2 --0 for root
CurrentNode = {}

sequence Nodes
constant N_ID        = 1,
         N_HINST     = 2,
         N_URI       = 3,
         N_LOCALNAME = 4,
         N_QNAME     = 5,
         N_PARENT    = 6,
         N_DEPTH     = 7,
         N_ATTS      = 8,
         N_CHILDREN  = 9,
         
         NEW_NODE = {0,0,"","","",0,0,{},{}}
Nodes = {}

atom NextID
NextID = 1

object LastError
LastError = 0

constant EEBAX = eebax_NewInstance() --for xmltree_Parse

-- BEGIN Utility routines
function sub_find(object fnd, sequence in, integer sub_element)
    for i = 1 to length(in) do
        if equal(fnd,in[i][sub_element]) then
            return i
        end if
    end for
    return 0
end function

function cutseq(sequence s, integer i)
    return s[1..i-1]&s[i+1..length(s)]
end function
-- END Utility routines

-- BEGIN EEBAX event handlers
global procedure xmltree_onEndDocument(integer hInst)

end procedure

global procedure xmltree_onStartDocument(integer hInst)
    if sub_find(hInst,Nodes,N_HINST) then
        for i = length(Nodes) to 1 by -1 do
            if Nodes[i][N_HINST] = hInst then
                -- Remove this node
                Nodes = cutseq(Nodes,i)
            end if
        end for
        for i = length(CurrentNode) to 1 by -1 do
            if CurrentNode[i][CN_HINST] = hInst then
                CurrentNode = cutseq(CurrentNode,i)
            end if
        end for
    end if
    
    -- Set up the current node
    CurrentNode = append(CurrentNode,{hInst,0})
end procedure

global procedure xmltree_onStartElement(integer hInst,sequence Uri, sequence LocalName, sequence QName, sequence Atts)
    integer nidx,pidx --node index, parent index
    -- Create the new node
    Nodes = append(Nodes,NEW_NODE)
    nidx = length(Nodes)
    Nodes[nidx][N_ID] = NextID
    NextID += 1
    Nodes[nidx][N_HINST] = hInst
    Nodes[nidx][N_URI] = Uri
    Nodes[nidx][N_LOCALNAME] = LocalName
    Nodes[nidx][N_QNAME] = QName
    Nodes[nidx][N_PARENT] = CurrentNode[sub_find(hInst,CurrentNode,CN_HINST)][CN_NODE]
    if Nodes[nidx][N_PARENT] = 0 then
        Nodes[nidx][N_DEPTH] = 0
    else
        Nodes[nidx][N_DEPTH] = Nodes[sub_find(Nodes[nidx][N_PARENT],Nodes,N_ID)][N_DEPTH]+1
        -- Add this node to the parent's contents
        pidx = sub_find(Nodes[nidx][N_PARENT],Nodes,N_ID)
        Nodes[pidx][N_CHILDREN] &= Nodes[nidx][N_ID]
    end if
    Nodes[nidx][N_ATTS] = Atts
    Nodes[nidx][N_CHILDREN] = {}
    
    -- Set the current node to the new node
    CurrentNode[sub_find(hInst,CurrentNode,CN_HINST)][CN_NODE] = Nodes[nidx][N_ID]
end procedure

global procedure xmltree_onEndElement(integer hInst,sequence Uri, sequence LocalName, sequence QName)
    CurrentNode[sub_find(hInst,CurrentNode,CN_HINST)][CN_NODE] = 
       Nodes[ sub_find(CurrentNode[sub_find(hInst,CurrentNode,CN_HINST)][CN_NODE],Nodes,N_ID) ][N_PARENT]
end procedure

global procedure xmltree_onStartPrefixMapping(integer hInst,sequence Prefix, sequence Uri)
    -- UNSUPORTED
end procedure

global procedure xmltree_onEndPrefixMapping(integer hInst,sequence Prefix, sequence Uri)
    -- UNSUPORTED
end procedure

global procedure xmltree_onCharacters(integer hInst,sequence Chars)
    integer nidx
    nidx = sub_find(CurrentNode[sub_find(hInst,CurrentNode,CN_HINST)][CN_NODE],Nodes,N_ID)
    -- Ignore characters outside the root node
    if nidx = 0 then return end if
    if length(Nodes[nidx][N_CHILDREN]) = 0 or atom(Nodes[nidx][N_CHILDREN][length(Nodes[nidx][N_CHILDREN])]) then
        Nodes[nidx][N_CHILDREN] = append(Nodes[nidx][N_CHILDREN],Chars)
    else
        -- Append these characters to the characters allready recieved
        Nodes[nidx][N_CHILDREN][length(Nodes[nidx][N_CHILDREN])] &= Chars
    end if
end procedure
    
global procedure xmltree_onIgnorableWhitespace(integer hInst,sequence Chars)
    xmltree_onCharacters(hInst,Chars)
end procedure

global procedure xmltree_onProcessingInstruction(integer hInst,sequence Target, sequence Data)
    -- UNSUPORTED
end procedure

global procedure xmltree_onComment(integer hInst,sequence Comment)
    -- UNSUPORTED
end procedure

global procedure xmltree_onParseError(integer hInst, integer ErrorNumber, sequence Description, integer LineNumber)
    LastError = {ErrorNumber,Description,LineNumber}
end procedure

global procedure xmltree_onXML(integer hInst, sequence XML)
    -- UNSUPORTED
end procedure

global procedure xmltree_onLoadExternal(integer hInst, integer Public, sequence URI)
    -- UNSUPORTED
end procedure
-- END EEBAX event handlers

eebax_SetStartDocumentEvent(EEBAX,routine_id("xmltree_onStartDocument"))
eebax_SetEndDocumentEvent(EEBAX,routine_id("xmltree_onEndDocument"))
eebax_SetStartElementEvent(EEBAX,routine_id("xmltree_onStartElement"))
eebax_SetEndElementEvent(EEBAX,routine_id("xmltree_onEndElement"))
eebax_SetCharactersEvent(EEBAX,routine_id("xmltree_onCharacters"))
eebax_SetIgnorableWhitespaceEvent(EEBAX,routine_id("xmltree_onIgnorableWhitespace"))
eebax_SetParseErrorEvent(EEBAX,routine_id("xmltree_onParseError"))

-- BEGIN Node navigation

-- xmltree_DeleteNode(integer node)
-- Deletes a node and all it's children
global procedure xmltree_DeleteNode(integer node)
    integer nidx
    sequence Children
    nidx = sub_find(node,Nodes,N_ID)
    Children = Nodes[nidx][N_CHILDREN]
    Nodes = cutseq(Nodes,nidx)
    for i = 1 to length(Children) do
        if atom(Children[i]) then
            xmltree_DeleteNode(Children[i])
        end if
    end for   
end procedure

function CopyNode(integer node, integer depth)
    integer nidx
    sequence newnode
    nidx = sub_find(node,Nodes,N_ID)
    
    newnode = Nodes[nidx]
    newnode[N_ID] = NextID
    NextID += 1
    newnode[N_DEPTH] = depth
    newnode[N_CHILDREN] = {}
    newnode[N_HINST] = 0
    
    for i = 1 to length(Nodes[nidx][N_CHILDREN]) do
        if atom(Nodes[nidx][N_CHILDREN][i]) then
            newnode[N_CHILDREN] = append(newnode[N_CHILDREN],CopyNode(Nodes[nidx][N_CHILDREN][i],depth+1))
        else
            newnode[N_CHILDREN] = append(newnode[N_CHILDREN],Nodes[nidx][N_CHILDREN][i])
        end if
    end for
    
    Nodes = append(Nodes,newnode)
    return newnode[N_ID]
end function

-- xmltree_CopyNode(integer node)
-- Copys a node and all it's children, returns new node
global function xmltree_CopyNode(integer node)
    return CopyNode(node,0)
end function

-- xmltree_GetRootFromhInst(integer hInst)
-- Given an EEBAX hInst returns the id of the root node.
global function xmltree_GetRootFromhInst(integer hInst)
    for i = 1 to length(Nodes) do
        if Nodes[i][N_HINST] = hInst and Nodes[i][N_DEPTH] = 0 then
            return Nodes[i][N_ID]
        end if
    end for
    return 0
end function

-- xmltree_SendToEEBAX(integer node, integer hInst)
-- Sends the node to the eebax instance given
global procedure xmltree_SendToEEBAX(integer node, integer hInst)
    integer nidx
    nidx = sub_find(node,Nodes,N_ID)
    if length(Nodes[nidx][N_CHILDREN]) > 0 then
        eebax_StartElement(hInst,Nodes[nidx][N_QNAME],Nodes[nidx][N_ATTS],0)
        for i = 1 to length(Nodes[nidx][N_CHILDREN]) do
            if atom(Nodes[nidx][N_CHILDREN][i]) then
                xmltree_SendToEEBAX(Nodes[nidx][N_CHILDREN][i],hInst)
            else
                eebax_Characters(hInst,Nodes[nidx][N_CHILDREN][i])
            end if
        end for
        eebax_EndElement(hInst,Nodes[nidx][N_QNAME])
    else
        eebax_StartElement(hInst,Nodes[nidx][N_QNAME],Nodes[nidx][N_ATTS],1)
    end if
end procedure

-- xmltree_GetRoot(integer node)
-- Returns the root node for the node given.
global function xmltree_GetRoot(integer node)
    integer nidx
    nidx = sub_find(node,Nodes,N_ID)
    for i = 1 to Nodes[nidx][N_DEPTH]+1 do
        if Nodes[nidx][N_DEPTH] = 0 then
            return Nodes[nidx][N_ID]
        end if
        nidx = Nodes[nidx][N_PARENT]
    end for
    return 0
end function

-- xmltree_GetAttributes(integer node)
-- Returns a list of attributes in the form used by eebax. 
global function xmltree_GetAttributes(integer node)
    integer nidx
    nidx = sub_find(node,Nodes,N_ID)
    return Nodes[nidx][N_ATTS]
end function

-- xmltree_GetChildren(integer node)
-- Returns a sequence, each element of the sequence is either another sequence (a string) or an atom (a node id).
global function xmltree_GetChildren(integer node)
    integer nidx
    nidx = sub_find(node,Nodes,N_ID)
    return Nodes[nidx][N_CHILDREN]
end function

-- xmltree_GetParent(integer node)
-- Returns the parent of the node, or 0 if it is the root node
global function xmltree_GetParent(integer node)
    integer nidx
    nidx = sub_find(node,Nodes,N_ID)
    return Nodes[nidx][N_PARENT]
end function

-- xmltree_GetDepth(integer node)
-- Returns the number of levels between this node and the root node
global function xmltree_GetDepth(integer node)
    integer nidx
    nidx = sub_find(node,Nodes,N_ID)
    return Nodes[nidx][N_DEPTH]
end function

-- xmltree_GetQName(integer node)
-- Returns the qualified name of the node
global function xmltree_GetQName(integer node)
    integer nidx
    nidx = sub_find(node,Nodes,N_ID)
    return Nodes[nidx][N_QNAME]
end function

-- xmltree_GetLocalName(integer node)
-- Returns the local name of the node (the bit after the : if a : exists)
global function xmltree_GetLocalName(integer node)
    integer nidx
    nidx = sub_find(node,Nodes,N_ID)
    return Nodes[nidx][N_LOCALNAME]
end function

-- xmltree_GetURI(integer node)
-- Returns the URI of the node
global function xmltree_GetURI(integer node)
    integer nidx
    nidx = sub_find(node,Nodes,N_ID)
    return Nodes[nidx][N_URI]
end function

-- xmltree_Parse(sequence xml)
-- Use EEBAX to parse the provided xml and return it's route node
global function xmltree_Parse(sequence xml)
    eebax_ResetInstance(EEBAX)
    eebax_StartDocument(EEBAX)
    LastError = 0
    if not eebax_Parse(EEBAX,xml) then
        if atom(LastError) then
            return "Unknown error"
        else
            return LastError
        end if
    end if
    eebax_EndDocument(EEBAX)
    return xmltree_CopyNode(xmltree_GetRootFromhInst(EEBAX))
end function

-- END Node navigation

