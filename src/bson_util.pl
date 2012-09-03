/** <module> Various utility predicates.
 */

:- module(_,
    [
        list_shaped/1
    ]).

:- include(bson(include/common)).

%%  list_shaped(+Term) is semidet.
%
%   True if Term looks like a list (no recursive checks).

list_shaped([]).
list_shaped([_|_]).
