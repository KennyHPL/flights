% $Id: functions.pl,v 1.3 2016-11-08 15:04:13-08 - - $

mathfns( X, List ) :-
   S is sin( X ),
   C is cos( X ),
   Q is sqrt( X ),
   List = [S, C, Q].

constants( List ) :-
   Pi is pi,
   E is e,
   Epsilon is epsilon,
   List = [Pi, E, Epsilon].

sincos( X, Y ) :-
   Y is sin( X ) ** 2 + cos( X ) ** 2.

haversine_radians( Lat1, Lon1, Lat2, Lon2, Distance ) :-
   Dlon is Lon2 - Lon1,
   Dlat is Lat2 - Lat1,
   A is sin( Dlat / 2 ) ** 2
      + cos( Lat1 ) * cos( Lat2 ) * sin( Dlon / 2 ) ** 2,
   Dist is 2 * atan2( sqrt( A ), sqrt( 1 - A )),
   Distance is Dist * 3961.

degmin_to_rads( degmin( Degrees, Minutes ), Rads ) :-
    Degs is Degrees + Minutes / 60,
    Rads is Degs * pi / 180.

distance(Airport1, Airport2, Distance) :-
  airport(Airport1,_,Lat1, Lon1),
  airport(Airport2,_,Lat2, Lon2),
  degmin_to_rads(Lat1, Lat1R),
  degmin_to_rads(Lat2, Lat2R),
  degmin_to_rads(Lon1, Lon1R),
  degmin_to_rads(Lon2, Lon2R),
  haversine_radians(Lat1R,Lon1R,Lat2R,Lon2R,Distance).

%
%Prolog version of not
%
not( X ) :- X, !, fail.
not( _ ).

%
%Time handling code
%

dist_to_time(Distance, Hours) :-
 Hours is Distance/500.

convert_time(time(Hours, Mins), Total_hours) :-
  Total_hours is Hours+Mins/60.

print_digs(Digits) :-
  Digits < 10, write( 0 ), write( Digits ).
print_digs(Digits) :-
  Digits >= 10, write( Digits ).

print_time(Total_hours) :-
  M is floor(Total_hours*60),
  H is M // 60,
  Ms is M mod 60,
  print_digs( H ), write( ':' ), print_digs( Ms ).

listflight(Terminal, Terminal, _, [Terminal], _).
listflight(Prev, Terminal, Visited, [[Prev, Departure, Arrival] | List],
           DepTime):-
  flight(Prev, Terminal, DepTime),
  not(member(Terminal, Visited)),
  convert_time(DepTime, Departure),
  distance(Prev, Terminal, Distance),
  dist_to_time(Distance, Hours),
  Arrival is Departure + Hours,
  Arrival < 24.0,
  listflight(Terminal, Terminal, [Terminal|Visited], List, _).
listflight(Prev, Terminal, Visited, [[Prev, Departure, Arrival] | List],
           DepTime):-
  flight(Prev, Next, DepTime),
  not(member(Next, Visited)),
  convert_time(DepTime, Departure),
  distance(Prev, Terminal, Distance),
  dist_to_time(Distance, Hours),
  Arrival is Departure + Hours,
  Arrival < 24.0,
  flight(Next, _, Next_dep),
  convert_time(Next_dep, Next_f_dep),
  NewTime is Next_f_dep - Arrival - 0.5,
  NewTime >= 0,
  listflight(Next, Terminal, [Next|Visited], List, Next_dep).

writepath([]) :-
  nl.
writepath( [[X, XDTime, XATime], Y | []] ) :-
    airport( X, Depart_Ext, _, _), airport( Y, Arrive_Ext, _, _),
    write( '     ' ), write( 'depart  ' ),
    write( X ), write( '  ' ),
    write( Depart_Ext ), print_time( XDTime ), nl,
    write( '     ' ), write( 'arrive  ' ),
    write( Y ), write( '  ' ),
    write( Arrive_Ext ), print_time( XATime ), nl,
    !, true.

writepath( [[X, XDTime, XATime], [Y, YDTime, YATime] | Z] ) :-
    airport( X, Depart_Ext, _, _), airport( Y, Arrive_Ext, _, _),
    write( '     ' ), write( 'depart  ' ),
    write( X ), write( '  ' ),
    write( Depart_Ext ), print_time( XDTime ), nl,
    write( '     ' ), write( 'arrive  ' ),
    write( Y ), write( '  ' ),
    write( Arrive_Ext ), print_time( XATime ), nl,
    !, writepath( [[Y, YDTime, YATime] | Z] ).

fly( Depart, Arrive ) :-
    airport( Depart, _, _, _ ),
    airport( Arrive, _, _, _ ),

    listflight( Depart, Arrive, [Depart], List, _ ),
    !, nl,
    writepath( List ),
    true.

fly( Depart, Arrive ) :-
    airport( Depart, _, _, _ ),
    airport( Arrive, _, _, _ ),
    write( 'Error: flight from: ' ), write(Depart),
    write( ' to '), write(Arrive), write( ' is not possible.' ),
    !, fail.

fly( Depart, Depart ) :-
    write( 'Error: the departure and arrival of: ' ), write(Depart),
    write( ' to '), write(Depart), write( ' are the same.' ),
    nl,
    !, fail.

fly( _, _) :-
    write( 'Error: nonexistent airports.' ), nl,
!, fail.
