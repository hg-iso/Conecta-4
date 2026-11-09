% ============================================================
%  player.pl - Jugador de Conecta 4 (INF224, Evaluacion 2)
%  Tablero: lista de 7 columnas; cada columna lista las fichas
%  jugadas con la mas reciente al frente. Casilla libre = no aparece.
% ============================================================
:- module(player, [ai_move/3]).

% ---------- Hechos base ----------
rival(x, o).
rival(o, x).

% Orden de preferencia de columnas: el centro participa en mas lineas
orden([4,3,5,2,6,1,7]).
columna(C) :- orden(O), member(C, O).

% Direcciones de las lineas: horizontal, vertical y las dos diagonales
dir(1, 0).
dir(0, 1).
dir(1, 1).
dir(1, -1).

% ---------- Interpretacion del tablero (solo logica de primer orden) ----------
disponible(T, C) :-
    between(1, 7, C),
    nth1(C, T, Col),
    length(Col, N),
    N < 6.

% celda(+T,+C,+R,?V): ficha V en columna C, fila R (fila 1 = abajo).
% Falla si la casilla esta libre o fuera del tablero.
celda(T, C, R, V) :-
    between(1, 7, C),
    nth1(C, T, Col),
    length(Col, N),
    between(1, N, R),
    I is N - R,
    nth0(I, Col, V).

libre(T, C, R) :-
    between(1, 7, C),
    between(1, 6, R),
    nth1(C, T, Col),
    length(Col, N),
    R > N.

% jugar(+T,+C,+F,-T2): T2 es T tras soltar F en C (no modifica T)
jugar(T, C, F, T2) :-
    nth1(C, T, Col, Resto),
    nth1(C, T2, [F|Col], Resto).

% ---------- Lineas de cuatro ----------
ventana(_, _, _, _, _, _, 0, 0).
ventana(T, F, C, R, DC, DR, N, H) :-
    N > 0,
    celda(T, C, R, F),
    C1 is C + DC, R1 is R + DR, N1 is N - 1,
    ventana(T, F, C1, R1, DC, DR, N1, H).
ventana(T, F, C, R, DC, DR, N, H) :-
    N > 0, H > 0,
    libre(T, C, R),
    C1 is C + DC, R1 is R + DR, N1 is N - 1, H1 is H - 1,
    ventana(T, F, C1, R1, DC, DR, N1, H1).

linea_por(T, F, C, R, H) :-
    dir(DC, DR),
    between(0, 3, K),
    C0 is C - K * DC,
    R0 is R - K * DR,
    ventana(T, F, C0, R0, DC, DR, 4, H).

% ---------- Estrategia 1: jugadas ganadoras ----------
gana_jugando(T, F, C) :-
    disponible(T, C),
    jugar(T, C, F, T2),
    nth1(C, T2, Col),
    length(Col, R),
    linea_por(T2, F, C, R, 0).

% ---------- Estrategia 3: evitar que el rival gane ----------
segura(T, F, C) :-
    disponible(T, C),
    rival(F, R),
    jugar(T, C, F, T2),
    \+ gana_jugando(T2, R, _).

% ---------- Estrategia 2: mas chances de ganar ----------
crea_amenaza(T, F, C) :-
    disponible(T, C),
    jugar(T, C, F, T2),
    gana_jugando(T2, F, _).

crea_doble(T, F, C) :-
    disponible(T, C),
    jugar(T, C, F, T2),
    gana_jugando(T2, F, C1),
    gana_jugando(T2, F, C2),
    C1 \= C2.

crea_potencial(T, F, C) :-
    disponible(T, C),
    jugar(T, C, F, T2),
    nth1(C, T2, Col),
    length(Col, R),
    linea_por(T2, F, C, R, 1).

fuerte(T, F, C) :-
    segura(T, F, C),
    rival(F, R),
    jugar(T, C, F, T2),
    \+ crea_doble(T2, R, _).

% ---------- Jerarquia de decision ----------
decision(F, T, C) :- gana_jugando(T, F, C).
decision(F, T, C) :- rival(F, R), gana_jugando(T, R, C).
decision(F, T, C) :- columna(C), segura(T, F, C), crea_doble(T, F, C).
decision(F, T, C) :- rival(F, R), columna(C), crea_doble(T, R, C), segura(T, F, C).
decision(F, T, C) :- columna(C), fuerte(T, F, C), crea_amenaza(T, F, C).
decision(F, T, C) :- columna(C), fuerte(T, F, C), crea_potencial(T, F, C).
decision(F, T, C) :- columna(C), fuerte(T, F, C).
decision(F, T, C) :- columna(C), segura(T, F, C).
decision(_, T, C) :- columna(C), disponible(T, C).

ai_move(F, T, C) :- decision(F, T, C), !.
