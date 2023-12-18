0 rem testusrf-0-4.bas
1 rem version 5 - test completed usr function
10 poke 785,0: poke 786,192:rem usr function at $c000
20 input "number";n
30 m = usr(n)
40 print n;"is ";: if not m then print "not ";
50 print "prime"
60 print "any key to continue"
70 poke 198,0:wait198,1:poke198,0
80 goto 20
