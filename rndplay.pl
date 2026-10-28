:- module(rnjesus, [rnjesus/3]).
:- use_module(library(random)).

% Set AIs moves to random empty spaces or human input
rnjesus(Dificulty, Board, Choice):-
    count_board(Board, Turn),
    dificulty_move(Dificulty, Turn, Board, Choice).

% Selection pools
mvs(n, [1,2,3,4,5,6,7]).
mvs(e, [1,2,6,7]).
mvs(h, [3,4,5]).

avail_mvs(Mode, Board, Moves):-
    mvs(Mode, All_moves),
    check_available(All_moves, Board, Moves), !.
check_available([Move| More_moves], Board, [Move| Avail_moves]):-
    nth1(Move, Board, Tokens),
    length(Tokens, Nc),
    Nc < 6,
    check_available(More_moves, Board, Avail_moves).
check_available([_| More_moves], Board, Avail_moves):-
    check_available(More_moves, Board, Avail_moves).
check_available([], _, []).
    
% Some simple input predicates
count_board([C| T], N):-
    atom(C), !,
    length([C| T], N).
count_board([C| T], N):-
    count_board(C, N1),
    count_board(T, N2),
    N is N1 + N2.
count_board([], 0).

dificulty_move(Mode, Turn, Board, Choice):-
    Turn < 7,
    avail_mvs(Mode, Board, Moves),
    random_member(Choice, Moves).
dificulty_move(_, _, Board, Choice):-
    avail_mvs(n, Board, Moves),
    random_member(Choice, Moves).
