% Acts as an interface to the system. Configures load paths and provides
% predicates for initiating the system.

%   bson_configure_globals is det.
%
%   Configures useful globals used throughout the session.

bson_configure_globals :-
    % For optimized compiles, tests are by default ignored.
    set_test_options([load(always)]).
    % Try to make everything as UTF-8 as possible.
    % set_prolog_flag(encoding, utf8). % When using streams, global setting.
    % Hunting implicit dependencies is easier without autoload.
    % set_prolog_flag(autoload, false),
    % Displays how modules and such are located.
    % set_prolog_flag(verbose_file_search, true).

%   bson_configure_load_paths is det.
%
%   Configures internal load paths in preparation of use_module calls.

bson_configure_load_paths :-
    prolog_load_context(directory, Root), % Available only during compilation.
    bson_configure_path(Root, 'lib', foreign),
    bson_configure_path(Root, 'src/misc', misc),
    bson_configure_path(Root, 'src', bson).

bson_configure_path(PathPrefix, PathSuffix, Name) :-
    atomic_list_concat([PathPrefix,PathSuffix], '/', Path),
    asserta(user:file_search_path(Name, Path)).

% Set everything up.
:- bson_configure_globals.
:- bson_configure_load_paths.

% Simply loading this module claims to speed up phrase, maplist, etc.,
% but I haven't noticed much difference.
% :- use_module(library(apply_macros)).

:- include(misc(common)).

bson_load_project_modules :-
    use_module(library(pldoc), []), % Load first to enable comment processing.
    use_module(bson(bson), []).

bson_load_project_tests :-
    plunit:load_test_files([]).

%%  bson_test is det.
%
%   Loads everything and runs the test suite.

bson_test :-
    bson_load_project_modules,
    bson_load_project_tests,
    bson_run_test_suite.

bson_run_test_suite :-
    core:format('~n% Run tests ...~n'),
    plunit:run_tests.

%%  bson_cov is det.
%
%   Loads everything and runs the test suite with coverage analysis.

bson_cov :-
    bson_load_project_modules,
    bson_load_project_tests,
    bson_run_test_suite_with_coverage.

bson_run_test_suite_with_coverage :-
    core:format('~n% Run tests ...~n'),
    plunit:show_coverage(plunit:run_tests).

%%  bson_repl is det.
%
%   Loads everything and enters interactive mode.

bson_repl :-
    bson_load_project_modules,
    bson_load_project_tests.
