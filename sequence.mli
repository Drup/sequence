(*
copyright (c) 2013, simon cruanes
all rights reserved.

redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.  redistributions in binary
form must reproduce the above copyright notice, this list of conditions and the
following disclaimer in the documentation and/or other materials provided with
the distribution.

this software is provided by the copyright holders and contributors "as is" and
any express or implied warranties, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose are
disclaimed. in no event shall the copyright holder or contributors be liable
for any direct, indirect, incidental, special, exemplary, or consequential
  damages (including, but not limited to, procurement of substitute goods or
  services; loss of use, data, or profits; or business interruption) however
  caused and on any theory of liability, whether in contract, strict liability,
  or tort (including negligence or otherwise) arising in any way out of the use
  of this software, even if advised of the possibility of such damage.
*)

(** Transient iterators, that abstract on a finite sequence of elements. They
    are designed to allow easy transfer (mappings) between data structures,
    without defining n^2 conversions between the n types. *)

type 'a t
  (** Sequence abstract iterator type, representing a finite sequence of
      values of type ['a]. *)

(** {2 Build a sequence} *)

val from_iter : (('a -> unit) -> unit) -> 'a t
  (** Build a sequence from a iter function *)

val singleton : 'a -> 'a t
  (** Singleton sequence *)

val repeat : 'a -> 'a t
  (** Infinite sequence of the same element *)

val cycle : 'a t -> 'a t
  (** Cycle forever through the given sequence. Assume the
      given sequence can be traversed any amount of times (not transient). *)

(** {2 Consume a sequence} *)

val iter : ('a -> unit) -> 'a t -> unit
  (** Consume the sequence, passing all its arguments to the function *)

val iteri : (int -> 'a -> unit) -> 'a t -> unit
  (** Iterate on elements and their index in the sequence *)

val fold : ('b -> 'a -> 'b) -> 'b -> 'a t -> 'b
  (** Fold over elements of the sequence, consuming it *)

val map : ('a -> 'b) -> 'a t -> 'b t
  (** Map objects of the sequence into other elements, lazily *)

val for_all : ('a -> bool) -> 'a t -> bool
  (** Do all elements satisfy the predicate? *)

val exists : ('a -> bool) -> 'a t -> bool
  (** Exists there some element satisfying the predicate? *)

val length : 'a t -> int
  (** How long is the sequence? *)

val is_empty : 'a t -> bool
  (** Is the sequence empty? *)

(** {2 Transform a sequence} *)

val filter : ('a -> bool) -> 'a t -> 'a t
  (** Filter on elements of the sequence *)

val append : 'a t -> 'a t -> 'a t
  (** Append two sequences *)

val concat : 'a t t -> 'a t
  (** Concatenate a sequence of sequences into one sequence *)

val take : int -> 'a t -> 'a t
  (** Take at most [n] elements from the sequence *)

val drop : int -> 'a t -> 'a t
  (** Drop the [n] first elements of the sequence *)

val rev : 'a t -> 'a t
  (** Reverse the sequence. O(n) memory. *)

(** {2 Basic data structures converters} *)

val to_list : 'a t -> 'a list

val to_rev_list : 'a t -> 'a list
  (** Get the list of the reversed sequence (more efficient) *)

val of_list : 'a list -> 'a t

val to_array : 'a t -> 'a array

val of_array : 'a array -> 'a t

val array_slice : 'a array -> int -> int -> 'a t
  (** [array_slice a i j] Sequence of elements whose indexes range
      from [i] to [j] *)

val to_stack : 'a Stack.t -> 'a t -> unit
  (** Push elements of the sequence on the stack *)

val of_stack : 'a Stack.t -> 'a t
  (** Sequence of elements of the stack (same order as [Stack.iter]) *)

val to_queue : 'a Queue.t -> 'a t -> unit
  (** Push elements of the sequence into the queue *)

val of_queue : 'a Queue.t -> 'a t
  (** Sequence of elements contained in the queue, FIFO order *)

val hashtbl_add : ('a, 'b) Hashtbl.t -> ('a * 'b) t -> unit
  (** Add elements of the sequence to the hashtable, with
      Hashtbl.add *)

val hashtbl_replace : ('a, 'b) Hashtbl.t -> ('a * 'b) t -> unit
  (** Add elements of the sequence to the hashtable, with
      Hashtbl.replace (erases conflicting bindings) *)

val to_hashtbl :('a * 'b) t -> ('a, 'b) Hashtbl.t
  (** Build a hashtable from a sequence of key/value pairs *)

val of_hashtbl : ('a, 'b) Hashtbl.t -> ('a * 'b) t
  (** Sequence of key/value pairs from the hashtable *)

val hashtbl_keys : ('a, 'b) Hashtbl.t -> 'a t
val hashtbl_values : ('a, 'b) Hashtbl.t -> 'b t

val of_str : string -> char t
val to_str :  char t -> string
val of_in_channel : in_channel -> char t

val int_range : start:int -> stop:int -> int t
  (** Iterator on integers in [start...stop] by steps 1 *)

val of_set : (module Set.S with type elt = 'a and type t = 'b) -> 'b -> 'a t
  (** Convert the given set to a sequence. The set module must be provided. *)

val to_set : (module Set.S with type elt = 'a and type t = 'b) -> 'a t -> 'b
  (** Convert the sequence to a set, given the proper set module *)

(** {2 Functorial conversions between sets and sequences} *)

module Set : sig
  module type S = sig
    type set
    include Set.S with type t := set
    val of_seq : elt t -> set
    val to_seq : set -> elt t
  end

  (** Create an enriched Set module from the given one *)
  module Adapt(X : Set.S) : S with type elt = X.elt and type set = X.t
    
  (** Functor to build an extended Set module from an ordered type *)
  module Make(X : Set.OrderedType) : S with type elt = X.t
end

(** {2 Conversion between maps and sequences.} *)

module Map : sig
  module type S = sig
    type +'a map
    include Map.S with type 'a t := 'a map
    val to_seq : 'a map -> (key * 'a) t
    val of_seq : (key * 'a) t -> 'a map
    val keys : 'a map -> key t
    val values : 'a map -> 'a t
  end

  (** Adapt a pre-existing Map module to make it sequence-aware *)
  module Adapt(M : Map.S) : S with type key = M.key and type 'a map = 'a M.t

  (** Create an enriched Map module, with sequence-aware functions *)
  module Make(V : Map.OrderedType) : S with type key = V.t
end

(** {2 Pretty printing of sequences} *)

val pp_seq : ?sep:string -> (Format.formatter -> 'a -> unit) ->
             Format.formatter -> 'a t -> unit
  (** Pretty print a sequence of ['a], using the given pretty printer
      to print each elements. An optional separator string can be provided. *)
