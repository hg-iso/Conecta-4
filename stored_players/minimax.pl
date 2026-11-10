% ============================================================
%  player.pl  -  Jugador Conecta 4: Minimax (negamax) + poda alfa-beta
%  INF224 Logica para Ciencias de la Computacion - UCM 2026
% ------------------------------------------------------------
%  Estrategia:
%   * El tablero (listas de columnas) se convierte UNA vez a dos
%     enteros ("bitboards"): Pos = fichas de quien mueve,
%     Mask = todas las fichas. Cada columna usa 7 bits (6 filas
%     + 1 bit centinela), asi las operaciones de bits no se
%     "enrollan" entre columnas. Esto hace la busqueda muy rapida.
%   * Negamax con poda alfa-beta, orden centro-primero.
%   * Profundizacion iterativa con presupuesto de tiempo: busca
%     profundidad 1, 2, 3... mientras quede tiempo; la mejor
%     jugada de la iteracion anterior se prueba primero.
%   * Hojas: heuristica de amenazas (casillas que completarian 4),
%     con bonus por paridad de fila y control del centro.
%   * Sin assert ni retract. Siempre entrega una columna valida.
% ============================================================

:- module(player, [ai_move/3]).

presupuesto(0.3).          % segundos aprox. por jugada
inf(1000000).

% ------------------------------------------------------------
%  ai_move(+Ficha, +Tablero, -Columna)
% ------------------------------------------------------------
ai_move(_Ficha, [[],[],[],[],[],[],[]], 4) :- !.          % apertura: centro
ai_move(Ficha, Tablero, Columna) :-
    tiene_libre(Tablero),
    bits(Tablero, Ficha, Pos, Mask),
    popcount(Mask, N),
    Max is min(42 - N, 24),
    get_time(T0),
    presupuesto(Pres),
    iterar(1, Max, T0, Pres, [4,3,5,2,6,1,7], Pos, Mask, Columna),
    nth1(Columna, Tablero, Fichas),
    length(Fichas, L), L < 6,                            % validacion final
    !.
ai_move(_Ficha, Tablero, Columna) :-                     % respaldo
    columna_disponible(Tablero, Columna),
    !.

tiene_libre(Tablero) :- columna_disponible(Tablero, _), !.

% columna_disponible(+Tablero, -Columna)
columna_disponible(Tablero, Columna) :-
    between(1, 7, Columna),
    nth1(Columna, Tablero, Fichas),
    length(Fichas, N),
    N < 6.

% ------------------------------------------------------------
%  Profundizacion iterativa
% ------------------------------------------------------------
iterar(D, Max, T0, Pres, Orden, Pos, Mask, Col) :-
    get_time(Ta),
    inf(Inf), NInf is -Inf,
    mejor(Orden, Pos, Mask, D, NInf, Inf, none, NInf, Mv, V),
    get_time(Tb),
    Dur is Tb - Ta,
    Total is Tb - T0,
    (   ( D >= Max ; abs(V) >= 9000 ; Total + 6 * Dur > Pres ; Mv == none )
    ->  ( Mv == none -> Orden = [Col|_] ; Col = Mv )
    ;   subtract(Orden, [Mv], Resto),
        D1 is D + 1,
        iterar(D1, Max, T0, Pres, [Mv|Resto], Pos, Mask, Col)
    ).

% ------------------------------------------------------------
%  negamax(+Pos, +Mask, +Prof, +Alfa, +Beta, -Valor)
%  Valor desde el punto de vista de quien mueve.
% ------------------------------------------------------------
negamax(Pos, Mask, Prof, Alfa, Beta, Valor) :-
    (   Prof =:= 0
    ->  evaluar(Pos, Mask, Valor)
    ;   inf(Inf), NInf is -Inf,
        mejor([4,3,5,2,6,1,7], Pos, Mask, Prof, Alfa, Beta, none, NInf, _, V0),
        (   V0 =:= NInf -> Valor = 0 ; Valor = V0 )     % sin jugadas: empate
    ).

% mejor(+Cols, +Pos, +Mask, +Prof, +Alfa, +Beta, +M0, +V0, -M, -V)
mejor([], _, _, _, _, _, M, V, M, V).
mejor([Col|Cols], Pos, Mask, Prof, Alfa, Beta, M0, V0, M, V) :-
    C0 is Col - 1,
    (   Mask /\ (1 << (5 + 7*C0)) =\= 0                 % columna llena
    ->  mejor(Cols, Pos, Mask, Prof, Alfa, Beta, M0, V0, M, V)
    ;   Nuevo is (Mask + (1 << (7*C0))) /\ (63 << (7*C0)),
        PosN is Pos \/ Nuevo,
        (   cuatro(PosN)
        ->  Val is 10000 + Prof
        ;   MaskN is Mask \/ Nuevo,
            Rival is PosN xor MaskN,                    % fichas del rival
            P1 is Prof - 1,
            NA is -Beta, NB is -Alfa,
            negamax(Rival, MaskN, P1, NA, NB, V1),
            Val is -V1
        ),
        (   Val > V0 -> M1 = Col, V1b = Val ; M1 = M0, V1b = V0 ),
        A1 is max(Alfa, V1b),
        (   A1 >= Beta                                  % poda beta
        ->  M = M1, V = V1b
        ;   mejor(Cols, Pos, Mask, Prof, A1, Beta, M1, V1b, M, V)
        )
    ).

% ------------------------------------------------------------
%  Cuatro en linea en el bitboard X
% ------------------------------------------------------------
cuatro(X) :- alinea(X, 7).      % horizontal
cuatro(X) :- alinea(X, 6).      % diagonal /
cuatro(X) :- alinea(X, 8).      % diagonal \
cuatro(X) :- alinea(X, 1).      % vertical

alinea(X, S) :-
    M is X /\ (X >> S),
    M /\ (M >> (2*S)) =\= 0.

% ------------------------------------------------------------
%  Heuristica
% ------------------------------------------------------------
evaluar(Pos, Mask, V) :-
    Rival is Pos xor Mask,
    tablero_completo(Full),
    Libres is Full xor Mask,
    amenazas(Pos, Libres, WP),
    amenazas(Rival, Libres, WR),
    popcount(WP, NP), popcount(WR, NR),
    popcount(Mask, Fichas),
    base(Base),
    Impar is 21 * Base,            % filas 1,3,5 (de abajo)
    Par   is 42 * Base,            % filas 2,4,6
    (   Fichas mod 2 =:= 0         % quien mueve es el primer jugador
    ->  GP = Impar, GR = Par
    ;   GP = Par,   GR = Impar
    ),
    popcount(WP /\ GP, QP), popcount(WR /\ GR, QR),
    Centro is 63 << 21,
    popcount(Pos /\ Centro, CP), popcount(Rival /\ Centro, CR),
    V is 6*(NP - NR) + 5*(QP - QR) + 3*(CP - CR).

base(B) :- B is ((1 << 49) - 1) // 127.
tablero_completo(F) :- base(B), F is 63 * B.

% amenazas(+X, +Libres, -W): casillas libres que completarian
% cuatro en linea para el dueno de X.
amenazas(X, Libres, W) :-
    Full is (1 << 49) - 1,
    A1 is (X << 1) /\ Full, A2 is (A1 << 1) /\ Full, A3 is (A2 << 1) /\ Full,
    R0 is A1 /\ A2 /\ A3,
    dir(X, 7, Full, R0, R1),
    dir(X, 6, Full, R1, R2),
    dir(X, 8, Full, R2, R3),
    W is R3 /\ Libres.

dir(X, S, Full, R0, R) :-
    A1 is (X << S) /\ Full,
    A2 is (A1 << S) /\ Full,
    A3 is (A2 << S) /\ Full,
    B1 is X >> S, B2 is X >> (2*S), B3 is X >> (3*S),
    P1 is A1 /\ A2,
    P2 is B1 /\ B2,
    R is R0 \/ (P1 /\ A3) \/ (P1 /\ B1) \/ (P2 /\ A1) \/ (P2 /\ B3).

% ------------------------------------------------------------
%  Utilidades
% ------------------------------------------------------------
popcount(X, N) :- popcount_(X, 0, N).
popcount_(0, N, N) :- !.
popcount_(X, A, N) :- X1 is X /\ (X - 1), A1 is A + 1, popcount_(X1, A1, N).

% bits(+Tablero, +Ficha, -Pos, -Mask)
bits(Tablero, Ficha, Pos, Mask) :-
    bits_cols(Tablero, 0, Ficha, 0, Pos, 0, Mask).

bits_cols([], _, _, P, P, M, M).
bits_cols([Col|Cs], C, F, P0, P, M0, M) :-
    reverse(Col, Abajo),
    bits_col(Abajo, C, 0, F, P0, P1, M0, M1),
    C1 is C + 1,
    bits_cols(Cs, C1, F, P1, P, M1, M).

bits_col([], _, _, _, P, P, M, M).
bits_col([T|Ts], C, R, F, P0, P, M0, M) :-
    Bit is 1 << (7*C + R),
    M1 is M0 \/ Bit,
    (   T == F -> P1 is P0 \/ Bit ; P1 = P0 ),
    R1 is R + 1,
    bits_col(Ts, C, R1, F, P1, P, M1, M).
