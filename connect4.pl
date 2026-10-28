% --- Connect-4 in Prolog ---
% Run with: ?- play.
% Execute with: swipl -s jugar.pl -g play -t halt
:- use_module('rndplay.pl', [ rnjesus/3 ]).
%   use_module('player.pl', [ ai_move/3 as player1_move ]),
%   use_module('player.pl', [ ai_move/3 as player2_move ]).
:- dynamic config/1.

% Parameters
config(X):-
    dconf(X).
dconf(start(0)).          % Random rounds played before start
dconf(delay(0)).          % Extend the response time of atomatic players
dconf(difficulty(n)).     % set random player difficulty (e: easy, n:normal, h:hard)
dconf(p_mode(x, rand)).   % use user(auto/rand) to ask a human(an AI/random) player
dconf(p_mode(o, rand)).   % use user(auto/rand) to ask a human(an AI/random) player
dconf(manual_check(n)).   % use n(y) to (not) allow manual invalid moves
dconf(pout(n)).           % use y(n) to (not) save match results in matches.csv
dconf(show(y)).           % use y(n) to (not) show the board and midgame messages
dconf(ntest(1000)).       % number of games to play in test
initial_board([[],[],[],[],[],[],[]]).

%--- Test Modes
run_play:-
    asserta(config(pout(y))),
    asserta(config(show(n))),
    get_time(T1),
    asserta(config(p_mode(x, rand))),
    config(ntest(N)),
    test_play(N, T1, T1t),
    format('~n~tPlayed ~d games as X in ~2f s~t~40|~n',[N, T1t]),
    retract(config(p_mode(x, rand))),
    asserta(config(p_mode(o, rand))),
    get_time(T2),
    test_play(N, T2, T2t),
    format('~n~tPlayed ~d games as O in ~2f s~t~40|~n',[N, T2t]),
    retract(config(p_mode(o, rand))),
    retract(config(show(n))),
    retract(config(pout(y))), !.
test_play(1, Tini, Ttotal):-
    play,
    get_time(Tend),
    Ttotal is Tend-Tini,!.
test_play(Games, Tini, Ttotal):-
    Left is Games-1,
    play,
    test_play(Left, Tini, Ttotal).

%--- Play the game
play :-
    config(start(RndRounds)),
    rand_start(RndRounds, Board),
    display_board(Board),
    play_turn(x, Board, [0.0, 0.0]), !.

% Play a turn    
play_turn(Player, Board, Times):-
    turn_message(start, Player),
    move(Player, Board, Times, [Cplayed, NewBoard], NewTimes),
    display_board(NewBoard),!,
    end_turn(Player, [Cplayed, NewBoard], NewTimes).

end_turn(Loser,[_, Loser],Times):-
    switch(Loser, Winner),
    turn_message(end, _),
    turn_message(win, Winner),
    export_game(Winner, error, Times),
    turn_message(finish, Times),!.
end_turn(Winner, Step, Times) :-
    winner(Step, Winner),
    turn_message(end, _),
    turn_message(win, Winner),
    export_game(Winner, normal,Times),
    turn_message(finish, Times), !.
end_turn(_, [_, Board], Times) :-
    full(Board),
    turn_message(tie, _),
    tie_breaker(Times, Winner),
    turn_message(tiebreak, Winner),
    export_game(Winner, tiebreak, Times),
    turn_message(finish, Times), !.
end_turn(Player, [_, Board], Times) :-
    switch(Player,Next),
    play_turn(Next, Board, Times),!.

% Player move
move(Player, Board, Times, [Played_col, NewBoard], NewTimes):-
    config(p_mode(Player, Mode)),
    player_move(Player, Mode, Board, Played_col, Dtime),
    update_times(Dtime, Player, Times, NewTimes),
    extend_wait(Player, Dtime),
    add_token(Board, Played_col, Player, NewBoard),!.

extend_wait(Player,_):-
    config(p_mode(Player, user)), !.
extend_wait(Player, Dtime):-
    config(p_mode(Player,_)),
    config(delay(Sfactor)),
    Wait is Dtime * Sfactor,
    sleep(Wait).
    
update_times(Dtime, x, [Ptime, Otime], [Ctime, Otime]):-
    Ctime is Ptime + Dtime.
update_times(Dtime, o, [Otime, Ptime], [Otime, Ctime]):-
    Ctime is Ptime + Dtime.

tie_breaker([T1, T2], x):-
    Diff is T2-T1,
    0.0002 < Diff.
tie_breaker([T1, T2], o):-
    Diff is T1-T2,
    0.0002 < Diff,
    turn_message(tiebreak, o),
    export_game(o, tiebreak, [T1, T2]),!.
tie_breaker([T1, T2], tie):-
    export_game(t, tie, [T1, T2]),
    turn_message(tiebreak, none).

% Set AIs or Player moves
player_move(Token, Mode, Board, Pos, Dtime):-
    get_time(Ini),
    player_type(Token, Mode, Board, Pos),
    get_time(Fin), !,
    Dtime is Fin-Ini,
    move_message(Dtime, Pos).
player_type(x, auto, Board, Column):-
    player1_move(x, Board, Column).
player_type(o, auto, Board, Column):-
    player2_move(o, Board, Column).
player_type(_, user, Board, Column):-
    human_move(Board, Column).
player_type(_, rand, Board, Column):-
    config(difficulty(D)),
    rnjesus(D, Board, Column).

    
% Basic Human move input
human_move(Board, Pos):-
    write('Elige tu columna (1-7): '), read(Pos),
    guard_check(Board, Pos), !.
human_move(Board, Pos):-
    format('~`-tMal movimiento, vuelve a intentar!~`-t~40|~n'),
    human_move(Board, Pos).    

guard_check(Board, Col):-  
    integer(Col),
    Col > 0, Col < 8,
    guard_check_(Board, Col).
guard_check_(Board, Col):-
    config(manual_check(y)), !,
    nth1(Col, Board, Column),
    length(Column, Nc), Nc < 6.
guard_check_(_,_).
    
%--- Board Management
%Display tokens
fill(x,'X').
fill(o,'O').

%Show Board
display_board(_):-
    config(show(n)),!.
display_board(Player) :-
    atom(Player),
    fill(Player,Out),
    format('~n~`-t~40|~n~tJugada Invalida de ~w~t~40|~n',[Out]),
    format('~`-t~40|~n~tJUGADOR ~w DESCALIFICADO!~t~40|~n',[Out]),!.
display_board(Board) :-
    nl, format('~t┌───┬───┬───┬───┬───┬───┬───┐~t~40|~n'),
    draw_rows(6,Board),
    format('~t└───┴───┴───┴───┴───┴───┴───┘~t~40|~n~n'),!.

draw_rows(1, Board) :-
    row_tokens(1, Board, Tokens),
    format('~t| ~w | ~w | ~w | ~w | ~w | ~w | ~w |~t~40|~n', Tokens).
draw_rows(Row, Board) :-
    row_tokens(Row, Board,  Tokens),
    format('~t| ~w | ~w | ~w | ~w | ~w | ~w | ~w |~t~40|~n', Tokens),
    format('~t├───┼───┼───┼───┼───┼───┼───┤~t~40|~n'),
    Nrow is Row-1,
    draw_rows(Nrow, Board), !.

%-- Messages
move_message(_, _):-
    config(show(n)),!.
move_message(Delta, Pos):-
    Micro is round(Delta*1000000),
    format('~n~tColumna: ~d~tTiempo: ~3d ms~t~40|~n',[Pos,Micro]).

turn_message(_, _):-
    config(show(n)),!.
turn_message(start, Player):-
    fill(Player, Out),
    format('~`-t~40|~n~3|Jugador ~w esta pensando...~t~t~40|~n',[Out]),
    format('~`-t~40|~n').    
turn_message(end, _):-
    format('~tFin del Juego!~t~40|~n').
turn_message(win, Player):-
    fill(Player, Out),
    format('~tGanador: ~w~t~40|~n', [Out]).
turn_message(finish, Times):-
    format('~n~tTiempo X~tTiempo O~t~40|~n'),
    multiply(Times, 1000, Timems),
    format('~t~1f ms~t~1f ms~t~40|~n',Timems).
turn_message(tie, _):-
    format('~tFin del Juego~t~40|~n~tEmpate!~t~40|~n').
turn_message(tiebreak, none):-
    format('~tEmpate completo!~t~40|~n').
turn_message(tiebreak, Player):-
    fill(Player, Out),
    format('~tJugador ~w gano por tiempo!~t~40|~n',[Out]).

%Change and explore values in the board
row_tokens(Row, Board, Tokens):-
    get_row([Row, 1], Board, Tokens),!.
get_row([_, 8], _, []).
get_row([Row, Col], Board, [Token| Other_tokens]):-
    get_token(Board, [Col, Row], Player),
    fill(Player,Token),
    NCol is Col + 1,
    get_row([Row, NCol], Board, Other_tokens).
get_row([Row, Col], Board, [' '| Other_tokens]):-
    NCol is Col + 1,
    get_row([Row, NCol], Board, Other_tokens).
    
add_token(Board, Col, Player, NewBoard) :-
    Col >= 1, Col =< 7,
    nth1(Col, Board, Old_column, Tboard),
    length(Old_column, Clevel),
    Clevel<6,
    nth1(Col, NewBoard, [Player| Old_column], Tboard),!.
add_token(_,_,Player,Player).
get_token(Board, [Col, Row], Val):-
    nth1(Col, Board, Column),
    length(Column, Nr), Rval is Nr - Row,
    nth0(Rval, Column, Val).

%--- Utilities
export_game(Winner, EndType, Times):-
    config(pout(y)),
    open('match.csv',append,Fd),
    multiply(Times, 1000, [T1, T2]),
    format(Fd, '"~w","~w",~4f,~4f~n',[Winner, EndType, T1, T2]),
    close(Fd),!.
export_game(_, _, _).

multiply([], _, []).
multiply([H|T], Mul, [Mh|Mt]):-
    multiply(T, Mul, Mt),
    Mh is H*Mul.

% Switch player
switch(x, o).
switch(o, x).

% Check if the board is full
full(Board) :-
    full_(Board, Count), !,
    Count = 42.
full_([Col| Rest], Total):-
    full_(Rest, Subtotal),!,
    length(Col, N),
    Total is Subtotal + N.
full_([],0).

% Winner detection
winner([Cplayed, Board], Player) :-
    nth1(Cplayed, Board, Column),
    length(Column, Rplayed),!,
    get_token(Board, [Cplayed, Rplayed], Player),
    connected4(Board, [Cplayed, Rplayed]).

connected4(Board, Coord_played):-
    get_token(Board, Coord_played, Player),
    check_line(Board, Coord_played, Player, Connected),
    Connected >2, !.
check_line(Board, Coord, Player, Count):- % Horizontal Check
    count_adyacent(Board, Coord, [1,0], Player, C1),
    count_adyacent(Board, Coord, [-1,0], Player, C2),
    Count is C1 + C2.
check_line(Board, Coord, Player, Count):- % Diag. Ascend Check
    count_adyacent(Board, Coord, [1,1], Player, C1),
    count_adyacent(Board, Coord, [-1,-1], Player, C2),
    Count is C1 + C2.
check_line(Board, Coord, Player, Count):- % Diag. Descend Check
    count_adyacent(Board, Coord, [1,-1], Player, C1),
    count_adyacent(Board, Coord, [-1,1], Player, C2),
    Count is C1 + C2.
check_line(Board, Coord, Player, Count):- % Vertical Check
    count_adyacent(Board, Coord, [0,-1], Player, Count).

count_adyacent(Board, [Col, Row], [Dx, Dy], Player, Count):-
    Nrow is Row + Dy,
    Ncol is Col + Dx,
    get_token(Board, [Ncol, Nrow], Player),
    count_adyacent(Board, [Ncol, Nrow], [Dx, Dy], Player, Remain),
    !, Count is Remain + 1.
count_adyacent(_,_,_,_,0).

% Random Kickstart
rand_start(Rounds, OutBoard):-
    initial_board(Board),
    Rounds < 4, Turns is Rounds*2,
    rand_start_(Turns, x, Board, OutBoard), !.
rand_start_(N, Player, InBoard, OutBoard) :-
    rnjesus(n, InBoard, Move),
    Next is N-1,
    add_token(InBoard, Move, Player, TmpBoard),
    switch(Player, Nplayer),
    rand_start_(Next, Nplayer, TmpBoard, OutBoard).
rand_start_(0, _, Board, Board).
