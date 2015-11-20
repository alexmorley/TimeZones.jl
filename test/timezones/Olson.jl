import TimeZones: Transition
import TimeZones.Olson: ZoneDict, RuleDict, zoneparse, ruleparse, resolve, parsedate, order_rules
import Base.Dates: Hour, Minute, Second

# Variations of until dates
@test parsedate("1945") == (DateTime(1945), 'w')
@test parsedate("1945 Aug") == (DateTime(1945,8), 'w')
@test parsedate("1945 Aug 2") == (DateTime(1945,8,2), 'w')
@test parsedate("1945 Aug 2 12") == (DateTime(1945,8,2,12), 'w')  # Doesn't actually occur
@test parsedate("1945 Aug 2 12:34") == (DateTime(1945,8,2,12,34), 'w')
@test parsedate("1945 Aug 2 12:34:56") == (DateTime(1945,8,2,12,34,56), 'w')

# Make sure parsing can handle additional spaces.
@test parsedate("1945  Aug") == (DateTime(1945,8), 'w')
@test parsedate("1945  Aug  2") == (DateTime(1945,8,2), 'w')
@test parsedate("1945  Aug  2  12") == (DateTime(1945,8,2,12), 'w')
@test parsedate("1945  Aug  2  12:34") == (DateTime(1945,8,2,12,34), 'w')
@test parsedate("1945  Aug  2  12:34:56") == (DateTime(1945,8,2,12,34,56), 'w')

# Explicit zone "local wall time"
@test_throws Exception parsedate("1945w")
@test_throws Exception parsedate("1945 Augw")
@test_throws Exception parsedate("1945 Aug 2w")
@test parsedate("1945 Aug 2 12w") == (DateTime(1945,8,2,12), 'w')
@test parsedate("1945 Aug 2 12:34w") == (DateTime(1945,8,2,12,34), 'w')
@test parsedate("1945 Aug 2 12:34:56w") == (DateTime(1945,8,2,12,34,56), 'w')

# Explicit zone "UTC time"
@test_throws Exception parsedate("1945u")
@test_throws Exception parsedate("1945 Augu")
@test_throws Exception parsedate("1945 Aug 2u")
@test parsedate("1945 Aug 2 12u") == (DateTime(1945,8,2,12), 'u')
@test parsedate("1945 Aug 2 12:34u") == (DateTime(1945,8,2,12,34), 'u')
@test parsedate("1945 Aug 2 12:34:56u") == (DateTime(1945,8,2,12,34,56), 'u')

# Explicit zone "standard time"
@test_throws Exception parsedate("1945s")
@test_throws Exception parsedate("1945 Augs")
@test_throws Exception parsedate("1945 Aug 2s")
@test parsedate("1945 Aug 2 12s") == (DateTime(1945,8,2,12), 's')
@test parsedate("1945 Aug 2 12:34s") == (DateTime(1945,8,2,12,34), 's')
@test parsedate("1945 Aug 2 12:34:56s") == (DateTime(1945,8,2,12,34,56), 's')

# Invalid zone
@test_throws Exception parsedate("1945 Aug 2 12:34i")

# Actual until date found in Zone "Pacific/Apia"
@test parsedate("2011 Dec 29 24:00") == (DateTime(2011,12,30), 'w')


warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)

# Europe/Warsaw timezone has a combination of factors that requires computing
# the abbreviation to be done in a specific way.
@test warsaw.transitions[1].zone.name == :LMT
@test warsaw.transitions[2].zone.name == :WMT
@test warsaw.transitions[3].zone.name == :CET   # Standard time
@test warsaw.transitions[4].zone.name == :CEST  # Daylight saving time
@test issorted(warsaw.transitions)

zone = Dict{AbstractString,FixedTimeZone}()
zone["LMT"] = FixedTimeZone("LMT", 5040, 0)
zone["WMT"] = FixedTimeZone("WMT", 5040, 0)
zone["CET"] = FixedTimeZone("CET", 3600, 0)
zone["CEST"] = FixedTimeZone("CEST", 3600, 3600)
zone["EET"] = FixedTimeZone("EET", 7200, 0)
zone["EEST"] = FixedTimeZone("EEST", 7200, 3600)

@test warsaw.transitions[1] == Transition(typemin(DateTime), zone["LMT"])  # Ideally -Inf
@test warsaw.transitions[2] == Transition(DateTime(1879,12,31,22,36), zone["WMT"])
@test warsaw.transitions[3] == Transition(DateTime(1915,8,4,22,36), zone["CET"])
@test warsaw.transitions[4] == Transition(DateTime(1916,4,30,22,0), zone["CEST"])
@test warsaw.transitions[5] == Transition(DateTime(1916,9,30,23,0), zone["CET"])
@test warsaw.transitions[6] == Transition(DateTime(1917,4,16,1,0), zone["CEST"])
@test warsaw.transitions[7] == Transition(DateTime(1917,9,17,1,0), zone["CET"])
@test warsaw.transitions[8] == Transition(DateTime(1918,4,15,1,0), zone["CEST"])
@test warsaw.transitions[9] == Transition(DateTime(1918,9,16,1,0), zone["EET"]) #
@test warsaw.transitions[10] == Transition(DateTime(1919,4,15,0,0), zone["EEST"])
@test warsaw.transitions[11] == Transition(DateTime(1919,9,16,0,0), zone["EET"])
@test warsaw.transitions[12] == Transition(DateTime(1922,5,31,22,0), zone["CET"]) #
@test warsaw.transitions[13] == Transition(DateTime(1940,6,23,1,0), zone["CEST"])

@test warsaw.transitions[14] == Transition(DateTime(1942,11,2,1,0), zone["CET"])
@test warsaw.transitions[15] == Transition(DateTime(1943,3,29,1,0), zone["CEST"])
@test warsaw.transitions[16] == Transition(DateTime(1943,10,4,1,0), zone["CET"])
@test warsaw.transitions[17] == Transition(DateTime(1944,4,3,1,0), zone["CEST"])
@test warsaw.transitions[18] == Transition(DateTime(1944,10,4,0,0), zone["CET"])


# Zone Pacific/Honolulu contains the following properties which make it good for testing:
# - Zone's contain save in rules field
# - Zone abbreviation redefined: HST

honolulu = resolve("Pacific/Honolulu", tzdata["northamerica"]...)

zone = Dict{AbstractString,FixedTimeZone}()
zone["LMT"] = FixedTimeZone("LMT", -37886, 0)
zone["HST"] = FixedTimeZone("HST", -37800, 0)
zone["HDT"] = FixedTimeZone("HDT", -37800, 3600)
zone["HST_NEW"] = FixedTimeZone("HST", -36000, 0)

@test honolulu.transitions[1] == Transition(typemin(DateTime), zone["LMT"])
@test honolulu.transitions[2] == Transition(DateTime(1896,1,13,22,31,26), zone["HST"])
@test honolulu.transitions[3] == Transition(DateTime(1933,4,30,12,30), zone["HDT"])
@test honolulu.transitions[4] == Transition(DateTime(1933,5,21,21,30), zone["HST"])
@test honolulu.transitions[5] == Transition(DateTime(1942,2,9,12,30), zone["HDT"])
@test honolulu.transitions[6] == Transition(DateTime(1945,9,30,11,30), zone["HST"])
@test honolulu.transitions[7] == Transition(DateTime(1947,6,8,12,30), zone["HST_NEW"])


# Zone Pacific/Apia contains the following properties which make it good for testing:
# - Offset switch from -11:00 to 13:00
# - Rules interaction with a large negative offset
# - Rules interaction with a large positive offset
# - Includes a DateTime Julia could consider invalid: "2011 Dec 29 24:00"
# - Changed zone format while in a non-standard transition
# - Zone abbreviation redefined: LMT, WSST

apia = resolve("Pacific/Apia", tzdata["australasia"]...)

zone = Dict{AbstractString,FixedTimeZone}()
zone["LMT_OLD"] = FixedTimeZone("LMT", 45184, 0)
zone["LMT"] = FixedTimeZone("LMT", -41216, 0)
zone["WSST_OLD"] = FixedTimeZone("WSST", -41400, 0)
zone["SST"] = FixedTimeZone("SST", -39600, 0)
zone["SDT"] = FixedTimeZone("SDT", -39600, 3600)
zone["WSST"] = FixedTimeZone("WSST", 46800, 0)
zone["WSDT"] = FixedTimeZone("WSDT", 46800, 3600)

@test apia.transitions[1] == Transition(typemin(DateTime), zone["LMT_OLD"])
@test apia.transitions[2] == Transition(DateTime(1879,7,4,11,26,56), zone["LMT"])
@test apia.transitions[3] == Transition(DateTime(1911,1,1,11,26,56), zone["WSST_OLD"])
@test apia.transitions[4] == Transition(DateTime(1950,1,1,11,30), zone["SST"])
@test apia.transitions[5] == Transition(DateTime(2010,9,26,11), zone["SDT"])
@test apia.transitions[6] == Transition(DateTime(2011,4,2,14), zone["SST"])
@test apia.transitions[7] == Transition(DateTime(2011,9,24,14), zone["SDT"])
@test apia.transitions[8] == Transition(DateTime(2011,12,30,10), zone["WSDT"])
@test apia.transitions[9] == Transition(DateTime(2012,3,31,14), zone["WSST"])
@test apia.transitions[10] == Transition(DateTime(2012,9,29,14), zone["WSDT"])


# Zone Europe/Madrid contains the following properties which make it good for testing:
# - Observed midsummer time
# - End of midsummer time also switches both the UTC offset and the saving time
# - In 1979-01-01 switches from "Spain" to "EU" rules which could create a redundant entry
madrid = resolve("Europe/Madrid", tzdata["europe"]...)

zone = Dict{AbstractString,FixedTimeZone}()
zone["WET"] = FixedTimeZone("WET", 0, 0)
zone["WEST"] = FixedTimeZone("WEST", 0, 3600)
zone["WEMT"] = FixedTimeZone("WEMT", 0, 7200)
zone["CET"] = FixedTimeZone("CET", 3600, 0)
zone["CEST"] = FixedTimeZone("CEST", 3600, 3600)

@test madrid.transitions[23] == Transition(DateTime(1939,4,15,23), zone["WEST"])
@test madrid.transitions[24] == Transition(DateTime(1939,10,7,23), zone["WET"])
@test madrid.transitions[25] == Transition(DateTime(1940,3,16,23), zone["WEST"])
@test madrid.transitions[26] == Transition(DateTime(1942,5,2,22), zone["WEMT"])

@test madrid.transitions[33] == Transition(DateTime(1945,9,29,23), zone["WEST"])
@test madrid.transitions[34] == Transition(DateTime(1946,4,13,22), zone["WEMT"])
@test madrid.transitions[35] == Transition(DateTime(1946,9,29,22), zone["CET"])
@test madrid.transitions[36] == Transition(DateTime(1949,4,30,22), zone["CEST"])

# Redundant transition would be around 1979-01-01T00:00:00 as CET
@test madrid.transitions[47] == Transition(DateTime(1978,9,30,23), zone["CET"])
@test madrid.transitions[48] == Transition(DateTime(1979,4,1,1), zone["CEST"])


# Behaviour of mixing "RULES" as a String and as a Time. In reality this behaviour has never
# been observed.

# Manually generate zones and rules as if we had read them from a file.
zones = ZoneDict()
rules = RuleDict()

zones["Pacific/Test"] = [
    zoneparse("-10:00", "-", "TST-1", "1933 Apr 1 2:00s"),
    zoneparse("-10:00", "1:00", "TDT-2", "1933 Sep 1 2:00s"),
    zoneparse("-10:00", "Testing", "T%sT-3", "1934 Sep 1 3:00s"),
    zoneparse("-10:00", "1:00", "TDT-4", "1935 Sep 1 3:00s"),
    zoneparse("-10:00", "Testing", "T%sT-5", ""),
]
rules["Testing"] = [
    ruleparse("1934", "1935", "-", "Apr", "1", "3:00s", "1", "D"),
    ruleparse("1934", "1935", "-", "Sep", "1", "3:00s", "0", "S"),
]

test = resolve("Pacific/Test", zones, rules)

zone = Dict{AbstractString,FixedTimeZone}()
zone["TST-1"] = FixedTimeZone("TST-1", -36000, 0)
zone["TDT-2"] = FixedTimeZone("TDT-2", -36000, 3600)
zone["TST-3"] = FixedTimeZone("TST-3", -36000, 0)
zone["TDT-3"] = FixedTimeZone("TDT-3", -36000, 3600)
zone["TDT-4"] = FixedTimeZone("TDT-4", -36000, 3600)
zone["TST-5"] = FixedTimeZone("TST-5", -36000, 0)
zone["TDT-5"] = FixedTimeZone("TDT-5", -36000, 3600)

@test test.transitions[1] == Transition(typemin(DateTime), zone["TST-1"])
@test test.transitions[2] == Transition(DateTime(1933,4,1,12), zone["TDT-2"]) # -09:00
@test test.transitions[3] == Transition(DateTime(1933,9,1,12), zone["TST-3"])
@test test.transitions[4] == Transition(DateTime(1934,4,1,13), zone["TDT-3"])
@test test.transitions[5] == Transition(DateTime(1934,9,1,13), zone["TDT-4"])
@test test.transitions[6] == Transition(DateTime(1935,9,1,13), zone["TST-5"])

# Note: Due to how the the zones/rules were written a redundant transition could be created
# such that `test.transitions[6] == test.transitions[7]`. The TimeZone code can safely
# handle redundant transitions but ideally they should be eliminated.
@test length(test.transitions) == 6

# Make sure that we can deal with Links. Take note that the current implementation converts
# links into zones which makes it hard to explicitly test for a link. We expect that the
# following link exists:
#
# Link  Europe/Oslo  Arctic/Longyearbyen

# Make sure that that the link timezone was parsed.
zone_names = keys(tzdata["europe"][1])
@test "Arctic/Longyearbyen" in zone_names

oslo = resolve("Europe/Oslo", tzdata["europe"]...)
longyearbyen = resolve("Arctic/Longyearbyen", tzdata["europe"]...)

@test oslo.transitions == longyearbyen.transitions


# Zones that don't include multiple lines and no rules should be treated as a FixedTimeZone.
mst = resolve("MST", tzdata["northamerica"]...)
@test isa(mst, FixedTimeZone)

# order rules
    # Rule    Poland  1918    1919    -   Sep 16  2:00s   0       -
    # Rule    Poland  1919    only    -   Apr 15  2:00s   1:00    S
    # Rule    Poland  1944    only    -   Apr  3  2:00s   1:00    S
rule_a = ruleparse("1918", "1919", "-", "Sep", "16", "2:00s", "0", "-")
rule_b = ruleparse("1919", "only", "-", "Apr", "15", "2:00s", "1:00", "S")
rule_c = ruleparse("1944", "only", "-", "Apr", "3", "2:00s", "1:00", "S")

for rules in ([rule_a, rule_b, rule_c], [rule_c, rule_b, rule_a], [rule_a, rule_c, rule_b])
    dates, ordered = order_rules(rules)

    @test dates == [Date(1918, 9, 16), Date(1919, 4, 15), Date(1919, 9, 16), Date(1944, 4, 3)]
    @test ordered == [rule_a, rule_b, rule_a, rule_c]
end

# ignore rules starting after the cutoff
dates, ordered = order_rules([rule_a, rule_b, rule_c], max_year=1940)
@test dates == [Date(1918, 9, 16), Date(1919, 4, 15), Date(1919, 9, 16)]
@test ordered == [rule_a, rule_b, rule_a]

# make sure order_rules works for both 32- and 64-bit julia
for year in (Int32(1940), Int64(1940))
    dates, ordered = order_rules([rule_a, rule_b, rule_c], max_year=year)
    @test dates == [DateTime(1918, 9, 16), DateTime(1919, 4, 15), DateTime(1919, 9, 16)]
    @test ordered == [rule_a, rule_b, rule_a]
end

# truncate rules ending after the cutoff
rule_pre = ruleparse("1999", "only", "-", "Jun", "7", "2:00s", "0", "P" )
rule_overlap = ruleparse("1999", "2001", "-", "Jan", "1", "0:00s", "0", "-")
rule_endless = ruleparse("1993", "max", "-", "Feb", "2", "6:00s", "0", "G")
rule_post = ruleparse("2002", "only", "-", "Jan", "1", "0:00s", "0", "IP")

truncated = ruleparse("1999", "2000", "-", "Jan", "1", "0:00s", "0", "-")

dates, ordered = order_rules([rule_post, rule_endless, rule_overlap, rule_pre], max_year=2000)
@test dates == [
    Date(1993, 2, 2),
    Date(1994, 2, 2),
    Date(1995, 2, 2),
    Date(1996, 2, 2),
    Date(1997, 2, 2),
    Date(1998, 2, 2),
    Date(1999, 1, 1),
    Date(1999, 2, 2),
    Date(1999, 6, 7),
    Date(2000, 1, 1),
    Date(2000, 2, 2),
]

expected = [
    rule_endless,
    rule_endless,
    rule_endless,
    rule_endless,
    rule_endless,
    rule_endless,
    truncated,
    rule_endless,
    rule_pre,
    truncated,
    rule_endless,
]

for (o, e) in zip(ordered, expected)
    @test get(o.from) == get(e.from)
    @test isnull(o.to) == isnull(e.to)
    if !isnull(o.to)
        @test get(o.to) == get(e.to)
    end
    @test o.month == e.month
    @test o.at == e.at
    @test o.at_flag == e.at_flag
    @test o.save == e.save
    @test o.letter == e.letter
end
