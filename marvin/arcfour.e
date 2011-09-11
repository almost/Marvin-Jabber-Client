-- arcfour.e - Arcfour encryption algorithm - version 1.11
-- Copyright (C) 2000  Davi Tassinari de Figueiredo
--
-- Export or use of this program may be restricted in some countries.
--
-- If you wish to contact me, send an e-mail to davitf@usa.net .
--
-- You can get the latest version of this program from my Euphoria page:
-- http://davitf.n3.net/
--
--
-- License terms and disclaimer:
--
-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it
-- freely, subject to the following restrictions:
--
-- 1. The origin of this software must not be misrepresented; you must not
--    claim that you wrote the original software or remove the original
--    authors' names.
-- 2. Altered source versions must be plainly marked as such, and must not
--    be misrepresented as being the original software.
-- 3. All source distributions, with or without modifications, must be
--    distributed under this license. If this software's source code is
--    distributed as part of a larger product, this item does not apply to
--    the rest of the product.
-- 4. If you use this software in a product, an acknowledgment in the
--    product documentation is required. If the source code for the product
--    is not freely distributed, you must include information on how to
--    freely obtain the original software's source code.
--
-- This software is provided 'as-is', without any express or implied
-- warranty.  In no event will the authors be held liable for any damages
-- arising from the use of this software.
--
-- If you want to distribute this software in a way not allowed by this
-- license, or distribute the source under different license terms, contact
-- the authors for permission.

include machine.e

constant state_address=allocate(256),
	 a_address=allocate(2),b_address=a_address+1,max_block_size=1024,
	 data_address=allocate(max_block_size), key_address = allocate(256)

constant arcf_init = allocate(88)
poke( arcf_init, and_bits(#FF,
"ÅÈÆÇÌË¦5¦G.uuuuþ@ýx¸s5±uêl¦P3uuuu¦tÿ‰}w‘¬uHÿ©€ý‰€ý©}¼ötuuuuçw¦tµ²"-117&
"üýüünØžüüüüžüüüüZ[VUWT¿"+4))
poke4(arcf_init + 11, state_address)
poke4(arcf_init + 29, key_address)
poke4(arcf_init + 72, a_address)
poke4(arcf_init + 77, b_address)
constant key_length_address = arcf_init + 55

constant arcfour_enc = allocate(93)
poke(arcfour_enc, and_bits(#FF,
"øûùúÿþÙhÙzH¨¨¨¨2Í¨¨¨¨a¨¨¨¨f¨¨¨¨¦hÙz0j1©w2Ç¨„0Š©r2â0Â0çÙz0‚¨¢2¼²Ø¾"+88&
"E€ýÿÿÿÿqÓ¡ÿÿÿÿ‡$ÿÿÿÿ]^YXZWÂ"+1))
poke4(arcfour_enc + 11, a_address)
poke4(arcfour_enc + 17, b_address)
poke4(arcfour_enc + 22, state_address)
poke4(arcfour_enc + 27, data_address)
poke4(arcfour_enc + 76, a_address)
poke4(arcfour_enc + 82, b_address)


constant max_data_address = arcfour_enc + 69

-- Read, write and clean state
function get_state()
    return {peek(a_address), peek(b_address), peek({state_address, 256})}
end function

procedure put_state(sequence state)
    poke(a_address, state[1])
    poke(b_address, state[2])
    poke(state_address, state[3])
end procedure

procedure clean_state()
    poke(a_address, 0)
    poke(b_address, 0)
    mem_set(state_address, 0, 256)
end procedure

-- Generate state based on key
procedure arcfour_init(sequence key)
    -- Write key length
    poke4(key_length_address, length(key))
    -- Write key
    poke(key_address, key)
    -- Call initialization routine
    call(arcf_init)
end procedure


function arcfour_encryption(sequence data)

    -- Store maximum block length
    poke4(max_data_address, data_address+max_block_size)

    for t=1 to length(data) by max_block_size do
	-- Proccess one block at a time
	if t+max_block_size<=length(data) then   -- Not last block yet

	    -- Write data to memory
	    poke(data_address,data[t..t+max_block_size-1])
	    -- Call encryption/decryption routine
	    call(arcfour_enc)
	    -- Store data in sequence
	    data[t..t+max_block_size-1]=peek({data_address,max_block_size})

	else                                -- Last block

	    -- Write data length
	    poke4(max_data_address, data_address+length(data)-t+1)
	    -- Write data to memory
	    poke(data_address,data[t..length(data)])
	    -- Call encryption/decryption routine
	    call(arcfour_enc)
	    -- Store data in sequence
	    data[t..length(data)]=peek({data_address,length(data)-t+1})

	end if

    end for

    -- Erase data from memory
    mem_set (data_address, 0, max_block_size)
    return data
end function


-- Stream routines
sequence state
global procedure arcfour_init_encrypt(sequence key)
    arcfour_init(key)
    state = get_state()
    clean_state()
end procedure

global function arcfour_encrypt_block(sequence data)
    put_state(state)
    data = arcfour_encryption (data)
    state = get_state()
    clean_state()
    return data
end function

global function arcfour_decrypt_block(sequence data)
    return arcfour_encrypt_block(data)
end function

-- Simple routines
global function arcfour_encrypt(sequence data, sequence key)
    arcfour_init(key)
    data = arcfour_encryption (data)
    clean_state()
    return data
end function

global function arcfour_decrypt(sequence data, sequence key)
    return arcfour_encrypt(data, key)
end function

