-- unzip.e - v1.23 - by Davi Figueiredo
-- You can get the latest version of this program from my Euphoria page,
-- at http://www.brasil.terravista.pt/Jenipabu/2571

-- This file contains routines that read a zip file and decompress
-- files from it.

-- Changes in version 1.23 from 1.22 : file info structure changed; reads
-- date and time of files
-- Changes in version 1.22 from 1.2 : file reading is a little bit faster
-- Changes in version 1.2 from 1.0 : handles encrypted files

-- MODIFIED BY THOMAS PARSLOW 10-4-2002 TO REMOVE ENCRYPTED FILE SUPPORT AND CHANGE INCLUDE FILE PATHS

include machine.e
include file.e
include wildcard.e
include inflate.e
include crc32.e

global constant ZIP_NO_ERRORS=0,ZIP_UNEXPECTED_EOF=1,
                ZIP_CORRUPTED_DATA=2,ZIP_NOT_A_ZIP=3,
                ZIP_UNSUPPORTED=4,ZIP_WRONG_CHECKSUM=5,
                ZIP_FILE_READING_ERROR=6,ZIP_WRONG_PASSWORD=7,
                ZIP_FILE_NOT_FOUND=-1,

                -- Error messages for each of the errors above
                error_messages={"Unexpected end of file","Corrupted data",
                "Not a ZIP archive","Unsupported feature","CRC error",
                "Could not read from file","Incorrect password"},

                CENTRAL_DIRECTORY_REACHED=256  -- This is not an error


global constant
Z_NAME=1,Z_FLAGS=2,Z_SIZE=3,Z_YEAR=4,Z_MONTH=5,Z_DAY=6,
Z_HOUR=7,Z_MINUTE=8,Z_SECOND=9,Z_CRC=10,Z_METHOD=11,Z_CSIZE=12,Z_POSITION=13,
Z_DATE=Z_YEAR,Z_TIME=Z_HOUR



atom zfn

sequence dir_info

object junk


zfn=-1
dir_info={}                      

function file_size(atom file_number)
    -- Gets the file size.
    atom lof,current_position
    current_position=where(file_number)

    if seek(file_number,-1) then
        return -1
    end if

    lof=where(file_number)
    if seek(file_number,current_position) then
        return -1
    end if
    return lof

end function


constant block_size=256
function read_bytes(atom file_number,atom bytes)
    integer last_block
    sequence data

    last_block=bytes-and_bits(bytes,block_size-1)
    data=repeat(-1,bytes)


    for temp=1 to last_block by block_size do
        for byte_number=temp to temp+block_size-1 do
            data[byte_number]=getc(file_number)
        end for
        if data[temp+block_size-1]=-1 then
            last_block=temp+block_size-2  -- Using last_block simply to avoid declaring another variable
            while data[last_block] = -1 do
                last_block=last_block-1
            end while
            return data[1..last_block]
        end if
    end for


    for byte_number=last_block+1 to bytes do
        data[byte_number]=getc(file_number)
    end for

    if data[bytes]=-1 then
        last_block=bytes-1
        while data[last_block] = -1 do
            last_block=last_block-1
        end while
        return data[1..last_block]
    end if


    return data
end function


function convert_date(atom zip_date)
    atom year,month,day
    year=and_bits(floor(zip_date/512),#7F)+1980
    month=and_bits(floor(zip_date/32),#F)
    day=and_bits(zip_date,#1F)

    return {year,month,day}

end function

function convert_time(atom zip_time)
    integer hour,minute,second

    hour=and_bits(floor(zip_time/2048),#1F)
    minute=and_bits(floor(zip_time/32),#3F)
    second=and_bits(zip_time,#1F)*2
    return {hour,minute,second}
end function


function read_header()

    integer flags,method,compressed_size,uncompressed_size
    integer filename_length,extra_length,position_in_file
    sequence crc,filename,signature,info,file_time,file_date

    -- A. Local file header:

    -- Zip signature - 4 bytes
    signature={getc(zfn),getc(zfn),getc(zfn),getc(zfn)}
    if compare(signature,{#50,#4B,#03,#04}) then
        -- Not a zip file, return
        if not compare(signature,{#50,#4B,#01,#02}) then    -- Central directory
            return CENTRAL_DIRECTORY_REACHED
        end if
        return ZIP_NOT_A_ZIP
    end if
    
    -- Version needed to extract - 2 bytes - skip
    junk=getc(zfn) and getc(zfn)
    
    -- General purpose bit flag - 2 bytes
    flags=getc(zfn)+getc(zfn)*256
    
    -- Compression method - 2 bytes
    method=getc(zfn)+getc(zfn)*256
    
    -- File time and date - 4 bytes
    file_time=convert_time(getc(zfn)+getc(zfn)*#100)
    file_date=convert_date(getc(zfn)+getc(zfn)*#100)

    -- CRC-32 - 4 bytes
    crc={getc(zfn),getc(zfn),getc(zfn),getc(zfn)}
    
    -- Compressed size - 4 bytes
    compressed_size=bytes_to_int({getc(zfn),getc(zfn),getc(zfn),getc(zfn)})
    
    -- Uncompressed size - 4 bytes
    uncompressed_size=bytes_to_int({getc(zfn),getc(zfn),getc(zfn),getc(zfn)})
    
    -- Filename length - 2 bytes
    filename_length=getc(zfn)+getc(zfn)*256

    -- Extra field length - 2 bytes
    extra_length=getc(zfn)+getc(zfn)*256
    
    -- Test for EOF
    if crc[4]=-1 then
        return ZIP_UNEXPECTED_EOF
    end if
    
    -- Read filename
    filename=repeat(0,filename_length)
    for temp=1 to filename_length do
        filename[temp]=getc(zfn)
    end for                    

    -- Skip extra field
    for temp=1 to extra_length do
        junk=getc(zfn)
    end for                    

    -- Test for EOF
    if junk=-1 then
        return ZIP_UNEXPECTED_EOF
    end if

    -- Get position of beggining of compressed data
    position_in_file=where(zfn)
    
    -- Return
--    return {filename,flags,method,crc,compressed_size,uncompressed_size,position_in_file}
    info=repeat(0,13)
    info[Z_NAME]=filename
    info[Z_CRC]=crc
    info[Z_FLAGS]=flags
    info[Z_METHOD]=method
    info[Z_CSIZE]=compressed_size
    info[Z_SIZE]=uncompressed_size
    info[Z_POSITION]=position_in_file
    info[Z_TIME..Z_TIME+2]=file_time
    info[Z_DATE..Z_DATE+2]=file_date

    return info

end function


global procedure close_zip()
    if zfn!=-1 then
        close(zfn)
        zfn=-1
        dir_info={}
    end if
end procedure

global function open_zip(sequence zip_file_name)
    atom lof
    object header
    
    -- Open file
    if zfn!=-1 then close_zip() end if
    zfn=open(zip_file_name,"rb")
    if zfn=-1 then
        return {ZIP_FILE_NOT_FOUND,{}}
    end if
    lof=file_size(zfn)
    if lof=-1 then
        return {ZIP_FILE_READING_ERROR,{}}
    end if

    while 1 do

        header=read_header()
        if atom(header) then
            if header=CENTRAL_DIRECTORY_REACHED then
                return {ZIP_NO_ERRORS,dir_info}
            else -- error
                return {header,dir_info}
            end if
        end if

        if and_bits(header[Z_FLAGS],8) and header[Z_METHOD]=8 then   -- Bit 3 is set
            return {ZIP_UNSUPPORTED,dir_info}
        end if

        dir_info=append(dir_info,header)

        if header[Z_POSITION]+header[Z_CSIZE]>=lof then    -- Past end of file
            return {ZIP_UNEXPECTED_EOF,dir_info}
        end if

        if seek(zfn,header[Z_POSITION]+header[Z_CSIZE]) then -- Skip compressed data
            return {ZIP_FILE_READING_ERROR,dir_info}
        end if

    end while

end function


function find_file_in_zip(sequence filename)

    filename=upper(filename)
    for temp=1 to length(dir_info) do
        if compare(upper(dir_info[temp][Z_NAME]),filename)=0 then -- Found file
            return dir_info[temp]
        end if
    end for

    return {}    
end function


global function unzip_file(sequence filename)
    sequence file_info,comp_file
    object uncompressed_file

    if zfn=-1 then return {ZIP_FILE_NOT_FOUND,{}} end if

    file_info=find_file_in_zip(filename)

    if not length(file_info) then   -- File not found
        return {ZIP_FILE_NOT_FOUND,{}}
    end if


    if seek(zfn,file_info[Z_POSITION]) then -- Go to beggining of compressed data
        return {ZIP_FILE_READING_ERROR,{}}
    end if

    if (file_info[Z_METHOD]!=8 and file_info[Z_METHOD]!=0) then -- Not DEFLATEd or stored, unknown method
        return {ZIP_UNSUPPORTED,{}}
    end if

    if and_bits(file_info[Z_FLAGS],1) then -- Encrypted file
        return {ZIP_WRONG_PASSWORD,{}}
    end if
    


    comp_file=read_bytes(zfn,file_info[Z_CSIZE])

    if file_info[Z_METHOD]=0 then  -- Stored file

        uncompressed_file=comp_file

        if file_info[Z_SIZE]!=length(uncompressed_file) then
            return {ZIP_UNEXPECTED_EOF,uncompressed_file}
        end if

        uncompressed_file={0,uncompressed_file}


    elsif file_info[Z_METHOD]=8 then   -- Deflated file

        uncompressed_file=inflate(comp_file,file_info[Z_SIZE])

        if uncompressed_file[1] then    -- Error in decompression
            return uncompressed_file[1..2]
        end if

        if file_info[Z_CSIZE]!=uncompressed_file[3]  then
            return {ZIP_CORRUPTED_DATA,uncompressed_file[2]}   -- Wrong compressed size
        end if
        
        if file_info[Z_SIZE]!=length(uncompressed_file[2]) then
            return {ZIP_CORRUPTED_DATA,uncompressed_file[2]}   -- Wrong uncompressed size
        end if

    end if

    -- Check decompression
    if compare(file_info[Z_CRC],crc_32(uncompressed_file[2])) then
        return {ZIP_WRONG_CHECKSUM,uncompressed_file[2]}   -- Wrong CRC
    end if


    return uncompressed_file[1..2]

end function

