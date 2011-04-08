:- module(bson_encoder,
    [
        term_to_bson/2
    ]).

% <module> BSON encoder.

:- use_module(bson_bits, []).
:- use_module(bson_unicode, []).

:- include(misc(common)).

%%  term_to_bson(+Term, ?Bson:list) is semidet.
%
%   True if xxx.

term_to_bson(Term, Bson) :-
    phrase(document(Term, _Len), Bson),
    !.
term_to_bson(_Term, _Bson) :-
    throw(bson_error(invalid)).

document(Elements, Len) -->
    bytes_n(BytesForLen, 4),
    elements(Elements, LenElements),
    [0],
    { Len is 4 + LenElements + 1 },
    { bson_bits:littlebytes_n_integer(BytesForLen, 4, Len) }.

elements(Elements, Len) -->
    elements(Elements, 0, Len).

elements([], Len, Len) --> [].
elements([Key:Value|Elements], Len0, Len) -->
    element(Key, Value, LenElement),
    { Len1 is Len0 + LenElement },
    elements(Elements, Len1, Len).

element(Key, Value, Len) -->
    [Tag],
    key(Key, KeyLen),
    value(Value, Tag, ValueLen),
    { Len is 1 + KeyLen + ValueLen }.

key(Key, Len) -->
    c_string(Key, Len).

list_shaped([]).
list_shaped([_|_]).

value(Value, Tag, Len) -->
    { inbuilt:integer(Value) }, !,
    value_integer(Value, Tag, Len).
value(Value, Tag, Len) -->
    { inbuilt:float(Value) }, !,
    value_float(Value, Tag, Len).
value(Value, Tag, Len) -->
    { inbuilt:atom(Value) }, !,
    value_atom(Value, Tag, Len).
value(Value, Tag, Len) -->
    { list_shaped(Value) }, !,
    value_list(Value, Tag, Len).
value(Value, Tag, Len) -->
    { inbuilt:compound(Value) }, !,
    value_compound(Value, Tag, Len).

value_compound(object_id(ObjectId), 0x07, 12) -->
    { object_id_atom_to_bytes(ObjectId, Bytes) },
    Bytes.
value_compound(utc(Timestamp), 0x09, 8) -->
    int64(Timestamp).
value_compound(js(JsText), 0x0D, Len) -->
    string(JsText, Len).
value_compound(js(JsText,MappingsDoc), 0x0F, Len) -->
    bytes_n(BytesForLen, 4),
    string(JsText, StrLen),
    document(MappingsDoc, DocLen),
    { Len is 4 + StrLen + DocLen },
    { bson_bits:littlebytes_n_integer(BytesForLen, 4, Len) }.
value_compound(mongostamp(Timestamp), 0x11, 8) -->
    int64(Timestamp).
value_compound(symbol(Atom), 0x0E, Len) -->
    string(Atom, Len).
value_compound(Compound, _Tag, _Len) -->
    { throw(bson_error(invalid(Compound))) }.

value_list(Pairs, 0x03, Len) -->
    document(Pairs, Len),
    !.
value_list(List, 0x04, Len) -->
    { add_array_keys(List, Pairs) },
    document(Pairs, Len),
    !.

add_array_keys(List, Array) :-
    add_array_keys(List, 0, Array).

add_array_keys([], _Index, []).
add_array_keys([Value|Values], Index, [Key:Value|Pairs]) :-
    inbuilt:atom_number(Key, Index),
    Index1 is Index + 1,
    add_array_keys(Values, Index1, Pairs).

value_float(Float, 0x01, 8) -->
    { bson_bits:bytes_float(Bytes, Float) },
    Bytes.

value_integer(Integer, 0x10, 4) -->
    { bson_bits:fits_in_32_bits(Integer) },
    !,
    int32(Integer).
value_integer(Integer, 0x12, 8) -->
    { bson_bits:fits_in_64_bits(Integer) },
    !,
    int64(Integer).

bytes_n([], 0) --> [], !.
bytes_n([Byte|Bytes], Len0) -->
    [Byte], % May be anything.
    { Len1 is Len0 - 1 },
    bytes_n(Bytes, Len1).

int32(Integer) -->
    int_size(Integer, 4).

int64(Integer) -->
    int_size(Integer, 8).

int_size(Integer, N) -->
    { bson_bits:littlebytes_n_integer(Bytes, N, Integer) },
    Bytes.

value_atom(undefined, 0x06, 0)   --> []. % Deprecated in BSON 1.0.
value_atom(false,     0x08, 1)   --> [0].
value_atom(true,      0x08, 1)   --> [1].
value_atom(null,      0x0A, 0)   --> [].
value_atom(min,       0xFF, 0)   --> [].
value_atom(max,       0x7F, 0)   --> [].
value_atom(Atom,      0x02, Len) -->
    string(Atom, Len).

c_string(Utf8, Len) -->
    { bson_unicode:utf8_bytes(Utf8, Bytes, NumBytes) },
    { Len is NumBytes + 1 },
    Bytes,
    [0].

string(Utf8, Len) -->
    { bson_unicode:utf8_bytes(Utf8, Bytes, NumBytes) },
    { NumBytesWithNul is NumBytes + 1 },
    { Len is 4 + NumBytesWithNul },
    int32(NumBytesWithNul),
    Bytes,
    [0].

object_id_atom_to_bytes(ObjectIdAtom, Bytes) :-
    inbuilt:atom_concat('0x', ObjectIdAtom, HexAtom),
    inbuilt:atom_number(HexAtom, Integer),
    % XXX This is probably wrong.
    % Machine and inc parts are big-endian. Look into this.
    bson_bits:littlebytes_n_integer(BytesLE, 12, Integer),
    lists:reverse(BytesLE, Bytes).
