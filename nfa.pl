%IS_REGEXP
%Caso base atomico
is_regexp(RE):- atomic(RE).
%caso base e passo or
is_regexp(RE):- RE=..[or,X,Y],
                is_regexp(X),
                is_regexp(Y).
is_regexp(RE):- RE=..[or,X|Xs],
                is_regexp(X),
                Z=..[or|Xs],
                is_regexp(Z).
%caso base e passo seq
is_regexp(RE):- RE=..[seq,X,Y],
                is_regexp(X),
                is_regexp(Y).
is_regexp(RE):- RE=..[seq,X|Xs],
                is_regexp(X),
                Z=..[seq|Xs],
                is_regexp(Z).
%caso base star
is_regexp(RE):- RE=..[star,X],
                is_regexp(X).
%caso base star
is_regexp(RE):- RE=..[plus,X],
                is_regexp(X).

%NFA_REGEXP_COMP
%caso base atomico: scrive delta per un atomo
nfa_regexp_comp(FA_Id, RE):- atomic(RE),
                             gensym(q, X),
                             gensym(q, Y),
                             assert(nfa_initial(FA_Id, X)),
                             assert(nfa_final(FA_Id, Y)),
                             assert(nfa_delta(FA_Id, X, RE, Y)).
%caso star
%controlla che la RE sia star e lancia comp su i suoi argomenti
%genera un nuovo nodo iniziale e un nuovo nodo finale
%prende i nodi iniziali e finale dell'automa precendetemente costruito
%aggiunge alla base di conoscenza i delta con epsilon mosse
%rende i vecchi nodi inizialie  finali dei nodi semplici
%rende i nuovi nodi inizili e finali tali
nfa_regexp_comp(FA_Id, RE):- is_regexp(RE),
                             RE=.. [star, X],
                             nfa_regexp_comp(FA_Id, X),
                             gensym(q, In),
                             gensym(q, Fin),
                             nfa_initial(FA_Id, OldIn),
                             nfa_final(FA_Id, OldFin),
                             assert(nfa_delta(FA_Id, In, epsilon, OldIn)),
                             assert(nfa_delta(FA_Id, OldFin, epsilon, Fin)),
                             assert(nfa_delta(FA_Id, In, epsilon, Fin)),
                             assert(nfa_delta(FA_Id, OldFin, epsilon, OldIn)),
                             retract(nfa_initial(FA_Id, OldIn)),
                             retract(nfa_final(FA_Id, OldFin)),
                             assert(nfa_initial(FA_Id, In)),
                             assert(nfa_final(FA_Id, Fin)).
%caso seq
%caso base
nfa_regexp_comp(FA_Id, RE):- is_regexp(RE),
                            RE=.. [seq, X, Y],
                            gensym(FA_Id, NewId1),
                            gensym(FA_Id, NewId2),
                            nfa_regexp_comp(NewId1, X),
                            nfa_regexp_comp(NewId2, Y),
                            nfa_final(NewId1, Fin1),
                            nfa_initial(NewId2, In2),
                            assert(nfa_delta(FA_Id, Fin1, epsilon, In2)),
                            retract(nfa_final(NewId1, Fin1)),
                            retract(nfa_initial(NewId2, In2)),
                            rename_initial(NewId1, FA_Id),
                            rename_deltas(NewId1, FA_Id),
                            rename_deltas(NewId2, FA_Id),
                            rename_final(NewId2, FA_Id).

%caso passo seq
%creo il sotto automa formato da seq(Xs), xs sono tutti gli argomenti tranne il
%primo
%creo automa per il primo elemento
%collego il final del primo automa al restante
%rinomino il primo automa con id correto
nfa_regexp_comp(FA_Id, RE):- is_regexp(RE),
                             RE=.. [seq,X|Xs],
                             SubRE=.. [seq|Xs],
                             nfa_regexp_comp(FA_Id, SubRE),
			                       gensym(FA_Id, NewId),
                             nfa_regexp_comp(NewId, X),
			                       nfa_final(NewId, OldFin1),
                             nfa_initial(FA_Id, OldIn2),
			                       assert(nfa_delta(FA_Id, OldFin1, epsilon, OldIn2)),
			                       retract(nfa_final(NewId, OldFin1)),
                             retract(nfa_initial(FA_Id, OldIn2)),
			                       rename_initial(NewId, FA_Id),
                             rename_deltas(NewId, FA_Id).

%Caso base or
%Crea due nuovi Id per i due casi
%crea due nuovi stati iniziali e finali fasulli
%genera i due sotto-automi
%collega i due dfa ai nuovi stati iniziali e finali
%elimina initial e final dei sotto alberi e rinomina i delta
nfa_regexp_comp(FA_Id, RE):- is_regexp(RE),
                             RE=.. [or,X,Y],
                             gensym(FA_Id, NewId1),
                             gensym(FA_Id, NewId2),
			                       gensym(q, FinState),
                             gensym(q, InState),
                             nfa_regexp_comp(NewId1, X),
                             nfa_regexp_comp(NewId2, Y),
			                       nfa_initial(NewId1, In1),
                             nfa_initial(NewId2, In2),
                             nfa_final(NewId1, Fin1),
                             nfa_final(NewId2, Fin2),
			                       assert(nfa_delta(FA_Id, InState, epsilon, In1)),
                             assert(nfa_delta(FA_Id, InState, epsilon, In2)),
			                       assert(nfa_delta(FA_Id, Fin1, epsilon, FinState)),
                             assert(nfa_delta(FA_Id, Fin2, epsilon, FinState)),
			                       retract(nfa_initial(NewId1, In1)),
                             retract(nfa_initial(NewId2, In2)),
                             retract(nfa_final(NewId1, Fin1)),
                             retract(nfa_final(NewId2, Fin2)),
			                       assert(nfa_initial(FA_Id, InState)),
                             assert(nfa_final(FA_Id, FinState)),
                             rename_deltas(NewId1, FA_Id),
                             rename_deltas(NewId2, FA_Id).
%Passo or
nfa_regexp_comp(FA_Id, RE):- is_regexp(RE),
                             RE=.. [or,X|Xs],
                             SubRE=.. [or|Xs],
                             nfa_regexp_comp(FA_Id, SubRE),
                             gensym(FA_Id, NewId),
                             nfa_regexp_comp(NewId, X),
                             nfa_final(NewId, OldFin),
                             nfa_initial(NewId, OldIn),
                             nfa_final(FA_Id, NewFin),
                             nfa_initial(FA_Id, NewIn),
                             assert(nfa_delta(FA_Id, NewIn, epsilon, OldIn)),
                             assert(nfa_delta(FA_Id, OldFin, epsilon, NewFin)),
                             retract(nfa_final(NewId, OldFin)),%cancella initial e final del nuovo ID
                             retract(nfa_initial(NewId, OldIn)),
                             rename_deltas(NewId, FA_Id).
%CASO PLUS
%Si può svolgere in due modi:
%1.chiamando la compilazione di una nuova regexp (seq(X, star(X))
%2. In maniera simile allo star (commentato)
nfa_regexp_comp(FA_Id,RE):- is_regexp(RE),
                            RE=.. [plus,X],
                            nfa_regexp_comp(FA_Id, seq(X, star(X))).
/*%nfa_regexp_comp(FA_Id,RE):- is_regexp(RE),
                               RE=.. [plus,X],
                               nfa_regexp_comp(FA_Id,X),
                               gensym(q,In),
                               gensym(q,Fin),
                               nfa_initial(FA_Id,OldIn),
                               nfa_final(FA_Id,OldFin),
                               assert(nfa_delta(FA_Id,In,epsilon,OldIn)),
                               assert(nfa_delta(FA_Id,OldFin,epsilon,Fin)),
                               assert(nfa_delta(FA_Id,OldFin,epsilon,OldIn)),
                               retract(nfa_initial(FA_Id,OldIn)),
                               retract(nfa_final(FA_Id,OldFin)),
                               assert(nfa_initial(FA_Id,In)),
                               assert(nfa_final(FA_Id,Fin)).*/

%rename
%Predicati per semplificare la rinominazione dei nodi
rename_final(OldId, NewId):- nfa_final(OldId, Y),
                             retract(nfa_final(OldId, Y)),
                             assert(nfa_final(NewId, Y)).
rename_initial(OldId, NewId):- nfa_initial(OldId, X),
                               retract(nfa_initial(OldId, X)),
                               assert(nfa_initial(NewId, X)).
rename_delta(OldId, NewId):- nfa_delta(OldId, Q1, W, Q2),
                             retract(nfa_delta(OldId, Q1, W, Q2)),
                             assert(nfa_delta(NewId, Q1, W, Q2)).
rename_deltas(OldId, NewId):- forall(rename_delta(OldId, NewId), true).
%NFA_TEST
nfa_test(FA_Id, Input):- nfa_initial(FA_Id, S),
                         accept(FA_Id, Input, S).
%accept
accept(FA_Id, [], Q):- nfa_final(FA_Id, Q).
accept(FA_Id, Xs, Q):- nfa_delta(FA_Id, Q, epsilon, S),
                     accept(FA_Id, Xs, S).
accept(FA_Id, [X|Xs], Q):- nfa_delta(FA_Id, Q, X, S),
                         accept(FA_Id, Xs, S).
%clear
nfa_clear():- forall(retract(nfa_final(Y, X)), true),
              forall(retract(nfa_initial(Y, X)), true),
              forall(retract(nfa_delta(_, _, _, _)), true).
nfa_clear(FA_Id):- retract(nfa_final(FA_Id, _)),
                   retract(nfa_initial(FA_Id, _)),
                   forall(retract(nfa_delta(FA_Id, _, _, _)), true).
