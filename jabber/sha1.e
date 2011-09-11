--From:
--Kryptonite File Encrypter/Decrypter v2.1
--December 29, 1998
--Copyright (c) Alan Tu <atu5713@compuserve.com> 1998
--
--With modifcation to output in hex by PatRat 21 Feb 2001

include wildcard.e

constant K_words=repeat({#5A,#82,#79,#99},20)&repeat({#6E,#D9,#EB,#A1},20)&
                 repeat({#8F,#1B,#BC,#DC},20)&repeat({#CA,#62,#C1,#D6},20),
         c_H_words={{#67,#45,#23,#01},{#EF,#CD,#AB,#89},{#98,#BA,#DC,#FE},
                    {#10,#32,#54,#76},{#C3,#D2,#E1,#F0}}


sequence H_words
global function integer_to_bytes(atom x)
-- returns value of x as a sequence of 4 bytes 
    integer a,b,c,d
    
    a = remainder(x, #100)
    x = floor(x / #100)
    b = remainder(x, #100)
    x = floor(x / #100)
    c = remainder(x, #100)
    x = floor(x / #100)
    d = remainder(x, #100)
    return {d,c,b,a}
end function

global function bytes_to_integer(sequence s)
-- converts 4 bytes into an integer value
    return s[4] + 
           s[3] * #100 + 
           s[2] * #10000 + 
           s[1] * #1000000
end function

function left_shift(sequence word,integer bits)

    atom total,power_2
    
    power_2=power(2,bits)
    total=bytes_to_integer(word)

    total=remainder(total*power(2,bits),#100000000)+floor(total/power(2,32-bits))
    return integer_to_bytes(total)
end function

function adjust_word(sequence word)
    for temp=4 to 2 by -1 do
        if word[temp]>255 then
            word[temp-1]=word[temp-1]+floor(word[temp]/256)
            word[temp]=and_bits(word[temp],255)
        end if
    end for
    word[1]=and_bits(word[1],255)
    return word
end function


function divide_in_words(sequence message)
    -- Divide in words = 4-byte = 32-bit blocks
    for temp=1 to length(message)/4 do
        message=message[1..temp-1]&{message[temp..temp+3]}&message[temp+4..length(message)]
    end for
    return message
    
end function

function divide_in_blocks(sequence message)
    -- Divide in 16-word = 64-byte = 512-bit blocks
    for temp=1 to length(message)/64 do
        message=message[1..temp-1]&{message[temp..temp+63]}&message[temp+64..length(message)]
    end for
    return message
end function




function func_f(sequence B_word,sequence C_word,sequence D_word,integer index)
    if index<=20 then       -- from 1 to 20
        -- (B and C) or ((not B) and D)
        return or_bits(and_bits(B_word,C_word),and_bits(not_bits(B_word),D_word))
    elsif index<=40 then    -- from 21 to 40
        -- B xor C xor D
        return xor_bits(B_word,xor_bits(C_word,D_word))
    elsif index<=60 then    -- from 41 to 60
        -- (B and C) or (B and D) or (C and D)
        return or_bits(and_bits(B_word,C_word),or_bits(and_bits(B_word,D_word),and_bits(C_word,D_word)))
    else                    -- from 61 to 80
        -- B xor C xor D
        return xor_bits(B_word,xor_bits(C_word,D_word))
    end if

end function


procedure process_block(sequence block)
    sequence A_word,B_word,C_word,D_word,E_word,TEMP_word
    sequence W_words
    W_words=repeat({0,0,0,0},80)
    W_words[1..16]=divide_in_words(block)
    for temp=17 to 80 do
        W_words[temp]=left_shift(xor_bits(xor_bits(W_words[temp-3],W_words[temp-8]),
                                xor_bits(W_words[temp-14],W_words[temp-16])),1)
    end for

    A_word=H_words[1]
    B_word=H_words[2]
    C_word=H_words[3]
    D_word=H_words[4]
    E_word=H_words[5]


    for temp=1 to 80 do
        TEMP_word=adjust_word(left_shift(A_word,5)+func_f(B_word,C_word,D_word,temp)+E_word+W_words[temp]+K_words[temp])

        E_word=D_word  D_word=C_word  C_word=left_shift(B_word,30)  B_word=A_word  A_word=TEMP_word
    end for

    H_words[1]=adjust_word(H_words[1]+A_word)
    H_words[2]=adjust_word(H_words[2]+B_word)
    H_words[3]=adjust_word(H_words[3]+C_word)
    H_words[4]=adjust_word(H_words[4]+D_word)
    H_words[5]=adjust_word(H_words[5]+E_word)

end procedure




function pad_message(sequence message)
    atom len,temp
    temp=64-remainder(length(message)+9,64)
    if temp=64 then temp=0 end if

    len=length(message)*8        -- Length of message in bits
    message=message&128&repeat(0,temp)&
      {0,0,0,0}&integer_to_bytes(len)
    return message
end function



function bytes2hex(sequence message)
	sequence ret
	ret = ""
	for i = 1 to length(message) do
		ret = ret & sprintf("%02x",{message[i]})
	end for
	return lower(ret)
end function



global function sha1_GetHash(sequence message)
    H_words=c_H_words
    message=pad_message(message)

    for temp=1 to length(message) by 64 do
       process_block(message[temp..temp+63])
    end for

    return bytes2hex(H_words[1]&H_words[2]&H_words[3]&H_words[4]&H_words[5])
end function

