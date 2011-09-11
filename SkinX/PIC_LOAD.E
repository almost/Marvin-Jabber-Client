---------------------- Information from the mail header -----------------------
--Sender:       Euphoria Programming for MS-DOS <EUPHORIA@MIAMIU.ACS.MUOHIO.EDU>
--Poster:       Michael Bolin <michaeltom@GEOCITIES.COM>
--Subject:      GIF loader bug fix
--Sent:         Sunday, September 28, 1997 2:21 PM
-------------------------------------------------------------------------------
-- Hi all,
-- I've just fixed my PCX loader routine to be able to load files which
-- use a non-standard method of indicating the color depth.

-- Modifications by Thomas Parslow
-- 15-March-2002: Added read_gif_from_seq

include machine.e
include file.e
 
global constant PCX_OPEN_FAILED=1,
        PCX_UNEXPECTED_EOF=2,
        PCX_UNSUPPORTED_FORMAT=3,
        GIF_OPEN_FAILED=1,
        GIF_UNEXPECTED_EOF=2,
        GIF_UNSUPPORTED_FORMAT=3
 
object junk
sequence image,the_palette,bit_table
integer file_num,exit_flag,palette_at_end
integer x_size,y_size,bits_per_pixel,n_colors
integer background,bytes_per_line,x_min,x_max
integer y_min,y_max,n_planes
 
bit_table=repeat({},256)
for n=0 to 255 do
    bit_table[n+1]=int_to_bits(n,8)
end for

-- Added by Thomas Parslow 15-March-2002
integer ReadingFromSeq
ReadingFromSeq = 0
sequence Bytes
integer Offset
--------
 
function read_bytes(integer amount)
    sequence bytes
    -- Added by Thomas Parslow 15-March-2002
    if ReadingFromSeq then
        if amount+Offset > length(Bytes) then
            exit_flag=GIF_UNEXPECTED_EOF
            return Bytes[Offset+1..length(Bytes)]
        end if
        Offset += amount
        return Bytes[Offset-amount+1..Offset]
    else
        bytes=repeat(0,amount)
        for b=1 to amount do
        bytes[b]=getc(file_num)
        if bytes[b]=-1 then
            exit_flag=GIF_UNEXPECTED_EOF
        end if
        end for
        return bytes
    end if
end function
 
function read_byte()
    object byte
    byte = read_bytes(1)
    if atom(byte) or length(byte) = 0 then
        return -1
    else    
        return byte[1]
    end if
end function
 
function bytes_left()
    integer place,end_place
    -- Added by Thomas Parslow 15-March-2002
    if ReadingFromSeq then
        return length(Bytes)-Offset
    else
        place=where(file_num)
        if seek(file_num,-1)=0 then
        end_place=where(file_num)
        if seek(file_num,place)=0 then
            return end_place-place
        else
            return -1
        end if
        else
        return -1
        end if
    end if
end function
 
-- procedure read_pcx_header()
--  if bytes_left()<128 then
--      exit_flag=PCX_UNEXPECTED_EOF
--      return
--  end if
--  junk=read_byte()
--  palette_at_end=0
--  if read_byte()=5 then
--      palette_at_end=1
--  end if
--  if read_byte()!=1 then
--      exit_flag=PCX_UNSUPPORTED_FORMAT
--      return
--  end if
--  bits_per_pixel=read_byte()
--  if bits_per_pixel!=1 and bits_per_pixel!=8 then
--      exit_flag=PCX_UNSUPPORTED_FORMAT
--      return
--  end if
--  x_min=read_byte()+read_byte()*256
--  y_min=read_byte()+read_byte()*256
--  x_max=read_byte()+read_byte()*256
--  y_max=read_byte()+read_byte()*256
--  x_size=x_max-x_min+1
--  y_size=y_max-y_min+1
--  junk=read_bytes(4)
--  the_palette={}
--  if palette_at_end then
--      junk=read_bytes(48)
--  else
--      for c=1 to 16 do
--          the_palette=append(the_palette,read_bytes(3))
--      end for
--  end if
--  if exit_flag then
--      return
--  end if
--  if read_byte() then
--      exit_flag=PCX_UNSUPPORTED_FORMAT
--      return
--  end if
--  n_planes=read_byte()
--  bytes_per_line=read_byte()+read_byte()*256
--  junk=read_bytes(6)
--  for x=1 to 54 do
--      junk=read_byte()
--      if junk=-1 then
--          exit_flag=PCX_UNEXPECTED_EOF
--          return
--      elsif junk then
--          exit_flag=PCX_UNSUPPORTED_FORMAT
--          return
--      end if
--  end for
-- end procedure
procedure read_pcx_header()    -- updated Sep. 28/97
    if bytes_left()<128 then
    exit_flag=PCX_UNEXPECTED_EOF
    return
    end if
    junk=read_byte()
    palette_at_end=0
    if read_byte()=5 then
    palette_at_end=1
    end if
    if read_byte()!=1 then
    exit_flag=PCX_UNSUPPORTED_FORMAT
    return
    end if
    bits_per_pixel=read_byte()
    if bits_per_pixel!=1 and bits_per_pixel!=8 then
    exit_flag=PCX_UNSUPPORTED_FORMAT
    return
    end if
    if bits_per_pixel=1 then
    palette_at_end=0
    end if
    x_min=read_byte()+read_byte()*256
    y_min=read_byte()+read_byte()*256
    x_max=read_byte()+read_byte()*256
    y_max=read_byte()+read_byte()*256
    x_size=x_max-x_min+1
    y_size=y_max-y_min+1
    junk=read_bytes(4)
    the_palette={}
    if palette_at_end then
    junk=read_bytes(48)
    else
    for c=1 to 16 do
        the_palette=append(the_palette,read_bytes(3))
    end for
    end if
    if exit_flag then
    return
    end if
    if read_byte() then
    exit_flag=PCX_UNSUPPORTED_FORMAT
    return
    end if
    n_planes=read_byte()
    bytes_per_line=read_byte()+read_byte()*256
    junk=read_bytes(6)
    for x=1 to 54 do
    junk=read_byte()
    if junk=-1 then
        exit_flag=PCX_UNEXPECTED_EOF
        return
    elsif junk then
        exit_flag=PCX_UNSUPPORTED_FORMAT
        return
    end if
    end for
end procedure

procedure read_pcx_image()
    sequence one_row,bits,new_row
    integer number,byte,line,count,and_value,place
    integer plane_power,amount
 
    image=repeat({},y_size)
    one_row=repeat(0,bytes_per_line*n_planes)
    line=1
    while line<=y_size do
    number=1
    while number<=length(one_row) do
        byte=read_byte()
        if byte=-1 then
        exit_flag=PCX_UNEXPECTED_EOF
        return
        end if
        if byte>191 then
        count=byte-193
        byte=read_byte()
        if byte=-1 then
            exit_flag=PCX_UNEXPECTED_EOF
            return
        end if
        one_row[number..number+count]=byte
        number=number+count+1
        else
        one_row[number]=byte
        number=number+1
        end if
    end while
    if bits_per_pixel=1 then
        bits=repeat(0,bytes_per_line*8*n_planes)
        place=1
        for p=0 to n_planes-1 do
        plane_power=power(2,p)
        for t=1 to bytes_per_line do
            byte=one_row[p*bytes_per_line+t]
            and_value=256
            for z=1 to 8 do
            and_value=and_value/2
            if and_bits(byte,and_value) then
                bits[place]=plane_power
            end if
            place=place+1
            end for
        end for
        end for
        amount=bytes_per_line*8
        new_row=bits[1..amount]
        for p=1 to n_planes-1 do
        new_row=new_row+bits[amount*p+1..amount*(p+1)]
        end for
        if length(new_row)>x_size then
        new_row=new_row[1..x_size]
        end if
    else
        new_row=one_row
    end if
    image[line]=new_row
    line=line+1
    end while
    if palette_at_end then
    junk=read_byte()
    for c=1 to 256 do
        the_palette=append(the_palette,read_bytes(3))
        if find(-1,the_palette[c]) then
        exit_flag=PCX_UNEXPECTED_EOF
        return
        end if
    end for
    end if
end procedure
 
procedure read_gif_header()
    object work
    sequence stuff,bits
    integer global_color_map
 
    if bytes_left()<6 then
    exit_flag=GIF_UNEXPECTED_EOF
    return
    end if
    stuff=read_bytes(3)
    if compare(stuff,"GIF") and compare(stuff,"GIF") then
    exit_flag=GIF_UNSUPPORTED_FORMAT
    return
    end if
    junk=read_bytes(3)
    if bytes_left()<7 then
    exit_flag=GIF_UNEXPECTED_EOF
    return
    end if
    junk=read_bytes(4)
    bits=bit_table[read_byte()+1]
    global_color_map=bits[8]
    bits_per_pixel=bits_to_int(bits[1..3])+1
    n_colors=power(2,bits_per_pixel)
    background=read_byte()
    junk=read_byte()
    the_palette={}
    if global_color_map then
    if bytes_left()<n_colors*3 then
        exit_flag=GIF_UNEXPECTED_EOF
        return
    end if
    for c=1 to n_colors do
        the_palette=append(the_palette,read_bytes(3))
    end for
    end if
    while 1 do
    work=read_byte()
    if work=-1 then
        exit_flag=GIF_UNEXPECTED_EOF
        return
    elsif work=',' then
        exit
    end if
    end while
end procedure
 
procedure read_gif_image()
    object work
    sequence strings,bits,output,work_bits,string,stream
    integer interlace,code_size,clear_code,end_of_info
    integer num_bits,code,old,done,pointer,block_length
    integer bit_add
 
    if bytes_left()<9 then
    exit_flag=GIF_UNEXPECTED_EOF
    return
    end if
    junk=read_bytes(4)
    x_size=read_byte()+read_byte()*256
    y_size=read_byte()+read_byte()*256
    work=read_byte()
    bits=bit_table[work+1]
    if bits[8] then
    bits_per_pixel=bits_to_int(bits[1..3])+1
    n_colors=power(2,bits_per_pixel)
    the_palette={}
    for c=1 to n_colors do
        the_palette=append(the_palette,read_bytes(3))
    end for
    if exit_flag then
        return
    end if
    end if
    interlace=bits[7]
    image=repeat({},y_size)
    output={}
    if n_colors=2 then
    n_colors=4
    end if
    strings=repeat({},n_colors+2)
    for t=1 to n_colors do
    strings[t]={t-1}
    end for
    code_size=read_byte()
    if code_size=-1 then
    exit_flag=GIF_UNEXPECTED_EOF
    return
    end if
    clear_code=power(2,code_size)+1
    end_of_info=clear_code+1
    num_bits=code_size+1
    stream={}
    while 1 do
    block_length=read_byte()
    if block_length=0 then
        exit
    end if
    for b=1 to block_length do
        stream=append(stream,read_byte())
    end for
    end while
    if find(-1,stream) then
    exit_flag=GIF_UNEXPECTED_EOF
    return
    end if
    stream=append(stream,0)
    stream=append(stream,-1)
    pointer=1
    bits={}
    while length(bits)<26 do
    bits=bits & bit_table[stream[pointer]+1]
    pointer=pointer+1
    end while
    bits=bits[num_bits+1..length(bits)]
    work_bits=bits[1..num_bits]
    code=bits_to_int(work_bits)+1
    output=strings[code]
    old=code
    bits=bits[num_bits+1..length(bits)]
    done=0
    while 1 do
    while length(bits)<26 and done=0 do
        work=stream[pointer]
        pointer=pointer+1
        if work=-1 then
        done=1
        exit
        end if
        bits=bits & bit_table[work+1]
    end while
    if length(bits)<num_bits then
        exit
    end if
    code=1
    bit_add=1
    for b=1 to num_bits do
        if bits[b] then
        code=code+bit_add
        end if
        bit_add=bit_add+bit_add
    end for
    bits=bits[num_bits+1..length(bits)]
    if code=end_of_info then
        exit
    elsif code=clear_code then
        strings=repeat({},n_colors+2)
        for t=1 to n_colors do
        strings[t]={t-1}
        end for
        num_bits=code_size+1
        work_bits=bits[1..num_bits]
        code=bits_to_int(work_bits)+1
        for t=1 to length(strings[code]) do
        output=append(output,strings[code][t])
        end for
        old=code
        bits=bits[num_bits+1..length(bits)]
    else
        if code<=length(strings) then
        string=strings[code]
        for t=1 to length(string) do
            output=append(output,string[t])
        end for
        work=strings[old] & string[1]
        strings=append(strings,work)
        old=code
        else
        work=strings[old] & strings[old][1]
        for t=1 to length(work) do
            output=append(output,work[t])
        end for
        strings=append(strings,work)
        old=code
        end if
    end if
    if length(strings)=power(2,num_bits) then
        num_bits=num_bits+1
        if num_bits=13 then
        num_bits=12
        end if
    end if
    end while
    work=repeat({},y_size)
    for r=0 to y_size-1 do
    work[r+1]=output[r*x_size+1..r*x_size+x_size]
    end for
    if interlace then
    image=repeat({},y_size)
    pointer=1
    for l=1 to y_size by 8 do
        image[l]=work[pointer]
        pointer=pointer+1
    end for
    for l=5 to y_size by 8 do
        image[l]=work[pointer]
        pointer=pointer+1
    end for
    for l=3 to y_size by 4 do
        image[l]=work[pointer]
        pointer=pointer+1
    end for
    for l=2 to y_size by 2 do
        image[l]=work[pointer]
        pointer=pointer+1
    end for
    else
    image=work
    end if
end procedure
 
global function read_pcx(sequence filename)
    exit_flag=0
    file_num=open(filename,"rb")
    if file_num<0 then
    return PCX_OPEN_FAILED
    end if
    read_pcx_header()
    if exit_flag then
    close(file_num)
    return exit_flag
    end if
    read_pcx_image()
    close(file_num)
    if exit_flag then
    return exit_flag
    end if
    the_palette=the_palette[1..power(2,bits_per_pixel*n_planes)]
    return {the_palette,image}
end function
 
global function read_gif(sequence file_name)
    exit_flag=0
    file_num=open(file_name,"rb")
    if file_num<0 then
    return GIF_OPEN_FAILED
    end if
    read_gif_header()
    if exit_flag then
    close(file_num)
    return exit_flag
    end if
    read_gif_image()
    close(file_num)
    if exit_flag then
    return exit_flag
    end if
    return {the_palette,image}
end function
 
-- Added by Thomas Parslow 15-March-2002
global function read_gif_from_seq(sequence bytes)
    exit_flag=0
    Bytes = bytes
    Offset = 0
    ReadingFromSeq = 1
    read_gif_header()
    if exit_flag then
    return exit_flag
    end if
    read_gif_image()
    if exit_flag then
    return exit_flag
    end if
    ReadingFromSeq = 0
    return {the_palette,image}
end function
