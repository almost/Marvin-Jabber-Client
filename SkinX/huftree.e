-- huftree.e - v1.0 - by Davi T. Figueiredo
-- You can get the latest version of this program from my Euphoria page,
-- at http://www.brasil.terravista.pt/Jenipabu/2571

-- This file contains the routine that creates the Huffman tree from
-- a sequence of code lengths.

global function create_huffman_tree(sequence lengths)
    -- Creates a Huffman tree from the sequence of lengths given

    sequence first_of_length,tree,new_tree

    -- Order the codes according to their lengths

    first_of_length=repeat(1,15)
    tree={}

    for current_length=1 to 15 do

        first_of_length[current_length]=length(tree)+1

        for temp=1 to length(lengths) do

            if lengths[temp]=current_length then
                tree=tree&temp
            end if

        end for

    end for

    -- First value is 0, not 1
    tree=tree-1


    for current_length=15 to 2 by -1 do
        new_tree=tree[1..first_of_length[current_length]-1]

        for temp=first_of_length[current_length] to length(tree) by 2 do
            if temp=length(tree) then       -- the last code has a 0 digit
                new_tree=append(new_tree,{tree[temp]})  -- ok, let's leave it alone
            else                            -- no problem
                new_tree=append(new_tree,tree[temp..temp+1])
            end if
        end for

        tree=new_tree
    end for



    return tree
end function

