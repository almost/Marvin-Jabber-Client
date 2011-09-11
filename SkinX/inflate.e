-- inflate.e - Unzip version - v1.2
-- by Davi T. Figueiredo
-- You can get the latest version of this program from my Euphoria page,
-- at http://www.brasil.terravista.pt/Jenipabu/2571

-- This file contains the Deflate decompression algorithm.
-- If you want to understand what the code in this file does, I suggest
-- that you read the DEFLATE Compressed Data Format Specification
-- (see unzip.txt).

-- This is a modified version of inflate.e in my ungzip program.

-- Changes in version 1.2 from 1.1 : does not read from file any more,
--                                   instead gets the compressed file from a string
-- Changes in version 1.1 from 1.0 : faster
-- MODIFIED BY THOMAS PARSLOW 10-4-2002 TO CHANGE INCLUDE FILE PATH

include huftree.e

-- Global constants: error codes
global constant INFLATE_NO_ERRORS=0,INFLATE_UNEXPECTED_EOF=1,
                INFLATE_CORRUPTED_DATA=2,INFLATE_OUT_OF_MEMORY=3,
                INFLATE_UNSUPPORTED=4,INFLATE_WRONG_CHECKSUM=5

-- Code length order in dynamic Huffman codes
constant code_length_order={16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15}

-- Fixed Huffman alphabets
constant fixed_huff_codes={create_huffman_tree(repeat(8,144)&repeat(9,112)&repeat(7,24)&repeat(8,8)),
                           create_huffman_tree(repeat(5,32))}

-- Extra length bits
constant extra_length_bits={0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0}
constant first_length={3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258}

-- Extra distance bits
constant extra_distance_bits={0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13}
constant first_distance={1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,
                         6145,8193,12289,16385,24577}


atom bits_in_byte,current_byte,error,pos_in_data
sequence huffman_codes,compressed_data

-- No errors yet
error=0


function read_bits(atom number_of_bits) -- Read the specified number of bits
                                        -- from the file and return it as a
                                        -- number
    atom num,char

    while bits_in_byte<number_of_bits do
        pos_in_data=pos_in_data+1
        if pos_in_data>length(compressed_data) then error=INFLATE_UNEXPECTED_EOF return -1 end if
        char=compressed_data[pos_in_data]

        current_byte=current_byte+char*power(2,bits_in_byte)

        bits_in_byte=bits_in_byte+8

    end while

    num=and_bits(current_byte,power(2,number_of_bits)-1)

    current_byte=floor(current_byte/power(2,number_of_bits))
    bits_in_byte=bits_in_byte-number_of_bits
    return num

end function

function read_byte()
    bits_in_byte=0
    current_byte=0
    pos_in_data=pos_in_data+1
    if pos_in_data>length(compressed_data) then error=INFLATE_UNEXPECTED_EOF return -1 end if
    return compressed_data[pos_in_data]
end function


function read_huffman_code(atom code_number)
    -- Reads a Huffman code from the compressed data using the specified
    -- alphabet. All alphabets are stored in huffman_codes.
    -- Alphabet 1 is the literal/length alphabet, 2 is the distance alphabet
    -- and 3 is the code length alphabet (used to read the other alphabets).

    atom next_bit
    object node

    node=huffman_codes[code_number]

    while sequence(node) do


        -- Read a bit from the file

        if bits_in_byte=0 then

            pos_in_data=pos_in_data+1
            if pos_in_data>length(compressed_data) then error=INFLATE_UNEXPECTED_EOF return -1 end if
            current_byte=compressed_data[pos_in_data]
            bits_in_byte=8
            
        end if
    
        next_bit=and_bits(current_byte,1)
        current_byte=floor(current_byte/2)
        bits_in_byte=bits_in_byte-1
    
        if length(node)=1 and next_bit=1 then
                error=INFLATE_CORRUPTED_DATA
                return 0
        end if

        node=node[next_bit+1]

    end while

    return node

end function


procedure read_huffman_length()
    -- This function reads the literal/length and distance codes from the
    -- compressed data when using dynamic Huffman codes and stores the trees
    -- in huffman_codes.

    atom h_literal_length,h_distance,h_codes,curr_value,curr_code,addicional_bits
    
    sequence code_codes,litlendist_codes

    -- Read the number of literal/length codes
    h_literal_length=read_bits(5)+257
    if error then return end if         -- Handle errors

    -- Read the number of distance codes
    h_distance=read_bits(5)+1
    if error then return end if         -- Handle errors

    -- Read the number of code codes (It took me some time to understand it)
    h_codes=read_bits(4)+4
    if error then return end if         -- Handle errors

    code_codes=repeat(0,19)

    for temp=1 to h_codes do
        code_codes[code_length_order[temp]+1]=read_bits(3)
        if error then return end if     -- Handle errors
    end for

    huffman_codes[3]=create_huffman_tree(code_codes)

    litlendist_codes=repeat(0,h_literal_length+h_distance)  -- literal/length and distance codes

    curr_code=1
    while curr_code<=length(litlendist_codes) do
        curr_value=read_huffman_code(3)
        if error then return end if     -- Handle errors

        if curr_value<16 then       -- Represent code lengths of 0 - 15
            litlendist_codes[curr_code]=curr_value
            curr_code=curr_code+1

        elsif curr_value=16 then    -- Copy the previous code length 3 - 6 times
            addicional_bits=read_bits(2)+3
            if error then return end if -- Handle errors
            
            litlendist_codes[curr_code..curr_code+addicional_bits-1]=litlendist_codes[curr_code-1]
            curr_code=curr_code+addicional_bits

        elsif curr_value=17 then    -- Repeat a code length of 0 for 3 - 10 times
            addicional_bits=read_bits(3)+3
            if error then return end if -- Handle errors
            curr_code=curr_code+addicional_bits

        elsif curr_value=18 then    -- Repeat a code length of 0 for 11 - 138 times
            addicional_bits=read_bits(7)+11
            if error then return end if -- Handle errors
            curr_code=curr_code+addicional_bits
        end if

    end while

    -- Create the Huffman trees and store them in huffman_codes.
    huffman_codes[1]=create_huffman_tree(litlendist_codes[1..h_literal_length])
    huffman_codes[2]=create_huffman_tree(litlendist_codes[h_literal_length+1..length(litlendist_codes)])


end procedure


global function inflate(sequence file,atom file_size)
    -- Uncompresses the deflated data.

    atom final_block,compression_method,field_length,last_char,dist_value
    atom lengt,distance,complement,unc_pos
    sequence uncompressed_data


    -- Initialize variables
    compressed_data=file
    pos_in_data=0
    bits_in_byte=0
    current_byte=0
    final_block=0

    huffman_codes={{},{},{}}

    uncompressed_data=repeat(-1,file_size)
    
    unc_pos=1
    



    while not final_block do

        -- Read the final block flag
        final_block=read_bits(1)
        if error then return error  end if -- Handle errors
    
        -- Read the compression method
        compression_method=read_bits(2)
        if error then return error  end if -- Handle errors




        if compression_method=0 then        -- uncompressed block
    
            -- Read field length (first byte is already in current_byte)
            field_length=read_byte()+read_byte()*256
            -- Next two bytes must be the two's complement of the field length
            complement=read_byte()+read_byte()*256

            if error then return {error,uncompressed_data[1..unc_pos-1]} end if

            if field_length+complement!=#FFFF then
                return {INFLATE_CORRUPTED_DATA,uncompressed_data[1..unc_pos-1]}
            end if

            if unc_pos+field_length-1>file_size then
                return {INFLATE_CORRUPTED_DATA,uncompressed_data[1..unc_pos-1]}
            end if

            for temp=1 to field_length do
                uncompressed_data[unc_pos]=read_byte()                
                if error then return {error,uncompressed_data[1..unc_pos-1]} end if
                unc_pos=unc_pos+1
            end for




        elsif compression_method=3 then     -- Error
                error=INFLATE_UNSUPPORTED          -- Unsupported feature
                return {error,uncompressed_data[1..unc_pos-1]}     -- Handle errors





        else                        -- compressed block

            if compression_method=1 then        -- fixed Huffman codes
                huffman_codes=fixed_huff_codes
            else                                -- dynamic Huffman codes
                read_huffman_length()
                if error then return {error,uncompressed_data[1..unc_pos-1]}  end if -- Handle errors
            end if

            last_char=0

            -- While not end of block
            while last_char!=256 do

                -- Read one literal/length code
                last_char=read_huffman_code(1)

                if error then   -- Handle errors
                    return {error,uncompressed_data[1..unc_pos-1]}  end if -- Handle errors

                if last_char<256 then   -- Literal byte

                    if unc_pos>file_size then
                        return {INFLATE_CORRUPTED_DATA,uncompressed_data[1..unc_pos-1]}
                    end if
                     
                    uncompressed_data[unc_pos]=last_char
                    unc_pos=unc_pos+1

                elsif last_char>256 then    -- <length,distance> pair

                    -- Read extra length bits

                    if last_char<=264 then  -- no extra bits
                        lengt=last_char-254
                    else
                        lengt=first_length[last_char-256]+read_bits(extra_length_bits[last_char-256])
                        if error then return {error,uncompressed_data[1..unc_pos-1]}  end if -- Handle errors
                    end if


                    -- Read one distance code
                    dist_value=read_huffman_code(2)+1
                    if error then return {error,uncompressed_data[1..unc_pos-1]}  end if -- Handle errors

                    -- Read extra distance bits
                    if dist_value<=4 then   -- no extra bits
                        distance=dist_value
                    else
                        distance=first_distance[dist_value]+read_bits(extra_distance_bits[dist_value])
                        if error then return {error,uncompressed_data[1..unc_pos-1]}  end if -- Handle errors
                    end if                   
                   
                    if distance>=unc_pos then      -- Backwards distance points to a position before the beggining of data
                        error=INFLATE_CORRUPTED_DATA          -- Corrupted data
                        return {error,uncompressed_data[1..unc_pos-1]}
                    end if

                    -- Copy (length) bytes from the already uncompressed data

                    for temp=1 to lengt do

                        if unc_pos>file_size then
                            error=INFLATE_CORRUPTED_DATA          -- Corrupted data
                            return {error,uncompressed_data[1..unc_pos-1]}
                        end if

                        uncompressed_data[unc_pos]=uncompressed_data[unc_pos-distance]

                        unc_pos=unc_pos+1
    
                    end for
            
                end if

            end while


        end if



    end while

    -- Decompression ended.

    return {INFLATE_NO_ERRORS,uncompressed_data,pos_in_data}       -- No errors

end function

