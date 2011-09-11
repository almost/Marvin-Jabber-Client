-----------------------------------------------------------------------------
--                                                                         --
--  DateTime.e - Routines for handling Date and Time - (c) 2001 CyrekSoft  --
--                                                                         --
-----------------------------------------------------------------------------

--Changed CrashMessage to CrashMessage for compatability with machine.e

-- include machine.e -- segment:
constant M_CrashMessage = 37

procedure CrashMessage(sequence msg)
    machine_proc(M_CrashMessage, msg & "\n--> see ex.err\n")
end procedure

-- Constants and Type Declarations ------------------------------------------

-- Change this to 1 for extended leap year rules
global integer XLEAP
    XLEAP = 0

constant--s
    Gregorian_Reformation   = 1752,
    Gregorian_Reformation00 = 1700,

    DaysPerMonth = {
    31,         28,         31,         30,
    31,         30,         31,         31,
    30,         31,         30,         31
    },

    AverageDaysPerMonth = 30.43687604,
    AverageDaysPerYear  = 12 * AverageDaysPerMonth

global constant--s
-- Zero Date -- 1 Jan 1AD
    Date_0 = {1, 1, 1},

-- Zero Time (or possibly Midnight)
    Time_0 = {0, 0, 0},

-- Zero DateTime
    DateTime_0 = {Date_0, Time_0},

-- Date/Time/DateTime datatype indices
    DT_DATE = 1, YEAR  = 1, MONTH   = 2, DAY     = 3, JDAY = 2,
    DT_TIME = 2, HOURS = 1, MINUTES = 2, SECONDS = 3,

-- 1970 Epoch DateTime
    EPOCH_1970 = { { 1970, 1, 1 }, Time_0 },

    DayLengthInSeconds = 86400

-- Dates
    type year_(object y) if integer(y) and
    -2500000 <= y and y <= 2500000
    then return 1 end if  return 0  end type

    type month_(object m) if integer(m) and
    1 <= m and m <= 12
    then return 1 end if  return 0  end type

    type day_(object d) if integer(d) and
    1 <= d and d <= 31
    then return 1 end if  return 0  end type

    type jday_(object d) if integer(d) and
    1 <= d and d <= 366
    then return 1 end if  return 0  end type

global type Date(object ymd) if sequence(ymd) and length(ymd) = 3 and
    year_(ymd[YEAR]) and month_(ymd[MONTH]) and day_(ymd[DAY])
then return 1 end if  return 0  end type

global type JDate(object ymd) if sequence(ymd) and length(ymd) = 2 and
    year_(ymd[YEAR]) and jday_(ymd[JDAY])
then return 1 end if  return 0  end type

-- Times
    type hour_(object h) if integer(h) and
    0 <= h and h <= 23
    then return 1 end if  return 0  end type

    type minute_(object m) if integer(m) and
    0 <= m and m <= 59
    then return 1 end if  return 0  end type

    type seconds_(object s) if atom(s) and
    0 <= s and s <  60
    then return 1 end if  return 0  end type

global type Time(object hms) if sequence(hms) and length(hms) = 3 and
    hour_(hms[HOURS]) and minute_(hms[MINUTES]) and seconds_(hms[SECONDS])
then return 1 end if  return 0  end type

-- Date and Time combined data type

global type DateTime(object dt) if sequence(dt) and length(dt) = 2 and
    Date(dt[DT_DATE]) and Time(dt[DT_TIME])
then return 1 end if  return 0  end type

-- Date Handling ------------------------------------------------------------

-- 'Now'

global function nowDate() -- returns a Date
    sequence now now = date()
    return (now[1] + 1900) & now[2..3]
end function

-- Basic functions

global function isLeap(year_ year) -- returns integer (0 or 1)
    sequence ly
    ly = (remainder(year, {4, 100, 400, 3200, 80000})=0)

    if not ly[1] then return 0 end if

    if year <= Gregorian_Reformation then
    return 1 -- ly[1] can't possibly be 0 here so set shortcut as '1'.

    elsif XLEAP then
    return ly[1] - ly[2] + ly[3] - ly[4] + ly[5]

    else -- Standard Gregorian Calendar
    return ly[1] - ly[2] + ly[3]

    end if
end function

global function daysInMonth(year_ year, month_ month) -- returns a month_
    if year = Gregorian_Reformation and month = 9 then
    return 19
    elsif month != 2 then
    return DaysPerMonth[month]
    else
    return DaysPerMonth[month] + isLeap(year)
    end if
end function

global function daysInYear(year_ year) -- returns a jday_ (355, 365 or 366)
    if year = Gregorian_Reformation then
    return 355
    end if
    return 365 + isLeap(year)
end function

-- Functions using the new data-types

global function julianDayOfYear(Date ymd) -- returns an integer
    integer year, month, day
    integer d

    year = ymd[YEAR]
    month = ymd[MONTH]
    day = ymd[DAY]

    if month = 1 then return day end if

    d = 0
    for i = 1 to month - 1 do
    d += daysInMonth(year, i)
    end for

    d += day

    if year = Gregorian_Reformation and month = 9 and
       2 < day and day < 14
    then
    d -= 11
    end if

    return d
end function

global function julianDateInYear(JDate yd) -- returns a Date
    integer year, d
    year = yd[YEAR]
    d = yd[JDAY]

    -- guess month
    if d <= daysInMonth(year, 1) then
    return {year, 1, d}
    end if
    for month = 2 to 12 do
    d -= daysInMonth(year, month-1)
    if d <= daysInMonth(year, month) then
        return {year, month, d}
    end if
    end for

    -- we should never get here
    CrashMessage("julianDateInYear(): oops! Things haven't quite worked out!")
end function

global function JDateToDate(object o) -- Converts a JDate to a Date
    return julianDateInYear(o) -- we're just aliasing jDIY here
end function

global function DateToJDate(Date d) -- Converts a Date to a JDate
    return d[YEAR] & julianDayOfYear(d)
end function

global function julianDay(Date ymd) -- returns an integer
    integer year
    integer j, greg00

    year = ymd[YEAR]
    j = julianDayOfYear(ymd)

    year  -= 1
    greg00 = year - Gregorian_Reformation00

    j += (
    365 * year
    + floor(year/4)
    + (greg00 > 0)
        * (
        - floor(greg00/100)
        + floor(greg00/400+.25)
        )
    - 11 * (year >= Gregorian_Reformation)
    )

    if XLEAP then
    j += (
        - (year >=  3200) * floor(year/ 3200)
        + (year >= 80000) * floor(year/80000)
    )
    end if

    return j
end function

global function julianDate(integer j) -- returns a Date
    integer year, doy

    -- Take a guesstimate at the year -- this is usually v.close
    if j >= 0 then
    year = floor(j / AverageDaysPerYear) + 1
    else
    year = -floor(-j / 365.25) + 1
    end if

    -- Calculate the day in the guessed year
    doy = j - (julianDay({year, 1, 1}) - 1) -- = j - last day of prev year

    -- Correct any errors

    -- The guesstimate is usually so close that these whiles could probably
    -- be made into ifs, but I haven't checked all possible dates yet... ;)

    while doy <= 0 do -- we guessed too high for the year
    year -= 1
    doy += daysInYear(year)
    end while

    while doy > daysInYear(year) do -- we guessed too low
    doy -= daysInYear(year)
    year += 1
    end while

    return julianDateInYear({year, doy})
end function

-- Date Math I

global function daysDifference(Date past, Date future) -- returns an integer
    return julianDay(future) - julianDay(past)
end function

global function daysSince(Date past) -- returns an integer
    Date now now = nowDate()
    return daysDifference(past, now)
end function

global function daysUntil(Date future) -- returns an integer
    return -daysSince(future)
end function

-- Date Math II

global function addToDate(Date a, integer b) -- returns a Date
    return julianDate(julianDay(a) + b)
end function

global function subFromDate(Date a, integer b) -- returns a Date
    return julianDate(julianDay(a) - b)
end function

-- Super-strict types -- also usable as boolean functions

global type ValidDate(object d) if Date(d) and
    equal(d, julianDate(julianDay(d)))
then return 1 end if  return 0  end type

global type ValidDateTime(object dt) if DateTime(dt) and
    ValidDate(dt[DT_DATE]) -- and Time(dt[DT_TIME])
then return 1 end if  return 0  end type

-- Day of week

function clock7(integer number) -- returns an integer (1..7)
    return remainder(number+4094, 7)+1
    -- modulo(number-1, 7)+1 would be better. Hence adding a few multiples
    --   of 7 to the -1 in the remainder() call
end function

global function dayOfWeek(Date ymd) -- returns an integer
    return clock7(julianDay(ymd)-1)
    -- Sun..Sat = 1..7
end function

-- Time calculations --------------------------------------------------------

-- 'Now'

global function nowTime() -- returns a Time
    sequence now now = date()
    return now[4..6]
end function

-- Conversions to and from seconds

global function hmsToSeconds(Time hms) -- returns an atom
    return (hms[HOURS] * 60 + hms[MINUTES]) * 60 + hms[SECONDS]
end function

global function secondsToHms(atom in) -- returns a Time
    integer hours, minutes
    atom secs

    in = remainder(in, DayLengthInSeconds)
    if in < 0 then in += DayLengthInSeconds end if

    secs = remainder(in, 60)

    in = floor(in / 60)
    minutes = remainder(in, 60)

    hours = remainder(floor(in / 60), 24)

    return {hours, minutes, secs}
end function

-- Time Math I -- See DateTime Math I

-- Time Math II

global function addToTime(Time a, object b) -- returns a Time
    if Time(b) then b = hmsToSeconds(b) end if
    if atom(b) then
    return secondsToHms(hmsToSeconds(a) + b)
    end if
    CrashMessage("Expected an atom or a Time as second parameter in addToTime()")
end function

global function subFromTime(Time a, object b) -- returns a Time
    if Time(b) then b = hmsToSeconds(b) end if
    if atom(b) then
    return secondsToHms(hmsToSeconds(a) - b)
    end if
    CrashMessage("Expected an atom or a Time as second parameter in subFromTime()")
end function

-- DateTime Calculations ----------------------------------------------------

-- 'Now'

global function nowDateTime()
    sequence now now = date()
    return {now[1..3] + {1900,0,0}, now[4..6]}
end function

-- Conversions to and from seconds

global function DateTimeToSeconds(DateTime dt) -- returns an atom
    return
    + julianDay(dt[DT_DATE]) * DayLengthInSeconds
    + hmsToSeconds(dt[DT_TIME])
end function

global function secondsToDateTime(atom seconds) -- returns a DateTime
    integer days

    days = floor(seconds / DayLengthInSeconds)
    seconds = remainder(seconds, DayLengthInSeconds)

    return {julianDate(days), secondsToHms(seconds)}
end function

-- Conversions to and from Dates

global function DateToDateTime(Date d) -- returns a DateTime
    return {d, Time_0}
end function

global function DateTimeToDate(DateTime dt) -- returns a Date
    return dt[DT_DATE] -- Warning! Loss of DT_TIME information!
end function

-- DateTime Math I

global function secondsDifference(object past, object future)
    if Time(past) and Time(future) then
    return hmsToSeconds(future) - hmsToSeconds(past)
    elsif DateTime(past) and DateTime(future) then
    return DateTimeToSeconds(future) - DateTimeToSeconds(past)
    end if
    CrashMessage("Expected matching DateTimes or Times in secondsDifference()")
end function

-- DateTime Math II

global function addToDateTime(DateTime a, object b) -- returns a DateTime
    if Time(b) then b = hmsToSeconds(b) end if
    if atom(b) then return secondsToDateTime(DateTimeToSeconds(a) + b) end if
    CrashMessage("Expected an atom or a Time as second parameter in addToDateTime()")
end function

global function subFromDateTime(DateTime a, object b) -- returns a DateTime
    if Time(b) then b = hmsToSeconds(b) end if
    if atom(b) then return secondsToDateTime(DateTimeToSeconds(a) - b) end if
    CrashMessage("Expected an atom or a Time as second parameter in subFromDateTime()")
end function

-- Variable Epoch calculations ----------------------------------------------

global DateTime Epoch
    Epoch = EPOCH_1970 -- set default

global function secondsSinceEpoch(atom seconds) -- returns an atom
    return seconds - DateTimeToSeconds(Epoch)
end function

global function EpochTimeTo1ADTime(atom eseconds) -- returns an atom
    return eseconds + DateTimeToSeconds(Epoch)
end function

