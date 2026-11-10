% ============================================================
%  player.pl   -   PLANTILLA DE ENTREGA
%  Evaluación 2  ·  INF224 Lógica para Ciencias de la Computación
%  Nico God
%  UCM 2026
% ------------------------------------------------------------

:- module(player, [ai_move/3]).

% Jugador de Conecta 4. Tablero: lista de 7 columnas, ficha mas reciente al frente.

rival(x, o).
rival(o, x).

% columnas ordenadas de mas a menos lineas posibles (centro primero)
preferencia([4,3,5,2,6,1,7]).

% horizontal, vertical y diagonales
eje(1, 0).
eje(0, 1).
eje(1, 1).
eje(1, -1).

% columna con menos de 6 fichas
con_espacio(T, C) :-
    preferencia(O), member(C, O),
    nth1(C, T, Col), length(Col, N), N < 6.

% la casilla (C,R) tiene la ficha F (fila 1 = abajo)
ocupa(T, F, C, R) :-
    C >= 1, C =< 7, R >= 1,
    nth1(C, T, Col), length(Col, N),
    R =< N, I is N - R,
    nth0(I, Col, F).

% T2 es T despues de soltar F en la columna C
soltar(T, C, F, T2) :-
    nth1(C, T, Col, Resto),
    nth1(C, T2, [F|Col], Resto).

% fichas F seguidas desde (C,R) en una direccion, sin contar (C,R)
cuenta(T, F, C, R, DC, DR, 0) :-
    C1 is C + DC, R1 is R + DR,
    \+ ocupa(T, F, C1, R1).
cuenta(T, F, C, R, DC, DR, N) :-
    C1 is C + DC, R1 is R + DR,
    ocupa(T, F, C1, R1),
    cuenta(T, F, C1, R1, DC, DR, N1),
    N is N1 + 1.

% la ficha en (C,R) esta unida a K o mas fichas iguales (K=3 es cuatro en linea)
en_linea(T, F, C, R, K) :-
    eje(DC, DR),
    cuenta(T, F, C, R, DC, DR, A),
    DC2 is -DC, DR2 is -DR,
    cuenta(T, F, C, R, DC2, DR2, B),
    A + B >= K.

% estrategia 1: jugada ganadora
gana(T, F, C) :-
    con_espacio(T, C),
    soltar(T, C, F, T2),
    nth1(C, T2, Col), length(Col, R),
    en_linea(T2, F, C, R, 3).

% estrategia 2: mas chances de ganar
crea_amenaza(T, F, C) :-
    con_espacio(T, C),
    soltar(T, C, F, T2),
    gana(T2, F, _).

crea_doble(T, F, C) :-
    con_espacio(T, C),
    soltar(T, C, F, T2),
    gana(T2, F, C1),
    gana(T2, F, C2),
    C1 \== C2.

crea_linea(T, F, C, K) :-
    con_espacio(T, C),
    soltar(T, C, F, T2),
    nth1(C, T2, Col), length(Col, R),
    en_linea(T2, F, C, R, K).

% estrategia 3: evitar que gane el rival
segura(T, F, C) :-
    con_espacio(T, C),
    rival(F, R),
    soltar(T, C, F, T2),
    \+ gana(T2, R, _).

fuerte(T, F, C) :-
    segura(T, F, C),
    rival(F, R),
    soltar(T, C, F, T2),
    \+ crea_doble(T2, R, _).

% orden de decision
decision(F, T, C) :- gana(T, F, C).
decision(F, T, C) :- rival(F, R), gana(T, R, C).
decision(F, T, C) :- segura(T, F, C), crea_doble(T, F, C).
decision(F, T, C) :- rival(F, R), crea_doble(T, R, C), segura(T, F, C).
decision(F, T, C) :- fuerte(T, F, C), crea_amenaza(T, F, C).
decision(F, T, C) :- fuerte(T, F, C), crea_linea(T, F, C, 2).
decision(F, T, C) :- fuerte(T, F, C), crea_linea(T, F, C, 1).
decision(F, T, C) :- fuerte(T, F, C).
decision(F, T, C) :- segura(T, F, C).
decision(_, T, C) :- con_espacio(T, C).   % respaldo, nunca falla

ai_move(F, T, C) :- decision(F, T, C), !.
