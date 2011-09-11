-- crc32.e - v1.22 - by Davi T. Figueiredo
-- You can get the latest version of this program from my Euphoria page,
-- at http://www.brasil.terravista.pt/Jenipabu/2571

-- This file contains routines that calculate the CRC-32 for a string.
-- Changes from version 1.21 : crc_table is not global any more,
--                             but table_address is.
-- Changes from version 1.11 : about 6 times faster - uses machine code.
-- Changes from version 1.1 : crc_table is now global (zipdc.e uses it).
-- Changes from version 1.0 : The crc table is pre-computed, avoiding
-- a delay when the file is included; CRC is now given in LSB-to-MSB
-- order (as in ZIP files).

include machine.e
constant at_once=512    -- This is the number of chars that will be
                        -- processed in each call to the machine code
                        -- routine. That is the value that works best
                        -- for me. You might try other values to see
                        -- if you find a faster one.

constant crc_table = {
#00000000, #77073096, #EE0E612C, #990951BA, #076DC419, #706AF48F,
#E963A535, #9E6495A3, #0EDB8832, #79DCB8A4, #E0D5E91E, #97D2D988,
#09B64C2B, #7EB17CBD, #E7B82D07, #90BF1D91, #1DB71064, #6AB020F2,
#F3B97148, #84BE41DE, #1ADAD47D, #6DDDE4EB, #F4D4B551, #83D385C7,
#136C9856, #646BA8C0, #FD62F97A, #8A65C9EC, #14015C4F, #63066CD9,
#FA0F3D63, #8D080DF5, #3B6E20C8, #4C69105E, #D56041E4, #A2677172,
#3C03E4D1, #4B04D447, #D20D85FD, #A50AB56B, #35B5A8FA, #42B2986C,
#DBBBC9D6, #ACBCF940, #32D86CE3, #45DF5C75, #DCD60DCF, #ABD13D59,
#26D930AC, #51DE003A, #C8D75180, #BFD06116, #21B4F4B5, #56B3C423,
#CFBA9599, #B8BDA50F, #2802B89E, #5F058808, #C60CD9B2, #B10BE924,
#2F6F7C87, #58684C11, #C1611DAB, #B6662D3D, #76DC4190, #01DB7106,
#98D220BC, #EFD5102A, #71B18589, #06B6B51F, #9FBFE4A5, #E8B8D433,
#7807C9A2, #0F00F934, #9609A88E, #E10E9818, #7F6A0DBB, #086D3D2D,
#91646C97, #E6635C01, #6B6B51F4, #1C6C6162, #856530D8, #F262004E,
#6C0695ED, #1B01A57B, #8208F4C1, #F50FC457, #65B0D9C6, #12B7E950,
#8BBEB8EA, #FCB9887C, #62DD1DDF, #15DA2D49, #8CD37CF3, #FBD44C65,
#4DB26158, #3AB551CE, #A3BC0074, #D4BB30E2, #4ADFA541, #3DD895D7,
#A4D1C46D, #D3D6F4FB, #4369E96A, #346ED9FC, #AD678846, #DA60B8D0,
#44042D73, #33031DE5, #AA0A4C5F, #DD0D7CC9, #5005713C, #270241AA,
#BE0B1010, #C90C2086, #5768B525, #206F85B3, #B966D409, #CE61E49F,
#5EDEF90E, #29D9C998, #B0D09822, #C7D7A8B4, #59B33D17, #2EB40D81,
#B7BD5C3B, #C0BA6CAD, #EDB88320, #9ABFB3B6, #03B6E20C, #74B1D29A,
#EAD54739, #9DD277AF, #04DB2615, #73DC1683, #E3630B12, #94643B84,
#0D6D6A3E, #7A6A5AA8, #E40ECF0B, #9309FF9D, #0A00AE27, #7D079EB1,
#F00F9344, #8708A3D2, #1E01F268, #6906C2FE, #F762575D, #806567CB,
#196C3671, #6E6B06E7, #FED41B76, #89D32BE0, #10DA7A5A, #67DD4ACC,
#F9B9DF6F, #8EBEEFF9, #17B7BE43, #60B08ED5, #D6D6A3E8, #A1D1937E,
#38D8C2C4, #4FDFF252, #D1BB67F1, #A6BC5767, #3FB506DD, #48B2364B,
#D80D2BDA, #AF0A1B4C, #36034AF6, #41047A60, #DF60EFC3, #A867DF55,
#316E8EEF, #4669BE79, #CB61B38C, #BC66831A, #256FD2A0, #5268E236,
#CC0C7795, #BB0B4703, #220216B9, #5505262F, #C5BA3BBE, #B2BD0B28,
#2BB45A92, #5CB36A04, #C2D7FFA7, #B5D0CF31, #2CD99E8B, #5BDEAE1D,
#9B64C2B0, #EC63F226, #756AA39C, #026D930A, #9C0906A9, #EB0E363F,
#72076785, #05005713, #95BF4A82, #E2B87A14, #7BB12BAE, #0CB61B38,
#92D28E9B, #E5D5BE0D, #7CDCEFB7, #0BDBDF21, #86D3D2D4, #F1D4E242,
#68DDB3F8, #1FDA836E, #81BE16CD, #F6B9265B, #6FB077E1, #18B74777,
#88085AE6, #FF0F6A70, #66063BCA, #11010B5C, #8F659EFF, #F862AE69,
#616BFFD3, #166CCF45, #A00AE278, #D70DD2EE, #4E048354, #3903B3C2,
#A7672661, #D06016F7, #4969474D, #3E6E77DB, #AED16A4A, #D9D65ADC,
#40DF0B66, #37D83BF0, #A9BCAE53, #DEBB9EC5, #47B2CF7F, #30B5FFE9,
#BDBDF21C, #CABAC28A, #53B39330, #24B4A3A6, #BAD03605, #CDD70693,
#54DE5729, #23D967BF, #B3667A2E, #C4614AB8, #5D681B02, #2A6F2B94,
#B40BBE37, #C30C8EA1, #5A05DF1B, #2D02EF8D}


global constant table_address=allocate(1024)
for temp=0 to 255 do
    poke4(table_address+temp*4,crc_table[temp+1])
end for


constant crc32 = allocate(59)
-- This code was created by me and converted to machine code by Pete Eberlein's ASM.EX .
poke(crc32, {
    #50,                    --    0: PUSH EAX
    #53,                    --    1: PUSH EBX
    #51,                    --    2: PUSH ECX
    #A1,#00,#00,#00,#00,    --    3: MOV  EAX,  [crc_address] (4)
    #B9,#00,#00,#00,#00,    --    8: MOV  ECX,  char_address (9)
                            --    D: CalcCRC:
    #89,#C3,                --    D: MOV  EBX,  EAX
    #81,#E3,#FF,#00,#00,#00,--    F: AND  EBX,  #FF  ;keep only the LSB byte
    #32,#19,                --   15: XOR  BL,   [ECX]
    #C1,#E3,#02,            --   17: SHL  EBX,  2    ;multiply by four
    #81,#C3,#00,#00,#00,#00,--   1A: ADD  EBX,  table_address    ; find the position of the value in the table (28)
    #C1,#E8,#08,            --   20: SHR  EAX,  8    ;take away the LSB
    #33,#03,                --   23: XOR  EAX,  [EBX]    ; xor the CRC with the value from the table
    #41,                    --   25: INC  ECX    ; next char
    #81,#F9,#00,#00,#00,#00,--   26: CMP  ECX,  after_chars (40)
    #72,#DF,                --   2C: JB   CalcCRC    ;Process next char if not all chars have been processed yet
    #A3,#00,#00,#00,#00,    --   2E: MOV  [crc_address], EAX ; Copy the CRC to its original place (47)
    #59,                    --   33: POP  ECX
    #5B,                    --   34: POP  EBX
    #58,                    --   35: POP  EAX
    #C3,                    --   36: RET
    #FF,#FF,#FF,#FF})       --   37: The CRC will be stored here


constant char_address=allocate(at_once),crc_address=crc32+55

poke4(crc32 + 4, crc_address)  -- CRC address
poke4(crc32 + 9, char_address)
poke4(crc32 + 28, table_address)
poke4(crc32 + 47, crc_address) -- CRC address


procedure process_chars(sequence chars)
    poke4(crc32 + 40, char_address+length(chars))
    poke(char_address,chars)
    call(crc32)
end procedure


global function crc_32(sequence buf)
    -- Calculates the CRC-32 for the string given.

    sequence crc
    poke4(crc_address,#FFFFFFFF)
    for n=1 to length(buf) by at_once do
        if n+at_once-1>length(buf) then
            process_chars(buf[n..length(buf)])
        else
            process_chars(buf[n..n+at_once-1])
        end if
    end for


    crc=peek({crc_address,4})
    crc=xor_bits(crc,#FF)
    return crc
end function

